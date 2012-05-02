MODULE OpenCLUtils; (** AUTHOR "fnecati"; PURPOSE "OpenCL1.2 utilities"; *)
IMPORT CL:=OpenCL, S:= SYSTEM, Files, Strings;


TYPE
	String64 =ARRAY 64 OF CHAR;
	PChar = CL.PChar;

(**
 Loads an ASCII Program file and prepends the header to the code.
	fname        program filename
	header        code that is prepended to the loaded file, typically a set of #defines or a header
*)

PROCEDURE LoadProgramSource*(fname: ARRAY OF CHAR; CONST header: ARRAY OF CHAR): PChar;
VAR
     f: Files.File;
      rider: Files.Rider;
      str: PChar;
      len: LONGINT;
BEGIN
	f := Files.Old(fname);
	IF f = NIL THEN RETURN NIL END;
	len := Strings.Length(header);

	NEW(str, f.Length()+1+len);
	Strings.Append(str^, header);
	Strings.AppendChar(str^,0AX);
	f.Set(rider, 0);

	f.ReadBytes(rider, str^, len, f.Length());

	 RETURN S.VAL(PChar, S.ADR(str[0]));

END LoadProgramSource;

(** Roundup division function for efficient workgrup size calculation *)
PROCEDURE RoundUp*(groupsize, globalsize: LONGINT): LONGINT; (* size_t *)
VAR r: LONGINT;
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

END OpenCLUtils.


