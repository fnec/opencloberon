MODULE MyJuliasetCL; (** AUTHOR "fnecati"; PURPOSE ""; *)
(* 
		This example shows how to use OpenCL to raytrace a 4d Quaternion Julia-Set 
          Fractal and intermix the results of a compute kernel with WM for rendering
 *)
 
IMPORT
	Raster, WMRectangles, WMGraphics, Modules, Strings, Kernel, Random,
	WM := WMWindowManager,  WMMessages, KernelLog, WMDialogs,
	S:=SYSTEM, CL := OpenCL, Utils := OpenCLUtils;

CONST
	WindowWidth = 512; WindowHeight = 512;
	
TYPE 
	IVector = ARRAY [*] OF LONGINT;
 	RVector = ARRAY [4] OF REAL; 

	KillerMsg = OBJECT
	END KillerMsg;

	MBWindow* =  OBJECT(WM.BufferWindow)
	VAR
		(* timer: Kernel.MilliTimer; *)
		mimage: Raster.Image;
		mode: Raster.Mode;
		alive, dead, animated: BOOLEAN;
		 		
		PROCEDURE &New;
		BEGIN
			Init(WindowWidth, WindowHeight, FALSE);
			manager := WM.GetDefaultManager();
			manager.Add(100, 100, SELF, {WM.FlagFrame, WM.FlagClose, WM.FlagNoResizing});

			SetTitle(Strings.NewString("JuliaSetCL: "));
			SetIcon(WMGraphics.LoadImage("WMIcons.tar://TuringCoatWnd.png", TRUE));
			
		(* since bpp of linuxAos WM is 16bpp, an image buffer is used. For 32bpp,  windows.img can be used directly *)
			NEW(mimage);			
			Raster.Create(mimage, WindowWidth, WindowHeight, Raster.BGRA8888);
			Raster.InitMode(mode, Raster.srcCopy);
			dead := FALSE;
			UpdateImage;
			animated := FALSE;
		END New;

		PROCEDURE KeyEvent* (ucs: LONGINT; flags: SET; keysym: LONGINT);
		CONST 
			stepSize = 0.05;
		VAR 
			err: LONGINT;
		     
		BEGIN
			CASE CHR(ucs) OF
			 "+":	IF epsilon >= 0.002 THEN epsilon := epsilon*(1.0/1.05) END;
			|  "-": 	IF epsilon < 0.01 THEN epsilon := epsilon*1.05 END;
			| "w" : muC[0] := muC[0] + stepSize;
			| "x" :  muC[0] := muC[0] - stepSize;
			| "q" : muC[1] := muC[1] + stepSize;
			| "z" :  muC[1] := muC[1] - stepSize;
			| "a" : muC[2] := muC[2] + stepSize;
			| "d" :  muC[2] := muC[2] - stepSize;
			| "e" : muC[3] := muC[3] + stepSize;
			| "c" :  muC[3] := muC[3] - stepSize;
			| "A" : animated := ~animated;
			| "S": SaveImage;
			ELSE
			
			END;
			IF inited THEN
				UpdateImage;
			END
		END KeyEvent;
	
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
		BEGIN
			alive := FALSE;
			BEGIN {EXCLUSIVE} AWAIT(dead); END;
			Close^;
			window := NIL;
		END Close;

		PROCEDURE UpdateImage;
		VAR err: LONGINT;	
			elapsed: LONGINT;
			str1, str2 : ARRAY 128 OF CHAR;
			relapsed: LONGREAL;
			
		BEGIN
			IF inited THEN	
				(* Kernel.SetTimer(timer,0);*)
			IF animated THEN
				UpdateMu( muT, muA, muB );
				Interpolate( muC, muT, muA, muB );
				UpdateColor( colT, colA, colB );
				Interpolate(colC, colT, colA, colB );			
			END;
				
			(* err := CL.clSetKernelArg(kernel, 0, S.SIZEOF(CL.cl_mem), S.ADR(objmem));*)
			err := CL.clSetKernelArg(kernel, 1, S.SIZEOF(REAL)*LEN(muC,0), S.ADR(muC[0]));
			err := CL.clSetKernelArg(kernel, 2, S.SIZEOF(REAL)*LEN(colC,0), S.ADR(colC[0]));
			err := CL.clSetKernelArg(kernel, 3, S.SIZEOF(REAL), S.ADR(epsilon));		
			
				err := CL.clEnqueueNDRangeKernel(commands, kernel, 2, 0 ,  S.ADR(global[0]), S.ADR(local[0]), 0, 0, S.ADR(kernelEvent));
				err := CL.clWaitForEvents(1, S.ADR(kernelEvent));
				
