MODULE OpenCLEvents; (** AUTHOR "fnecati"; PURPOSE "Square of vectors using OpenCL"; *)
IMPORT CL := OpenCL, KernelLog, Streams, Strings, Utils:=OpenCLUtils ;

(* An example for Event based timing measurements with two program kernel *)

TYPE RVector = POINTER TO ARRAY OF REAL;

VAR
	wr: Streams.Writer;

(* c[i] := a[i] + b[i] *)
PROCEDURE MyProgramSource0():Strings.String;
VAR sw: Streams.StringWriter;
      buf: Strings.String;
BEGIN
 NEW(sw,1024);
 sw.String(" __kernel void vectorAdd(__global const float* a, __global const float* b, __global float* c)"); sw.Ln;
 sw.String("  { "); 								sw.Ln;
 sw.String("    int i  = get_global_id(0);"); 	sw.Ln;
 sw.String("     c[i] = a[i] + b[i];"); 			sw.Ln;
 sw.String("  }"); 								sw.Ln;
 NEW(buf, sw.Pos());
 sw.Get(buf^);
 RETURN buf
END MyProgramSource0;

(* c[i] := a[i] .* b[i] *)
PROCEDURE MyProgramSource1():Strings.String;
VAR sw: Streams.StringWriter;
      buf: Strings.String;
BEGIN
 NEW(sw,1024);
 sw.String(" __kernel void vectorMul(__global const float* a, __global const float* b, __global float* c)"); sw.Ln;
 sw.String("  { "); 								sw.Ln;
 sw.String("    int i  = get_global_id(0);"); 	sw.Ln;
 sw.String("     c[i] = a[i] * b[i];"); 			sw.Ln;
 sw.String("  }"); 								sw.Ln;
 NEW(buf, sw.Pos());
 sw.Get(buf^);
 RETURN buf
END MyProgramSource1;

(* calculate execution time for the event *)
PROCEDURE ExecutionTime(e: CL.cl_event);
VAR sec: LONGREAL;
	 err: LONGINT;
	 endtime, starttime: HUGEINT;
BEGIN
	err := CL.GetEventProfilingInfo(e , CL.PROFILING_COMMAND_END, SIZEOF(HUGEINT), ADDRESSOF(endtime),0);
	err := CL.GetEventProfilingInfo(e, CL.PROFILING_COMMAND_START, SIZEOF(HUGEINT), ADDRESSOF(starttime), 0);

	sec := 1.0D-3*(endtime-starttime);   (* ns -> us *)
	wr.FloatFix(sec, 20,3,0); wr.String(" us.");
END ExecutionTime;

PROCEDURE WriteVector(v: RVector; kmax: LONGINT);
VAR i: LONGINT;
BEGIN
	FOR i:=0 TO kmax-1 DO   wr.FloatFix(v[i],10,1,0);  END;
	wr.Ln;
	wr.Update;
END WriteVector;

PROCEDURE Test*;
VAR
	n: LONGINT; (* size of data *)
	err, i, itemp     : LONGINT; (* error code returned from api calls*)

	srcArrayA, srcArrayB, dstArray0, dstArray1 : RVector;

	globalWorkSize  : CL.size_t;  (* global domain size for our calculation *)

	platformids  : POINTER TO ARRAY OF CL.cl_platform_id;
	platform: CL.cl_platform_id;
	nplatforms: LONGINT;

	deviceids : POINTER TO ARRAY OF CL.cl_device_id;
	deviceid : CL.cl_device_id;
	ndevices: LONGINT;

	context : CL.cl_context;
	commands : CL.cl_command_queue;

	prog0, prog1      : CL.cl_program;       (* compute program *)
	kernel0, kernel1    : CL.cl_kernel;         (* compute kernel *)

	srcMemA, srcMemB   : CL.cl_mem;  (* device memory used for the input arrays *)
	dstMem0, dstMem1 : CL.cl_mem;  (* device memory used for the results array *)

	kernelEvent0, kernelEvent1: CL.cl_event;
	readEvent0, readEvent1: CL.cl_event;
	eventlist, readeventlist: POINTER TO ARRAY OF CL.cl_event;

      progsource0, progsource1: Strings.String;
     cmdproperties: HUGEINT;
     commandprops: HUGEINT;
     
     adr: ADDRESS;
	
