MODULE OpenCLVectorSquare; (** AUTHOR "fnecati"; PURPOSE "Square of vectors using OpenCL"; *)
IMPORT CL := OpenCL, KernelLog, Streams, Strings, Utils:=OpenCLUtils;

CONST DATA_SIZE=32768;

TYPE
	RVector = POINTER TO ARRAY OF REAL;

VAR
	wr: Streams.Writer;

PROCEDURE Test*;
VAR
	err     : LONGINT; (* error code returned from api calls*)

	data    : RVector; (* original data set given to device *)
	results : RVector; (* results returned from device *)

	global  : CL.size_t;  (* global domain size for our calculation *)
	local   : CL.size_t;  (* local domain size for our calculation *)

	platformids  : POINTER TO ARRAY OF CL.cl_platform_id;
	platform: CL.cl_platform_id;
	nplatforms: LONGINT;

	deviceids : POINTER TO ARRAY OF CL.cl_device_id;
	deviceid : CL.cl_device_id;
	ndevices: LONGINT;

	context : CL.cl_context;
	commands : CL.cl_command_queue;

	prog      : CL.cl_program;       (* compute program *)
	kernel    : CL.cl_kernel;         (* compute kernel *)
	input   : CL.cl_mem;  (* device memory used for the input array *)
	output  : CL.cl_mem;  (* device memory used for the output array *)

	kernelsource: Strings.String;

	i, count : LONGINT;
	correct: LONGINT;
	tmpd: REAL;

	buf:  ARRAY 1024 OF  CHAR;
	bufwritten: LONGINT;
	dumy: LONGINT;
	retsize: CL.size_t;
	