(*				err := CL.clFinish(commands);*)
				err := CL.clEnqueueReadBuffer( commands, objmem, CL.CL_TRUE, 0,WindowWidth*WindowHeight*4  , mimage.adr, 0, 0, S.ADR(readEvent));
				err := CL.clWaitForEvents(1, S.ADR(readEvent));

				(*  write timing info  *)						
				str1:= "JuliaSetCL:  ";
				relapsed := ExecutionTime(kernelEvent);
				Strings.FloatToStr(relapsed, 10,2,0, str2);
				
				(* elapsed := Kernel.Elapsed(timer);
				Strings.IntToStr(elapsed, str2);
				*)

				Strings.Append(str1, str2);
				Strings.Append(str1, " ms.");
				
				SetTitle(Strings.NewString(str1));
				Raster.Copy(mimage,img, 0,0,WindowWidth, WindowHeight, 0,0, mode);
				Invalidate(WMRectangles.MakeRect(0, 0, GetWidth(), GetHeight()));
			END;
		END UpdateImage;

		PROCEDURE SaveImage;
		VAR res: LONGINT;
			fname: ARRAY 128 OF CHAR;
		BEGIN
		fname:="juliaset0.bmp";
		IF WMDialogs.QueryString(" Save File name: ",fname)=WMDialogs.ResOk THEN
				WMGraphics.StoreImage(img,fname,res);
		END;
		END SaveImage;
		
	BEGIN {ACTIVE}
	alive := TRUE;
	WHILE alive DO
		IF animated THEN
			UpdateImage;
		END
	END;
	BEGIN {EXCLUSIVE} dead := TRUE; END;	
	END MBWindow;

VAR
		window : MBWindow;
		rand: Random.Generator;
     
		platformids: CL.cl_platform_id;
		deviceids : CL.cl_device_id;
		context : CL.cl_context;
		commands : CL.cl_command_queue;  
		prog      : CL.cl_program;       (* compute program *)
		kernel    : CL.cl_kernel;         (* compute kernel *)
		
		objmem   : CL.cl_mem;  (* device memory used for the input array *)
		global, local  : IVector; (* global domain size for our calculation *)
		kernelsource: CL.PChar;  

		muA, muB, muC, colA, colB, colC: RVector;
		muT, colT: REAL;
		
		epsilon: REAL;
		inited : BOOLEAN;
	
		MaxWorkGroupSize: CL.csize_t;
		WorkGroupItems : LONGINT;
		WorkGroupSize: IVector;
		sizeX, sizeY: LONGINT;

		kernelEvent, readEvent: CL.cl_event; (* for event profiling *)
	    		
