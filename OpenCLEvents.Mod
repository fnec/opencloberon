MODULE OpenCLEvents; (** AUTHOR "fnecati"; PURPOSE "Square of vectors using OpenCL"; *)
IMPORT CL := OpenCL, S:=SYSTEM, KernelLog, Streams, Utils:=OpenCLUtils ;

(* An example for Event based timing measurements with two program kernel *)
 
TYPE RVector = POINTER TO ARRAY OF REAL;
	  	
VAR 
	wr: Streams.Writer;

(* c[i] := a[i] + b[i] *)
PROCEDURE MyProgramSource0():CL.PChar;
VAR sw: Streams.StringWriter;
      buf: CL.PChar;
BEGIN
 NEW(sw,1024);
 sw.String(" __kernel void vectorAdd(__global const float* a, __global const float* b, __global float* c)"); sw.Ln;
 sw.String("  { "); 								sw.Ln;
 sw.String("    int i  = get_global_id(0);"); 	sw.Ln;
 sw.String("     c[i] = a[i] + b[i];"); 			sw.Ln;
 sw.String("  }"); 								sw.Ln;
 NEW(buf, sw.Pos());
 sw.Get(buf^);
 RETURN S.VAL(CL.PChar, S.ADR(buf[0]));
END MyProgramSource0;

(* c[i] := a[i] .* b[i] *)
PROCEDURE MyProgramSource1():CL.PChar;
VAR sw: Streams.StringWriter;
      buf: CL.PChar;
BEGIN
 NEW(sw,1024);
 sw.String(" __kernel void vectorMul(__global const float* a, __global const float* b, __global float* c)"); sw.Ln;
 sw.String("  { "); 								sw.Ln;
 sw.String("    int i  = get_global_id(0);"); 	sw.Ln;
 sw.String("     c[i] = a[i] * b[i];"); 			sw.Ln;
 sw.String("  }"); 								sw.Ln;
 NEW(buf, sw.Pos());
 sw.Get(buf^);
 RETURN S.VAL(CL.PChar, S.ADR(buf[0]));
END MyProgramSource1;

(* calculate execution time for the event *)
PROCEDURE ExecutionTime(e: CL.cl_event);
VAR sec: LONGREAL;
	 err: LONGINT;
	 endtime, starttime: HUGEINT;
BEGIN
	err := CL.clGetEventProfilingInfo(e , CL.PROFILING_COMMAND_END, S.SIZEOF(HUGEINT), S.ADR(endtime),0);	   
	err := CL.clGetEventProfilingInfo(e, CL.PROFILING_COMMAND_START, S.SIZEOF(HUGEINT), S.ADR(starttime), 0);

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
	
	globalWorkSize  : CL.csize_t;  (* global domain size for our calculation *)
    
	platformids  : CL.cl_platform_id;
	deviceids : CL.cl_device_id;
	context : CL.cl_context;
	commands : CL.cl_command_queue;  
	
	prog0, prog1      : CL.cl_program;       (* compute program *)
	kernel0, kernel1    : CL.cl_kernel;         (* compute kernel *)

	srcMemA, srcMemB   : CL.cl_mem;  (* device memory used for the input arrays *)
	dstMem0, dstMem1 : CL.cl_mem;  (* device memory used for the results array *)
	
	kernelEvent0, kernelEvent1: CL.cl_event;
	readEvent0, readEvent1: CL.cl_event;
	eventlist, readeventlist: CL.Pcl_event;

      progsource0, progsource1: CL.PChar;
     cmdproperties: HUGEINT;
     commandprops: HUGEINT;
     
