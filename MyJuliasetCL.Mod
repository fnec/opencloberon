MODULE MyJuliasetCL; (** AUTHOR "fnecati"; PURPOSE "A Raytracing demo using OpenCL"; *)
(*
		This example shows how to use OpenCL to raytrace a 4d Quaternion Julia-Set
          Fractal and intermix the results of a compute kernel with WM for rendering
 *)

IMPORT
	Raster, WMRectangles, WMGraphics, Modules, Strings, Kernel, Random,
	WM := WMWindowManager,  WMMessages, KernelLog, WMDialogs,
	CL := OpenCL, Utils := OpenCLUtils, Streams;

CONST
	WindowWidth = 512; WindowHeight = 512;

TYPE
	IVector = ARRAY 2 OF CL.size_t;
 	RVector = ARRAY 4 OF FLOAT32;

	KillerMsg = OBJECT
	END KillerMsg;

	MBWindow* =  OBJECT(WM.BufferWindow)
	VAR
		(* timer: Kernel.MilliTimer; *)
		mimage: Raster.Image;
		mode: Raster.Mode;
		alive, animated: BOOLEAN;

		rand: Random.Generator;

		platformids  : POINTER TO ARRAY OF CL.cl_platform_id;
		platform: CL.cl_platform_id;
		nplatforms: SIGNED32;

		deviceids : POINTER TO ARRAY OF CL.cl_device_id;
		deviceid : CL.cl_device_id;
		ndevices: SIGNED32;

		context : CL.cl_context;
		commands : CL.cl_command_queue;
		prog      : CL.cl_program;       (* compute program *)
		kernel    : CL.cl_kernel;         (* compute kernel *)

		objmem   : CL.cl_mem;  (* device memory used for the input array *)
		global, local  : IVector; (* global domain size for our calculation *)
		kernelsource: Strings.String;

		muA, muB, muC, colA, colB, colC: RVector;
		muT, colT: FLOAT32;

		epsilon: FLOAT32;
		inited : BOOLEAN;

		MaxWorkGroupSize: CL.size_t;
		WorkGroupItems : SIGNED32;
		WorkGroupSize: IVector;
		sizeX, sizeY: CL.size_t;

		kernelEvent, readEvent: CL.cl_event; (* for event profiling *)
		endupdate: BOOLEAN;
		
		PROCEDURE &New;
		BEGIN
			Init(WindowWidth, WindowHeight, FALSE);
			manager := WM.GetDefaultManager();
			manager.Add(100, 100, SELF, {WM.FlagFrame, WM.FlagClose, WM.FlagNoResizing});
			SetTitle(Strings.NewString("JuliaSetCL: "));
			SetIcon(WMGraphics.LoadImage("WMIcons.tar://TuringCoatWnd.png", TRUE));

			NEW(rand);
			rand.InitSeed(Kernel.GetTicks());
			IncCount;
			
			IF ~InitCL() THEN Close(); RETURN END;
		(* since bpp of linuxAos WM is 16bpp, an image buffer is used. For 32bpp,  windows.img can be used directly *)
			NEW(mimage);
			Raster.Create(mimage, WindowWidth, WindowHeight, Raster.BGRA8888);
			Raster.InitMode(mode, Raster.srcCopy);
			UpdateImage;
			alive := TRUE;
			animated := FALSE;
			
		END New;

		PROCEDURE InitCL(): BOOLEAN;
		VAR err: SIGNED32;
			bufwritten: SIGNED32;
			buf: ARRAY 1024 OF CHAR;
			retsize: CL.size_t;
		BEGIN
			epsilon := 0.001;
			WorkGroupItems := 32;

			muT := 0.0;

			muA := [-0.278, -0.479, 0.0, 0.0];
			muB := [0.278, 0.479, 0.0, 0.0];
			muC := [-0.278, -0.479, -0.231, 0.235];

			colA := [0.25, 0.45, 1.0, 1.0];
			colB := [0.25, 0.45, 1.0, 1.0];
			colC := [0.25, 0.45, 1.0, 1.0];

			err := CL.GetPlatformIDs( 0, 0, ADDRESSOF(nplatforms) );
			out.String("clGetPlatformIDs nplatforms: "); out.String(Utils.GetError(err)); out.Ln;
			IF (err # CL.SUCCESS) OR (nplatforms=0) THEN
				out.String('Error: Cannot get # of platforms!'); out.Ln; out.Update;
				RETURN FALSE
			END;

			NEW(platformids, nplatforms);

			err := CL.GetPlatformIDs( nplatforms, ADDRESSOF(platformids[0]), 0 );
			out.String("clGetPlatformIDs : "); out.String(Utils.GetError(err)); out.Ln;
			IF (err # CL.SUCCESS) THEN
				out.String('Error: Cannot get platforms!'); out.Ln; out.Update;
				RETURN FALSE
			END;

		    	platform := platformids[0];

			(*  Devices  *)

			 err := CL.GetDeviceIDs (platform, CL.DEVICE_TYPE_GPU, 0, 0 , ADDRESSOF(ndevices));
		      IF (err # CL.SUCCESS) OR (ndevices = 0) THEN
				out.String("clGetDeviceIDs Error: "); out.String(Utils.GetError(err)); out.Ln;
		          out.String('Error: Cannot get number of GPU devices!'); out.Ln; out.Update;
		          RETURN FALSE
		       END;

			NEW(deviceids, ndevices);
			err := CL.GetDeviceIDs(platform, CL.DEVICE_TYPE_GPU, ndevices, ADDRESSOF(deviceids[0]), 0);
			out.String("clGetDeviceIDs : "); out.String(Utils.GetError(err)); out.Ln;
			IF (err # CL.SUCCESS) THEN
				out.String('Error: Cannot get devices!'); out.Ln; out.Update;
				RETURN FALSE
			END;
			deviceid := deviceids[0];


			context := CL.CreateContext(0, 1, ADDRESSOF(deviceid), NIL , NIL, err);
			out.String("clCreateContext: ");  out.String(Utils.GetError(err)); out.Ln; out.Update;

			(* with event profile *)

			commands := CL.CreateCommandQueue(context, deviceid, CL.QUEUE_PROFILING_ENABLE + CL.QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE, err);
			out.String("clCreateCommandQueue: ");  out.String(Utils.GetError(err)); out.Ln; out.Update;
			
			kernelsource := Utils.LoadProgramSource("opencloberon/qjulia_kernel.cl", "");
			prog := Utils.CreateProgramWithSource(context, kernelsource^, err);
			out.String("clCreateProgramWithSource: ");  out.String(Utils.GetError(err)); out.Ln; out.Update;


		(*	err := CL.GetProgramInfo(prog, CL.PROGRAM_SOURCE, LEN(buf), ADDRESSOF(buf), bufwritten);
			out.String("bufwritten= "); out.Int(bufwritten, 0); out.Ln;
			out.String("clGetProgramInfoSource= "); out.String(buf); out.Ln;

		*)
			err := CL.BuildProgram(prog, 0, 0, "", NIL, 0);
			out.String("clBuildProgram: ");  out.String(Utils.GetError(err));out.Ln; out.Update;
		(*
			err := CL.GetProgramBuildInfo(prog, deviceids,CL.PROGRAM_BUILD_LOG, LEN(buf), ADDRESSOF(buf[0]), bufwritten);
			out.String("bufwritten= "); out.Int(bufwritten, 0); out.Ln;
			out.String("buf= "); out.String(buf); out.Ln;
		*)


			err := CL.CreateKernelsInProgram(prog, 0,0, ADDRESSOF(bufwritten));
			out.String("clCreateKernelsInProgram: ");  out.String(Utils.GetError(err)); out.Ln; out.Update;

			out.String(" number of kernels in the program = "); out.Int(bufwritten, 0); out.Ln; out.Update;
			err := CL.CreateKernelsInProgram(prog, bufwritten, ADDRESSOF(kernel), 0);

			(*kernel := CL.CreateKernel(prog, "QJuliaKernel", err); *)

			err := CL.GetKernelInfo(kernel, CL.KERNEL_FUNCTION_NAME, LEN(buf), ADDRESSOF(buf[0]),0);
			out.String("Kernelname :"); out.String(buf); out.Ln; out.Update;

			err := CL.GetKernelWorkGroupInfo(kernel, deviceid, CL.KERNEL_WORK_GROUP_SIZE, SIZEOF(CL.size_t), ADDRESSOF(MaxWorkGroupSize), retsize);
			out.String("MaxWorkGroupSize= "); out.Int(MaxWorkGroupSize, 0); out.Ln; out.Update;

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

			objmem := CL.CreateBuffer(context,  CL.MEM_WRITE_ONLY, WindowWidth*WindowHeight*4 , 0, err);
			out.String("clCreateBuffer: ");  out.String(Utils.GetError(err)); out.Ln; out.Update;

			err := CL.SetKernelArg(kernel, 0, SIZEOF(CL.cl_mem), ADDRESSOF(objmem));
			out.String("clSetKernelArg-0: ");  out.String(Utils.GetError(err)); out.Ln; out.Update;

			err := CL.SetKernelArg(kernel, 1, SIZEOF(FLOAT32)*LEN(muC,0), ADDRESSOF(muC[0]));
			out.String("clSetKernelArg-1: ");  out.String(Utils.GetError(err)); out.Ln; out.Update;

			err := CL.SetKernelArg(kernel, 2, SIZEOF(FLOAT32)*LEN(colC,0), ADDRESSOF(colC[0]));
			out.String("clSetKernelArg-2: ");  out.String(Utils.GetError(err)); out.Ln; out.Update;

			err := CL.SetKernelArg(kernel, 3, SIZEOF(FLOAT32), ADDRESSOF(epsilon));
			out.String("clSetKernelArg-3: ");  out.String(Utils.GetError(err)); out.Ln; out.Update;

			inited := (context # NIL) & (commands # NIL) & (prog # NIL)  & (kernel # NIL) & (err=0);
			RETURN inited
		END InitCL;


		PROCEDURE KeyEvent (ucs: SIZE; flags: SET; keysym: SIZE);
		CONST
			stepSize = 0.05;

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
			| "A" : BEGIN {EXCLUSIVE} animated := ~animated; END;
			| "Q" : Close; RETURN;
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

		PROCEDURE Draw(canvas : WMGraphics.Canvas; w, h: SIZE; q: INTEGER);
		BEGIN
			Draw^(canvas, w, h, 0)
		END Draw;

		PROCEDURE Close;
		VAR err: SIGNED32;
		BEGIN
			BEGIN{EXCLUSIVE} alive := FALSE; animated := FALSE; AWAIT(endupdate) END;
			(* Free resources *)
			IF inited THEN
				err := CL.ReleaseEvent(kernelEvent);
				err := CL.ReleaseEvent(readEvent);
				err := CL.ReleaseMemObject(objmem);
				err := CL.ReleaseKernel(kernel);
				err := CL.ReleaseProgram(prog);
				err := CL.ReleaseCommandQueue(commands);
				err := CL.ReleaseContext(context);
			END;			
			Close^;
			DecCount;
		END Close;

		PROCEDURE UpdateMu( VAR t: FLOAT32; VAR a, b: RVector );
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

		PROCEDURE UpdateColor( VAR t: FLOAT32; VAR a, b: RVector );
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

		PROCEDURE Interpolate( VAR m: RVector; t: FLOAT32; CONST a, b: RVector );
		VAR i: SIGNED32;
		BEGIN
		    FOR i:=0 TO 3 DO
		        m[ i ] := ( 1.0 - t ) * a[ i ] + t * b[ i ];
		    END;
		END Interpolate;

		PROCEDURE ExecutionTime(e: CL.cl_event): FLOAT64;
		VAR sec: FLOAT64;
			 err: SIGNED32;
			 endtime, starttime: SIGNED64;
		BEGIN
			err := CL.GetEventProfilingInfo(e , CL.PROFILING_COMMAND_END, SIZEOF(SIGNED64), ADDRESSOF(endtime),0);
			err := CL.GetEventProfilingInfo(e, CL.PROFILING_COMMAND_START, SIZEOF(SIGNED64), ADDRESSOF(starttime), 0);

			sec := 1.0D-6*(endtime-starttime); (* ns->ms *)
			RETURN sec;
		END ExecutionTime;

		PROCEDURE UpdateImage;
		VAR err: SIGNED32;
			str1, str2 : ARRAY 128 OF CHAR;
			relapsed: FLOAT64;

		BEGIN
			BEGIN {EXCLUSIVE} endupdate := FALSE; END;
			IF inited THEN
				(* Kernel.SetTimer(timer,0);*)
			IF animated THEN
				UpdateMu( muT, muA, muB );
				Interpolate( muC, muT, muA, muB );
				UpdateColor( colT, colA, colB );
				Interpolate(colC, colT, colA, colB );
			END;

			(* err := CL.SetKernelArg(kernel, 0, SIZEOF(CL.cl_mem), ADDRESSOF(objmem));*)
			err := CL.SetKernelArg(kernel, 1, SIZEOF(FLOAT32)*LEN(muC,0), ADDRESSOF(muC[0]));
			err := CL.SetKernelArg(kernel, 2, SIZEOF(FLOAT32)*LEN(colC,0), ADDRESSOF(colC[0]));
			err := CL.SetKernelArg(kernel, 3, SIZEOF(FLOAT32), ADDRESSOF(epsilon));

				err := CL.EnqueueNDRangeKernel(commands, kernel, 2, 0 ,  ADDRESSOF(global[0]), ADDRESSOF(local[0]), 0, 0, ADDRESSOF(kernelEvent));
				err := CL.WaitForEvents(1, ADDRESSOF(kernelEvent));

(*				err := CL.Finish(commands);*)
				err := CL.EnqueueReadBuffer( commands, objmem, CL.CL_TRUE, 0,WindowWidth*WindowHeight*4  , mimage.adr, 0, 0, ADDRESSOF(readEvent));
				err := CL.WaitForEvents(1, ADDRESSOF(readEvent));

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
			BEGIN {EXCLUSIVE} endupdate := TRUE; END;
		END UpdateImage;

		PROCEDURE SaveImage;
		VAR res: SIGNED32;
			fname: ARRAY 128 OF CHAR;
		BEGIN
		fname:="juliaset0.bmp";
		IF WMDialogs.QueryString(" Save File name: ",fname)=WMDialogs.ResOk THEN
				WMGraphics.StoreImage(img,fname,res);
		END;
		END SaveImage;

	BEGIN  {ACTIVE}
		WHILE alive DO
			BEGIN{EXCLUSIVE} AWAIT(animated) END;
				UpdateImage;
		END
	END MBWindow;

VAR
	out: Streams.Writer;
	nofWindows: SIGNED32;
	
PROCEDURE Open*;
VAR window : MBWindow;
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
	Streams.OpenWriter(out, KernelLog.Send);
END MyJuliasetCL.

System.Free  MyJuliasetCL  ~

System.FreeDownTo OpenCL ~

MyJuliasetCL.Open ~