PROCEDURE InitCL;
VAR err: LONGINT;
		bufwritten: LONGINT;
		 buf: ARRAY 1024 OF CHAR; 
		BEGIN
			epsilon := 0.001; 
			WorkGroupItems := 32;
			NEW(WorkGroupSize, 2);
			muT := 0.0; 

			muA := [-0.278, -0.479, 0.0, 0.0];
			muB := [0.278, 0.479, 0.0, 0.0];
			muC := [-0.278, -0.479, -0.231, 0.235];
			
			colA := [0.25, 0.45, 1.0, 1.0];
			colB := [0.25, 0.45, 1.0, 1.0];
			colC := [0.25, 0.45, 1.0, 1.0];
		
			NEW(global,2); NEW(local,2);
			
			err := CL.clGetPlatformIDs( 1, S.ADR(platformids), 0 ); 
			err := CL.clGetDeviceIDs(platformids, CL.DEVICE_TYPE_ALL, 1, S.ADR(deviceids), 0);
			
			context := CL.clCreateContext(0, 1, S.ADR(deviceids), NIL , 0, err);
			
			(* with event profile *)
			commands := CL.clCreateCommandQueue(context, deviceids, S.VAL(HUGEINT, {CL.QUEUE_PROFILING_ENABLE, CL.QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE}), err);
			
			kernelsource := Utils.LoadProgramSource("qjulia_kernel.cl", "");
			prog := CL.clCreateProgramWithSource(context, 1, S.ADR(kernelsource), 0, err);

		(*	err := CL.clGetProgramInfo(prog, CL.PROGRAM_SOURCE, LEN(buf), S.ADR(buf), bufwritten);
			KernelLog.String("bufwritten= "); KernelLog.Int(bufwritten, 0); KernelLog.Ln; 
			KernelLog.String("clGetProgramInfoSource= "); KernelLog.String(buf); KernelLog.Ln; 
			
		*)					
			err := CL.clBuildProgram(prog, 0, NIL, 0, 0, 0);

	(*		err := CL.clGetProgramBuildInfo(prog, deviceids,CL.PROGRAM_BUILD_LOG, LEN(buf), S.ADR(buf[0]), bufwritten);
			KernelLog.String("bufwritten= "); KernelLog.Int(bufwritten, 0); KernelLog.Ln; 
			KernelLog.String("buf= "); KernelLog.String(buf); KernelLog.Ln; 
	*)
				

			err := CL.clCreateKernelsInProgram(prog, 0,0, S.ADR(bufwritten));
			KernelLog.String(" number of kernels in the program = "); KernelLog.Int(bufwritten, 0); KernelLog.Ln; 
			err := CL.clCreateKernelsInProgram(prog, bufwritten, S.ADR(kernel), 0);
			
