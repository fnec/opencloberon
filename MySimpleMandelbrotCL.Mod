MODULE MySimpleMandelbrotCL; (** AUTHOR "fnecati"; PURPOSE "a Mandelbrot demo using OpenCL"; *)

IMPORT
	Raster,  WMRectangles, WMGraphics, Modules, Math, Strings, Kernel,
	WM := WMWindowManager, WMMessages, CL := OpenCL, Utils := OpenCLUtils, 
	KernelLog;

CONST
	WindowWidth = 512; WindowHeight = 512;

TYPE
	KillerMsg = OBJECT
	END KillerMsg;

	MBWindow* =  OBJECT(WM.BufferWindow)
	VAR
		timer: Kernel.MilliTimer;

		mimage: Raster.Image;
		mode: Raster.Mode;

		platformids: POINTER TO ARRAY OF CL.cl_platform_id;
		platform: CL.cl_platform_id;
		nplatforms: LONGINT;

		deviceids : POINTER TO ARRAY OF CL.cl_device_id;
		deviceid: CL.cl_device_id;
		ndevices: LONGINT;

		context : CL.cl_context;
		commands : CL.cl_command_queue;
		prog      : CL.cl_program;       (* compute program *)
		kernel    : CL.cl_kernel;         (* compute kernel *)

		pixelmem   : CL.cl_mem;  (* The OpenCL memory object which stores the pixel data *)
		colorMapMem: CL.cl_mem; (*  An OpenCL memory object which stores a nifty color map, encoded as integers combining the RGB components of  the colors. *)
		colorMap: POINTER TO ARRAY  OF LONGINT;  (*The color map which will be copied to OpenCL for filling the PBO *)
		colormapLength: SIZE;
		x0, y0, x1, y1: REAL; (* minimum x,y-value of the area in which the Mandelbrot set should be computed *)
		maxIterations: LONGINT;
		sizeX, sizeY: LONGINT; (* size of window *)

		globalWorkSize  : ARRAY 2 OF CL.size_t; (* globalWorkSize domain size for our calculation *)

		kernelsource: Strings.String;

		 mousex1, mousey1: SIZE;
		 selecting: BOOLEAN;

		
	PROCEDURE &New(w, h: LONGINT);
	BEGIN
		Init(w, h, FALSE);
		sizeX := w;
		sizeY := h;
		manager := WM.GetDefaultManager();
		manager.Add(100, 100, SELF, {WM.FlagFrame, WM.FlagClose, WM.FlagNoResizing});

		SetTitle(Strings.NewString("SimpleMandelbrotCL: "));
		SetIcon(WMGraphics.LoadImage("WMIcons.tar://TuringCoatWnd.png", TRUE));

		(* since bpp of linuxAos WM is 16bpp, an image buffer is used. For 32bpp,  windows.img can be used directly *)
		Raster.InitMode(mode, Raster.srcCopy);
		NEW(mimage);
		Raster.Create(mimage, w, h, Raster.BGRA8888);
		IncCount;
		IF ~InitCL() THEN Close(); RETURN END;
		UpdateImage;
		
	END New;

	PROCEDURE InitCL(): BOOLEAN;
	VAR err: LONGINT;
		bufwritten : LONGINT;
		buf: ARRAY 4096 OF CHAR;
		size: CL.size_t;
	BEGIN

		globalWorkSize[0] := sizeX; globalWorkSize[1] := sizeY;

		err := CL.GetPlatformIDs( 0, 0, ADDRESSOF(nplatforms) );
		KernelLog.String("clGetPlatformIDs nplatforms: "); KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		IF (err # CL.SUCCESS) OR (nplatforms=0) THEN
			KernelLog.String('Error: Cannot get # of platforms!'); KernelLog.Ln;
			RETURN FALSE ;
		END;

		NEW(platformids, nplatforms);

		err := CL.GetPlatformIDs( nplatforms, ADDRESSOF(platformids[0]), 0 );
		KernelLog.String("clGetPlatformIDs : "); KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		IF (err # CL.SUCCESS) THEN
			KernelLog.String('Error: Cannot get platforms!'); KernelLog.Ln;
			RETURN FALSE;
		END;
	    	platform := platformids[0];

		(*  Devices  *)
		 err := CL.GetDeviceIDs (platform, CL.DEVICE_TYPE_GPU, 0, 0 , ADDRESSOF(ndevices));
	      IF (err # CL.SUCCESS) OR (ndevices = 0) THEN
		        KernelLog.String("clGetDeviceIDs Error: "); KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
	          KernelLog.String('Error: Cannot get number of GPU devices!'); KernelLog.Ln;
	          RETURN FALSE;
	       END;

		NEW(deviceids, ndevices);
		err := CL.GetDeviceIDs(platform, CL.DEVICE_TYPE_GPU, ndevices, ADDRESSOF(deviceids[0]), 0);
		KernelLog.String("clGetDeviceIDs : "); KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		IF (err # CL.SUCCESS) THEN
			KernelLog.String('Error: Cannot get devices!'); KernelLog.Ln;
			RETURN FALSE;
		END;
		deviceid := deviceids[0];

		context := CL.CreateContext(0, 1, ADDRESSOF(deviceid), NIL , NIL, err);
		commands := CL.CreateCommandQueue(context, deviceid, 0, err);

		kernelsource := Utils.LoadProgramSource("opencloberon/SimpleMandelbrot.cl", "");
		IF kernelsource = NIL THEN
			RETURN FALSE
		END;
		prog := Utils.CreateProgramWithSource(context, kernelsource^, err);

		err := CL.BuildProgram(prog, 0, 0, "-cl-mad-enable", NIL, 0);
		KernelLog.String("Build error: "); KernelLog.Int(err, 0); KernelLog.String(" -> ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		IF err # CL.SUCCESS THEN
			err := CL.GetProgramBuildInfo(prog, deviceid, CL.PROGRAM_BUILD_LOG, LEN(buf), ADDRESSOF(buf[0]), bufwritten);
			KernelLog.String("Build Log : "); KernelLog.Ln;
			KernelLog.String(buf); KernelLog.Ln;
			RETURN FALSE
		END;

		kernel := CL.CreateKernel(prog, "computeMandelbrot", err);
		size := sizeX*sizeY*4;
		pixelmem := CL.CreateBuffer(context,  CL.MEM_WRITE_ONLY, size , 0, err);

		(* Create and fill the memory object containing the color map *)
		InitColorMap(256);
		colormapLength := LEN(colorMap,0);
		size := colormapLength*SIZEOF(CL.cl_uint);
		
		colorMapMem := CL.CreateBuffer(context, CL.MEM_READ_WRITE, size, 0, err);
		err:= CL.EnqueueWriteBuffer(commands, colorMapMem, CL.CL_TRUE, 0, colormapLength * SIZEOF(CL.cl_uint), ADDRESSOF(colorMap[0]), 0, 0, 0);

		maxIterations := 1250;
		x0 := -2.0; y0 := -1.3; x1 := 0.6; y1:= 1.3;
		RETURN  (context # NIL) & (commands # NIL) & (prog # NIL)  & (kernel # NIL) &(pixelmem # NIL) & (colorMapMem # NIL);
	END InitCL;

	PROCEDURE InitColorMap(stepsize: LONGINT);
	VAR i, x: LONGINT;
	BEGIN
		NEW(colorMap,stepsize);
  		FOR i := 0 TO stepsize-1 DO
		x := ENTIER(200 * Math.sqrt(Math.sqrt(Math.sin(i / stepsize*Math.pi / 2)))) + 55;
		colorMap[i] := WMGraphics.RGBAToColor(x, x*2 MOD 255, x*4 MOD 255, 0)
		END;
	END InitColorMap;

	PROCEDURE Handle(VAR m: WMMessages.Message);
	BEGIN
		IF (m.msgType = WMMessages.MsgExt) & (m.ext # NIL) & (m.ext IS KillerMsg) THEN
			Close;
		ELSE Handle^(m)
		END
	END Handle;

	PROCEDURE Draw(canvas : WMGraphics.Canvas; w, h: SIZE; q: WORD);
	BEGIN
		Draw^(canvas, w, h, 0)
	END Draw;

	PROCEDURE Close;
	VAR err: LONGINT;
	BEGIN
		(* Free resources *)
		err := CL.ReleaseMemObject(pixelmem);
		err := CL.ReleaseMemObject(colorMapMem);
		err := CL.ReleaseCommandQueue(commands);
		err := CL.ReleaseContext(context);
		err := CL.ReleaseKernel(kernel);
		err := CL.ReleaseProgram(prog);
		Close^;
		DecCount;
	END Close;

	PROCEDURE PointerMove(x,y : SIZE; keys : SET);
	VAR dx, dy: SIZE;
		wdx, wdy: REAL;
	BEGIN
		IF selecting THEN
                dx := mousex1 - x;
                dy := mousey1 - y;

                wdx := x1-x0;
                wdy := y1-y0;

                x0 := x0 + (dx / sizeX) * wdx;
                x1 := x1 + (dx / sizeX) * wdx;

                y0 := y0 + (dy / sizeY) * wdy;
                y1 := y1 + (dy / sizeY) * wdy;
                mousex1 := x; mousey1 := y;
                UpdateImage;
		END;
	END PointerMove;

	PROCEDURE PointerDown(x,y : SIZE; keys : SET);
	BEGIN
		IF (keys*{0}#{}) THEN
			selecting := TRUE;
			mousex1:=x; mousey1:=y;
		END
	END PointerDown;

	PROCEDURE PointerUp(x,y : SIZE; keys : SET);
	BEGIN
		selecting := FALSE;
	END PointerUp;

	PROCEDURE WheelMove(dz : SIZE);
	VAR dx, dy, delta: REAL;
	BEGIN
		dx := x1-x0;
     dy := y1-y0;
     delta := dz / 20.0;
		x0 := x0 + delta * dx;
		x1 := x1- delta * dx;
		y0 := y0 + delta * dy;
		y1 := y1 - delta * dy;
		UpdateImage;
	END WheelMove;

	PROCEDURE KeyEvent (ucs: SIZE; flags: SET; keysym: SIZE);
	BEGIN
		CASE CHR(ucs) OF
		 "q": Close;
		ELSE
		END;
	END KeyEvent;
	
	PROCEDURE UpdateImage;
	VAR err: LONGINT;
		elapsed: LONGINT;
		str1, str2 : ARRAY 128 OF CHAR;
	    size: CL.size_t;
	BEGIN
			Kernel.SetTimer(timer,0);
			err := CL.SetKernelArg(kernel, 0, SIZEOF(CL.cl_mem), ADDRESSOF(pixelmem));
			err := CL.SetKernelArg(kernel, 1, SIZEOF(LONGINT), ADDRESSOF(sizeX));
			err := CL.SetKernelArg(kernel, 2, SIZEOF(LONGINT), ADDRESSOF(sizeY));
			err := CL.SetKernelArg(kernel, 3, SIZEOF(REAL), ADDRESSOF(x0));
			err := CL.SetKernelArg(kernel, 4, SIZEOF(REAL), ADDRESSOF(y0));
			err := CL.SetKernelArg(kernel, 5, SIZEOF(REAL), ADDRESSOF(x1));
			err := CL.SetKernelArg(kernel, 6, SIZEOF(REAL), ADDRESSOF(y1));
			err := CL.SetKernelArg(kernel, 7, SIZEOF(LONGINT), ADDRESSOF(maxIterations));
			err := CL.SetKernelArg(kernel, 8, SIZEOF(CL.cl_mem), ADDRESSOF(colorMapMem));
			err := CL.SetKernelArg(kernel, 9, SIZEOF(LONGINT), ADDRESSOF(colormapLength));

			err := CL.EnqueueNDRangeKernel(commands, kernel, 2, 0 ,  ADDRESSOF(globalWorkSize[0]), 0, 0, 0, 0);
			err := CL.Finish(commands);
			size := sizeX*sizeY*4;
			err := CL.EnqueueReadBuffer( commands, pixelmem, CL.CL_TRUE, 0, size , mimage.adr, 0, 0, 0);

			elapsed := Kernel.Elapsed(timer);
			str1:= "SimpleMandelbrotCL:  ";
			Strings.IntToStr(elapsed, str2);
			Strings.Append(str1, str2);
			Strings.Append(str1, " ms.");
			SetTitle(Strings.NewString(str1));
			Raster.Copy(mimage,img, 0,0,sizeX, sizeY, 0,0, mode);
			Invalidate(WMRectangles.MakeRect(0, 0, sizeX, sizeY));

	END UpdateImage;

	BEGIN

	END MBWindow;

VAR
	nofWindows : LONGINT;

PROCEDURE Open*;
VAR
	window : MBWindow;
BEGIN
	NEW(window,WindowWidth,WindowHeight);
END Open;


PROCEDURE IncCount;
BEGIN {EXCLUSIVE}
	INC(nofWindows)
END IncCount;

PROCEDURE DecCount;
BEGIN {EXCLUSIVE}
	DEC(nofWindows)
END DecCount;

PROCEDURE Cleanup;
VAR die : KillerMsg;
	 msg : WMMessages.Message;
	 m : WM.WindowManager;
BEGIN {EXCLUSIVE}
	NEW(die);
	msg.ext := die;
	msg.msgType := WMMessages.MsgExt;
	m := WM.GetDefaultManager();
	m.Broadcast(msg);
	AWAIT(nofWindows = 0)
END Cleanup;

BEGIN
	Modules.InstallTermHandler(Cleanup);
END MySimpleMandelbrotCL.

System.Free MySimpleMandelbrotCL ~

System.FreeDownTo OpenCL ~

MySimpleMandelbrotCL.Open ~
