MODULE OpenCLUtils; (** AUTHOR "fnecati"; PURPOSE "OpenCL1.2 utilities"; *)
IMPORT CL:=OpenCL, Files, Strings, KernelLog;

TYPE
	String64 = ARRAY 64 OF CHAR;

TYPE PlatformName* = LONGINT; 
CONST 
	(* current platforms *)
	AMD* = 0;
	NVIDIA* = 1;
	INTEL* = 2;
	APPLE* = 3;
	
CONST
	(* error codes for InitPlatform *)
	Ok* = 0;
	NoPlatform* = 1;
	NoDevice* = 2;
	NoContext* = 3;
	NoCommandQueue* = 4;
	

TYPE
	SizeArray = POINTER TO ARRAY OF CL.size_t;
	
	Device* = RECORD
		id*: CL.cl_device_id;
		platformid*: CL.cl_platform_id;
		
		name*: ARRAY 64 OF CHAR;
		vendor*: ARRAY 64 OF CHAR;
		driverVersion*: ARRAY 64 OF CHAR;
		deviceVersion*: ARRAY 64 OF CHAR;
		openclVersion*: ARRAY 64 OF CHAR;
		devtype*: CL.cl_bitfield;
		typestr*: ARRAY 32 OF CHAR;
		
		maxComputeUnits*: CL.cl_uint;
		maxWorkItemDimension*: CL.cl_uint;
		maxWorkItemSize*: SizeArray;
		maxWorkGroupSize*: CL.size_t;
		
		(* add others .. *)
	END;	
	
	Devices* = POINTER TO ARRAY OF Device;
	
	Platform* = RECORD 		
		id*: CL.cl_platform_id;
		profile*: ARRAY 64 OF CHAR;
		version*: ARRAY 64 OF CHAR;		
		name*: ARRAY 64 OF CHAR;
		vendor*: ARRAY 64 OF CHAR;
		extensions*: ARRAY 128 OF CHAR;
		
		numOfDevices*: LONGINT;
		devices*: Devices;
	END;
		
	Platforms*  = POINTER TO ARRAY OF Platform;

VAR
	NumberOfPlatforms-: LONGINT;
	platforms-: Platforms;

(**
 Loads an ASCII Program file and prepends the header to the code.
	fname        program filename
	header        code that is prepended to the loaded file, typically a set of #defines or a header
*)
PROCEDURE LoadProgramSource*(fname: ARRAY OF CHAR; CONST header: ARRAY OF CHAR): Strings.String;
VAR
     f: Files.File;
      rider: Files.Rider;
      str: Strings.String;
      len: LONGINT;
BEGIN
	f := Files.Old(fname);
	IF f # NIL THEN
		len := Strings.Length(header);
		NEW(str, f.Length()+1+len);
		Strings.Append(str^, header);
		Strings.AppendChar(str^,0AX);
		f.Set(rider, 0);
		f.ReadBytes(rider, str^, len, f.Length());
	END;	
	RETURN str;
END LoadProgramSource;

PROCEDURE CheckError*(CONST title: ARRAY OF CHAR; err: LONGINT);
BEGIN
	IF err # CL.SUCCESS THEN
		KernelLog.String(title);  KernelLog.String(GetError(err)); KernelLog.Ln;
	END;	
END CheckError;

(** wrapper procedure  for CL.CreateProgramWithSource *)
PROCEDURE CreateProgramWithSource*(context: CL.cl_context; CONST progSource: ARRAY OF CHAR; VAR err: LONGINT ): CL.cl_program;
VAR adr: ADDRESS;
	prog: CL.cl_program;
BEGIN
	prog := 0;
	err := CL.SUCCESS;
	
	IF progSource # "" THEN
		adr := ADDRESSOF(progSource[0]);
		prog := CL.CreateProgramWithSource(context, 1, ADDRESSOF(adr), 0, err);
		IF err # CL.SUCCESS THEN
			CheckError("ERROR: Creating program from this program source: ", err);
		END;
	ELSE	
		CheckError("ERROR: Loading this program source = NIL ", err);
	END;
	RETURN prog;
END CreateProgramWithSource;