(*			kernel := CL.clCreateKernel(prog, "QJuliaKernel", err); *)

			err := CL.clGetKernelInfo(kernel, CL.KERNEL_FUNCTION_NAME, LEN(buf), S.ADR(buf),0);
			KernelLog.String("Kernelname :"); KernelLog.String(buf); KernelLog.Ln; 
			
			err := CL.clGetKernelWorkGroupInfo(kernel, deviceids, CL.KERNEL_WORK_GROUP_SIZE, S.SIZEOF(LONGINT), S.ADR(MaxWorkGroupSize), 0);
			KernelLog.String("MaxWorkGroupSize= "); KernelLog.Int(MaxWorkGroupSize, 0); KernelLog.Ln; 
			
			IF MaxWorkGroupSize>1 THEN
				 WorkGroupSize[0] := MaxWorkGroupSize DIV WorkGroupItems 
			ELSE
				 WorkGroupSize[0] := MaxWorkGroupSize;
			END;
			 WorkGroupSize[1] := MaxWorkGroupSize DIV WorkGroupSize[0] ;
			 
			 sizeX :=  WorkGroupSize[0] ;
			 sizeY :=  WorkGroupSize[1] ;
			 
 			global[0] := Utils.RoundUp(WindowWidth, sizeX)*sizeX;
 			global[1] :=  Utils.RoundUp(WindowHeight, sizeY)*sizeY;
			
			local[0] := sizeX; local[1] :=sizeY;
			 
			objmem := CL.clCreateBuffer(context,  CL.MEM_WRITE_ONLY, WindowWidth*WindowHeight*4 , 0, err);
			
			err := CL.clSetKernelArg(kernel, 0, S.SIZEOF(CL.cl_mem), S.ADR(objmem));
			err := CL.clSetKernelArg(kernel, 1, S.SIZEOF(REAL)*LEN(muC,0), S.ADR(muC[0]));
			err := CL.clSetKernelArg(kernel, 2, S.SIZEOF(REAL)*LEN(colC,0), S.ADR(colC[0]));
			err := CL.clSetKernelArg(kernel, 3, S.SIZEOF(REAL), S.ADR(epsilon));			
			inited := (context # 0) & (commands # 0) & (prog # 0)  & (kernel # 0) & (err=0);
			
END InitCL;

PROCEDURE Open*;
BEGIN
  IF window = NIL THEN
	NEW(window);
 END;	
END Open;

PROCEDURE UpdateMu( VAR t: REAL; VAR a, b: RVector );
BEGIN
    t := t + 0.01;  
    IF t >= 1.0 THEN
       t := 0.0;
        a[ 0 ] := b[ 0 ];
        a[ 1 ] := b[ 1 ];
        a[ 2 ] := b[ 2 ];
        a[ 3 ] := b[ 3 ];

        b[ 0 ] := 2.0 * rand.Uniform()- 1.0;
        b[ 1 ] := 2.0 * rand.Uniform()  - 1.0;
        b[ 2 ] := 2.0 * rand.Uniform() - 1.0;
        b[ 3 ] := 2.0 * rand.Uniform() - 1.0;
    END;
END UpdateMu;

PROCEDURE RandomColor( VAR v: RVector );
BEGIN
    v[ 0 ] := 2.0 * rand.Uniform() - 1.0;
    v[ 1 ] := 2.0 * rand.Uniform() - 1.0;
    v[ 2 ] := 2.0 * rand.Uniform()- 1.0;
    v[ 3 ] := 1.0;
END  RandomColor;   

PROCEDURE UpdateColor( VAR t: REAL; VAR a, b: RVector );
BEGIN
    t := t + 0.01;
    IF  t >= 1.0 THEN
        t := 0.0;
        a[ 0 ] := b[ 0 ];
        a[ 1 ] := b[ 1 ];
        a[ 2 ] := b[ 2 ];
        a[ 3 ] := b[ 3 ];
        RandomColor(b);
    END;
END UpdateColor;

PROCEDURE Interpolate( VAR m: RVector; t: REAL; a, b: RVector );
VAR i: LONGINT;
BEGIN
    FOR i:=0 TO 3 DO
        m[ i ] := ( 1.0 - t ) * a[ i ] + t * b[ i ];
    END;
END Interpolate;

PROCEDURE ExecutionTime(e: CL.cl_event): LONGREAL;
VAR sec: LONGREAL;
	 err: LONGINT;
	 endtime, starttime: HUGEINT;
BEGIN
	err := CL.clGetEventProfilingInfo(e , CL.PROFILING_COMMAND_END, S.SIZEOF(HUGEINT), S.ADR(endtime),0);	   
	err := CL.clGetEventProfilingInfo(e, CL.PROFILING_COMMAND_START, S.SIZEOF(HUGEINT), S.ADR(starttime), 0);

	sec := 1.0D-6*(endtime-starttime); (* ns->ms *)
	RETURN sec;
END ExecutionTime;

PROCEDURE Cleanup;
VAR die : KillerMsg;
	 msg : WMMessages.Message;
	 m : WM.WindowManager;
	 err: LONGINT;
	 
BEGIN {EXCLUSIVE}
	NEW(die); msg.ext := die; msg.msgType := WMMessages.MsgExt;
	m := WM.GetDefaultManager();
	m.Broadcast(msg);
	AWAIT(window = NIL);
	(* Free resources *)
	IF inited THEN
		err := CL.clReleaseEvent(kernelEvent);
		err := CL.clReleaseEvent(readEvent);
		err := CL.clReleaseMemObject(objmem);
		err := CL.clReleaseKernel(kernel);
		err := CL.clReleaseProgram(prog);
		err := CL.clReleaseCommandQueue(commands);
		err := CL.clReleaseContext(context);	
	END;	
END Cleanup;

BEGIN
	Modules.InstallTermHandler(Cleanup);
	NEW(rand);
	rand.InitSeed(Kernel.GetTicks());
	InitCL;
END MyJuliasetCL.

SystemTools.Free  MyJuliasetCL  ~

MyJuliasetCL.Open ~



