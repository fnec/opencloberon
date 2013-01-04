MODULE OpenCLVectorSquare1; (** AUTHOR "fnecati"; PURPOSE "Square of vectors using OpenCL"; *)
IMPORT CL := OpenCL, S:=SYSTEM, KernelLog, Streams, Utils:=OpenCLUtils, DynamicStrings, Strings;

CONST DATA_SIZE=32768;

TYPE
	RVector = POINTER TO ARRAY OF REAL;

TYPE
	DynamicString = DynamicStrings.DynamicString;

VAR
	wr: Streams.Writer;
      CRLF: ARRAY 2 OF CHAR;

(* Create kernels using Streams.Writer *)
PROCEDURE MyKernelSource():CL.PChar;
VAR sw: Streams.StringWriter;
      buf: CL.PChar;
BEGIN
 NEW(sw,1024);
 sw.String(" __kernel void square(__global float* input, __global float* output, const unsigned int count)"); sw.Ln;
 sw.String("  { "); 								sw.Ln;
 sw.String("    int i  = get_global_id(0);"); 			sw.Ln;
 sw.String("     if(i < count)"); 						sw.Ln;
 sw.String("         output[i] = input[i] * input[i];"); sw.Ln;
 sw.String("  }"); 									sw.Ln;
 NEW(buf, sw.Pos());
 sw.Get(buf^);
 RETURN S.VAL(CL.PChar, ADDRESSOF(buf[0]));
END MyKernelSource;

(* using array of chars *)
PROCEDURE MyKernelSource2():CL.PChar;
VAR
      buf: ARRAY 1024 OF CHAR;
BEGIN
 buf :=" __kernel void square(__global float* input, __global float* output, const unsigned int count)   {  int i  = get_global_id(0);  if(i < count)      output[i] = input[i] * input[i]; } ";
 RETURN S.VAL(CL.PChar, ADDRESSOF(buf[0]));
END MyKernelSource2;

(* using DynamicString *)
PROCEDURE MyKernelSource3():Strings.String;
VAR ds: DynamicString;
      buf: Strings.String;
BEGIN
 NEW(ds);
 ds.Append(" __kernel void square(__global float* input, __global float* output, const unsigned int count)"); ds.Append(CRLF);
 ds.Append("  { "); 								ds.Append(CRLF);
 ds.Append("    int i  = get_global_id(0);"); 			ds.Append(CRLF);
 ds.Append("     if(i < count)"); 						ds.Append(CRLF);
 ds.Append("         output[i] = input[i] * input[i];"); ds.Append(CRLF);
 ds.Append("  }"); 									ds.Append(CRLF);
 buf := ds.ToArrOfChar();
 RETURN S.VAL(Strings.String, ADDRESSOF(buf^[0]));
END MyKernelSource3;

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

	kernelsource: Strings.String;

	prog      : CL.cl_program;       (* compute program *)
	kernel    : CL.cl_kernel;         (* compute kernel *)
	input   : CL.cl_mem;  (* device memory used for the input array *)
	output  : CL.cl_mem;  (* device memory used for the output array *)

	i, count : LONGINT;
	correct: LONGINT;
	tmpd: REAL;

	buf:  ARRAY 1024 OF  CHAR;
	bufwritten: LONGINT;
	dumy: LONGINT;
      pbuf: CL.PChar;

