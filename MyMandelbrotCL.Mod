MODULE MyMandelbrotCL; (** AUTHOR "fnecati"; PURPOSE "a Mandelbrot demo using OpenCL"; *)

IMPORT
	Raster, WMRectangles, WMGraphics, Modules, Strings, Kernel,
	WM := WMWindowManager, WMMessages, CL := OpenCL, Utils := OpenCLUtils, 
	KernelLog;

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

		objmem   : CL.cl_mem;  (* device memory used for the input array *)
		global  : IVector; (* global domain size for our calculation *)
		Left, Top, Bottom, Right: REAL;
		Stride: LONGINT;
		inited: BOOLEAN;

	PROCEDURE &New;
	BEGIN
		Init(WindowWidth, WindowHeight, FALSE);
		manager := WM.GetDefaultManager();
		manager.Add(100, 100, SELF, {WM.FlagFrame, WM.FlagClose, WM.FlagNoResizing});

		SetTitle(Strings.NewString("MandelbrotCL: "));
		SetIcon(WMGraphics.LoadImage("WMIcons.tar://TuringCoatWnd.png", TRUE));
		inited := FALSE;
		(* since bpp of linuxAos WM is 16bpp, an image buffer is used. For 32bpp,  windows.img can be used directly *)
		NEW(mimage);
		Raster.Create(mimage, WindowWidth, WindowHeight, Raster.BGRA8888);
		Raster.InitMode(mode, Raster.srcCopy);
		InitCL;
		IncCount;
	END New;

	PROCEDURE SetTopLeft;
	VAR err: LONGINT;
	BEGIN
		IF inited THEN
			err := CL.SetKernelArg(kernel, 0, SIZEOF(REAL), ADDRESSOF(Left));
			err := CL.SetKernelArg(kernel, 1, SIZEOF(REAL), ADDRESSOF(Top));
			DrawIt;
		END
	END SetTopLeft;

	PROCEDURE KeyEvent* (ucs: LONGINT; flags: SET; keysym: LONGINT);
	BEGIN
		CASE CHR(ucs) OF
		 "t":	Top := Top -0.1; SetTopLeft;;
		|  "T": Top := Top + 0.1; SetTopLeft;
		| "l" : Left := Left -0.1; SetTopLeft;
		| "L" : Left := Left + 0.1;  SetTopLeft;
		| "q": Close;
		ELSE
		END;
	END KeyEvent;

	PROCEDURE Handle(VAR m: WMMessages.Message);
	BEGIN
		IF (m.msgType = WMMessages.MsgExt) & (m.ext # NIL) & (m.ext IS KillerMsg) THEN
			Close;
		ELSE Handle^(m)
		END
	END Handle;
	
	PROCEDURE InitCL*;
	VAR err: LONGINT;
	
(*	bufwritten: LONGINT;
	buf: ARRAY 4096 OF CHAR;*)
	BEGIN
		NEW(global,2);
		global[0] := WindowWidth; global[1] := WindowHeight;

		err := CL.GetPlatformIDs( 0, 0, ADDRESSOF(nplatforms) );
		KernelLog.String("clGetPlatformIDs nplatforms: "); KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		IF (err # CL.SUCCESS) OR (nplatforms=0) THEN
			KernelLog.String('Error: Cannot get # of platforms!'); KernelLog.Ln;
			RETURN
		END;

		NEW(platformids, nplatforms);

		err := CL.GetPlatformIDs( nplatforms, ADDRESSOF(platformids[0]), 0 );
		KernelLog.String("clGetPlatformIDs : "); KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		IF (err # CL.SUCCESS) THEN
			KernelLog.String('Error: Cannot get platforms!'); KernelLog.Ln;
			RETURN
		END;
	    	platform := platformids[0];

		(*  Devices  *)

		 err := CL.GetDeviceIDs (platform, CL.DEVICE_TYPE_GPU, 0, 0 , ADDRESSOF(ndevices));
	      IF (err # CL.SUCCESS) OR (ndevices = 0) THEN
		        KernelLog.String("clGetDeviceIDs Error: "); KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
	          KernelLog.String('Error: Cannot get number of GPU devices!'); KernelLog.Ln;
	          RETURN
	       END;

		NEW(deviceids, ndevices);
		err := CL.GetDeviceIDs(platform, CL.DEVICE_TYPE_GPU, ndevices, ADDRESSOF(deviceids[0]), 0);
		KernelLog.String("clGetDeviceIDs : "); KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		IF (err # CL.SUCCESS) THEN
			KernelLog.String('Error: Cannot get devices!'); KernelLog.Ln;
			RETURN
		END;
		deviceid := deviceids[0];



			context := CL.CreateContext(0, 1, ADDRESSOF(deviceid), NIL , NIL, err);
			commands := CL.CreateCommandQueue(context, deviceid, 0, err);


			prog := Utils.BuildProgramFromSourceFile(context, "opencloberon/Mandelbrot.cl", "", "", err);
			IF err # CL.SUCCESS THEN RETURN END;

		(*	err := CL.GetProgramInfo(prog, CL.PROGRAM_SOURCE, LEN(buf), ADDRESSOF(buf), bufwritten);
			KernelLog.String("bufwritten= "); KernelLog.Int(bufwritten, 0); KernelLog.Ln;
			KernelLog.String("clGetProgramInfoSource= "); KernelLog.String(buf); KernelLog.Ln;

		*)
		(*	err := CL.BuildProgram(prog, 0, 0, "", 0, 0);*)

(*			err := CL.GetProgramBuildInfo(prog, deviceids,CL.PROGRAM_BUILD_LOG, LEN(buf), ADDRESSOF(buf[0]), bufwritten);
			KernelLog.String("bufwritten= "); KernelLog.Int(bufwritten, 0); KernelLog.Ln;
			KernelLog.String("buf= "); KernelLog.String(buf); KernelLog.Ln;
*)

			kernel := CL.CreateKernel(prog, "Mandelbrot", err);

			objmem := CL.CreateBuffer(context,  CL.MEM_WRITE_ONLY, WindowWidth*WindowHeight*4 , 0, err);

			Top := -2.0; Left := 2.0; Right := -2.0; Bottom:=2.0; Stride := WindowWidth;

			err := CL.SetKernelArg(kernel, 0, SIZEOF(REAL), ADDRESSOF(Left));
			err := CL.SetKernelArg(kernel, 1, SIZEOF(REAL), ADDRESSOF(Top));
			err := CL.SetKernelArg(kernel, 2, SIZEOF(REAL), ADDRESSOF(Right));
			err := CL.SetKernelArg(kernel, 3, SIZEOF(REAL), ADDRESSOF(Bottom));
			err := CL.SetKernelArg(kernel, 4, SIZEOF(LONGINT), ADDRESSOF(Stride));
			err := CL.SetKernelArg(kernel, 5, SIZEOF(CL.cl_mem), ADDRESSOF(objmem));
			inited := (context # 0) & (commands # 0) & (prog # 0)  & (kernel # 0) & (err=0);
			DrawIt;
		END InitCL;

		PROCEDURE Draw*(canvas : WMGraphics.Canvas; w, h, q : LONGINT);
		BEGIN
			Draw^(canvas, w, h, 0)
		END Draw;

		PROCEDURE Close*;
		VAR err: LONGINT;
		BEGIN
			(* Free resources *)
			IF inited THEN
				err := CL.ReleaseMemObject(objmem);
				err := CL.ReleaseProgram(prog);
				err := CL.ReleaseKernel(kernel);
				err := CL.ReleaseCommandQueue(commands);
				err := CL.ReleaseContext(context);
			END;
			Close^;
			DecCount;
		END Close;

		PROCEDURE DrawIt;
		VAR err: LONGINT;
			elapsed: LONGINT;
			str1, str2 : ARRAY 128 OF CHAR;
		BEGIN
			IF inited THEN
				Kernel.SetTimer(timer,0);
				err := CL.EnqueueNDRangeKernel(commands, kernel, 2, 0 ,  ADDRESSOF(global[0]), 0, 0, 0, 0);
				err := CL.Finish(commands);
				err := CL.EnqueueReadBuffer( commands, objmem, CL.CL_TRUE, 0,WindowWidth*WindowHeight*4  , mimage.adr, 0, 0, 0);

				elapsed := Kernel.Elapsed(timer);
				str1:= "MandelbrotCL:  ";
				Strings.IntToStr(elapsed, str2);
				Strings.Append(str1, str2);
				Strings.Append(str1, " ms.");
				SetTitle(Strings.NewString(str1));
				Raster.Copy(mimage,img, 0,0,WindowWidth, WindowHeight, 0,0, mode);
				Invalidate(WMRectangles.MakeRect(0, 0, GetWidth(), GetHeight()));
			END;
		END DrawIt;

	BEGIN

	END MBWindow;


VAR
	nofWindows : LONGINT;
	
PROCEDURE Open*;
VAR
	window : MBWindow;
BEGIN
	NEW(window);
END Open;

PROCEDURE IncCount;
BEGIN {EXCLUSIVE}
	INC(nofWindows)
END IncCount;

PROCEDURE DecCount;
BEGIN {EXCLUSIVE}
	DEC(nofWindows)
END DecCount;

PROCEDURE Cleanup*;
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
END MyMandelbrotCL.

SystemTools.Free MyMandelbrotCL~

SystemTools.FreeDownTo OpenCL ~

MyMandelbrotCL.Open ~