(** build program from given program source and build options as array of char *)
PROCEDURE BuildProgramFromStringSource*(context: CL.cl_context; CONST progSource: ARRAY OF CHAR; CONST buildoptions:  ARRAY OF CHAR; VAR err: LONGINT): CL.cl_program;
VAR 
	adr : ADDRESS;
	prog: CL.cl_program;
BEGIN
	prog := 0;
	IF progSource # "" THEN
		adr := ADDRESSOF(progSource[0]);
		prog := CL.CreateProgramWithSource(context, 1, ADDRESSOF(adr), 0, err);
		IF err # CL.SUCCESS THEN
			CheckError("ERROR: clCreateProgramWithSource with this program source: ", err);
			prog := 0;
		END;
	ELSE
		CheckError("ERROR: Loading this kernel,  source = NIL ", err);
		err := CL.INVALID_VALUE;
		prog := 0;
	END;
	
	(* Build the program executable *)
	IF prog # 0 THEN
		err := CL.BuildProgram(prog, 0, 0, buildoptions, 0, 0);
		IF err # CL.SUCCESS THEN
			KernelLog.String('Error: Failed to build program executable! '); KernelLog.String(GetError(err)); KernelLog.Ln;
			prog := 0;
		END;
	END;	
		
	RETURN prog;
END BuildProgramFromStringSource;

(** build program from given program filename and build options *)
PROCEDURE BuildProgramFromSourceFile*(context: CL.cl_context; CONST progFilename, kernelheader, buildoptions: ARRAY OF CHAR; VAR err: LONGINT): CL.cl_program;
VAR prog: CL.cl_program;
	progSource : Strings.String;
	erstr: ARRAY 128 OF CHAR;
BEGIN
	prog := 0;
	progSource := LoadProgramSource(progFilename, kernelheader);
	IF progSource = NIL THEN
		COPY(progFilename, erstr);
		Strings.Append(erstr,":  ERROR: Loading this program source file: ");				
	END;	
	prog := BuildProgramFromStringSource(context, progSource^, buildoptions, err);
	
	RETURN prog;
END BuildProgramFromSourceFile;

PROCEDURE GetProgramBuildLog*(program : CL.cl_program; deviceid : CL.cl_device_id): LONGINT;
VAR err: LONGINT;
	buf:  ARRAY 1024 OF  CHAR;
BEGIN
	err := CL.GetProgramBuildInfo(program, deviceid,CL.PROGRAM_BUILD_LOG, LEN(buf), ADDRESSOF(buf[0]), 0);
	IF err # CL.SUCCESS THEN
		KernelLog.String('Error: Failed to get GetProgramBuildLog ! '); KernelLog.String(GetError(err)); KernelLog.Ln;
	ELSE
		KernelLog.String("Prog Build Info: "); KernelLog.String(buf); KernelLog.Ln;
	END;
	RETURN err;
END GetProgramBuildLog;

PROCEDURE GetProgramSource*(program : CL.cl_program ): LONGINT;
VAR err: LONGINT;
	buf:  ARRAY 1024 OF  CHAR;
	bufwritten: LONGINT;
