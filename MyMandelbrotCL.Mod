MODULE MyMandelbrotCL;

IMPORT
	Raster, WMRectangles, WMGraphics, Modules, Strings, S:=SYSTEM, Kernel,
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
		
		platformids: CL.cl_platform_id;
		deviceids : CL.cl_device_id;
		context : CL.cl_context;
		commands : CL.cl_command_queue;  
		prog      : CL.cl_program;       (* compute program *)
		kernel    : CL.cl_kernel;         (* compute kernel *)
		
		objmem   : CL.cl_mem;  (* device memory used for the input array *)
		global  : IVector; (* global domain size for our calculation *)
		kernelsource: CL.PChar;  
		kernelname: ARRAY 128 OF CHAR;
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
		END New;

		PROCEDURE KeyEvent* (ucs: LONGINT; flags: SET; keysym: LONGINT);
		VAR err: LONGINT;
		BEGIN
			CASE CHR(ucs) OF
			 "t":	Top := Top -0.1;
			|  "T": Top := Top + 0.1;
			| "l" : Left := Left -0.1;
			| "L" : Left := Left + 0.1;
			ELSE
			
			END;
			IF inited THEN
				err := CL.clSetKernelArg(kernel, 0, S.SIZEOF(REAL), S.ADR(Left));
				err := CL.clSetKernelArg(kernel, 1, S.SIZEOF(REAL), S.ADR(Top));
				DrawIt;
			END
		END KeyEvent;
		
		PROCEDURE InitCL*;
		VAR err: LONGINT;
(*		bufwritten: LONGINT;
		buf: ARRAY 4096 OF CHAR;*)
		BEGIN
			NEW(global,2);
			global[0] := WindowWidth; global[1] := WindowHeight;
			err := CL.clGetPlatformIDs( 1, S.ADR(platformids), 0 ); 
			err := CL.clGetDeviceIDs(platformids, CL.DEVICE_TYPE_ALL, 1, S.ADR(deviceids), 0);

			
			context := CL.clCreateContext(NIL, 1, S.ADR(deviceids), NIL , 0, err);
			commands := CL.clCreateCommandQueue(context, deviceids, 0, err);
			
			kernelsource := Utils.LoadProgramSource("Mandelbrot.cl", "");
			prog := CL.clCreateProgramWithSource(context, 1, S.ADR(kernelsource), NIL, err);

		(*	err := CL.clGetProgramInfo(prog, CL.PROGRAM_SOURCE, LEN(buf), S.ADR(buf), bufwritten);
			KernelLog.String("bufwritten= "); KernelLog.Int(bufwritten, 0); KernelLog.Ln; 
			KernelLog.String("clGetProgramInfoSource= "); KernelLog.String(buf); KernelLog.Ln; 
			
		*)					
			err := CL.clBuildProgram(prog, 0, NIL, NIL, NIL, 0);

(*			err := CL.clGetProgramBuildInfo(prog, deviceids,CL.PROGRAM_BUILD_LOG, LEN(buf), S.ADR(buf[0]), bufwritten);
			KernelLog.String("bufwritten= "); KernelLog.Int(bufwritten, 0); KernelLog.Ln; 
			KernelLog.String("buf= "); KernelLog.String(buf); KernelLog.Ln; 
*)				
			kernelname := "Mandelbrot";
			kernel := CL.clCreateKernel(prog, S.ADR(kernelname[0]), err); 
						
			objmem := CL.clCreateBuffer(context,  CL.MEM_WRITE_ONLY, WindowWidth*WindowHeight*4 , 0, err);
			
			Top := -2.0; Left := 2.0; Right := -2.0; Bottom:=2.0; Stride := WindowWidth;

			err := CL.clSetKernelArg(kernel, 0, S.SIZEOF(REAL), S.ADR(Left));
			err := CL.clSetKernelArg(kernel, 1, S.SIZEOF(REAL), S.ADR(Top));
			err := CL.clSetKernelArg(kernel, 2, S.SIZEOF(REAL), S.ADR(Right));
			err := CL.clSetKernelArg(kernel, 3, S.SIZEOF(REAL), S.ADR(Bottom));
			err := CL.clSetKernelArg(kernel, 4, S.SIZEOF(LONGINT), S.ADR(Stride));
			err := CL.clSetKernelArg(kernel, 5, S.SIZEOF(CL.cl_mem), S.ADR(objmem));
			inited := (context # 0) & (commands # 0) & (prog # 0)  & (kernel # 0) & (err=0);
			DrawIt;
		END InitCL;
		
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
				err := CL.clReleaseMemObject(objmem);
				err := CL.clReleaseProgram(prog);
				err := CL.clReleaseKernel(kernel);
				err := CL.clReleaseCommandQueue(commands);
				err := CL.clReleaseContext(context);	
			END;	
			Close^;
			window := NIL;
		END Close;

		PROCEDURE DrawIt;
		VAR err: LONGINT;	
			elapsed: LONGINT;
			str1, str2 : ARRAY 128 OF CHAR;
		BEGIN
			IF inited THEN	
				Kernel.SetTimer(timer,0);
				err := CL.clEnqueueNDRangeKernel(commands, kernel, 2, 0 ,  S.ADR(global[0]), 0, 0, NIL, NIL);
				err := CL.clFinish(commands);
				err := CL.clEnqueueReadBuffer( commands, objmem, CL.CL_TRUE, 0,WindowWidth*WindowHeight*4  , mimage.adr, 0, NIL, NIL);
				
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
	window : MBWindow;

PROCEDURE Open*;
BEGIN
  IF window = NIL THEN
	NEW(window);
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
END MyMandelbrotCL.

SystemTools.Free MyMandelbrotCL OpenCLUtils OpenCL ~

MyMandelbrotCL.Open ~