BEGIN
	(*Fill our data set with float values *)
	count := DATA_SIZE;
	NEW(data, count);
	NEW(results, count);

	FOR i:=0 TO count - 1 DO data[i]:=i; END;

	err := CL.clGetPlatformIDs( 0, 0, ADDRESSOF(nplatforms) );
	wr.String("clGetPlatformIDs nplatforms: "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) OR (nplatforms=0) THEN
		wr.String('Error: Cannot get # of platforms!'); wr.Ln; wr.Update;
		RETURN
	END;

	NEW(platformids, nplatforms);

	err := CL.clGetPlatformIDs( nplatforms, ADDRESSOF(platformids[0]), 0 );
	wr.String("clGetPlatformIDs : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Cannot get platforms!'); wr.Ln; wr.Update;
		RETURN
	END;

    	platform := platformids[0];

	(*  Devices  *)

	 err := CL.clGetDeviceIDs (platform, CL.DEVICE_TYPE_GPU, 0, 0 , ADDRESSOF(ndevices));
      IF (err # CL.SUCCESS) OR (ndevices = 0) THEN
	        wr.String("clGetDeviceIDs Error: "); wr.String(Utils.GetError(err)); wr.Ln;
          wr.String('Error: Cannot get number of GPU devices!'); wr.Ln; wr.Update;
          RETURN
       END;

	NEW(deviceids, ndevices);
	err := CL.clGetDeviceIDs(platform, CL.DEVICE_TYPE_GPU, ndevices, ADDRESSOF(deviceids[0]), 0);
	wr.String("clGetDeviceIDs : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Cannot get devices!'); wr.Ln; wr.Update;
		RETURN
	END;
	deviceid := deviceids[0];

	context := CL.clCreateContext(0, 1, ADDRESSOF(deviceid), 0 , 0, err);
	wr.String("clContext : "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
	IF context = 0 THEN
		wr.String('Error: Cannot create context!'); wr.Ln; wr.Update;
		RETURN
	END;

	commands := CL.clCreateCommandQueue(context, deviceid, 0, err);
	wr.String("clCommandQueue: "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
	IF commands = 0 THEN
		wr.String("commands NIL: "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
		RETURN
	END;

(*	kernelsource := Utils.LoadProgramSource("opencloberon/vectorsquare.cl", ""); *)
(*	kernelsource := MyKernelSource(); *)
(*	kernelsource := MyKernelSource2();*)
	kernelsource := MyKernelSource3();
	IF kernelsource = NIL THEN
		wr.String(" File Load Error"); wr.Ln; wr.Update; wr.Ln;
		RETURN;
	END;
	buf :=" __kernel void square(__global float* input, __global float* output, const unsigned int count)   {  int i  = get_global_id(0);  if(i < count)      output[i] = input[i] * input[i]; } ";
	pbuf := S.VAL(CL.PChar, ADDRESSOF(buf[0]));
	
    (* Create the compute program from the source buffer *)
	(*	prog := CL.clCreateProgramWithSource(context, 1, ADDRESSOF(kernelsource), NIL, err);*)
	prog := CL.clCreateProgramWithSource(context, 1, ADDRESSOF(pbuf), 0, bufwritten);
	wr.String("clCreateProgramWithSource : "); wr.String(Utils.GetError(err)); wr.Ln;  wr.Update;
	IF prog = 0 THEN
		wr.String("prog NIL: "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
		RETURN
	END;

	err := CL.clGetProgramInfo(prog, CL.PROGRAM_SOURCE, LEN(buf), ADDRESSOF(buf), bufwritten);
	wr.String("clGetProgramInfo : "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: clGetProgramInfo!'); wr.Ln; wr.Update;
		RETURN
	END;
	wr.String("bufwritten= "); wr.Int(bufwritten, 0); wr.Ln;
	wr.String("Prog Source: "); wr.Ln;
	wr.String(buf); wr.Ln; wr.Update;

	err := CL.clGetProgramInfo(prog, CL.PROGRAM_NUM_DEVICES, SIZEOF(LONGINT), ADDRESSOF(dumy), bufwritten);
	wr.String("clGetProgramInfo : "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
	IF (err # CL.SUCCESS) THEN
		wr.String("clGetProgramInfo Error: "); wr.String(Utils.GetError(err)); wr.Ln;
		wr.String('Error: clGetProgramInfo!'); wr.Ln; wr.Update;
		RETURN
	END;
	wr.String("numdevices dumy= "); wr.Int(dumy, 0); wr.Ln;

	(* Build the program executable *)
	err := CL.clBuildProgram(prog, 0, 0, "", 0, 0);
	wr.String("clBuildProgram : "); wr.String(Utils.GetError(err)); wr.Ln;  wr.Update;
	IF err # CL.SUCCESS THEN
		wr.String('Error: Failed to build program executable!'); wr.Ln; wr.Update;
	END;

	err := CL.clGetProgramBuildInfo(prog, deviceid,CL.PROGRAM_BUILD_LOG, LEN(buf), ADDRESSOF(buf[0]), bufwritten);
	wr.String("clGetProgramBuildInfo : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: clGetProgramBuildInfo!'); wr.Ln; wr.Update;
		RETURN
	END;
	wr.String("bufwritten= "); wr.Int(bufwritten, 0); wr.Ln;
	wr.String("Prog Build Info: "); wr.String(buf); wr.Ln; wr.Update;

	 (* Create the compute kernel in the program we wish to run *)
	kernel := CL.clCreateKernel(prog, "square", err);
	wr.String("clCreateKernel : "); wr.String(Utils.GetError(err)); wr.Ln;  wr.Update;
	IF kernel=0 THEN
		wr.String("kernel NIL: "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
		RETURN
	END;

	err := CL.clGetKernelWorkGroupInfo(kernel, deviceid,  CL.KERNEL_WORK_GROUP_SIZE, SIZEOF(LONGINT), ADDRESSOF(local), 0);
	wr.String("clGetKernelWorkGroupInfo : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: clGetKernelWorkGroupInfo!'); wr.Ln; wr.Update;
		RETURN
	END;

	(* Create the input and output arrays in device memory for our calculation *)
	input := CL.clCreateBuffer(context,  CL.MEM_READ_ONLY,  SIZEOF(REAL) * count, 0, err);
	wr.String("clCreateBuffer input  : "); wr.String(Utils.GetError(err)); wr.Ln;

	output := CL.clCreateBuffer(context, CL.MEM_WRITE_ONLY, SIZEOF(REAL) * count, 0, err);
	wr.String("clCreateBuffer output  : "); wr.String(Utils.GetError(err)); wr.Ln;

	IF (input = 0) OR   (output = 0) THEN
		wr.String("Failed to allocate device memory!  : "); wr.Ln; wr.Update;
		RETURN
	END;

	(* Write our data set into the input array in device memory *)
	err := CL.clEnqueueWriteBuffer(commands, input, CL.CL_TRUE, 0, SIZEOF(REAL) * count, ADDRESSOF(data[0]), 0, 0, 0);
	wr.String("clEnqueueWriteBuffer : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to write source array!'); wr.Ln; wr.Update;
		RETURN
	END;

	(* Set the arguments to our compute kernel *)
	err := CL.clSetKernelArg(kernel, 0, SIZEOF(CL.cl_mem), ADDRESSOF(input));
	wr.String("clSetKernelArg-0 : "); wr.String(Utils.GetError(err)); wr.Ln;

	err := CL.clSetKernelArg(kernel, 1, SIZEOF(CL.cl_mem), ADDRESSOF(output));
	wr.String("clSetKernelArg-1 : "); wr.String(Utils.GetError(err)); wr.Ln;

	err := CL.clSetKernelArg(kernel, 2, SIZEOF(CL.cl_uint), ADDRESSOF(count));
	wr.String("clSetKernelArg-2 : "); wr.String(Utils.GetError(err)); wr.Ln;

	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to set kernel arguments!!'); wr.Ln; wr.Update;
		RETURN
	END;

	(* Get the maximum work group size for executing the kernel on the device *)
	err := CL.clGetKernelWorkGroupInfo(kernel, deviceid,  CL.KERNEL_WORK_GROUP_SIZE, SIZEOF(LONGINT), ADDRESSOF(local), 0);
	wr.String("clGetKernelWorkGroupInfo : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to retrieve kernel work group info!'); wr.Ln; wr.Update;
		RETURN
	END;

	(* Execute the kernel over the entire range of our 1d input data set
		using the maximum number of work group items for this device *)
	global := count;
	err := CL.clEnqueueNDRangeKernel(commands, kernel, 1, 0 , ADDRESSOF(global), ADDRESSOF(local), 0, 0, 0);
	wr.String("clEnqueueNDRangeKernel : "); wr.String(Utils.GetError(err)); wr.Ln;
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Failed to execute kernel!'); wr.Ln; wr.Update;
		RETURN
	END;

	(* Wait for the command commands to get serviced before reading back results*)
	err := CL.clFinish(commands);
	wr.String("clFinish : "); wr.String(Utils.GetError(err)); wr.Ln;

	(* Read back the results from the device to verify the output *)
	err := CL.clEnqueueReadBuffer( commands, output, CL.CL_TRUE, 0, SIZEOF(REAL) * count, ADDRESSOF(results[0]), 0, 0, 0);
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
	err := CL.clReleaseMemObject(input);
	err := CL.clReleaseMemObject(output);
	err := CL.clReleaseProgram(prog);
	err := CL.clReleaseKernel(kernel);
	err := CL.clReleaseCommandQueue(commands);
	err := CL.clReleaseContext(context);

	wr.String("******************************************"); wr.Ln;
	wr.Update;
END Test;

BEGIN
CRLF[0]:=0AX;
CRLF[1]:=0X;

Streams.OpenWriter(wr, KernelLog.Send);
END OpenCLVectorSquare1.

SystemTools.Free OpenCLVectorSquare1~

SystemTools.FreeDownTo OpenCL ~

OpenCLVectorSquare1.Test ~
