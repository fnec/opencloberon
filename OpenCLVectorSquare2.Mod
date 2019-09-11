MODULE OpenCLVectorSquare2; (** AUTHOR "fnecati"; PURPOSE "Square of vectors using OpenCL"; *)
IMPORT CL := OpenCL,  KernelLog, Streams, Utils:=OpenCLUtils;

CONST DATA_SIZE=32768 ;

TYPE
	RVector = POINTER TO ARRAY OF FLOAT32;

CONST kernelsource = 
 " kernel void square(global float* input, global float* output, const unsigned int count)
	{
	int i  = get_global_id(0);
     if(i < count)
         output[i] = input[i] * input[i];
	}";

VAR
	wr: Streams.Writer;

PROCEDURE Test*;
VAR
	err     : SIGNED32; (* error code returned from api calls*)

	data    : RVector; (* original data set given to device *)
	results : RVector; (* results returned from device *)

	global  : CL.size_t;  (* global domain size for our calculation *)
	local   : CL.size_t;  (* local domain size for our calculation *)

	platform: CL.cl_platform_id;
	deviceid : CL.cl_device_id;
	context : CL.cl_context;
	commands : CL.cl_command_queue;

	prog      : CL.cl_program;       (* compute program *)
	kernel    : CL.cl_kernel;         (* compute kernel *)
	input   : CL.cl_mem;  (* device memory used for the input array *)
	output  : CL.cl_mem;  (* device memory used for the output array *)

	i, count : SIGNED32;
	correct: SIGNED32;
	tmpd: FLOAT32;

	size, retsize: CL.size_t;
BEGIN
	(*Fill our data set with float values *)
	count := DATA_SIZE;
	NEW(data, count);
	NEW(results, count);

	FOR i:=0 TO count - 1 DO data[i]:=i; END;

	IF ~Utils.GetPlatformDevice("NVIDIA", CL.DEVICE_TYPE_GPU, platform, deviceid) THEN
		wr.String("ERROR: Couldnot find Vendor and device"); wr.Ln; wr.Update;
		RETURN
	END;
	
	context := CL.CreateContext(NIL, 1, ADDRESSOF(deviceid), NIL , NIL, err);
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


	(* build program *)
	prog := Utils.BuildProgramFromStringSource(context, kernelsource, "", err);
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Utils.BuildProgramFromStringSource'); wr.Ln; wr.Update;
		RETURN
	END;
	
	 (* Create the compute kernel in the program we wish to run *)
	kernel := CL.CreateKernel(prog, "square", err);
	wr.String("clCreateKernel : "); wr.String(Utils.GetError(err)); wr.Ln;  wr.Update;
	IF kernel=0 THEN
		wr.String("kernel NIL: "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
		RETURN
	END;

	(* Create the input and output arrays in device memory for our calculation *)
	size := SIZEOF(FLOAT32) * count;
	input := CL.CreateBuffer(context,  CL.MEM_READ_WRITE, size , 0, err);
	wr.String("clCreateBuffer input  : "); wr.String(Utils.GetError(err)); wr.Ln;

	output := CL.CreateBuffer(context, CL.MEM_READ_WRITE, size, 0, err);
	wr.String("clCreateBuffer output  : "); wr.String(Utils.GetError(err)); wr.Ln;

	IF (input = 0) OR   (output = 0) THEN
		wr.String("Failed to allocate device memory!  : "); wr.Ln; wr.Update;
		RETURN
	END;

	(* Write our data set into the input array in device memory *)
	err := CL.EnqueueWriteBuffer(commands, input, CL.CL_TRUE, 0, size, ADDRESSOF(data[0]), 0, 0, 0);
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
	wr.String("clGetKernelWorkGroupInfo : "); wr.Int(retsize, 0); wr.Int(local, 10); wr.String(" : "); wr.String(Utils.GetError(err)); wr.Ln;
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
	err := CL.EnqueueReadBuffer( commands, output, CL.CL_TRUE, 0, size, ADDRESSOF(results[0]), 0, 0, 0);
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
END OpenCLVectorSquare2.

System.Free OpenCLVectorSquare1~

System.FreeDownTo OpenCL ~

OpenCLVectorSquare2.Test ~