BEGIN
	err := CL.GetProgramInfo(program, CL.PROGRAM_SOURCE, LEN(buf), ADDRESSOF(buf), bufwritten);
	IF (err # CL.SUCCESS) THEN
		KernelLog.String('Error: Failed to get GetProgramSource ! '); KernelLog.String(GetError(err)); KernelLog.Ln;
	ELSE	
		KernelLog.String("Prog Source: "); KernelLog.Ln; 
		KernelLog.String(buf); KernelLog.Ln; 
	END;
	
	RETURN err;
END GetProgramSource;

(** search opencl platforms and devices and fill platforms variable *)
PROCEDURE SearchPlatformsAndDevices(); 
VAR
	err: LONGINT;
	platformids  : POINTER TO ARRAY OF CL.cl_platform_id;
	platform: CL.cl_platform_id;
	nplatforms: LONGINT;
	deviceids : POINTER TO ARRAY OF CL.cl_device_id;
	ndevices: LONGINT;
	devtype: CL.cl_bitfield;

	i, k: LONGINT;
	str : ARRAY 32 OF CHAR;
	buf  :  ARRAY 1024 OF  CHAR;

	uintvalue: CL.cl_uint;
	workitemsize: SizeArray;
	sizevalue: CL.size_t;
	
BEGIN
	
	err := CL.GetPlatformIDs( 0, 0, ADDRESSOF(nplatforms) );
	IF (err # CL.SUCCESS) OR (nplatforms=0) THEN
		KernelLog.String('Error: Cannot get # of platforms!: '); KernelLog.String(GetError(err)); KernelLog.Ln;
		RETURN
	END;
	
	NumberOfPlatforms := nplatforms;
	
	NEW(platformids, nplatforms);

	err := CL.GetPlatformIDs( nplatforms, ADDRESSOF(platformids[0]), 0 );
	IF (err # CL.SUCCESS) THEN
		KernelLog.String('Error: Cannot get platforms!: '); KernelLog.String(GetError(err)); KernelLog.Ln;
		RETURN
	END;
	
	NEW(platforms, NumberOfPlatforms);
	FOR i:=0 TO nplatforms-1 DO
		platforms[i].id := platformids[i];
		
		err := CL.GetPlatformInfo(platformids[i], CL.PLATFORM_PROFILE, LEN(buf), ADDRESSOF(buf[0]), 0);
		COPY(buf, platforms[i].profile);
		err := CL.GetPlatformInfo(platformids[i],CL.PLATFORM_VERSION, LEN(buf), ADDRESSOF(buf[0]), 0);
		COPY(buf, platforms[i].version);
		err := CL.GetPlatformInfo(platformids[i],CL.PLATFORM_NAME, LEN(buf), ADDRESSOF(buf[0]), 0);
		COPY(buf, platforms[i].name);
		err := CL.GetPlatformInfo(platformids[i],CL.PLATFORM_VENDOR, LEN(buf), ADDRESSOF(buf[0]), 0);
		COPY(buf, platforms[i].vendor);
		err := CL.GetPlatformInfo(platformids[i],CL.PLATFORM_EXTENSIONS, LEN(buf), ADDRESSOF(buf[0]), 0);
		COPY(buf, platforms[i].extensions);	
	END;	
	
	(*! =============================== *)
	(* search devices for each platform *)
	FOR i := 0 TO nplatforms-1 DO
	    	platform := platformids[i];

		(*  get # of devices for this platform  *)
		err := CL.GetDeviceIDs (platform, CL.DEVICE_TYPE_ALL, 0, 0 , ADDRESSOF(ndevices));
		IF (err = CL.SUCCESS) & (ndevices > 0) THEN
			
			platforms[i].numOfDevices := ndevices;
			
			NEW(deviceids, ndevices);
			NEW(platforms[i].devices, ndevices);
			
		
				err := CL.GetDeviceIDs(platform, CL.DEVICE_TYPE_ALL, ndevices, ADDRESSOF(deviceids[0]), 0);
				
				FOR k:=0 TO ndevices-1 DO
					platforms[i].devices[k].id := deviceids[k];
					platforms[i].devices[k].platformid := platform;
					
					 err := CL.GetDeviceInfo(deviceids[k],CL.DEVICE_NAME, LEN(buf), ADDRESSOF(buf[0]), 0);
					COPY(buf, platforms[i].devices[k].name);
					 err := CL.GetDeviceInfo(deviceids[k],CL.DEVICE_VENDOR, LEN(buf), ADDRESSOF(buf[0]), 0);
					COPY(buf, platforms[i].devices[k].vendor);
					 err := CL.GetDeviceInfo(deviceids[k],CL.DRIVER_VERSION, LEN(buf), ADDRESSOF(buf[0]), 0);
					COPY(buf, platforms[i].devices[k].driverVersion);

					 err := CL.GetDeviceInfo(deviceids[k],CL.DEVICE_VERSION, LEN(buf), ADDRESSOF(buf[0]), 0);
					COPY(buf, platforms[i].devices[k].deviceVersion);
					 err := CL.GetDeviceInfo(deviceids[k],CL.DEVICE_OPENCL_C_VERSION, LEN(buf), ADDRESSOF(buf[0]), 0);
					COPY(buf, platforms[i].devices[k].openclVersion);
					
					err := CL.GetDeviceInfo(deviceids[k],CL.DEVICE_TYPE,  SIZEOF(CL.cl_bitfield), ADDRESSOF(devtype), 0);
					platforms[i].devices[k].devtype := devtype;
					IF devtype = CL.DEVICE_TYPE_DEFAULT THEN str := 'DEVICE_TYPE_DEFAULT';
					ELSIF devtype = CL.DEVICE_TYPE_CPU THEN str := 'DEVICE_TYPE_CPU';
					ELSIF devtype = CL.DEVICE_TYPE_GPU THEN str := 'DEVICE_TYPE_GPU';
					ELSIF devtype = CL.DEVICE_TYPE_ACCELERATOR THEN str := 'DEVICE_TYPE_ACCELERATOR';
					ELSIF devtype = CL.DEVICE_TYPE_CUSTOM THEN str := 'DEVICE_TYPE_CUSTOM';
					ELSE str := "Unknown Device Type"
  					END;
  					COPY(str, platforms[i].devices[k].typestr);

					err := CL.GetDeviceInfo(deviceids[k],CL.DEVICE_MAX_COMPUTE_UNITS, SIZEOF(CL.cl_uint), ADDRESSOF(uintvalue), 0);
					platforms[i].devices[k].maxComputeUnits := uintvalue;
					err := CL.GetDeviceInfo(deviceids[k],CL.DEVICE_MAX_WORK_ITEM_DIMENSIONS, SIZEOF(CL.cl_uint), ADDRESSOF(uintvalue), 0);
					platforms[i].devices[k].maxWorkItemDimension := uintvalue;
					NEW(workitemsize, uintvalue);
					
					err := CL.GetDeviceInfo(deviceids[k],CL.DEVICE_MAX_WORK_ITEM_SIZES, uintvalue*SIZEOF(CL.size_t), ADDRESSOF(workitemsize[0]), 0);
					platforms[i].devices[k].maxWorkItemSize := workitemsize;
					err := CL.GetDeviceInfo(deviceids[k],CL.DEVICE_MAX_WORK_GROUP_SIZE, SIZEOF(CL.size_t), ADDRESSOF(sizevalue), 0);
					platforms[i].devices[k].maxWorkGroupSize := sizevalue;
					
					(* add others ... *)
					 
			END; (* k *)
				
		END;
	END; (* i *)	
END SearchPlatformsAndDevices;

PROCEDURE GetPlatformByVendor*(CONST vname: ARRAY OF CHAR; VAR p: Platform): BOOLEAN;
VAR i: LONGINT;
	found: BOOLEAN;
BEGIN
	found := FALSE;
	IF NumberOfPlatforms > 0 THEN
		i := 0;
		WHILE (i< NumberOfPlatforms) & ~found DO
			IF Strings.Pos(platforms[i].vendor, vname) > 0 THEN		
				p := platforms[i];
				found := TRUE;
			END;
			INC(i);			
		END;		
	END;
	RETURN found;	
END GetPlatformByVendor;

(* vendors AMD, NVIDIA, Intel; devicetype: CPU, GPU,.. *)

PROCEDURE GetPlatformDevice*(CONST vname: ARRAY OF CHAR; devicetype: CL.cl_bitfield; VAR platform: CL.cl_platform_id; VAR device: CL.cl_device_id): BOOLEAN;
VAR i: LONGINT;
	found: BOOLEAN;
	p: Platform;
BEGIN
	(* first, search platform *)
	found := FALSE;
	IF NumberOfPlatforms > 0 THEN
		i := 0;
		WHILE (i< NumberOfPlatforms) & ~found DO
			IF Strings.Pos(vname, platforms[i].vendor) # -1 THEN		
				p := platforms[i];
				found := TRUE;
				
			END;
			INC(i);			
		END;		
	END;
	
	IF ~found THEN
		 KernelLog.String("ERROR: Could find Platform Vendor: "); KernelLog.String(vname); KernelLog.Ln; 
	 	RETURN FALSE
	 END;
	 
	platform := p.id;
	
	(* search device type, return first found*)
	found:= FALSE;
	i := 0;
	WHILE (i <= p.numOfDevices) & ~found DO
		IF p.devices[i].devtype = devicetype THEN
			found := TRUE;
			device := p.devices[i].id;
		END;
		INC(i);
	END;
	
	IF ~found THEN 
		KernelLog.String("ERROR: Could find  "); 
		KernelLog.String(vname); KernelLog.String(": GPU "); KernelLog.Ln;
	END;
	RETURN found;	
END GetPlatformDevice;

(** Roundup division function for efficient workgrup size calculation *)
PROCEDURE RoundUp*(groupsize, globalsize: CL.size_t): CL.size_t; (* size_t *)
VAR r: CL.size_t;
BEGIN
	r := globalsize MOD groupsize;
	IF r = 0 THEN RETURN globalsize END;
	RETURN globalsize + groupsize - r;
END RoundUp;

(** convert cl error number to the corresponding string *)
PROCEDURE GetError*(err:LONGINT): String64;
VAR serr : String64;
	serrno: ARRAY 16 OF CHAR;
BEGIN
	(* cl.h errors *)
	IF err = CL.SUCCESS THEN serr := "SUCCESS"
	ELSIF err = CL.DEVICE_NOT_FOUND THEN serr := "DEVICE_NOT_FOUND";
	ELSIF err = CL.DEVICE_NOT_AVAILABLE THEN serr := "DEVICE_NOT_AVAILABLE";
	ELSIF err = CL.COMPILER_NOT_AVAILABLE THEN serr := "COMPILER_NOT_AVAILABLE";
	ELSIF err = CL.MEM_OBJECT_ALLOCATION_FAILURE THEN serr := "MEM_OBJECT_ALLOCATION_FAILURE";
	ELSIF err = CL.OUT_OF_RESOURCES THEN serr := "OUT_OF_RESOURCES";
	ELSIF err = CL.OUT_OF_HOST_MEMORY THEN serr := "OUT_OF_HOST_MEMORY";
	ELSIF err = CL.PROFILING_INFO_NOT_AVAILABLE THEN serr := "PROFILING_INFO_NOT_AVAILABLE";
	ELSIF err = CL.MEM_COPY_OVERLAP THEN serr := "MEM_COPY_OVERLAP";
	ELSIF err = CL.IMAGE_FORMAT_MISMATCH THEN serr := "IMAGE_FORMAT_MISMATCH";
	ELSIF err = CL.IMAGE_FORMAT_NOT_SUPPORTED THEN serr := "IMAGE_FORMAT_NOT_SUPPORTED";
	ELSIF err = CL.BUILD_PROGRAM_FAILURE THEN serr := "BUILD_PROGRAM_FAILURE";
	ELSIF err = CL.MAP_FAILURE THEN serr := "MAP_FAILURE";
	ELSIF err = CL.MISALIGNED_SUB_BUFFER_OFFSET THEN serr := "MISALIGNED_SUB_BUFFER_OFFSET";
	ELSIF err = CL.EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST THEN serr := "EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST";
	ELSIF err = CL.COMPILE_PROGRAM_FAILURE THEN serr := "COMPILE_PROGRAM_FAILURE";
	ELSIF err = CL.LINKER_NOT_AVAILABLE THEN serr := "LINKER_NOT_AVAILABLE";
	ELSIF err = CL.LINK_PROGRAM_FAILURE THEN serr := "LINK_PROGRAM_FAILURE";
	ELSIF err = CL.DEVICE_PARTITION_FAILED THEN serr := "DEVICE_PARTITION_FAILED";
	ELSIF err = CL.KERNEL_ARG_INFO_NOT_AVAILABLE THEN serr := "KERNEL_ARG_INFO_NOT_AVAILABLE";

	ELSIF err = CL.INVALID_VALUE THEN serr := "INVALID_VALUE";
	ELSIF err = CL.INVALID_DEVICE_TYPE THEN serr := "INVALID_DEVICE_TYPE";
	ELSIF err = CL.INVALID_PLATFORM THEN serr :=  "INVALID_PLATFORM";
	ELSIF err = CL.INVALID_DEVICE THEN serr :=  "INVALID_DEVICE";
	ELSIF err = CL.INVALID_CONTEXT THEN serr :=  "INVALID_CONTEXT";
	ELSIF err = CL.INVALID_QUEUE_PROPERTIES THEN serr :=  "INVALID_QUEUE_PROPERTIES";
	ELSIF err = CL.INVALID_COMMAND_QUEUE THEN serr :=  "INVALID_COMMAND_QUEUE";
	ELSIF err = CL.INVALID_HOST_PTR THEN serr :=  "INVALID_HOST_PTR";
	ELSIF err =  CL.INVALID_MEM_OBJECT THEN serr :=  "INVALID_MEM_OBJECT";

	ELSIF err = CL.INVALID_IMAGE_FORMAT_DESCRIPTOR THEN serr :=  "INVALID_IMAGE_FORMAT_DESCRIPTOR";
	ELSIF err = CL.INVALID_IMAGE_SIZE THEN serr :=  "INVALID_IMAGE_SIZE";
	ELSIF err = CL.INVALID_SAMPLER THEN serr :=  "INVALID_SAMPLER";
	ELSIF err = CL.INVALID_BINARY THEN serr :=  "INVALID_BINARY";
	ELSIF err = CL.INVALID_BUILD_OPTIONS THEN serr :=  "INVALID_BUILD_OPTIONS";
	ELSIF err = CL.INVALID_PROGRAM THEN serr :=  "INVALID_PROGRAM";
	ELSIF err = CL.INVALID_PROGRAM_EXECUTABLE THEN serr :=  "INVALID_PROGRAM_EXECUTABLE";
	ELSIF err = CL.INVALID_KERNEL_NAME THEN serr :=  "INVALID_KERNEL_NAME";
	ELSIF err = CL.INVALID_KERNEL_DEFINITION THEN serr :=  "INVALID_KERNEL_DEFINITION";
	ELSIF err = CL.INVALID_KERNEL THEN serr :=  "INVALID_KERNEL";
	ELSIF err = CL.INVALID_ARG_INDEX THEN serr :=  "INVALID_ARG_INDEX";
	ELSIF err = CL.INVALID_ARG_VALUE THEN serr :=  "INVALID_ARG_VALUE";
	ELSIF err = CL.INVALID_ARG_SIZE THEN serr :=  "INVALID_ARG_SIZE";
	ELSIF err = CL.INVALID_KERNEL_ARGS THEN serr :=  "INVALID_KERNEL_ARGS";
	ELSIF err = CL.INVALID_WORK_DIMENSION THEN serr :=  "INVALID_WORK_DIMENSION";
	ELSIF err = CL.INVALID_WORK_GROUP_SIZE THEN serr :=  "INVALID_WORK_GROUP_SIZE";
	ELSIF err = CL.INVALID_WORK_ITEM_SIZE THEN serr :=  "INVALID_WORK_ITEM_SIZE";
	ELSIF err = CL.INVALID_GLOBAL_OFFSET THEN serr :=  "INVALID_GLOBAL_OFFSET";
	ELSIF err = CL.INVALID_EVENT_WAIT_LIST THEN serr :=  "INVALID_EVENT_WAIT_LIST";
	ELSIF err = CL.INVALID_EVENT THEN serr :=  "INVALID_EVENT";
	ELSIF err = CL.INVALID_OPERATION THEN serr :=  "INVALID_OPERATION";
	ELSIF err = CL.INVALID_GL_OBJECT THEN serr :=  "INVALID_GL_OBJECT";
	ELSIF err = CL.INVALID_BUFFER_SIZE THEN serr :=  "INVALID_BUFFER_SIZE";

	ELSIF err = CL.INVALID_MIP_LEVEL THEN serr :=  "INVALID_MIP_LEVEL";
	ELSIF err = CL.INVALID_GLOBAL_WORK_SIZE THEN serr :=  "INVALID_GLOBAL_WORK_SIZE";
	ELSIF err = CL.INVALID_PROPERTY THEN serr :=  "INVALID_PROPERTY";
	ELSIF err = CL.INVALID_IMAGE_DESCRIPTOR THEN serr :=  "INVALID_IMAGE_DESCRIPTOR";

	ELSIF err = CL.INVALID_COMPILER_OPTIONS THEN serr :=  "INVALID_COMPILER_OPTIONS";
	ELSIF err = CL.INVALID_LINKER_OPTIONS THEN serr :=  "INVALID_LINKER_OPTIONS";
	ELSIF err = CL.INVALID_DEVICE_PARTITION_COUNT THEN serr :=  "INVALID_DEVICE_PARTITION_COUNT";

	(*cl_ext.h additional errors *)
	ELSIF err = -1000 THEN serr := "CL_INVALID_GL_SHAREGROUP_REFERENCE_KHR"; (* defined in cl_gl.h *)
	ELSIF err = -1001 THEN  serr := "CL_PLATFORM_NOT_FOUND_KHR"; (* these are defined in cl_ext.h *)
	ELSIF err = -1057 THEN serr := "CL_DEVICE_PARTITION_FAILED_EXT";
	ELSIF err = -1058 THEN serr := "CL_INVALID_PARTITION_COUNT_EXT";
	ELSIF err = -1059 THEN serr := "CL_INVALID_PARTITION_NAME_EXT";
	ELSE
		Strings.IntToStr(err, serrno);
		serr := "Unknown CL Error: ";
		Strings.Append(serr, serrno);
	END;
	RETURN serr;
END GetError;

(** Helper function to get OpenCL image format string (channel order and type) from constant *)
PROCEDURE ImageFormatString* (imf: CL.cl_uint): String64;
VAR imgformat: String64;
BEGIN
	imgformat := "Unknown";

	(* cl_channel_order *)
	IF imf = CL.R THEN imgformat := "R";
	ELSIF imf = CL.A THEN imgformat := "A";
	ELSIF imf = CL.RG THEN imgformat := "RG";
	ELSIF imf = CL.RA THEN imgformat := "RA";
	ELSIF imf = CL.RGB THEN imgformat := "RGB";
	ELSIF imf = CL.RGBA THEN imgformat := "RGBA";
	ELSIF imf = CL.BGRA THEN imgformat := "BGRA";
	ELSIF imf = CL.ARGB THEN imgformat := "ARGB";
	ELSIF imf = CL.INTENSITY THEN imgformat := "INTENSITY";
	ELSIF imf = CL.LUMINANCE THEN imgformat := "LUMINANCE";
	ELSIF imf = CL.Rx THEN imgformat := "Rx";
	ELSIF imf = CL.RGx THEN imgformat := "RGx";
	ELSIF imf = CL.RGBx THEN imgformat := "RGBx";
	(* cl_channel_type *)
	ELSIF imf = CL.SNORM_INT8 THEN imgformat := "SNORM_INT8";
	ELSIF imf = CL.SNORM_INT16 THEN imgformat := "SNORM_INT16";
	ELSIF imf = CL.UNORM_INT8 THEN imgformat := "UNORM_INT8";
	ELSIF imf = CL.UNORM_INT16 THEN imgformat := "UNORM_INT16";
	ELSIF imf = CL.UNORM_SHORT_565 THEN imgformat := "UNORM_SHORT_565";
	ELSIF imf = CL.UNORM_SHORT_555 THEN imgformat := "UNORM_SHORT_555";
	ELSIF imf = CL.UNORM_INT_101010 THEN imgformat := "UNORM_INT_101010";
	ELSIF imf = CL.SIGNED_INT8 THEN imgformat := "SIGNED_INT8";
	ELSIF imf = CL.SIGNED_INT16 THEN imgformat := "SIGNED_INT16";
	ELSIF imf = CL.SIGNED_INT32 THEN imgformat := "SIGNED_INT32";
	ELSIF imf = CL.UNSIGNED_INT8 THEN imgformat := "UNSIGNED_INT8";
	ELSIF imf = CL.UNSIGNED_INT16 THEN imgformat := "UNSIGNED_INT16";
	ELSIF imf = CL.UNSIGNED_INT32 THEN imgformat := "UNSIGNED_INT32";
	ELSIF imf = CL.HALF_FLOAT THEN imgformat := "HALF_FLOAT";
	ELSIF imf = CL.FLOAT THEN imgformat := "FLOAT";
	END;
	
     RETURN imgformat;
END ImageFormatString;

BEGIN
	SearchPlatformsAndDevices();
END OpenCLUtils.

