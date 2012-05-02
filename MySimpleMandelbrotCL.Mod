MODULE MySimpleMandelbrotCL; (** AUTHOR "fnecati"; PURPOSE "a Mandelbrot demo using OpenCL"; *)

IMPORT
	Raster,  WMRectangles, WMGraphics, Modules, Math, Strings, S:=SYSTEM, Kernel,
	WM := WMWindowManager, WMMessages, CL := OpenCL, Utils := OpenCLUtils, KernelLog;

CONST
	WindowWidth = 512; WindowHeight = 512;

TYPE
	IVector=ARRAY [*] OF LONGINT;

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
		colorMap: IVector;  (*The color map which will be copied to OpenCL for filling the PBO *)
		colormapLength: LONGINT;
		x0, y0, x1, y1: REAL; (* minimum x,y-value of the area in which the Mandelbrot set should be computed *)
		maxIterations: LONGINT;
		sizeX, sizeY: LONGINT; (* size of window *)

		globalWorkSize  : IVector; (* globalWorkSize domain size for our calculation *)

		kernelsource: CL.PChar;

		 inited: BOOLEAN;
		 mousex1, mousey1: LONGINT;
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
		inited := FALSE;

		(* since bpp of linuxAos WM is 16bpp, an image buffer is used. For 32bpp,  windows.img can be used directly *)
		Raster.InitMode(mode, Raster.srcCopy);
		NEW(mimage);
		Raster.Create(mimage, sizeX, sizeY, Raster.BGRA8888);
		InitCL;
	END New;

	PROCEDURE InitCL*;
	VAR err: LONGINT;
		bufwritten : LONGINT;
		buf: ARRAY 4096 OF CHAR;
	BEGIN
		NEW(globalWorkSize,2);
		globalWorkSize[0] := sizeX; globalWorkSize[1] := sizeY;

		err := CL.clGetPlatformIDs( 0, 0, S.ADR(nplatforms) );
		KernelLog.String("clGetPlatformIDs nplatforms: "); KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		IF (err # CL.SUCCESS) OR (nplatforms=0) THEN
			KernelLog.String('Error: Cannot get # of platforms!'); KernelLog.Ln;
			RETURN;
		END;

		NEW(platformids, nplatforms);

		err := CL.clGetPlatformIDs( nplatforms, S.ADR(platformids[0]), 0 );
		KernelLog.String("clGetPlatformIDs : "); KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		IF (err # CL.SUCCESS) THEN
			KernelLog.String('Error: Cannot get platforms!'); KernelLog.Ln;
			RETURN;
		END;
	    	platform := platformids[0];

		(*  Devices  *)
		 err := CL.clGetDeviceIDs (platform, CL.DEVICE_TYPE_GPU, 0, 0 , S.ADR(ndevices));
	      IF (err # CL.SUCCESS) OR (ndevices = 0) THEN
		        KernelLog.String("clGetDeviceIDs Error: "); KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
	          KernelLog.String('Error: Cannot get number of GPU devices!'); KernelLog.Ln;
	          RETURN;
	       END;

		NEW(deviceids, ndevices);
		err := CL.clGetDeviceIDs(platform, CL.DEVICE_TYPE_GPU, ndevices, S.ADR(deviceids[0]), 0);
		KernelLog.String("clGetDeviceIDs : "); KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		IF (err # CL.SUCCESS) THEN
			KernelLog.String('Error: Cannot get devices!'); KernelLog.Ln;
			RETURN;
		END;
		deviceid := deviceids[0];

		context := CL.clCreateContext(0, 1, S.ADR(deviceid), 0 , 0, err);
		commands := CL.clCreateCommandQueue(context, deviceid, 0, err);

		kernelsource := Utils.LoadProgramSource("SimpleMandelbrot.cl", "");
		prog := CL.clCreateProgramWithSource(context, 1, S.ADR(kernelsource), 0, err);

(*		err := CL.clGetProgramInfo(prog, CL.PROGRAM_SOURCE, LEN(buf), S.ADR(buf), bufwritten);
		KernelLog.String("bufwritten= "); KernelLog.Int(bufwritten, 0); KernelLog.Ln;
		KernelLog.String("clGetProgramInfoSource= "); KernelLog.String(buf); KernelLog.Ln;
*)

		err := CL.clBuildProgram(prog, 0, 0, "-cl-mad-enable", 0, 0);
		KernelLog.String("Build error: "); KernelLog.Int(err, 0); KernelLog.String(" -> ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		IF err # CL.SUCCESS THEN
			err := CL.clGetProgramBuildInfo(prog, deviceid, CL.PROGRAM_BUILD_LOG, LEN(buf), S.ADR(buf[0]), bufwritten);
			KernelLog.String("Build Log : "); KernelLog.Ln;
			KernelLog.String(buf); KernelLog.Ln;
		END;

(*		err := CL.clGetProgramBuildInfo(prog, deviceids,CL.PROGRAM_BUILD_OPTIONS, LEN(buf), S.ADR(buf[0]), bufwritten);
		KernelLog.String("bufwritten= "); KernelLog.Int(bufwritten, 0); KernelLog.Ln;
		KernelLog.String("buf= "); KernelLog.String(buf); KernelLog.Ln;
*)

		kernel := CL.clCreateKernel(prog, "computeMandelbrot", err);

		pixelmem := CL.clCreateBuffer(context,  CL.MEM_WRITE_ONLY, sizeX*sizeY*4 , 0, err);

		(* Create and fill the memory object containing the color map *)
		InitColorMap(256);
		colormapLength := LEN(colorMap,0);
		colorMapMem := CL.clCreateBuffer(context, CL.MEM_READ_WRITE, colormapLength*S.SIZEOF(CL.cl_uint), 0, err);
		err:= CL.clEnqueueWriteBuffer(commands, colorMapMem, CL.CL_TRUE, 0, colormapLength * S.SIZEOF(CL.cl_uint), S.ADR(colorMap[0]), 0, 0, 0);

		maxIterations := 1250;
		x0 := -2.0; y0 := -1.3; x1 := 0.6; y1:= 1.3;
		inited := (context # 0) & (commands # 0) & (prog # 0)  & (kernel # 0) &(pixelmem # 0) & (colorMapMem # 0);
		UpdateImage;
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

	PROCEDURE Draw*(canvas : WMGraphics.Canvas; w, h, q : LONGINT);
	BEGIN
		Draw^(canvas, w, h, 0)
	END Draw;

	PROCEDURE Close*;
	VAR err: LONGINT;
	BEGIN
		(* Free resources *)
		IF inited THEN
			err := CL.clReleaseMemObject(pixelmem);
			err := CL.clReleaseMemObject(colorMapMem);
			err := CL.clReleaseCommandQueue(commands);
			err := CL.clReleaseContext(context);
			err := CL.clReleaseKernel(kernel);
			err := CL.clReleaseProgram(prog);
		END;
		Close^;
		window := NIL;
	END Close;

	PROCEDURE PointerMove(x,y : LONGINT; keys : SET);
	VAR dx, dy: LONGINT;
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

	PROCEDURE PointerDown(x,y : LONGINT; keys : SET);
	BEGIN
		IF (keys*{0}#{}) THEN
			selecting := TRUE;
			mousex1:=x; mousey1:=y;
		END
	END PointerDown;

	PROCEDURE PointerUp(x,y : LONGINT; keys : SET);
	BEGIN
		selecting := FALSE;
	END PointerUp;

	PROCEDURE WheelMove*(dz : LONGINT);
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

	PROCEDURE UpdateImage;
	VAR err: LONGINT;
		elapsed: LONGINT;
		str1, str2 : ARRAY 128 OF CHAR;
	BEGIN
		IF inited THEN
			Kernel.SetTimer(timer,0);
			err := CL.clSetKernelArg(kernel, 0, S.SIZEOF(CL.cl_mem), S.ADR(pixelmem));
			err := CL.clSetKernelArg(kernel, 1, S.SIZEOF(LONGINT), S.ADR(sizeX));
			err := CL.clSetKernelArg(kernel, 2, S.SIZEOF(LONGINT), S.ADR(sizeY));
			err := CL.clSetKernelArg(kernel, 3, S.SIZEOF(REAL), S.ADR(x0));
			err := CL.clSetKernelArg(kernel, 4, S.SIZEOF(REAL), S.ADR(y0));
			err := CL.clSetKernelArg(kernel, 5, S.SIZEOF(REAL), S.ADR(x1));
			err := CL.clSetKernelArg(kernel, 6, S.SIZEOF(REAL), S.ADR(y1));
			err := CL.clSetKernelArg(kernel, 7, S.SIZEOF(LONGINT), S.ADR(maxIterations));
			err := CL.clSetKernelArg(kernel, 8, S.SIZEOF(CL.cl_mem), S.ADR(colorMapMem));
			err := CL.clSetKernelArg(kernel, 9, S.SIZEOF(LONGINT), S.ADR(colormapLength));

			err := CL.clEnqueueNDRangeKernel(commands, kernel, 2, 0 ,  S.ADR(globalWorkSize[0]), 0, 0, 0, 0);
			err := CL.clFinish(commands);
			err := CL.clEnqueueReadBuffer( commands, pixelmem, CL.CL_TRUE, 0,sizeX*sizeY*4  , mimage.adr, 0, 0, 0);

			elapsed := Kernel.Elapsed(timer);
			str1:= "SimpleMandelbrotCL:  ";
			Strings.IntToStr(elapsed, str2);
			Strings.Append(str1, str2);
			Strings.Append(str1, " ms.");
			SetTitle(Strings.NewString(str1));
			Raster.Copy(mimage,img, 0,0,sizeX, sizeY, 0,0, mode);
			Invalidate(WMRectangles.MakeRect(0, 0, sizeX, sizeY));
		END;
	END UpdateImage;

	BEGIN

	END MBWindow;

VAR
	window : MBWindow;

PROCEDURE Open*;
BEGIN
	IF window = NIL THEN
		NEW(window,WindowWidth,WindowHeight);
	 END;
END Open;


PROCEDURE Cleanup;
VAR die : KillerMsg;
	 msg : WMMessages.Message;
	 m : WM.WindowManager;
BEGIN {EXCLUSIVE}
	NEW(die); msg.ext := die; msg.msgType := WMMessages.MsgExt;
	m := WM.GetDefaultManager();
	m.Broadcast(msg);
	AWAIT(window = NIL);
END Cleanup;

BEGIN
	Modules.InstallTermHandler(Cleanup);
END MySimpleMandelbrotCL.

SystemTools.Free MySimpleMandelbrotCL ~

SystemTools.FreeDownTo OpenCL ~

MySimpleMandelbrotCL.Open ~