BEGIN
	(*Fill our data set with float values *)
	n := 50000;
	NEW(srcArrayA, n); NEW(srcArrayB, n); NEW(dstArray0,n); NEW(dstArray1, n);
	
	FOR i:=0 TO n - 1 DO srcArrayA[i]:=i; srcArrayB[i]:=i; END;

	(* get the platfoms *)	
	err := CL.clGetPlatformIDs( 1, S.ADR(platformids), 0 ); 
	wr.String("clGetPlatformIDs : "); wr.String(Utils.ErrorToStr(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Cannot get platforms!'); wr.Ln; wr.Update;
		RETURN
	END;
    
	(*  Devices  *)  
	err := CL.clGetDeviceIDs(platformids, S.VAL(HUGEINT, {CL.DEVICE_TYPE_GPU}), 1, S.ADR(deviceids), 0);
	wr.String("clGetDeviceIDs : "); wr.String(Utils.ErrorToStr(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Cannot get GPU devices!'); wr.Ln; wr.Update;
		RETURN
	END;     
	
	context := CL.clCreateContext(0, 1, S.ADR(deviceids), NIL , 0, err);
	wr.String("clCreateContext : "); wr.String(Utils.ErrorToStr(err)); wr.Ln; wr.Update; 
	IF context = 0 THEN 
		wr.String('Error: Cannot create context!'); wr.Ln; wr.Update;
		RETURN
	END;
	
	(* properties type cl_bit_field (64 bits), and in oberon there is no 64 bit SET, so, *)
     cmdproperties := S.VAL(HUGEINT, {CL.QUEUE_PROFILING_ENABLE, CL.QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE});
	commands := CL.clCreateCommandQueue(context, deviceids, cmdproperties, err);
	wr.String("clCommandQueue: "); wr.String(Utils.ErrorToStr(err)); wr.Ln; wr.Update;  
	IF commands = 0 THEN 
		wr.String("commands NIL: "); wr.String(Utils.ErrorToStr(err)); wr.Ln; wr.Update;  
		RETURN 
	END;
  (* ******************* *)	
	(* for testing *)
    err := CL.clGetCommandQueueInfo(commands, CL.QUEUE_PROPERTIES, S.SIZEOF(HUGEINT), S.ADR(commandprops), S.ADR(itemp));
   wr.String("commands properties= "); wr.Int(SHORT(commandprops),0); wr.Ln; wr.Update;
   wr.String("commandinfo returned bytes itemp0= "); wr.Int(itemp,0); wr.Ln; wr.Update;   
	wr.String("clGetCommandQueueInfo : "); wr.String(Utils.ErrorToStr(err)); wr.Ln; 	
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to clGetCommandQueueInfo!'); wr.Ln; wr.Update;
		RETURN
	END;   
 
      (*************************************)
      (* allocate device memory objects   *)
	srcMemA := CL.clCreateBuffer(context,  CL.MEM_READ_ONLY,  S.SIZEOF(REAL) * n, 0, err);
	srcMemB := CL.clCreateBuffer(context,  CL.MEM_READ_ONLY,  S.SIZEOF(REAL) * n, 0, err);
		
	dstMem0 := CL.clCreateBuffer(context, CL.MEM_READ_WRITE, S.SIZEOF(REAL) * n, 0, err);
	dstMem1 := CL.clCreateBuffer(context, CL.MEM_READ_WRITE, S.SIZEOF(REAL) * n, 0, err);

	err := CL.clEnqueueWriteBuffer(commands, srcMemA, CL.CL_TRUE, 0, n * S.SIZEOF(REAL), S.ADR(srcArrayA[0]), 0, 0, 0);
	err := CL.clEnqueueWriteBuffer(commands, srcMemB, CL.CL_TRUE, 0, n * S.SIZEOF(REAL), S.ADR(srcArrayB[0]), 0, 0, 0);

	IF (srcMemA = 0) OR  (srcMemB = 0) OR (dstMem0 = 0) OR  (dstMem1 = 0) THEN
		wr.String("Failed to allocate device memory!  : "); wr.Ln; wr.Update;
		RETURN
	END;
      
 	(* ******** Create programs ************ *)
 	
	progsource0 := MyProgramSource0();
	IF progsource0 = NIL THEN
		wr.String("Program Source-0 error"); wr.Ln; wr.Update; wr.Ln; 
		RETURN;
	END;  
	
	prog0 := CL.clCreateProgramWithSource(context, 1, S.ADR(progsource0), 0, err);
	wr.String("clCreateProgramWithSource-0 : "); wr.String(Utils.ErrorToStr(err)); wr.Ln;  wr.Update;
	IF prog0 = 0 THEN 
		wr.String("prog0 NIL: "); wr.String(Utils.ErrorToStr(err)); wr.Ln; wr.Update;  
		RETURN 
	END;

	progsource1 := MyProgramSource1();
	IF progsource1 = NIL THEN
		wr.String("Program Source-1 error"); wr.Ln; wr.Update; wr.Ln; 
		RETURN;
	END;  
	
	prog1 := CL.clCreateProgramWithSource(context, 1, S.ADR(progsource1), 0, err);
	wr.String("clCreateProgramWithSource-1 : "); wr.String(Utils.ErrorToStr(err)); wr.Ln;  wr.Update;
	IF prog1 = 0 THEN 
		wr.String("prog1 NIL: "); wr.String(Utils.ErrorToStr(err)); wr.Ln; wr.Update;  
		RETURN 
	END;	
	(* **************************** *)
	
   
	(* Build the programs *)
	err := CL.clBuildProgram(prog0, 0, NIL, "", 0, 0);
	wr.String("clBuildProgram-0 : "); wr.String(Utils.ErrorToStr(err)); wr.Ln;  wr.Update;
	IF err # CL.SUCCESS THEN
		wr.String('Error: Failed to build program0 executable!'); wr.Ln; wr.Update; 
	END;

	err := CL.clBuildProgram(prog1, 0, NIL, "", 0, 0);
	wr.String("clBuildProgram-1 : "); wr.String(Utils.ErrorToStr(err)); wr.Ln;  wr.Update;
	IF err # CL.SUCCESS THEN
		wr.String('Error: Failed to build program1 executable!'); wr.Ln; wr.Update; 
	END;

	(* Create the compute kernels in the program we wish to run *)
	kernel0 := CL.clCreateKernel(prog0, "vectorAdd" , err); 
	wr.String("clCreateKernel-0 : "); wr.String(Utils.ErrorToStr(err)); wr.Ln;  wr.Update;
	IF kernel0=0 THEN 
		wr.String("kernel0 NIL: "); wr.String(Utils.ErrorToStr(err)); wr.Ln; wr.Update;  
		RETURN 
	END;

	kernel1 := CL.clCreateKernel(prog1, "vectorMul", err); 
	wr.String("clCreateKernel-1: "); wr.String(Utils.ErrorToStr(err)); wr.Ln;  wr.Update;
	IF kernel1=0 THEN 
		wr.String("kernel1 NIL: "); wr.String(Utils.ErrorToStr(err)); wr.Ln; wr.Update;  
		RETURN 
	END;

(* ************************** *)

	(* Set the arguments to our compute kernels *)	
	err := CL.clSetKernelArg(kernel0, 0, S.SIZEOF(CL.cl_mem), S.ADR(srcMemA));
	err := CL.clSetKernelArg(kernel0, 1, S.SIZEOF(CL.cl_mem), S.ADR(srcMemB));
	err := CL.clSetKernelArg(kernel0, 2, S.SIZEOF(CL.cl_mem), S.ADR(dstMem0));

	err := CL.clSetKernelArg(kernel1, 0, S.SIZEOF(CL.cl_mem), S.ADR(srcMemA));
	err := CL.clSetKernelArg(kernel1, 1, S.SIZEOF(CL.cl_mem), S.ADR(srcMemB));
	err := CL.clSetKernelArg(kernel1, 2, S.SIZEOF(CL.cl_mem), S.ADR(dstMem1));
	
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to set kernel arguments!!'); wr.Ln; wr.Update;
		RETURN
	END;
	
	(* Set work-item dimensions and execute the kernels *)
	globalWorkSize := n;
            
	(* Execute the kernels over the entire range of our 1d input data set *)
	wr.String("0-kernelEvent0: "); wr.Int(kernelEvent0,0); wr.Ln;	
	err := CL.clEnqueueNDRangeKernel(commands, kernel0, 1, 0 , S.ADR(globalWorkSize), 0, 0, 0, S.ADR(kernelEvent0));
	wr.String("clEnqueueNDRangeKernel-0 : "); wr.String(Utils.ErrorToStr(err)); wr.Ln; 	
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to execute kernel-0!'); wr.Ln; wr.Update;
		RETURN
	END;   
 
	err := CL.clEnqueueNDRangeKernel(commands, kernel1, 1, 0 , S.ADR(globalWorkSize), 0, 0, 0, S.ADR(kernelEvent1));
	wr.String("clEnqueueNDRangeKernel-1 : "); wr.String(Utils.ErrorToStr(err)); wr.Ln; 	
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to execute kernel-1!'); wr.Ln; wr.Update;
		RETURN
	END;   

	(* ********************* *)
	(* get event info for testing *)
   err := CL.clGetEventInfo(kernelEvent0, CL.EVENT_COMMAND_TYPE, S.SIZEOF(LONGINT), S.ADR(itemp),0);
   wr.String("COMMAND_TYPE for kernelEvent0 = "); wr.Hex(itemp, -4); wr.Ln; 
	wr.String("clGetEventInfo-0 : "); wr.String(Utils.ErrorToStr(err)); wr.Ln; 	
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to clGetEventInfo-0!'); wr.Ln; wr.Update;
		RETURN
	END;   

   err := CL.clGetEventInfo(kernelEvent0, CL.EVENT_COMMAND_EXECUTION_STATUS, S.SIZEOF(LONGINT), S.ADR(itemp),0);
   wr.String("EXECUTION_STATUS for kernelEvent0= "); wr.Hex(itemp, -4); wr.Ln; 
	wr.String("clGetEventInfo-0 : "); wr.String(Utils.ErrorToStr(err)); wr.Ln; 	
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
		err := CL.clWaitForEvents(2, S.ADR(eventlist[0]));

(*
	err := CL.clWaitForEvents(1, S.ADR(kernelEvent0));
	err := CL.clWaitForEvents(1, S.ADR(kernelEvent1));
*)
	(* ******************** *)
	
   err := CL.clGetEventInfo(kernelEvent0, CL.EVENT_COMMAND_EXECUTION_STATUS, S.SIZEOF(LONGINT), S.ADR(itemp),0);
   wr.String("AFTER: EXECUTION_STATUS for kernelEvent0= "); wr.Hex(itemp, -4); wr.Ln; 
	wr.String("clGetEventInfo-0 : "); wr.String(Utils.ErrorToStr(err)); wr.Ln; 	
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to clGetEventInfo-0!'); wr.Ln; wr.Update;
		RETURN
	END;   
	
	 (*  write timing info for kernels *)	
	wr.String("kernel-0 execution time: "); ExecutionTime(kernelEvent0); wr.Ln; wr.Update;
	wr.String("kernel-1 execution time: ");  ExecutionTime(kernelEvent1); wr.Ln; wr.Update;
        	
	(* Read the results from device to host variable*)
	err := CL.clEnqueueReadBuffer(commands, dstMem0, CL.CL_TRUE, 0, n * S.SIZEOF(REAL), S.ADR(dstArray0[0]), 0, 0, S.ADR(readEvent0));
	err := CL.clEnqueueReadBuffer(commands, dstMem1, CL.CL_TRUE, 0, n * S.SIZEOF(REAL), S.ADR(dstArray1[0]), 0, 0, S.ADR(readEvent1));
        
        (* Wait for the the events, i.e. until the results are read *)
        wr.String("Waiting for read events..."); wr.Ln; wr.Update;        
        NEW(readeventlist,2);
        readeventlist[0] := readEvent0;
        readeventlist[1] := readEvent1;
        err := CL.clWaitForEvents(2, S.ADR(readeventlist[0]));                
(*  
		err := CL.clWaitForEvents(1, S.ADR(readEvent0));
		err := CL.clWaitForEvents(1, S.ADR(readEvent1));
  *)
   	 (*  write timing info for readbuffer *)	    
   wr.String("read-0 execution time: ");  ExecutionTime(readEvent0);  wr.Ln; wr.Update;
   wr.String("read-1 execution time: "); ExecutionTime(readEvent1); wr.Ln; wr.Update;

(* write the results *)
	wr.String("destArray0 :"); wr.Ln;  WriteVector(dstArray0, 10);
	wr.String("destArray1  :"); wr.Ln;  WriteVector(dstArray1, 10);
   
   (* ****************************** *)
	(* Free resources *)
	err := CL.clReleaseEvent(kernelEvent0);
	err := CL.clReleaseEvent(kernelEvent1);
	err := CL.clReleaseEvent(readEvent0);
	err := CL.clReleaseEvent(readEvent1);
	err := CL.clReleaseMemObject(srcMemA);
	err := CL.clReleaseMemObject(srcMemB);
	err := CL.clReleaseMemObject(dstMem0);	
	err := CL.clReleaseMemObject(dstMem1);	
	err := CL.clReleaseProgram(prog0);
	err := CL.clReleaseProgram(prog1);	
	err := CL.clReleaseKernel(kernel0);
	err := CL.clReleaseKernel(kernel1);	
	err := CL.clReleaseCommandQueue(commands);
	err := CL.clReleaseContext(context);

 
	deviceids := 0;
	platformids := 0;    	
	wr.String("******************************************"); wr.Ln;
	wr.Update;
END Test;

BEGIN
Streams.OpenWriter(wr, KernelLog.Send);
END OpenCLEvents.

SystemTools.Free OpenCLEvents ~ 

OpenCLEvents.Test ~ 