BEGIN
	(*Fill our data set with float values *)
	count := DATA_SIZE;
	NEW(data, count);
	NEW(results, count);

	FOR i:=0 TO count - 1 DO data[i]:=1.0*i; END;

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
	wr.String("clContext : "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
	IF context = 0 THEN
		wr.String('Error: Cannot create context!'); wr.Ln; wr.Update;
		RETURN
	END;

	commands := CL.CreateCommandQueue(context, deviceid, 0, err);
	wr.String("clCommandQueue: "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
	IF commands = 0 THEN
		wr.String("commands NIL: "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
		RETURN
	END;

	kernelsource := Utils.LoadProgramSource("opencloberon/vectorsquare.cl", "");
	IF kernelsource = NIL THEN
		wr.String(" File Load Error"); wr.Ln; wr.Update; wr.Ln;
	END;

    (* Create the compute program from the source buffer *)
 
	prog := Utils.CreateProgramWithSource(context, kernelsource^, err);
	wr.String("clCreateProgramWithSource : "); wr.String(Utils.GetError(err)); wr.Ln;  wr.Update;
	IF prog = 0 THEN
		wr.String("prog NIL: "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
		RETURN
	END;

	err := CL.GetProgramInfo(prog, CL.PROGRAM_SOURCE, LEN(buf), ADDRESSOF(buf), bufwritten);
	wr.String("clGetProgramInfo : "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: clGetProgramInfo!'); wr.Ln; wr.Update;
		RETURN
	END;
	wr.String("bufwritten= "); wr.Int(bufwritten, 0); wr.Ln;
	wr.String("Prog Source: "); wr.Ln;
	wr.String(buf); wr.Ln; wr.Update;

	err := CL.GetProgramInfo(prog, CL.PROGRAM_NUM_DEVICES, SIZEOF(LONGINT), ADDRESSOF(dumy), 0);
	wr.String("clGetProgramInfo : "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
	IF (err # CL.SUCCESS) THEN
		wr.String("clGetProgramInfo Error: "); wr.String(Utils.GetError(err)); wr.Ln;
		wr.String('Error: clGetProgramInfo!'); wr.Ln; wr.Update;
		RETURN
	END;
	wr.String("numdevices dumy= "); wr.Int(dumy, 0); wr.Ln;

	(* Build the program executable *)
	err := CL.BuildProgram(prog, 0, 0, "", NIL, NIL );
	wr.String("clBuildProgram : "); wr.String(Utils.GetError(err)); wr.Ln;  wr.Update;
	IF err # CL.SUCCESS THEN
		wr.String('Error: Failed to build program executable!'); wr.Ln; wr.Update;
	END;

	err := CL.GetProgramBuildInfo(prog, deviceid,CL.PROGRAM_BUILD_LOG, LEN(buf), ADDRESSOF(buf[0]), 0);
	wr.String("clGetProgramBuildInfo : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: clGetProgramBuildInfo!'); wr.Ln; wr.Update;
		RETURN
	END;
	wr.String("bufwritten= "); wr.Int(bufwritten, 0); wr.Ln;
	wr.String("Prog Build Info: "); wr.String(buf); wr.Ln; wr.Update;

	 (* Create the compute kernel in the program we wish to run *)
	kernel := CL.CreateKernel(prog, "square", err);
	wr.String("clCreateKernel : "); wr.String(Utils.GetError(err)); wr.Ln;  wr.Update;
	IF kernel=0 THEN
		wr.String("kernel NIL: "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
		RETURN
	END;

	err := CL.GetKernelWorkGroupInfo(kernel, deviceid,  CL.KERNEL_WORK_GROUP_SIZE, SIZEOF(CL.size_t), ADDRESSOF(local), retsize);
	wr.String("clGetKernelWorkGroupInfo : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: clGetKernelWorkGroupInfo!'); wr.Ln; wr.Update;
		RETURN
	END;

	(* Create the input and output arrays in device memory for our calculation *)
	input := CL.CreateBuffer(context,  CL.MEM_READ_ONLY,  SIZEOF(REAL) * count, 0, err);
	wr.String("clCreateBuffer input  : "); wr.String(Utils.GetError(err)); wr.Ln;

	output := CL.CreateBuffer(context, CL.MEM_WRITE_ONLY, SIZEOF(REAL) * count, 0, err);
	wr.String("clCreateBuffer output  : "); wr.String(Utils.GetError(err)); wr.Ln;

	IF (input = 0) OR   (output = 0) THEN
		wr.String("Failed to allocate device memory!  : "); wr.Ln; wr.Update;
		RETURN
	END;

	(* Write our data set into the input array in device memory *)
	err := CL.EnqueueWriteBuffer(commands, input, CL.CL_TRUE, 0, SIZEOF(REAL) * count, ADDRESSOF(data[0]), 0, 0, 0);
	wr.String("clEnqueueWriteBuffer : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to write source array!'); wr.Ln; wr.Update;
		RETURN
	END;

	(* Set the arguments to our compute kernel *)
	err := CL.SetKernelArg(kernel, 0, SIZEOF(CL.cl_mem), ADDRESSOF(input));
	wr.String("clSetKernelArg-0 : "); wr.String(Utils.GetError(err)); wr.Ln;

	err := CL.SetKernelArg(kernel, 1, SIZEOF(CL.cl_mem), ADDRESSOF(output));
	wr.String("clSetKernelArg-1 : "); wr.String(Utils.GetError(err)); wr.Ln;

	err := CL.SetKernelArg(kernel, 2, SIZEOF(CL.cl_uint), ADDRESSOF(count));
	wr.String("clSetKernelArg-2 : "); wr.String(Utils.GetError(err)); wr.Ln;

	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to set kernel arguments!!'); wr.Ln; wr.Update;
		RETURN
	END;

	(* Get the maximum work group size for executing the kernel on the device *)
	err := CL.GetKernelWorkGroupInfo(kernel, deviceid,  CL.KERNEL_WORK_GROUP_SIZE, SIZEOF(CL.size_t), ADDRESSOF(local), retsize);
	wr.String("clGetKernelWorkGroupInfo : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to retrieve kernel work group info!'); wr.Ln; wr.Update;
		RETURN
	END;

	(* Execute the kernel over the entire range of our 1d input data set
		using the maximum number of work group items for this device *)
	global := count;
	err := CL.EnqueueNDRangeKernel(commands, kernel, 1, 0 , ADDRESSOF(global), ADDRESSOF(local), 0, 0, 0);
	wr.String("clEnqueueNDRangeKernel : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to execute kernel!'); wr.Ln; wr.Update;
		RETURN
	END;

	(* Wait for the command commands to get serviced before reading back results*)
	err := CL.Finish(commands);
	wr.String("clFinish : "); wr.String(Utils.GetError(err)); wr.Ln;

	(* Read back the results from the device to verify the output *)
	err := CL.EnqueueReadBuffer( commands, output, CL.CL_TRUE, 0, SIZEOF(REAL) * count, ADDRESSOF(results[0]), 0, 0, 0);
	wr.String("EnqueueReadBuffer : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to read output array! '); wr.Ln; wr.Update;
		RETURN
	END;

	(* Validate our results *)
	correct := 0;
	FOR i:= 0 TO count - 1 DO
		(* FPU warning:
			the following check (as in original C sample)
			if results[i] = data[i] * data[i] then

			return the incorrect result (FP accuracy?),
			must store the result to single type variable first,
			and then compare: *)
		tmpd := data[i] * data[i];
		IF results[i] = tmpd THEN INC(correct); END;
	END;

	(* Print a brief summary detailing the results *)
	wr.String('Computed '); wr.Int(correct,0); wr.String('/'); wr.Int(count,0); wr.String(' correct values!'); wr.Ln; wr.Update;

	wr.String("data [1..10 ]"); wr.Ln;
	FOR i:=0 TO 10 DO   wr.FloatFix(data[i],10,1,0);  END;    wr.Ln;
	wr.String("results [1..10 ]"); wr.Ln;
	FOR i:=0 TO 10 DO   wr.FloatFix(results[i],10,1,0);  END;   wr.Ln;

	(* Free resources *)
	err := CL.ReleaseMemObject(input);
	err := CL.ReleaseMemObject(output);
	err := CL.ReleaseProgram(prog);
	err := CL.ReleaseKernel(kernel);
	err := CL.ReleaseCommandQueue(commands);
	err := CL.ReleaseContext(context);

	wr.String("******************************************"); wr.Ln;
	wr.Update;
END Test;

BEGIN

Streams.OpenWriter(wr, KernelLog.Send);
END OpenCLVectorSquare.

System.Free OpenCLVectorSquare ~

System.FreeDownTo OpenCL ~

OpenCLVectorSquare.Test ~