BEGIN
	(*Fill our data set with float values *)
	n := 50000;
	NEW(srcArrayA, n); NEW(srcArrayB, n); NEW(dstArray0,n); NEW(dstArray1, n);

	FOR i:=0 TO n - 1 DO srcArrayA[i]:=i; srcArrayB[i]:=i; END;

	(* get the platfoms *)
	err := CL.GetPlatformIDs( 0, 0, ADDRESSOF(nplatforms) );
	wr.String("clGetPlatformIDs nplatforms: "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) OR (nplatforms=0) THEN
		wr.String('Error: Cannot get # of platforms!'); wr.Ln; wr.Update;
		RETURN
	END;

	NEW(platformids, nplatforms);

	err := CL.GetPlatformIDs( nplatforms, ADDRESSOF(platformids[0]), 0 );
	wr.String("clGetPlatformIDs : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Cannot get platforms!'); wr.Ln; wr.Update;
		RETURN
	END;

    	platform := platformids[0];

	(*  Devices  *)

	 err := CL.GetDeviceIDs (platform, CL.DEVICE_TYPE_GPU, 0, 0 , ADDRESSOF(ndevices));
      IF (err # CL.SUCCESS) OR (ndevices = 0) THEN
	        wr.String("clGetDeviceIDs Error: "); wr.String(Utils.GetError(err)); wr.Ln;
          wr.String('Error: Cannot get number of GPU devices!'); wr.Ln; wr.Update;
          RETURN
       END;

	NEW(deviceids, ndevices);
	err := CL.GetDeviceIDs(platform, CL.DEVICE_TYPE_GPU, ndevices, ADDRESSOF(deviceids[0]), 0);
	wr.String("clGetDeviceIDs : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Cannot get devices!'); wr.Ln; wr.Update;
		RETURN
	END;
	deviceid := deviceids[0];

	context := CL.CreateContext(0, 1, ADDRESSOF(deviceid), NIL , NIL, err);
	wr.String("clCreateContext : "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
	IF context = 0 THEN
		wr.String('Error: Cannot create context!'); wr.Ln; wr.Update;
		RETURN
	END;

	(* properties type cl_bit_field (64 bits), and in oberon there is no 64 bit SET, so, *)
     cmdproperties := CL.QUEUE_PROFILING_ENABLE + CL.QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE;
	commands := CL.CreateCommandQueue(context, deviceid, cmdproperties, err);
	wr.String("clCommandQueue: "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
	IF commands = 0 THEN
		wr.String("commands NIL: "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
		RETURN
	END;
  (* ******************* *)
	(* for testing *)
    err := CL.GetCommandQueueInfo(commands, CL.QUEUE_PROPERTIES, SIZEOF(HUGEINT), ADDRESSOF(commandprops), ADDRESSOF(itemp));
   wr.String("commands properties= "); wr.Int(SHORT(commandprops),0); wr.Ln; wr.Update;
   wr.String("commandinfo returned bytes itemp0= "); wr.Int(itemp,0); wr.Ln; wr.Update;
	wr.String("clGetCommandQueueInfo : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to clGetCommandQueueInfo!'); wr.Ln; wr.Update;
		RETURN
	END;

      (*************************************)
      (* allocate device memory objects   *)
	srcMemA := CL.CreateBuffer(context,  CL.MEM_READ_ONLY,  SIZEOF(REAL) * n, 0, err);
	srcMemB := CL.CreateBuffer(context,  CL.MEM_READ_ONLY,  SIZEOF(REAL) * n, 0, err);

	dstMem0 := CL.CreateBuffer(context, CL.MEM_READ_WRITE, SIZEOF(REAL) * n, 0, err);
	dstMem1 := CL.CreateBuffer(context, CL.MEM_READ_WRITE, SIZEOF(REAL) * n, 0, err);

	err := CL.EnqueueWriteBuffer(commands, srcMemA, CL.CL_TRUE, 0, n * SIZEOF(REAL), ADDRESSOF(srcArrayA[0]), 0, 0, 0);
	err := CL.EnqueueWriteBuffer(commands, srcMemB, CL.CL_TRUE, 0, n * SIZEOF(REAL), ADDRESSOF(srcArrayB[0]), 0, 0, 0);

	IF (srcMemA = 0) OR  (srcMemB = 0) OR (dstMem0 = 0) OR  (dstMem1 = 0) THEN
		wr.String("Failed to allocate device memory!  : "); wr.Ln; wr.Update;
		RETURN
	END;

 	(* ******** Create programs ************ *)

	progsource0 := MyProgramSource0();
	adr := ADDRESSOF(progsource0^[0]);
	prog0 := CL.CreateProgramWithSource(context, 1, ADDRESSOF(adr), 0, err);
	wr.String("clCreateProgramWithSource-0 : "); wr.String(Utils.GetError(err)); wr.Ln;  wr.Update;
	IF prog0 = 0 THEN
		wr.String("prog0 NIL: "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
		RETURN
	END;

	progsource1 := MyProgramSource1();
	adr := ADDRESSOF(progsource1^[0]);
	prog1 := CL.CreateProgramWithSource(context, 1, ADDRESSOF(adr), 0, err);
	wr.String("clCreateProgramWithSource-1 : "); wr.String(Utils.GetError(err)); wr.Ln;  wr.Update;
	IF prog1 = 0 THEN
		wr.String("prog1 NIL: "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
		RETURN
	END;
	(* **************************** *)


	(* Build the programs *)
	err := CL.BuildProgram(prog0, 0, 0, "", 0, 0);
	wr.String("clBuildProgram-0 : "); wr.String(Utils.GetError(err)); wr.Ln;  wr.Update;
	IF err # CL.SUCCESS THEN
		wr.String('Error: Failed to build program0 executable!'); wr.Ln; wr.Update;
	END;

	err := CL.BuildProgram(prog1, 0, 0, "", 0, 0);
	wr.String("clBuildProgram-1 : "); wr.String(Utils.GetError(err)); wr.Ln;  wr.Update;
	IF err # CL.SUCCESS THEN
		wr.String('Error: Failed to build program1 executable!'); wr.Ln; wr.Update;
	END;

	(* Create the compute kernels in the program we wish to run *)
	kernel0 := CL.CreateKernel(prog0, "vectorAdd" , err);
	wr.String("clCreateKernel-0 : "); wr.String(Utils.GetError(err)); wr.Ln;  wr.Update;
	IF kernel0=0 THEN
		wr.String("kernel0 NIL: "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
		RETURN
	END;

	kernel1 := CL.CreateKernel(prog1, "vectorMul", err);
	wr.String("clCreateKernel-1: "); wr.String(Utils.GetError(err)); wr.Ln;  wr.Update;
	IF kernel1=0 THEN
		wr.String("kernel1 NIL: "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
		RETURN
	END;

(* ************************** *)

	(* Set the arguments to our compute kernels *)
	err := CL.SetKernelArg(kernel0, 0, SIZEOF(CL.cl_mem), ADDRESSOF(srcMemA));
	err := CL.SetKernelArg(kernel0, 1, SIZEOF(CL.cl_mem), ADDRESSOF(srcMemB));
	err := CL.SetKernelArg(kernel0, 2, SIZEOF(CL.cl_mem), ADDRESSOF(dstMem0));

	err := CL.SetKernelArg(kernel1, 0, SIZEOF(CL.cl_mem), ADDRESSOF(srcMemA));
	err := CL.SetKernelArg(kernel1, 1, SIZEOF(CL.cl_mem), ADDRESSOF(srcMemB));
	err := CL.SetKernelArg(kernel1, 2, SIZEOF(CL.cl_mem), ADDRESSOF(dstMem1));

	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to set kernel arguments!!'); wr.Ln; wr.Update;
		RETURN
	END;

	(* Set work-item dimensions and execute the kernels *)
	globalWorkSize := n;

	(* Execute the kernels over the entire range of our 1d input data set *)
	wr.String("0-kernelEvent0: "); wr.Int(kernelEvent0,0); wr.Ln;
	err := CL.EnqueueNDRangeKernel(commands, kernel0, 1, 0 , ADDRESSOF(globalWorkSize), 0, 0, 0, ADDRESSOF(kernelEvent0));
	wr.String("clEnqueueNDRangeKernel-0 : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to execute kernel-0!'); wr.Ln; wr.Update;
		RETURN
	END;

	err := CL.EnqueueNDRangeKernel(commands, kernel1, 1, 0 , ADDRESSOF(globalWorkSize), 0, 0, 0, ADDRESSOF(kernelEvent1));
	wr.String("clEnqueueNDRangeKernel-1 : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to execute kernel-1!'); wr.Ln; wr.Update;
		RETURN
	END;

	(* ********************* *)
	(* get event info for testing *)
   err := CL.GetEventInfo(kernelEvent0, CL.EVENT_COMMAND_TYPE, SIZEOF(LONGINT), ADDRESSOF(itemp),0);
   wr.String("COMMAND_TYPE for kernelEvent0 = "); wr.Hex(itemp, -4); wr.Ln;
	wr.String("clGetEventInfo-0 : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to clGetEventInfo-0!'); wr.Ln; wr.Update;
		RETURN
	END;

   err := CL.GetEventInfo(kernelEvent0, CL.EVENT_COMMAND_EXECUTION_STATUS, SIZEOF(LONGINT), ADDRESSOF(itemp),0);
   wr.String("EXECUTION_STATUS for kernelEvent0= "); wr.Hex(itemp, -4); wr.Ln;
	wr.String("clGetEventInfo-0 : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to clGetEventInfo-0!'); wr.Ln; wr.Update;
		RETURN
	END;
(* ********************* *)

	(* Wait for the the events, i.e. until the kernels have completed *)
        wr.String("Waiting for kernel events..."); wr.Ln; wr.Update;
		NEW(eventlist,2);
		eventlist[0] := kernelEvent0;
		eventlist[1] := kernelEvent1;
		err := CL.WaitForEvents(2, ADDRESSOF(eventlist[0]));

(*
	err := CL.WaitForEvents(1, ADDRESSOF(kernelEvent0));
	err := CL.WaitForEvents(1, ADDRESSOF(kernelEvent1));
*)
	(* ******************** *)

   err := CL.GetEventInfo(kernelEvent0, CL.EVENT_COMMAND_EXECUTION_STATUS, SIZEOF(LONGINT), ADDRESSOF(itemp),0);
   wr.String("AFTER: EXECUTION_STATUS for kernelEvent0= "); wr.Hex(itemp, -4); wr.Ln;
	wr.String("clGetEventInfo-0 : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to clGetEventInfo-0!'); wr.Ln; wr.Update;
		RETURN
	END;

	 (*  write timing info for kernels *)
	wr.String("kernel-0 execution time: "); ExecutionTime(kernelEvent0); wr.Ln; wr.Update;
	wr.String("kernel-1 execution time: ");  ExecutionTime(kernelEvent1); wr.Ln; wr.Update;

	(* Read the results from device to host variable*)
	err := CL.EnqueueReadBuffer(commands, dstMem0, CL.CL_TRUE, 0, n * SIZEOF(REAL), ADDRESSOF(dstArray0[0]), 0, 0, ADDRESSOF(readEvent0));
	err := CL.EnqueueReadBuffer(commands, dstMem1, CL.CL_TRUE, 0, n * SIZEOF(REAL), ADDRESSOF(dstArray1[0]), 0, 0, ADDRESSOF(readEvent1));

        (* Wait for the the events, i.e. until the results are read *)
        wr.String("Waiting for read events..."); wr.Ln; wr.Update;
        NEW(readeventlist,2);
        readeventlist[0] := readEvent0;
        readeventlist[1] := readEvent1;
        err := CL.WaitForEvents(2, ADDRESSOF(readeventlist[0]));
(*
		err := CL.WaitForEvents(1, ADDRESSOF(readEvent0));
		err := CL.WaitForEvents(1, ADDRESSOF(readEvent1));
  *)
   	 (*  write timing info for readbuffer *)
   wr.String("read-0 execution time: ");  ExecutionTime(readEvent0);  wr.Ln; wr.Update;
   wr.String("read-1 execution time: "); ExecutionTime(readEvent1); wr.Ln; wr.Update;

(* write the results *)
	wr.String("destArray0 :"); wr.Ln;  WriteVector(dstArray0, 10);
	wr.String("destArray1  :"); wr.Ln;  WriteVector(dstArray1, 10);

   (* ****************************** *)
	(* Free resources *)
	err := CL.ReleaseEvent(kernelEvent0);
	err := CL.ReleaseEvent(kernelEvent1);
	err := CL.ReleaseEvent(readEvent0);
	err := CL.ReleaseEvent(readEvent1);
	err := CL.ReleaseMemObject(srcMemA);
	err := CL.ReleaseMemObject(srcMemB);
	err := CL.ReleaseMemObject(dstMem0);
	err := CL.ReleaseMemObject(dstMem1);
	err := CL.ReleaseProgram(prog0);
	err := CL.ReleaseProgram(prog1);
	err := CL.ReleaseKernel(kernel0);
	err := CL.ReleaseKernel(kernel1);
	err := CL.ReleaseCommandQueue(commands);
	err := CL.ReleaseContext(context);



	wr.String("******************************************"); wr.Ln;
	wr.Update;
END Test;

BEGIN
	Streams.OpenWriter(wr, KernelLog.Send);
END OpenCLEvents.

SystemTools.Free OpenCLEvents ~

SystemTools.FreeDownTo OpenCL ~

OpenCLEvents.Test ~
