MODULE OpenCL; (** AUTHOR "fnecati"; PURPOSE "OpenCL 1.0, 1.1, 1.2, 2.0 binding library for LinuxAos"; *)
IMPORT Modules, HostLibs, KernelLog;

(* ******************************************************************************
 * Copyright (c) 2008 - 2013 The Khronos Group Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and/or associated documentation files (the
 * "Materials"), to deal in the Materials without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Materials, and to
 * permit persons to whom the Materials are furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Materials.
 *
 * THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * MATERIALS OR THE USE OR OTHER DEALINGS IN THE MATERIALS.
 ***************************************************************************** *)

CONST
	debug* = FALSE;	
	
 #IF UNIX THEN
	libname = "libOpenCL.so.1";	
 #ELSIF WIN THEN
 	libname = "OpenCL.dll";
 #ELSE
   UNIMPLEMENTED
 #END
 
(* Use OpenCL Version *)
(*	VERSION_1_0* = TRUE;
	VERSION_1_1* = TRUE;
	VERSION_1_2* = FALSE;
	VERSION_2_0* = FALSE;
*)
	
VAR
	 oclib- : HostLibs.LibHandle;  (* handle to library *)

TYPE
	size_t* = SIZE;
(*	Psize_t* = POINTER TO ARRAY OF size_t; *)

	intptr_t* = ADDRESS; (* size_t *)

    	(* scalar types  *)
	cl_char* = CHAR; (*-127..+128 *)
	cl_uchar* = UNSIGNED8;  (* 0..255 *)
	cl_short* = INTEGER; (* - 32767..+32768; *)
	cl_ushort* = UNSIGNED16; (*  0..+65535; *)
	cl_int* = LONGINT; (*-2147483647..+2147483648;  *)
	cl_uint* = UNSIGNED32;  (* 0..4294967295;  *)
	cl_long* = HUGEINT; (* Int64;// 0..184467440773709551615;//-$8000000000000001..+$8000000000000000{9223372036854775808}; //typedef signed   __int64  cl_long; *)
	cl_ulong* = HUGEINT; (* UNSIGNED64; *)

	cl_half* = INTEGER;
	cl_float* = REAL;
	cl_double* = LONGREAL;


(* Macro names and corresponding values defined by OpenCL *)
 (* cl_platform.h *)
 CONST
	CHAR_BIT* = 8;
	SCHAR_MAX* = 127;
	SCHAR_MIN* = (-127-1);
	CHAR_MAX* = SCHAR_MAX;
	CHAR_MIN* = SCHAR_MIN;
	UCHAR_MAX* = 255;
	SHRT_MAX* = 32767;
	SHRT_MIN* = (-32767-1);
	USHRT_MAX* =  65535;
	INT_MAX* = 2147483647;
	INT_MIN* = (-2147483647-1);
	UINT_MAX* = 0FFFFFFFFH;
	LONG_MAX* = 7FFFFFFFFFFFFFFFH;
	LONG_MIN* = -(7FFFFFFFFFFFFFFFH) - 1;
	ULONG_MAX* =  0FFFFFFFFFFFFFFFFH;

	FLT_DIG* =  6;
	FLT_MANT_DIG* =  24;
	FLT_MAX_10_EXP* =  +38;
	FLT_MAX_EXP* =  +128;
	FLT_MIN_10_EXP* =  -37;
	FLT_MIN_EXP* =  -125;
	FLT_RADIX* =  2;
(*	FLT_MAX* =  FLT_MAX;
	FLT_MIN* =  FLT_MIN;
	FLT_EPSILON* =  FLT_EPSILON;
*)
	DBL_DIG* =  15;
	DBL_MANT_DIG* =  53;
	DBL_MAX_10_EXP* =  +308;
	DBL_MAX_EXP* =  +1024;
	DBL_MIN_10_EXP* =  -307;
	DBL_MIN_EXP* =  -1021;
	DBL_RADIX* =  2;
(*	DBL_MAX* =  DBL_MAX;
	DBL_MIN* =  DBL_MIN;
	DBL_EPSILON* =  DBL_EPSILON;
*)

	M_E* = 2.718281828459045090796;
	M_LOG2E* = 1.442695040888963387005;
	M_LOG10E* = 0.434294481903251816668;
	M_LN2* = 0.693147180559945286227;
	M_LN10* = 2.302585092994045901094;
	M_PI* = 3.141592653589793115998;
	M_PI_2* = 1.570796326794896557999;
	M_PI_4* = 0.785398163397448278999;
	M_1_PI* = 0.318309886183790691216;
	M_2_PI* = 0.636619772367581382433;
	M_2_SQRTPI* = 1.128379167095512558561;
	M_SQRT2* = 1.414213562373095145475;
	M_SQRT1_2* = 0.707106781186547572737;

	M_E_F* = 2.71828174591064;
	M_LOG2E_F* = 1.44269502162933;
	M_LOG10E_F* = 0.43429449200630;
	M_LN2_F* = 0.69314718246460;
	M_LN10_F* = 2.30258512496948;
	M_PI_F* = 3.14159274101257;
	M_PI_2_F* = 1.57079637050629;
	M_PI_4_F* = 0.78539818525314;
	M_1_PI_F* = 0.31830987334251;
	M_2_PI_F* = 0.63661974668503;
	M_2_SQRTPI_F* = 1.12837922573090;
	M_SQRT2_F* = 1.41421353816986;
	M_SQRT1_2_F* = 0.70710676908493;

TYPE
	(* Mirror types to GL types. Mirror types allow us to avoid deciding which headers to load based on whether we are using GL or GLES here. *)
	cl_GLuint* = cl_uint;
	cl_GLint* = LONGINT;;
	cl_GLenum* = cl_uint;


(*
 * Vector types
 *
 *  Note:   OpenCL requires that all types be naturally aligned.
 *          This means that vector types must be naturally aligned.
 *          For example, a vector of four floats must be aligned to
 *          a 16 byte boundary (calculated as 4 * the natural 4-byte
 *          alignment of the float).  The alignment qualifiers here
 *          will only function properly if your compiler supports them
 *          and if you don't actively work to defeat them.  For example,
 *          in order for a cl_float4 to be 16 byte aligned in a struct,
 *          the start of the struct must itself be 16-byte aligned.
 *
 *          Maintaining proper alignment is the user's responsibility.
 *)

(* **************************************************************************** *)


TYPE
	cl_platform_id* = ADDRESS;
	cl_device_id* =  ADDRESS;
	cl_context* = ADDRESS;
	cl_command_queue*  =  ADDRESS;
	cl_mem* = ADDRESS;
	cl_program* = ADDRESS;
	cl_kernel* = ADDRESS;
	cl_event* = ADDRESS;
	cl_sampler* = ADDRESS;

	cl_bool* = cl_uint; (*  WARNING!  Unlike cl_ types in cl_platform.h, cl_bool is not guaranteed to be the same size as the bool in kernels. *)
	cl_bitfield* = cl_ulong;
	cl_device_type* = cl_bitfield;
	cl_platform_info* = cl_uint;
	cl_device_info* = cl_uint;
	cl_device_fp_config* = cl_bitfield;
	cl_device_mem_cache_type* = cl_uint;
	cl_device_local_mem_type* = cl_uint;
	cl_device_exec_capabilities* = cl_bitfield;
	cl_device_svm_capabilities* = cl_bitfield;
	cl_command_queue_properties* = cl_bitfield;
	cl_device_partition_property* = intptr_t;
	cl_device_affinity_domain* = cl_bitfield;

	cl_context_properties* = intptr_t;
	cl_context_info* = cl_uint;
	cl_queue_properties* = cl_bitfield;
	cl_command_queue_info* = cl_uint;
	cl_channel_order* = cl_uint;
	cl_channel_type* = cl_uint;
	cl_mem_flags* = cl_bitfield;
	cl_svm_mem_flags* = cl_bitfield;
	cl_mem_object_type* = cl_uint;
	cl_mem_info* = cl_uint;
	cl_mem_migration_flags* = cl_bitfield;
	cl_image_info* = cl_uint;
	cl_buffer_create_type* = cl_uint;
	cl_addressing_mode* = cl_uint;
	cl_filter_mode* = cl_uint;
	cl_sampler_info* = cl_uint;
	cl_map_flags* = cl_bitfield;
	cl_pipe_properties* = intptr_t;
	cl_pipe_info* = cl_uint;
	cl_program_info* = cl_uint;
	cl_program_build_info* = cl_uint;
	cl_program_binary_type* = cl_uint;
	cl_build_status* = cl_int;
	cl_kernel_info* = cl_uint;
	cl_kernel_arg_info* = cl_uint;
	cl_kernel_arg_address_qualifier* = cl_uint;
	cl_kernel_arg_access_qualifier* = cl_uint;
	cl_kernel_arg_type_qualifier* = cl_bitfield;
	cl_kernel_work_group_info* = cl_uint;
	cl_event_info* = cl_uint;
	cl_command_type* = cl_uint;
	cl_profiling_info* = cl_uint;
	cl_sampler_properties* = cl_bitfield;
	cl_kernel_exec_info*=  cl_uint;

	cl_image_format* =  RECORD
		image_channel_order* : cl_channel_order;
		image_channel_data_type* : cl_channel_type;
	END ;

	cl_image_desc* = RECORD
		image_type* :cl_mem_object_type;
		image_width*: size_t;
		image_height*: size_t;
		image_depth*: size_t;
		image_array_size*: size_t;
		image_row_pitch*: size_t;
		image_slice_pitch*: size_t;
		num_mip_levels*: cl_uint;
		num_samples*: cl_uint;
		buffer*: cl_mem; (* buffer or mem_object *)
	END;

	cl_buffer_region* = RECORD
		origin*: size_t;
		size*: size_t;
	END;


CONST
	(* Error Codes *)
	SUCCESS* =  0;
	DEVICE_NOT_FOUND* = -1;
	DEVICE_NOT_AVAILABLE* = -2;
	COMPILER_NOT_AVAILABLE*	= -3;
	MEM_OBJECT_ALLOCATION_FAILURE*	= -4;
	OUT_OF_RESOURCES* = -5;
	OUT_OF_HOST_MEMORY* = -6;
	PROFILING_INFO_NOT_AVAILABLE* = -7;
	MEM_COPY_OVERLAP* = -8;
	IMAGE_FORMAT_MISMATCH* = -9;
	IMAGE_FORMAT_NOT_SUPPORTED* = -10;
	BUILD_PROGRAM_FAILURE* = -11;
	MAP_FAILURE* = -12;
	MISALIGNED_SUB_BUFFER_OFFSET* = -13;
	EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST* =  -14;
	COMPILE_PROGRAM_FAILURE* = -15;
	LINKER_NOT_AVAILABLE* = -16;
	LINK_PROGRAM_FAILURE* = -17;
	DEVICE_PARTITION_FAILED* = -18;
	KERNEL_ARG_INFO_NOT_AVAILABLE* = -19;

	INVALID_VALUE* = -30;
	INVALID_DEVICE_TYPE* = -31;
	INVALID_PLATFORM* = -32;
	INVALID_DEVICE* = -33;
	INVALID_CONTEXT* = -34;
	INVALID_QUEUE_PROPERTIES* = -35;
	INVALID_COMMAND_QUEUE* = -36;
	INVALID_HOST_PTR* = -37;
	INVALID_MEM_OBJECT* = -38;
	INVALID_IMAGE_FORMAT_DESCRIPTOR* = -39;
	INVALID_IMAGE_SIZE* = -40;
	INVALID_SAMPLER* = -41;
	INVALID_BINARY* = -42;
	INVALID_BUILD_OPTIONS* = -43;
	INVALID_PROGRAM* = -44;
	INVALID_PROGRAM_EXECUTABLE* = -45;
	INVALID_KERNEL_NAME* = -46;
	INVALID_KERNEL_DEFINITION* = -47;
	INVALID_KERNEL* = -48;
	INVALID_ARG_INDEX* = -49;
	INVALID_ARG_VALUE* = -50;
	INVALID_ARG_SIZE* = -51;
	INVALID_KERNEL_ARGS* = -52;
	INVALID_WORK_DIMENSION* = -53;
	INVALID_WORK_GROUP_SIZE* = -54;
	INVALID_WORK_ITEM_SIZE* = -55;
	INVALID_GLOBAL_OFFSET* = -56;
	INVALID_EVENT_WAIT_LIST* = -57;
	INVALID_EVENT* = -58;
	INVALID_OPERATION* = -59;
	INVALID_GL_OBJECT* = -60;
	INVALID_BUFFER_SIZE* = -61;
	INVALID_MIP_LEVEL* = -62;
	INVALID_GLOBAL_WORK_SIZE*       = -63;
	INVALID_PROPERTY* = -64;
	INVALID_IMAGE_DESCRIPTOR* = -65;
	INVALID_COMPILER_OPTIONS* = -66;
	INVALID_LINKER_OPTIONS* = -67;
	INVALID_DEVICE_PARTITION_COUNT* = -68;
	INVALID_PIPE_SIZE* = -69;
	INVALID_DEVICE_QUEUE* = -70;

	(* cl_bool *)
	CL_FALSE* = 0;
	CL_TRUE* = 1;
	CL_BLOCKING* = CL_TRUE;
	CL_NON_BLOCKING* = CL_FALSE;

	(* cl_platform_info*)
	PLATFORM_PROFILE* = 0900H;
	PLATFORM_VERSION* = 0901H;
	PLATFORM_NAME* = 0902H;
	PLATFORM_VENDOR* = 0903H;
	PLATFORM_EXTENSIONS*  = 0904H;
	
CONST
	(* cl_device_type - bitfield*)
	DEVICE_TYPE_DEFAULT* = 1;
	DEVICE_TYPE_CPU* = 2;
	DEVICE_TYPE_GPU* =  4;
	DEVICE_TYPE_ACCELERATOR* = 8;
	DEVICE_TYPE_CUSTOM* = 16;
	DEVICE_TYPE_ALL* = 0FFFFFFFFH;

	(* cl_device_info *)
	DEVICE_TYPE* = 1000H;
	DEVICE_VENDOR_ID* = 1001H;
	DEVICE_MAX_COMPUTE_UNITS* = 1002H;
	DEVICE_MAX_WORK_ITEM_DIMENSIONS* = 1003H;
	DEVICE_MAX_WORK_GROUP_SIZE* = 1004H;
	DEVICE_MAX_WORK_ITEM_SIZES* = 1005H;
	DEVICE_PREFERRED_VECTOR_WIDTH_CHAR* = 1006H;
	DEVICE_PREFERRED_VECTOR_WIDTH_SHORT* = 1007H;
	DEVICE_PREFERRED_VECTOR_WIDTH_INT* = 1008H;
	DEVICE_PREFERRED_VECTOR_WIDTH_LONG* = 1009H;
	DEVICE_PREFERRED_VECTOR_WIDTH_FLOAT* = 100AH;
	DEVICE_PREFERRED_VECTOR_WIDTH_DOUBLE* = 100BH;
	DEVICE_MAX_CLOCK_FREQUENCY* = 100CH;
	DEVICE_ADDRESS_BITS* = 100DH;
	DEVICE_MAX_READ_IMAGE_ARGS* = 100EH;
	DEVICE_MAX_WRITE_IMAGE_ARGS* = 100FH;
	DEVICE_MAX_MEM_ALLOC_SIZE* = 1010H;
	DEVICE_IMAGE2D_MAX_WIDTH* = 1011H;
	DEVICE_IMAGE2D_MAX_HEIGHT* = 1012H;
	DEVICE_IMAGE3D_MAX_WIDTH* = 1013H;
	DEVICE_IMAGE3D_MAX_HEIGHT* = 1014H;
	DEVICE_IMAGE3D_MAX_DEPTH* = 1015H;
	DEVICE_IMAGE_SUPPORT* = 1016H;
	DEVICE_MAX_PARAMETER_SIZE* = 1017H;
	DEVICE_MAX_SAMPLERS* = 1018H;
	DEVICE_MEM_BASE_ADDR_ALIGN* = 1019H;
	DEVICE_MIN_DATA_TYPE_ALIGN_SIZE* = 101AH;
	DEVICE_SINGLE_FP_CONFIG* = 101BH;
	DEVICE_GLOBAL_MEM_CACHE_TYPE* = 101CH;
	DEVICE_GLOBAL_MEM_CACHELINE_SIZE* = 101DH;
	DEVICE_GLOBAL_MEM_CACHE_SIZE* = 101EH;
	DEVICE_GLOBAL_MEM_SIZE* = 101FH;
	DEVICE_MAX_CONSTANT_BUFFER_SIZE* = 1020H;
	DEVICE_MAX_CONSTANT_ARGS* = 1021H;
	DEVICE_LOCAL_MEM_TYPE* = 1022H;
	DEVICE_LOCAL_MEM_SIZE* = 1023H;
	DEVICE_ERROR_CORRECTION_SUPPORT* = 1024H;
	DEVICE_PROFILING_TIMER_RESOLUTION* = 1025H;
	DEVICE_ENDIAN_LITTLE* = 1026H;
	DEVICE_AVAILABLE* = 1027H;
	DEVICE_COMPILER_AVAILABLE* = 1028H;
	DEVICE_EXECUTION_CAPABILITIES* = 1029H;
	DEVICE_QUEUE_PROPERTIES* = 102AH; (* deprecated *)
	DEVICE_QUEUE_ON_HOST_PROPERTIES* = 102AH;
	DEVICE_NAME* = 102BH;
	DEVICE_VENDOR* = 102CH;
	DRIVER_VERSION* = 102DH;
	DEVICE_PROFILE* = 102EH;
	DEVICE_VERSION* = 102FH;
	DEVICE_EXTENSIONS* = 1030H;
	DEVICE_PLATFORM* = 1031H;

	DEVICE_DOUBLE_FP_CONFIG* =  1032H;
	(* 1033H reserved for DEVICE_HALF_FP_CONFIG *)
	DEVICE_PREFERRED_VECTOR_WIDTH_HALF* =  1034H;
	DEVICE_HOST_UNIFIED_MEMORY* =  1035H;  (* deprecated *)
	DEVICE_NATIVE_VECTOR_WIDTH_CHAR* =  1036H;
	DEVICE_NATIVE_VECTOR_WIDTH_SHORT* =  1037H;
	DEVICE_NATIVE_VECTOR_WIDTH_INT* =  1038H;
	DEVICE_NATIVE_VECTOR_WIDTH_LONG* =  1039H;
	DEVICE_NATIVE_VECTOR_WIDTH_FLOAT* =  103AH;
	DEVICE_NATIVE_VECTOR_WIDTH_DOUBLE* =  103BH;
	DEVICE_NATIVE_VECTOR_WIDTH_HALF* =  103CH;
	DEVICE_OPENCL_C_VERSION* =  103DH;
	DEVICE_LINKER_AVAILABLE* =  103EH;
	DEVICE_BUILT_IN_KERNELS* =  103FH;
	DEVICE_IMAGE_MAX_BUFFER_SIZE* =  1040H;
	DEVICE_IMAGE_MAX_ARRAY_SIZE* =  1041H;
	DEVICE_PARENT_DEVICE* =  1042H;
	DEVICE_PARTITION_MAX_SUB_DEVICES* =  1043H;
	DEVICE_PARTITION_PROPERTIES* =  1044H;
	DEVICE_PARTITION_AFFINITY_DOMAIN* =  1045H;
	DEVICE_PARTITION_TYPE* =  1046H;
	DEVICE_REFERENCE_COUNT* =  1047H;
	DEVICE_PREFERRED_INTEROP_USER_SYNC* =  1048H;
	DEVICE_PRINTF_BUFFER_SIZE* =  1049H;

	DEVICE_IMAGE_PITCH_ALIGNMENT* = 104AH;
	DEVICE_IMAGE_BASE_ADDRESS_ALIGNMENT* = 104BH;
	DEVICE_MAX_READ_WRITE_IMAGE_ARGS* = 104CH;
	DEVICE_MAX_GLOBAL_VARIABLE_SIZE* = 104DH;
	DEVICE_QUEUE_ON_DEVICE_PROPERTIES* = 104EH;
	DEVICE_QUEUE_ON_DEVICE_PREFERRED_SIZE* = 104FH;
	DEVICE_QUEUE_ON_DEVICE_MAX_SIZE* = 1050H;
	DEVICE_MAX_ON_DEVICE_QUEUES* = 1051H;
	DEVICE_MAX_ON_DEVICE_EVENTS* = 1052H;
	DEVICE_SVM_CAPABILITIES* = 1053H;
	DEVICE_GLOBAL_VARIABLE_PREFERRED_TOTAL_SIZE* = 1054H;
	DEVICE_MAX_PIPE_ARGS* = 1055H;
	DEVICE_PIPE_MAX_ACTIVE_RESERVATIONS* = 1056H;
	DEVICE_PIPE_MAX_PACKET_SIZE* = 1057H;
	DEVICE_PREFERRED_PLATFORM_ATOMIC_ALIGNMENT* = 1058H;
	DEVICE_PREFERRED_GLOBAL_ATOMIC_ALIGNMENT* = 1059H;
	DEVICE_PREFERRED_LOCAL_ATOMIC_ALIGNMENT* = 105AH;

	(* cl_device_fp_config - bitfield *)
	FP_DENORM* = 1;
	FP_INF_NAN* = 2;
	FP_ROUND_TO_NEAREST* = 4;
	FP_ROUND_TO_ZERO* = 8;
	FP_ROUND_TO_INF* = 16;
	FP_FMA* = 32;
	FP_SOFT_FLOAT* = 64;
	FP_CORRECTLY_ROUNDED_DIVIDE_SQRT* = 128;

	(* cl_device_mem_cache_type *)
	NONE* = 0H;
	READ_ONLY_CACHE * = 1H;
	READ_WRITE_CACHE* = 2H;

	(* cl_device_local_mem_type *)
	LOCAL* = 1H;
	GLOBAL* = 2H;

	(* cl_device_exec_capabilities - bitfield *)
	EXEC_KERNEL* = 1;
	EXEC_NATIVE_KERNEL* = 2;

	(* cl_command_queue_properties - bitfield*)
	QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE* = 1;
	QUEUE_PROFILING_ENABLE* = 2;
	QUEUE_ON_DEVICE* = 4;
	QUEUE_ON_DEVICE_DEFAULT* = 8;

	(* cl_context_info *)
	CONTEXT_REFERENCE_COUNT* = 1080H;
	CONTEXT_DEVICES* = 1081H;
	CONTEXT_PROPERTIES* = 1082H;
	CONTEXT_NUM_DEVICES*	= 1083H;

	(* cl_context_properties *)
	CONTEXT_PLATFORM* = 1084H;
	CONTEXT_INTEROP_USER_SYNC* = 1085H;

	(* cl_device_partition_property *)
	DEVICE_PARTITION_EQUALLY* = 1086H;
	DEVICE_PARTITION_BY_COUNTS*= 1087H;
	DEVICE_PARTITION_BY_COUNTS_LIST_END*= 0H;
	DEVICE_PARTITION_BY_AFFINITY_DOMAIN* =1088H;

	(* cl_device_affinity_domain *)
	DEVICE_AFFINITY_DOMAIN_NUMA* = 1;
	DEVICE_AFFINITY_DOMAIN_L4_CACHE* = 2;
	DEVICE_AFFINITY_DOMAIN_L3_CACHE* = 4;
	DEVICE_AFFINITY_DOMAIN_L2_CACHE* = 8;
	DEVICE_AFFINITY_DOMAIN_L1_CACHE* = 16;
	DEVICE_AFFINITY_DOMAIN_NEXT_PARTITIONABLE* = 32;

	(* cl_device_svm_capabilities *)
	DEVICE_SVM_COARSE_GRAIN_BUFFER* = 1;
	DEVICE_SVM_FINE_GRAIN_BUFFER* = 2;
	DEVICE_SVM_FINE_GRAIN_SYSTEM* = 4;
	DEVICE_SVM_ATOMICS* = 8;

	(* cl_command_queue_info *)
	QUEUE_CONTEXT* = 1090H;
	QUEUE_DEVICE* = 1091H;
	QUEUE_REFERENCE_COUNT* = 1092H;
	QUEUE_PROPERTIES* = 1093H;
	QUEUE_SIZE* = 1094H;

	(* cl_mem_flags and cl_svm_mem_flags - bitfield *)
	MEM_READ_WRITE* = 1;
	MEM_WRITE_ONLY* = 2;
	MEM_READ_ONLY* = 4;
	MEM_USE_HOST_PTR* = 8;
	MEM_ALLOC_HOST_PTR* = 16;
	MEM_COPY_HOST_PTR* = 32;
	(*  reserved                     64; *)
	MEM_HOST_WRITE_ONLY* = 128;
	MEM_HOST_READ_ONLY* = 256;
	MEM_HOST_NO_ACCESS* = 512;
	MEM_SVM_FINE_GRAIN_BUFFER* = 1024; (* used by cl_svm_mem_flags only *)
	MEM_SVM_ATOMICS* = 2048; (* used by cl_svm_mem_flags only *)


	(* cl_mem_migration_flags - bitfield *)
	MIGRATE_MEM_OBJECT_HOST* = 1;
	MIGRATE_MEM_OBJECT_CONTENT_UNDEFINED* = 2;


	(* cl_channel_order *)
	R* = 10B0H;
	A* = 10B1H;
	RG* = 10B2H;
	RA* = 10B3H;
	RGB* = 10B4H;
	RGBA* = 10B5H;
	BGRA* = 10B6H;
	ARGB* = 10B7H;
	INTENSITY* = 10B8H;
	LUMINANCE* = 10B9H;
	Rx* = 10BAH;
	RGx* = 10BBH;
	RGBx* = 10BCH;
	DEPTH* = 10BDH;
	DEPTH_STENCIL* = 10BEH;
	sRGB* = 10BFH;
	sRGBx* = 10C0H;
	sRGBA* = 10C1H;
	sBGRA* = 10C2H;
	ABGR* = 10C3H;

	(* cl_channel_type *)
	SNORM_INT8* = 10D0H;
	SNORM_INT16* = 10D1H;
	UNORM_INT8* = 10D2H;
	UNORM_INT16* = 10D3H;
	UNORM_SHORT_565* = 10D4H;
	UNORM_SHORT_555* = 10D5H;
	UNORM_INT_101010* = 10D6H;
	SIGNED_INT8* = 10D7H;
	SIGNED_INT16* = 10D8H;
	SIGNED_INT32* = 10D9H;
	UNSIGNED_INT8* = 10DAH;
	UNSIGNED_INT16* = 10DBH;
	UNSIGNED_INT32* = 10DCH;
	HALF_FLOAT* = 10DDH;
	FLOAT* = 10DEH;
	UNORM_INT24* = 10DFH;

	(* cl_mem_object_type *)
	MEM_OBJECT_BUFFER* = 10F0H;
	MEM_OBJECT_IMAGE2D* = 10F1H;
	MEM_OBJECT_IMAGE3D* = 10F2H;
	MEM_OBJECT_IMAGE2D_ARRAY* = 10F3H;
	MEM_OBJECT_IMAGE1D* = 10F4H;
	MEM_OBJECT_IMAGE1D_ARRAY* = 10F5H;
	MEM_OBJECT_IMAGE1D_BUFFER* = 10F6H;
	MEM_OBJECT_PIPE* = 10F7H;

	(* cl_mem_info *)
	MEM_TYPE* = 1100H;
	MEM_FLAGS* = 1101H;
	MEM_SIZE* = 1102H;
	MEM_HOST_PTR* = 1103H;
	MEM_MAP_COUNT* = 1104H;
	MEM_REFERENCE_COUNT* = 1105H;
	MEM_CONTEXT* = 1106H;
	MEM_ASSOCIATED_MEMOBJECT* = 1107H;
	MEM_OFFSET* = 1108H;
	MEM_USES_SVM_POINTER* = 1109H;

	(* cl_image_info*)
	IMAGE_FORMAT* = 1110H;
	IMAGE_ELEMENT_SIZE* = 1111H;
	IMAGE_ROW_PITCH* = 1112H;
	IMAGE_SLICE_PITCH* = 1113H;
	IMAGE_WIDTH* = 1114H;
	IMAGE_HEIGHT* = 1115H;
	IMAGE_DEPTH* = 1116H;
	IMAGE_ARRAY_SIZE* = 1117H;
	IMAGE_BUFFER* = 1118H;
	IMAGE_NUM_MIP_LEVELS* = 1119H;
	IMAGE_NUM_SAMPLES* = 111AH;

	(* cl_pipe_info *)
	PIPE_PACKET_SIZE* = 1120H;
	PIPE_MAX_PACKETS* = 1121H;

	(* cl_addressing_mode *)
	ADDRESS_NONE* = 1130H;
	ADDRESS_CLAMP_TO_EDGE* = 1131H;
	ADDRESS_CLAMP* = 1132H;
	ADDRESS_REPEAT* = 1133H;
	ADDRESS_MIRRORED_REPEAT* = 1134H;

	(* cl_filter_mode *)
	FILTER_NEAREST* = 1140H;
	FILTER_LINEAR* = 1141H;

	(* cl_sampler_info *)
	SAMPLER_REFERENCE_COUNT* = 1150H;
	SAMPLER_CONTEXT* = 1151H;
	SAMPLER_NORMALIZED_COORDS* = 1152H;
	SAMPLER_ADDRESSING_MODE* = 1153H;
	SAMPLER_FILTER_MODE* = 1154H;
	SAMPLER_MIP_FILTER_MODE* = 1155H;
	SAMPLER_LOD_MIN* = 1156H;
	SAMPLER_LOD_MAX* = 1157H;

	(* cl_map_flags - bitfield *)
	MAP_READ* = 1;
	MAP_WRITE* = 2;
	MAP_WRITE_INVALIDATE_REGION* = 4;

	(* cl_program_info *)
	PROGRAM_REFERENCE_COUNT* = 1160H;
	PROGRAM_CONTEXT* = 1161H;
	PROGRAM_NUM_DEVICES* = 1162H;
	PROGRAM_DEVICES* = 1163H;
	PROGRAM_SOURCE* = 1164H;
	PROGRAM_BINARY_SIZES* = 1165H;
	PROGRAM_BINARIES* = 1166H;
	PROGRAM_NUM_KERNELS* = 1167H;
	PROGRAM_KERNEL_NAMES* = 1168H;

	(* cl_program_build_info*)
	PROGRAM_BUILD_STATUS* = 1181H;
	PROGRAM_BUILD_OPTIONS* = 1182H;
	PROGRAM_BUILD_LOG* = 1183H;
	PROGRAM_BINARY_TYPE* = 1184H;
	PROGRAM_BUILD_GLOBAL_VARIABLE_TOTAL_SIZE* = 1185H;

	(* cl_program_binary_type *)
	PROGRAM_BINARY_TYPE_NONE* = 0H;
	PROGRAM_BINARY_TYPE_COMPILED_OBJECT* = 1H;
	PROGRAM_BINARY_TYPE_LIBRARY* = 2H;
	PROGRAM_BINARY_TYPE_EXECUTABLE* = 4H;

	(* cl_build_status *)
	BUILD_SUCCESS* = 0;
	BUILD_NONE* = -1;
	BUILD_ERROR* = -2;
	BUILD_IN_PROGRESS* = -3;

	(* cl_kernel_info *)
	KERNEL_FUNCTION_NAME* = 1190H;
	KERNEL_NUM_ARGS* = 1191H;
	KERNEL_REFERENCE_COUNT* = 1192H;
	KERNEL_CONTEXT* = 1193H;
	KERNEL_PROGRAM* = 1194H;
	KERNEL_ATTRIBUTES*  = 1195H;

	(* cl_kernel_arg_info *)
	KERNEL_ARG_ADDRESS_QUALIFIER* = 1196H;
	KERNEL_ARG_ACCESS_QUALIFIER* = 1197H;
	KERNEL_ARG_TYPE_NAME* = 1198H;
	KERNEL_ARG_TYPE_QUALIFIER* = 1199H;
	KERNEL_ARG_NAME* = 119AH;

	(* cl_kernel_arg_address_qualifier *)
	KERNEL_ARG_ADDRESS_GLOBAL* = 119BH;
	KERNEL_ARG_ADDRESS_LOCAL* = 119CH;
	KERNEL_ARG_ADDRESS_CONSTANT* = 119DH;
	KERNEL_ARG_ADDRESS_PRIVATE* = 119EH;

	(* cl_kernel_arg_access_qualifier *)
	KERNEL_ARG_ACCESS_READ_ONLY* = 11A0H;
	KERNEL_ARG_ACCESS_WRITE_ONLY* = 11A1H;
	KERNEL_ARG_ACCESS_READ_WRITE* = 11A2H;
	KERNEL_ARG_ACCESS_NONE* = 11A3H;

	(* cl_kernel_arg_type_qualifer *)
	KERNEL_ARG_TYPE_NONE* =  0;
	KERNEL_ARG_TYPE_CONST* = 1;
	KERNEL_ARG_TYPE_RESTRICT* = 2;
	KERNEL_ARG_TYPE_VOLATILE* = 4;
	KERNEL_ARG_TYPE_PIPE* = 8;

	(* cl_kernel_work_group_info *)
	KERNEL_WORK_GROUP_SIZE* = 11B0H;
	KERNEL_COMPILE_WORK_GROUP_SIZE* = 11B1H;
	KERNEL_LOCAL_MEM_SIZE* = 11B2H;
	KERNEL_PREFERRED_WORK_GROUP_SIZE_MULTIPLE* = 11B3H;
	KERNEL_PRIVATE_MEM_SIZE* = 11B4H;
	KERNEL_GLOBAL_WORK_SIZE* = 11B5H;

	(* cl_kernel_exec_info *)
	KERNEL_EXEC_INFO_SVM_PTRS* = 11B6H;
	KERNEL_EXEC_INFO_SVM_FINE_GRAIN_SYSTEM* = 11B7H;

	(* cl_event_info *)
	EVENT_COMMAND_QUEUE* = 11D0H;
	EVENT_COMMAND_TYPE* = 11D1H;
	EVENT_REFERENCE_COUNT* = 11D2H;
	EVENT_COMMAND_EXECUTION_STATUS* = 11D3H;
	EVENT_CONTEXT* = 11DH;

	(* cl_command_type *)
	COMMAND_NDRANGE_KERNEL* = 11F0H;
	COMMAND_TASK* = 11F1H;
	COMMAND_NATIVE_KERNEL* = 11F2H;
	COMMAND_READ_BUFFER* = 11F3H;
	COMMAND_WRITE_BUFFER* = 11F4H;
	COMMAND_COPY_BUFFER* = 11F5H;
	COMMAND_READ_IMAGE* = 11F6H;
	COMMAND_WRITE_IMAGE* = 11F7H;
	COMMAND_COPY_IMAGE* = 11F8H;
	COMMAND_COPY_IMAGE_TO_BUFFER* = 11F9H;
	COMMAND_COPY_BUFFER_TO_IMAGE* = 11FAH;
	COMMAND_MAP_BUFFER* = 11FBH;
	COMMAND_MAP_IMAGE* = 11FCH;
	COMMAND_UNMAP_MEM_OBJECT* = 11FDH;
	COMMAND_MARKER* = 11FEH;
   	COMMAND_ACQUIRE_GL_OBJECTS* = 11FFH;
	COMMAND_RELEASE_GL_OBJECTS* = 1200H;
	COMMAND_READ_BUFFER_RECT* = 1201H;
	COMMAND_WRITE_BUFFER_RECT* = 1202H;
	COMMAND_COPY_BUFFER_RECT* = 1203H;
	COMMAND_USER* = 1204H;
	COMMAND_BARRIER* = 1205H;
	COMMAND_MIGRATE_MEM_OBJECTS* = 1206H;
	COMMAND_FILL_BUFFER* = 1207H;
	COMMAND_FILL_IMAGE* = 1208H;
	COMMAND_SVM_FREE* = 1209H;
	COMMAND_SVM_MEMCPY* = 120AH;
	COMMAND_SVM_MEMFILL* = 120BH;
	COMMAND_SVM_MAP* = 120CH;
	COMMAND_SVM_UNMAP* = 120DH;

	(* command execution status *)
	COMPLETE* = 0H;
	RUNNING* = 1H;
	SUBMITTED* = 2H;
	QUEUED* = 3H;

	(* cl_buffer_create_type  *)
	BUFFER_CREATE_TYPE_REGION* = 1220H;

	(* cl_profiling_info *)
	PROFILING_COMMAND_QUEUED* = 1280H;
	PROFILING_COMMAND_SUBMIT* = 1281H;
	PROFILING_COMMAND_START* = 1282H;
	PROFILING_COMMAND_END* = 1283H;
	PROFILING_COMMAND_COMPLETE* = 1284H;

(* ***********************
* cl_khr_icd extension *
*********************** *)
CONST

	(* cl_platform_info    *)
	PLATFORM_ICD_SUFFIX_KHR* =       0920H;

	(* Additional Error Codes  *)
	PLATFORM_NOT_FOUND_KHR* =  -1001;

TYPE TIcdGetPlatformIDsKHRfn* =  PROCEDURE {PlatformCC} (num_entries: cl_uint; platforms: cl_platform_id; VAR num_platforms: cl_uint): cl_int;

VAR IcdGetPlatformIDsKHR-: PROCEDURE {PlatformCC}(num_entries: cl_uint;  platforms:  cl_platform_id;  VAR num_platforms: cl_uint): cl_int;

CONST
	(* cl_nv_device_attribute_query extension - no extension #define since it has no functions *)
	DEVICE_COMPUTE_CAPABILITY_MAJOR_NV* =  4000H;
	DEVICE_COMPUTE_CAPABILITY_MINOR_NV* = 4001H;
	DEVICE_REGISTERS_PER_BLOCK_NV* = 4002H;
	DEVICE_WARP_SIZE_NV* = 4003H;
	DEVICE_GPU_OVERLAP_NV* = 4004H;
	DEVICE_KERNEL_EXEC_TIMEOUT_NV* = 4005H;
	DEVICE_INTEGRATED_MEMORY_NV* =4006H;

	(*********************************
	* cl_amd_device_attribute_query *
	*********************************)
	DEVICE_PROFILING_TIMER_OFFSET_AMD* = 4036H;

(* ************************************************************************** *)

(* ************************************************************************** *)


TYPE

	(*! Platform APIs *)
	(* VERSION_1_0 *)
	TGetPlatformIDs* = PROCEDURE {PlatformCC} (  num_entries   : cl_uint;     platforms     : ADDRESS;   num_platforms : ADDRESS): cl_int;
	TGetPlatformInfo* =  PROCEDURE {PlatformCC} ( iplatform : cl_platform_id;  param_name : cl_platform_info;  value_size : size_t;  value  : ADDRESS;  size_ret : ADDRESS (* size_t *)  ): cl_int;

	(*!  Device APIs *)
	TGetDeviceIDs* = PROCEDURE {PlatformCC} ( iplatform :  cl_platform_id ; device_type: cl_device_type; num_entries: cl_uint; devices : ADDRESS;    num_devices :  ADDRESS): cl_int;
	TGetDeviceInfo* = PROCEDURE {PlatformCC} (device: cl_device_id; param_name: cl_device_info; value_size: size_t; param_value: ADDRESS; size_ret : ADDRESS (* size_t *)): cl_int;


	(* VERSION_1_2 *)
	TCreateSubDevices* = PROCEDURE {PlatformCC} (in_device: cl_device_id; properties: cl_device_partition_property;
			num_devices: cl_uint;
			out_devices: ADDRESS (* cl_device_id*);
			VAR num_devices_ret: cl_uint ): cl_int;

	TRetainDevice* = PROCEDURE {PlatformCC} (device: cl_device_id) : cl_int;
	TReleaseDevice* = PROCEDURE {PlatformCC}(device: cl_device_id): cl_int;


	(*!  Context APIs *)

	(* callback *) 
	TContextNotifyProc* = PROCEDURE {PlatformCC} (CONST name: ARRAY OF CHAR; data: ADDRESS; size: size_t; data2: ADDRESS);

	(* VERSION_1_0 *)
	TCreateContext* = PROCEDURE {PlatformCC}(  properties : ADDRESS (*Pcl_context_properties*) ; num_devices  : cl_uint;  devices : ADDRESS;  pfn_notify : TContextNotifyProc; user_data: ADDRESS; VAR errcode_ret: cl_int): cl_context;

	TCreateContextFromType* = PROCEDURE {PlatformCC} (
			properties      : ADDRESS; (*Pcl_context_properties *)
			device_type     : cl_device_type;
			pf_notify          : TContextNotifyProc;
			user_data       : ADDRESS;
			VAR errcode_ret :  cl_int
			): cl_context;

	TRetainContext * = PROCEDURE {PlatformCC} (context: cl_context): cl_int;

	TReleaseContext * = PROCEDURE {PlatformCC} (context: cl_context): cl_int;

	TGetContextInfo* = PROCEDURE {PlatformCC}(
			context       : cl_context;
			param_name    : cl_context_info;
			param_value_size    : size_t;
			param_value         : ADDRESS;
			param_value_size_ret  : ADDRESS (* size_t *)
			): cl_int;

	(*!  Command Queue APIs *)
	(* VERSION_2_0; *)
	TCreateCommandQueueWithProperties* = PROCEDURE {PlatformCC} (context: cl_context;
                                   device: cl_device_id;
                                   properties: cl_queue_properties;
                                   VAR errcode_ret: cl_int): cl_command_queue; 

	(* Deprecated OpenCL 2.0 APIs *)
	TCreateCommandQueue* = PROCEDURE {PlatformCC}( context : cl_context;  device : cl_device_id;  properties : cl_command_queue_properties ;  VAR errcode_ret:  cl_int ): cl_command_queue;

	TRetainCommandQueue* = PROCEDURE {PlatformCC} (command_queue : cl_command_queue): cl_int;
	TReleaseCommandQueue* = PROCEDURE {PlatformCC} (command_queue : cl_command_queue): cl_int;

	TGetCommandQueueInfo* = PROCEDURE {PlatformCC}(
			command_queue: cl_command_queue;
			param_name   : cl_command_queue_info;
			param_value_size   : size_t;
			param_value        : ADDRESS;
			param_value_size_ret : ADDRESS (* size_t *)
			): cl_int;


	(*!  Memory Object APIs *)
	TCreateBuffer* = PROCEDURE {PlatformCC}(context : cl_context;  flags : cl_mem_flags; size : size_t; host_ptr : ADDRESS;  VAR errcode_ret	: cl_int): cl_mem;


	(*VERSION_1_1*)
	TCreateSubBuffer* = PROCEDURE {PlatformCC} ( buffer: cl_mem;
			flags: cl_mem_flags;
			buffer_create_type: cl_buffer_create_type;
			buffer_create_info: ADDRESS;
			VAR errcode_ret: cl_int): cl_mem;

	(*  VERSION_1_2 *)
	TCreateImage* = PROCEDURE {PlatformCC} (context: cl_context;
			flags: cl_mem_flags;
			image_format: cl_image_format;
			image_desc: cl_image_desc;
			host_ptr: ADDRESS;
			VAR errcode_ret: cl_int): cl_mem;

	(* VERSION_2_0 *)
	TCreatePipe* = PROCEDURE {PlatformCC}(context: cl_context;
             flags: cl_mem_flags;
             pipe_packet_size: cl_uint;
             pipe_max_packets: cl_uint;
             properties: cl_pipe_properties;
             VAR errcode_ret: cl_int): cl_mem;

	(* VERSION_1_0 *)
	TRetainMemObject* = PROCEDURE {PlatformCC} (memobj: cl_mem): cl_int;
	TReleaseMemObject* = PROCEDURE {PlatformCC} (memobj: cl_mem): cl_int;

	TGetSupportedImageFormats* = PROCEDURE {PlatformCC}(
			context		    	: cl_context;
			flags 			    : cl_mem_flags;
			image_type 		  : cl_mem_object_type;
			num_entries 		: cl_uint;
			image_formats   : ADDRESS; (* Pcl_image_format *)
			num_image_formats : ADDRESS (*cl_uint*)
			): cl_int;

	TGetMemObjectInfo* = PROCEDURE {PlatformCC} (
			image      	: cl_mem;
			param_name    : cl_mem_info;
			param_value_size    : size_t;
			param_value     	  : ADDRESS;
			param_value_size_ret  : ADDRESS (* size_t *)
			): cl_int;

	TGetImageInfo* = PROCEDURE {PlatformCC}(
			image         : cl_mem;
			param_name    : cl_image_info;
			param_value_size  : size_t;
			param_value         : ADDRESS;
			param_value_size_ret  : ADDRESS (* size_t *)
			): cl_int;


	(* VERSION_2_0 *)
	TGetPipeInfo* = PROCEDURE {PlatformCC}(pipe: cl_mem;
			              param_name: cl_pipe_info;
			              param_value_size: size_t;
			              param_value: ADDRESS;
			              VAR param_value_size_ret: size_t): cl_int;

	(* VERSION_1_1 *)
	TMemObjectDestructorCallbackProc* = PROCEDURE {PlatformCC} (memobj: cl_mem; user_data:ADDRESS);

	TSetMemObjectDestructorCallback* = PROCEDURE {PlatformCC} (memobj: cl_mem;
						pfn_notify: TMemObjectDestructorCallbackProc;
						user_data: ADDRESS):  cl_int;

	(* SVM Allocation APIs *)
	(* VERSION_2_0 *)
	TSVMAlloc* = PROCEDURE {PlatformCC}(context: cl_context;
			           flags: cl_svm_mem_flags;
			           size: size_t;
			           alignment: cl_uint): ADDRESS;

	(* VERSION_2_0 *)
	TSVMFree* = PROCEDURE {PlatformCC}(context: cl_context; svm_pointer: ADDRESS);
    
	(*!  Sampler APIs *)

	(* VERSION_2_0 *)
	TCreateSamplerWithProperties* = PROCEDURE {PlatformCC}(context: cl_context;
                              normalized_coords: cl_sampler_properties;
                              VAR errcode_ret: cl_int): cl_sampler;

	(* VERSION_1_0*) (*! VERSION_2_0_DEPRECATED *)  (* Deprecated OpenCL 2.0 APIs *)
	TCreateSampler* = PROCEDURE {PlatformCC} (
						context: cl_context;
						normalized_coords: cl_bool;
						addressing_mode: cl_addressing_mode;
						filter_mode: cl_filter_mode;
						VAR errcode_ret:  cl_int): cl_sampler;

	TRetainSampler* = PROCEDURE {PlatformCC} (sampler: cl_sampler): cl_int;
	TReleaseSampler* = PROCEDURE {PlatformCC} (sampler: cl_sampler): cl_int;

	TGetSamplerInfo* = PROCEDURE {PlatformCC}(
						sampler: cl_sampler;
						param_name: cl_sampler_info;
						param_value_size: size_t;
						param_value: ADDRESS;
						param_value_size_ret : ADDRESS (* size_t *)
						): cl_int;


	(*!  Program Object APIs *)
	TCreateProgramWithSource* = PROCEDURE {PlatformCC}( context  : cl_context;  count  : cl_uint; strings : ADDRESS; lengths  : ADDRESS (*Psize_t*);   VAR errcode_ret :  cl_int  ): cl_program;

(*	PByte* = POINTER TO ARRAY OF CHAR;
	PPByte* = POINTER TO ARRAY OF PByte;
*)

	TCreateProgramWithBinary* = PROCEDURE {PlatformCC} (
			context     : cl_context;
			num_devices : cl_uint;
			device_list : ADDRESS; (*Pcl_device_id *)
			lengths     : ADDRESS; (*Psize_t *)
			binaries    : ADDRESS; (*PPByte *)
			binary_status: ADDRESS; (* cl_int *)
			VAR errcode_ret: cl_int
			): cl_program;

	(* VERSION_1_2 *)
	TCreateProgramWithBuiltInKernels* = PROCEDURE {PlatformCC}(context: cl_context;
			num_devices: cl_uint;
			device_list: ADDRESS; (* Pcl_device_id *)
			kernel_names: ADDRESS;
			VAR errcode_ret: cl_int
			):cl_program;

	(* VERSION_1_0 *)
	TRetainProgram* = PROCEDURE {PlatformCC} (iprogram: cl_program): cl_int;
	TReleaseProgram* = PROCEDURE {PlatformCC} (iprogram: cl_program): cl_int;

	(* callback *) 
	TProgramNotifyProc* =  PROCEDURE {PlatformCC} (iprogram: cl_program; user_data: ADDRESS);

	TBuildProgram* = PROCEDURE {PlatformCC} (iprogram: cl_program; num_devices:  cl_uint;  device_list: ADDRESS; CONST options: ARRAY OF CHAR; notify: TProgramNotifyProc;  user_data: ADDRESS ): cl_int;

	(* VERSION_1_2 *)
	TCompileProgram* = PROCEDURE {PlatformCC}(program: cl_program;
			num_devices: cl_uint;
			device_list: ADDRESS (*cl_device_id*);
			CONST options: ARRAY OF CHAR;
			num_input_headers: cl_uint;
			input_headers: ADDRESS (* cl_program*);
			header_include_names: ADDRESS;
			pfn_notify :TProgramNotifyProc;
 			user_data: ADDRESS): cl_int;

	TLinkProgram* = PROCEDURE {PlatformCC}(context: cl_context;
			num_devices: cl_uint;
			device_list: ADDRESS (*cl_device_id*);
			CONST options: ARRAY OF CHAR;
			num_input_programs: cl_uint;
			input_programs: ADDRESS (*cl_program *);
			pfn_notify: TProgramNotifyProc;
			user_data: ADDRESS;
			VAR errcode_ret: cl_int 
			): cl_program;

	TUnloadPlatformCompiler* = PROCEDURE {PlatformCC}(platform: cl_platform_id ): cl_int;

	(* VERSION_1_0*)
	TGetProgramInfo* = PROCEDURE {PlatformCC} (
			iprogram : cl_program;
			param_name: cl_program_info;
			param_value_size: size_t;
			param_value         : ADDRESS;
			param_value_size_ret  : ADDRESS (* size_t *)
			): cl_int;

	TGetProgramBuildInfo* = PROCEDURE {PlatformCC} (
			iprogram      : cl_program;
			device        : cl_device_id;
			param_name    : cl_program_build_info;
			param_value_size    : size_t;
			param_value         : ADDRESS;
			param_value_size_ret  : ADDRESS (* size_t *)
			): cl_int;

	(*!  Kernel Object APIs *)
	TCreateKernel* = PROCEDURE {PlatformCC}(iprogram: cl_program;   CONST kernel_name: ARRAY OF CHAR;   VAR  errcode_ret: cl_int ): cl_kernel;

	TCreateKernelsInProgram* = PROCEDURE {PlatformCC} (
			iprogram      : cl_program;
			num_kernels   : cl_uint;
			kernels       : ADDRESS; (*Pcl_kernel *)
			num_kernels_ret   : ADDRESS (* cl_uint *)
			): cl_int;

	TRetainKernel* = PROCEDURE {PlatformCC} (kernel: cl_kernel): cl_int;
	TReleaseKernel* = PROCEDURE {PlatformCC} (kernel: cl_kernel): cl_int;

	TSetKernelArg* = PROCEDURE {PlatformCC} (
			kernel    : cl_kernel;
			arg_index : cl_uint;
			arg_size  : size_t;
			arg_value : ADDRESS
			): cl_int;

	TGetKernelInfo* = PROCEDURE {PlatformCC} (
			kernel        : cl_kernel;
			param_name    : cl_kernel_info;
			param_value_size    : size_t;
			param_value         : ADDRESS;
			param_value_size_ret  : ADDRESS (* size_t *)
			): cl_int;


	(* VERSION_2_0 *)
	TSetKernelArgSVMPointer* = PROCEDURE {PlatformCC}(kernel: cl_kernel;
                         arg_index: cl_uint;
                         arg_value: ADDRESS): cl_int;


	(* VERSION_2_0 *)
	TSetKernelExecInfo* = PROCEDURE {PlatformCC}(kernel: cl_kernel;
                    param_name: cl_kernel_exec_info;
                    param_value_size: size_t;
                    param_value: ADDRESS): cl_int;
 
	(* VERSION_1_2 *)
	TGetKernelArgInfo* = PROCEDURE {PlatformCC}(kernel: cl_kernel;
			arg_indx: cl_uint;
			param_name: cl_kernel_arg_info;
			param_value_size: size_t;
			param_value: ADDRESS;
			param_value_size_ret: ADDRESS
			): cl_int;

	TGetKernelWorkGroupInfo* = PROCEDURE {PlatformCC}(kernel: cl_kernel; device: cl_device_id; param_name: cl_kernel_work_group_info; value_size: size_t; value: ADDRESS; VAR size_ret : size_t ): cl_int;

	(*!  Event Object APIs *)
	TWaitForEvents* = PROCEDURE {PlatformCC} (num_events  : cl_uint; event_list  : ADDRESS ): cl_int;

	TGetEventInfo* = PROCEDURE {PlatformCC} (
			event         : cl_event;
			param_name    : cl_event_info;
			param_value_size    : size_t;
			param_value         : ADDRESS;
			param_value_size_ret  : ADDRESS (* size_t *)
			): cl_int;

	(* VERSION_1_1 *)
	TCreateUserEvent* = PROCEDURE {PlatformCC}(context: cl_context; VAR errcode_ret: cl_int): cl_event;

	(* VERSION_1_0 *)
	TRetainEvent* = PROCEDURE {PlatformCC} (event: cl_event): cl_int;
	TReleaseEvent* = PROCEDURE {PlatformCC} (event: cl_event): cl_int;

	(* VERSION_1_1 *)
	TSetUserEventStatus* = PROCEDURE {PlatformCC}(event: cl_event; execution_status: cl_int): cl_int;

	TSetEventCallbackProc* = PROCEDURE (event: cl_event; user_data: ADDRESS);

	TSetEventCallback* = PROCEDURE {PlatformCC}( event: cl_event;
			command_exec_callback_type: cl_int;
			pfn_notify: TSetEventCallbackProc;
			user_data: ADDRESS): cl_int;

	(*!  Profiling APIs *)
	TGetEventProfilingInfo * = PROCEDURE {PlatformCC} (
			event         : cl_event;
			param_name    : cl_profiling_info;
			param_value_size    : size_t;
			param_value         : ADDRESS;
			param_value_size_ret  : ADDRESS (* size_t *)
			): cl_int;


	(*!  Flush and Finish APIs *)
	TFlush * = PROCEDURE {PlatformCC} (command_queue: cl_command_queue): cl_int;
	TFinish* = PROCEDURE {PlatformCC} (command_queue: cl_command_queue): cl_int;

	(*!  Enqueued Commands APIs *)
	TEnqueueReadBuffer* = PROCEDURE {PlatformCC} (
			command_queue : cl_command_queue;
			buffer        : cl_mem;
			blocking_read : cl_bool;
			offset        : size_t;
			size            : size_t;
			ptr           : ADDRESS;
			num_events_in_wait_list    : cl_uint;
			event_wait_list   :ADDRESS ;
			event         : ADDRESS
			): cl_int;



	(* VERSION_1_1 *)
	TEnqueueReadBufferRect * = PROCEDURE {PlatformCC} (command_queue: cl_command_queue;
			buffer: cl_mem;
			blocking_read: cl_bool;
			buffer_offset: ADDRESS (* size_t *);
			host_offset: ADDRESS (* size_t *);
			region: ADDRESS (* size_t *);
			buffer_row_pitch: size_t;
			buffer_slice_pitch: size_t;
			host_row_pitch: size_t;
			host_slice_pitch: size_t;
			ptr: ADDRESS;
			num_events_in_wait_list: cl_uint;
			event_wait_list:ADDRESS (*cl_event*);
			event: ADDRESS (*cl_event*)
			):cl_int;


	TEnqueueWriteBuffer * = PROCEDURE {PlatformCC} ( command_queue: cl_command_queue;
			buffer : cl_mem;
			blocking_write : cl_bool;
			offset : size_t;
			size: size_t;
			ptr: ADDRESS;
			num_events_in_wait_list: cl_uint;
			event_wait_list: ADDRESS;
			event: ADDRESS
			): cl_int;

	(* VERSION_1_1*)
	TEnqueueWriteBufferRect* = PROCEDURE {PlatformCC} (command_queue: cl_command_queue;
			buffer: cl_mem;
			blocking_write: cl_bool;
			buffer_offset: ADDRESS (*size_t *);
			host_offset : ADDRESS (*size_t *);
			region: ADDRESS (*size_t *);
			buffer_row_pitch: size_t;
			buffer_slice_pitch: size_t;
			host_row_pitch: size_t;
			host_slice_pitch: size_t;
			ptr: ADDRESS;
			num_events_in_wait_list: cl_uint;
			event_wait_list: ADDRESS (* cl_event *);
			event: ADDRESS (*cl_event *)
			): cl_int;

	TEnqueueFillBuffer* = PROCEDURE {PlatformCC}(command_queue: cl_command_queue;
			buffer: cl_mem;
			pattern: ADDRESS;
			pattern_size: size_t;
			offset: size_t;
			size: size_t;
			num_events_in_wait_list: cl_uint;
			event_wait_list: ADDRESS (* cl_event *);
			event: ADDRESS (*cl_event *)
			): cl_int;

	TEnqueueCopyBuffer* = PROCEDURE {PlatformCC} (
			command_queue : cl_command_queue;
			src_buffer    : cl_mem;
			dst_buffer    : cl_mem;
			src_offset    : size_t;
			dst_offset    : size_t;
			size: size_t;
			num_events_in_wait_list    : cl_uint;
			event_wait_list   : ADDRESS; (*Pcl_event*)
			event: ADDRESS (*Pcl_event *)
			): cl_int;

	TEnqueueCopyBufferRect* = PROCEDURE {PlatformCC}(command_queue: cl_command_queue;
			src_buffer: cl_mem;
			dst_buffer: cl_mem;
			src_origin: ADDRESS (* size_t *);
			dst_origin: ADDRESS (* size_t *);
			region:  ADDRESS (* size_t *);
			src_row_pitch: size_t;
			src_slice_pitch: size_t;
			dst_row_pitch: size_t;
			dst_slice_pitch: size_t;
			num_events_in_wait_list: cl_uint;
			event_wait_list:  ADDRESS (*cl_event *);
			event: ADDRESS(*cl_event *)
			): cl_int;

	TEnqueueReadImage * = PROCEDURE {PlatformCC} (
			command_queue : cl_command_queue;
			image: cl_mem;
			blocking_read : cl_bool;
			origin: ADDRESS; (* origin[3] *)
			region: ADDRESS; (* region[3] *)
			row_pitch: size_t;
			slice_pitch: size_t;
			ptr : ADDRESS;
			num_events_in_wait_list    : cl_uint;
			event_wait_list   : ADDRESS; (*Pcl_event; *)
			event : ADDRESS (*Pcl_event*)
			): cl_int;

	TEnqueueWriteImage * = PROCEDURE {PlatformCC} (
			command_queue   : cl_command_queue;
			image : cl_mem;
			blocking_write  : cl_bool;
			origin: ADDRESS; (* origin[3] *)
			region: ADDRESS; (* region[3] *)
			input_row_pitch: size_t;
			input_slice_pitch: size_t;
			ptr : ADDRESS;
			num_events_in_wait_list      : cl_uint;
			event_wait_list     : ADDRESS; (*Pcl_event;*)
			event : ADDRESS (*Pcl_event*)
			): cl_int;

	(* VERSION_1_2 *)
	TEnqueueFillImage* = PROCEDURE {PlatformCC} (command_queue: cl_command_queue;
			image: cl_mem;
			fill_color: ADDRESS;
			origin: ADDRESS; (* origin[3] *)
			region: ADDRESS;(* region[3] *)
			num_events_in_wait_list: cl_uint;
			event_wait_list: ADDRESS (*cl_event *);
			event: ADDRESS (*cl_event *)
			): cl_int;

	TEnqueueCopyImage* = PROCEDURE {PlatformCC} (
			command_queue : cl_command_queue;
			src_image : cl_mem;
			dst_image: cl_mem;
			src_origin: ADDRESS; (* src_origin[3]*)
			dst_origin: ADDRESS; (* dst_origin[3] *)
			region : ADDRESS; (* region[3] *)
			num_events_in_wait_list    : cl_uint;
			event_wait_list: ADDRESS; (*Pcl_event;*)
			event : ADDRESS (*Pcl_event*)
			): cl_int;

	TEnqueueCopyImageToBuffer* = PROCEDURE {PlatformCC} (
			command_queue : cl_command_queue;
			src_image     : cl_mem;
			dst_buffer    : cl_mem;
			src_origin    : ADDRESS; (* src_origin[3] *)
			region        : ADDRESS; (* region[3] *)
			dst_offset    : size_t;
			num_events_in_wait_list    : cl_uint;
			event_wait_list     : ADDRESS; (*Pcl_event;*)
			event: ADDRESS (*Pcl_event*)
			): cl_int;

	TEnqueueCopyBufferToImage* = PROCEDURE {PlatformCC}(
			command_queue : cl_command_queue;
			src_buffer    : cl_mem;
			dst_image     : cl_mem;
			src_offset    : size_t;
			dst_origin    : ADDRESS; (* dst_origin[3] *)
			region        : ADDRESS; (* region[3] *)
			num_events_in_wait_list    : cl_uint;
			event_wait_list     : ADDRESS; (*Pcl_event;*)
			event : ADDRESS (*Pcl_event*)
			): cl_int;

	TEnqueueMapBuffer* = PROCEDURE {PlatformCC}(
			command_queue   : cl_command_queue;
			buffer          : cl_mem;
			blocking_map    : cl_bool;
			map_flags       : cl_map_flags;
			offset          : size_t;
			size              : size_t;
			num_events_in_wait_list      : cl_uint;
			event_wait_list     : ADDRESS; (*Pcl_event;*)
			event           : ADDRESS; (*Pcl_event*)
			VAR errcode_ret		: cl_int
			): ADDRESS;

	TEnqueueMapImage* = PROCEDURE {PlatformCC}(
			command_queue   : cl_command_queue;
			image           : cl_mem;
			blocking_map    : cl_bool;
			map_flags       : cl_map_flags;
			origin          : ADDRESS; (* origin[3] *)
			region          : ADDRESS; (* region[3] *)
			image_row_pitch: ADDRESS (*size_t*);
			image_slice_pitch : ADDRESS (*size_t*);
			num_events_in_wait_list      : cl_uint;
			event_wait_list     : ADDRESS; (*Pcl_event;*)
			event           : ADDRESS; (*Pcl_event*)
			VAR errcode_ret		: cl_int
			): ADDRESS;

	TEnqueueUnmapMemObject* = PROCEDURE {PlatformCC}(
			command_queue : cl_command_queue;
			memobj        : cl_mem;
			mapped_ptr    : ADDRESS;
			num_events_in_wait_list    : cl_uint;
			event_wait_list     : ADDRESS; (*Pcl_event;*)
			event           : ADDRESS (*Pcl_event*)
			): cl_int;

	(* VERSION_1_2 *)
	TEnqueueMigrateMemObjects* = PROCEDURE {PlatformCC}(command_queue: cl_command_queue;
			num_mem_objects: cl_uint;
 			mem_objects: ADDRESS (* cl_mem *);
 			flags: cl_mem_migration_flags;
			num_events_in_wait_list: cl_uint;
			event_wait_list: ADDRESS (*cl_event *);
			event: ADDRESS (*cl_event *)
			): cl_int;

	TEnqueueNDRangeKernel* = PROCEDURE {PlatformCC}(
			command_queue : cl_command_queue;
			kernel        : cl_kernel;
			work_dim      : cl_uint;
			global_work_offset,
			global_work_size,
			local_work_size    : ADDRESS;
			num_events_in_wait_list    : cl_uint;
			event_wait_list   : ADDRESS;
			event         : ADDRESS
			): cl_int;

	(* VERSION_2_0_DEPRECATED *)
	TEnqueueTask* = PROCEDURE {PlatformCC}(
			command_queue : cl_command_queue;
			kernel        : cl_kernel;
			num_events_in_wait_list    : cl_uint;
			event_wait_list     : ADDRESS; (*Pcl_event;*)
			event           : ADDRESS (*Pcl_event*)
			): cl_int;

	TEnqueueNativeKernelProc* =  PROCEDURE {PlatformCC} (userdata: ADDRESS);

	TEnqueueNativeKernel* = PROCEDURE {PlatformCC} (
			command_queue   : cl_command_queue;
			user_func       : TEnqueueNativeKernelProc;
			args            : ADDRESS;
			cb_args         : size_t;
			num_mem_objects : cl_uint;
			mem_list        : ADDRESS; (*Pcl_mem *)
			args_mem_loc    : ADDRESS;
			num_events_in_wait_list      : cl_uint;
			event_wait_list     : ADDRESS; (*Pcl_event;*)
			event           : ADDRESS (*Pcl_event*)
			): cl_int;

	(* VERSION_1_2 *)
	TEnqueueMarkerWithWaitList* = PROCEDURE {PlatformCC} (command_queue: cl_command_queue;
			num_events_in_wait_list: cl_uint;
			event_wait_list: ADDRESS (*cl_event *);
			event: ADDRESS (*cl_event *)): cl_int;

	TEnqueueBarrierWithWaitList* = PROCEDURE {PlatformCC} (command_queue: cl_command_queue;
			num_events_in_wait_list: cl_uint;
			event_wait_list: ADDRESS (*cl_event *);
			event: ADDRESS (*cl_event *)): cl_int;




	(* VERSION_2_0 *)
	TEnqueueSVMFreeProc* = PROCEDURE{PlatformCC}(queue: cl_command_queue; num_svm_pointers: cl_uint; svm_pointers: ADDRESS; user_data: ADDRESS);
	TEnqueueSVMFree* = PROCEDURE{PlatformCC}(command_queue: cl_command_queue;
					num_svm_pointers: cl_uint;
					svm_pointers: ADDRESS;          (* svm_pointers[] *)
					pfn_free_func: TEnqueueSVMFreeProc;
					user_data: ADDRESS;
					num_events_in_wait_list: cl_uint;
					event_wait_list: ADDRESS;
					event: ADDRESS): cl_int;

	(* VERSION_2_0 *)
	TEnqueueSVMMemcpy* = PROCEDURE{PlatformCC}(command_queue: cl_command_queue;
					blocking_copy: cl_bool;
					dst_ptr: ADDRESS;
					src_ptr: ADDRESS;
					size: size_t;
					num_events_in_wait_list: cl_uint;
					event_wait_list: ADDRESS; (* cl_event *)
					event: cl_event): cl_int;

	(* VERSION_2_0 *)
	TEnqueueSVMMemFill* = PROCEDURE{PlatformCC}(command_queue: cl_command_queue;
					svm_ptr: ADDRESS;
					pattern: ADDRESS;
					pattern_size: size_t;
					size: size_t;
					num_events_in_wait_list: cl_uint;
					event_wait_list: ADDRESS;
					event: ADDRESS): cl_int;
    
	(* VERSION_2_0 *)
	TEnqueueSVMMap* = PROCEDURE{PlatformCC}(command_queue: cl_command_queue;
					blocking_map:cl_bool;
					flags: cl_map_flags;
					svm_ptr: ADDRESS;
					size: size_t;
					num_events_in_wait_list: cl_uint;
					event_wait_list: ADDRESS;
					event: ADDRESS): cl_int;
    
	(* VERSION_2_0 *)
	TEnqueueSVMUnmap* = PROCEDURE{PlatformCC}(command_queue: cl_command_queue;
					svm_ptr: ADDRESS;
					num_events_in_wait_list: cl_uint;
					event_wait_list: ADDRESS;
					event: ADDRESS): cl_int;
    
	(*! Extension function access*)
	 (*
	 * Returns the extension function address for the given function name,
	 * or NULL if a valid function can not be found.  The client must
	 * check to make sure the address is not NULL, before using or
	 * calling the returned function address.
	 *)

	(* VERSION_1_2 *)
	TGetExtensionFunctionAddressForPlatform* = PROCEDURE {PlatformCC} (platform: cl_platform_id; CONST func_name:  ARRAY OF CHAR): ADDRESS;


	(*! CL_USE_DEPRECATED_OPENCL_1_0_APIS is defined.
		These APIs are unsupported and untested in OpenCL 1.1!

	     *  WARNING:
	     *     This API introduces mutable state into the OpenCL implementation. It has been REMOVED
	     *  to better facilitate thread safety.  The 1.0 API is not thread safe. It is not tested by the
	     *  OpenCL 1.1 conformance test, and consequently may not work or may not work dependably.
	     *  It is likely to be non-performant. Use of this API is not advised. Use at your own risk.
	     *
	     *  Software developers previously relying on this API are instructed to set the command queue
	     *  properties when creating the queue, instead.
	  *)

	 (*  VERSION_1_0_DEPRECATED *)
	TSetCommandQueueProperty* = PROCEDURE {PlatformCC}(
			command_queue       : cl_command_queue;
			properties          : cl_command_queue_properties;
			enable              : cl_bool;
			VAR old_properties  : cl_command_queue_properties
			): cl_int;

	(*  VERSION_1_1_DEPRECATED *)
	TCreateImage2D* = PROCEDURE {PlatformCC}(
			context         : cl_context;
			flags   	      : cl_mem_flags;
			CONST image_format    : cl_image_format;
			image_width     : size_t;
			image_height    : size_t;
			image_row_pitch : size_t;
			host_ptr        : ADDRESS;
			VAR errcode_ret		: cl_int
			): cl_mem;

	TCreateImage3D* = PROCEDURE {PlatformCC}(
			context 			    : cl_context;
			flags 			      : cl_mem_flags;
			CONST image_format      : cl_image_format;
			image_width 	    : size_t;
			image_height      : size_t;
			image_depth 	    : size_t;
			image_row_pitch 	: size_t;
			image_slice_pitch : size_t;
			host_ptr 		      : ADDRESS;
			VAR errcode_ret		: cl_int
			): cl_mem;

	TEnqueueMarker* = PROCEDURE {PlatformCC} (command_queue: cl_command_queue; event: ADDRESS ): cl_int;
	TEnqueueWaitForEvents* = PROCEDURE {PlatformCC} (command_queue: cl_command_queue; num_events: cl_uint; event_list: ADDRESS ): cl_int;
	TEnqueueBarrier* = PROCEDURE {PlatformCC} (command_queue: cl_command_queue): cl_int;

	TUnloadCompiler* = PROCEDURE {PlatformCC}(): cl_int;
	TGetExtensionFunctionAddress* = PROCEDURE {PlatformCC}(CONST funcname: ARRAY OF CHAR): ADDRESS;
(*
TYPE Context= OBJECT
	VAR 
				
	END Context;

TYPE Device= OBJECT
		VAR 
			platform: Platform;
			contex*: Context;
		(** *)
		PROCEDURE &Init*(p: Platform);
		VAR
		BEGIN
			
		END Init;
							
		END Device;
	

TYPE Platform* = OBJECT
	VAR
		devices: POINTER TO ARRAY OF Device;
	
	PROCEDURE &Init;
	BEGIN
		
	END Init;
		
	END Platform;
*)
		
VAR
	(* Platform APIs *)
	GetPlatformIDs- : TGetPlatformIDs;
	GetPlatformInfo- : TGetPlatformInfo;
	(*  Device APIs *)
	GetDeviceIDs- : TGetDeviceIDs;
	GetDeviceInfo- : TGetDeviceInfo;
	CreateSubDevices- : TCreateSubDevices;
	RetainDevice- : TRetainDevice;
	ReleaseDevice- : TReleaseDevice;
	(*  Context APIs *)
	CreateContext- : TCreateContext;
	CreateContextFromType- : TCreateContextFromType;
	RetainContext- : TRetainContext;
	ReleaseContext- : TReleaseContext;
	GetContextInfo- : TGetContextInfo;
	(*  Command Queue APIs *)
	CreateCommandQueue- : TCreateCommandQueue;
	RetainCommandQueue- : TRetainCommandQueue;
	ReleaseCommandQueue- : TReleaseCommandQueue;
	GetCommandQueueInfo- : TGetCommandQueueInfo;
	(*  Memory Object APIs *)
	CreateBuffer- : TCreateBuffer;
	CreateSubBuffer- : TCreateSubBuffer;
	CreateImage- : TCreateImage;
	RetainMemObject- : TRetainMemObject;
	ReleaseMemObject- : TReleaseMemObject;
	GetSupportedImageFormats- : TGetSupportedImageFormats;
	GetMemObjectInfo- : TGetMemObjectInfo;
	GetImageInfo- : TGetImageInfo;
	SetMemObjectDestructorCallback- : TSetMemObjectDestructorCallback;
	(*  Sampler APIs *)
	CreateSampler- : TCreateSampler;
	RetainSampler- : TRetainSampler;
	ReleaseSampler- : TReleaseSampler;
	GetSamplerInfo- : TGetSamplerInfo;
	(*  Program Object APIs *)
	CreateProgramWithSource- : TCreateProgramWithSource;
	CreateProgramWithBinary- : TCreateProgramWithBinary;
	CreateProgramWithBuiltInKernels- : TCreateProgramWithBuiltInKernels;
	RetainProgram- : TRetainProgram;
	ReleaseProgram- : TReleaseProgram;
	BuildProgram- : TBuildProgram;
	CompileProgram- : TCompileProgram;
	LinkProgram- : TLinkProgram;
	UnloadPlatformCompiler- : TUnloadPlatformCompiler;
	GetProgramInfo- : TGetProgramInfo;
	GetProgramBuildInfo- : TGetProgramBuildInfo;
	(*  Kernel Object APIs *)
	CreateKernel- : TCreateKernel;
	CreateKernelsInProgram- : TCreateKernelsInProgram;
	RetainKernel- : TRetainKernel;
	ReleaseKernel- : TReleaseKernel;
	SetKernelArg- : TSetKernelArg;
	GetKernelInfo- : TGetKernelInfo;
	GetKernelArgInfo- : TGetKernelArgInfo;
	GetKernelWorkGroupInfo- : TGetKernelWorkGroupInfo;
	(*  Event Object APIs *)
	WaitForEvents- : TWaitForEvents;
	GetEventInfo- : TGetEventInfo;
	CreateUserEvent- : TCreateUserEvent;
	RetainEvent- : TRetainEvent;
	ReleaseEvent- : TReleaseEvent;
	SetUserEventStatus- : TSetUserEventStatus;
	SetEventCallback- : TSetEventCallback;
	(*  Profiling APIs *)
	GetEventProfilingInfo- : TGetEventProfilingInfo;
	(*  Flush and Finish APIs *)
	Flush- : TFlush;
	Finish- : TFinish;
	(*  Enqueued Commands APIs *)
	EnqueueReadBuffer- : TEnqueueReadBuffer;
	EnqueueReadBufferRect- : TEnqueueReadBufferRect;
	EnqueueWriteBuffer- : TEnqueueWriteBuffer;
	EnqueueWriteBufferRect- : TEnqueueWriteBufferRect;
	EnqueueFillBuffer- : TEnqueueFillBuffer;
	EnqueueCopyBuffer- : TEnqueueCopyBuffer;
	EnqueueCopyBufferRect- : TEnqueueCopyBufferRect;
	EnqueueReadImage- : TEnqueueReadImage;
	EnqueueWriteImage- : TEnqueueWriteImage;
	EnqueueFillImage- : TEnqueueFillImage;
	EnqueueCopyImage- : TEnqueueCopyImage;
	EnqueueCopyImageToBuffer- : TEnqueueCopyImageToBuffer;
	EnqueueCopyBufferToImage- : TEnqueueCopyBufferToImage;
	EnqueueMapBuffer- : TEnqueueMapBuffer;
	EnqueueMapImage- : TEnqueueMapImage;
	EnqueueUnmapMemObject- : TEnqueueUnmapMemObject;
	EnqueueMigrateMemObjects- : TEnqueueMigrateMemObjects;
	EnqueueNDRangeKernel- : TEnqueueNDRangeKernel;
	EnqueueTask- : TEnqueueTask;
	EnqueueNativeKernel- : TEnqueueNativeKernel;
	EnqueueMarkerWithWaitList - : TEnqueueMarkerWithWaitList;
	EnqueueBarrierWithWaitList- : TEnqueueBarrierWithWaitList;
(*	SetPrintfCallback- : TSetPrintfCallback; *)
	(* Extension function access*)
	GetExtensionFunctionAddressForPlatform- : TGetExtensionFunctionAddressForPlatform;

	(*! DEPRECATED functions *)
	(*  Command Queue APIs *)
	SetCommandQueueProperty- : TSetCommandQueueProperty;
	(*  Memory Object APIs *)
	CreateImage2D- : TCreateImage2D;
	CreateImage3D- : TCreateImage3D;
	(*  Enqueued Commands APIs *)
	EnqueueMarker- : TEnqueueMarker;
	EnqueueWaitForEvents- : TEnqueueWaitForEvents;
	EnqueueBarrier- : TEnqueueBarrier;
	(*  Program Object APIs *)
	UnloadCompiler- : TUnloadCompiler;
	(* Extension function access*)
	GetExtensionFunctionAddress- : TGetExtensionFunctionAddress;

PROCEDURE GetProcAddress*( lib: HostLibs.LibHandle;  CONST procName: ARRAY OF CHAR;  adr: ADDRESS );
VAR res: BOOLEAN
BEGIN
	res := HostLibs.GetProcedure(lib,  procName, adr);
END GetProcAddress;


PROCEDURE Init;
VAR res: BOOLEAN;
BEGIN

	(* load the DLL *)
	res := HostLibs.LoadLibrary(libname, oclib);
	
	ASSERT(res, 300);
	
	KernelLog.String(libname); KernelLog.String(" loaded.");  KernelLog.Ln;

	(* Platform APIs *)
	GetProcAddress(oclib, 'clGetPlatformIDs', ADDRESSOF(GetPlatformIDs));
	GetProcAddress(oclib, 'clGetPlatformInfo', ADDRESSOF(GetPlatformInfo));
	(*  Device APIs *)
	GetProcAddress(oclib, 'clGetDeviceIDs', ADDRESSOF(GetDeviceIDs));
	GetProcAddress(oclib, 'clGetDeviceInfo', ADDRESSOF(GetDeviceInfo));
	
		(* VERSION_1_2 *)
		GetProcAddress(oclib, 'clCreateSubDevices', ADDRESSOF(CreateSubDevices));
		GetProcAddress(oclib, 'clRetainDevice', ADDRESSOF(RetainDevice));
		GetProcAddress(oclib, 'clReleaseDevice', ADDRESSOF(ReleaseDevice));

	
	(*  Context APIs *)
	GetProcAddress(oclib, 'clCreateContext', ADDRESSOF(CreateContext));
	GetProcAddress(oclib, 'clCreateContextFromType', ADDRESSOF(CreateContextFromType));
	GetProcAddress(oclib, 'clRetainContext', ADDRESSOF(RetainContext));
	GetProcAddress(oclib, 'clReleaseContext', ADDRESSOF(ReleaseContext));
	GetProcAddress(oclib, 'clGetContextInfo', ADDRESSOF(GetContextInfo));
	
	(*  Command Queue APIs *)
	GetProcAddress(oclib, 'clCreateCommandQueue', ADDRESSOF(CreateCommandQueue));
	GetProcAddress(oclib, 'clRetainCommandQueue', ADDRESSOF(RetainCommandQueue));
	GetProcAddress(oclib, 'clReleaseCommandQueue', ADDRESSOF(ReleaseCommandQueue));
	GetProcAddress(oclib, 'clGetCommandQueueInfo', ADDRESSOF(GetCommandQueueInfo));
	
	(*  Memory Object APIs *)
	GetProcAddress(oclib, 'clCreateBuffer', ADDRESSOF(CreateBuffer));
	
	(* VERSION_1_1 *)
		GetProcAddress(oclib, 'clCreateSubBuffer', ADDRESSOF(CreateSubBuffer));
	
	(* VERSION_1_2 *)
		GetProcAddress(oclib, 'clCreateImage', ADDRESSOF(CreateImage));
	
	GetProcAddress(oclib, 'clRetainMemObject', ADDRESSOF(RetainMemObject));
	GetProcAddress(oclib, 'clReleaseMemObject', ADDRESSOF(ReleaseMemObject));
	GetProcAddress(oclib, 'clGetSupportedImageFormats', ADDRESSOF(GetSupportedImageFormats));
	GetProcAddress(oclib, 'clGetMemObjectInfo', ADDRESSOF(GetMemObjectInfo));
	GetProcAddress(oclib, 'clGetImageInfo', ADDRESSOF(GetImageInfo));
	
	(* VERSION_1_1 *)
		GetProcAddress(oclib, 'clSetMemObjectDestructorCallback', ADDRESSOF(SetMemObjectDestructorCallback));
	
	(*  Sampler APIs *)
	GetProcAddress(oclib, 'clCreateSampler', ADDRESSOF(CreateSampler));
	GetProcAddress(oclib, 'clRetainSampler', ADDRESSOF(RetainSampler));
	GetProcAddress(oclib, 'clReleaseSampler', ADDRESSOF(ReleaseSampler));
	GetProcAddress(oclib, 'clGetSamplerInfo', ADDRESSOF(GetSamplerInfo));
	
	(*  Program Object APIs *)
	GetProcAddress(oclib, 'clCreateProgramWithSource', ADDRESSOF(CreateProgramWithSource));
	GetProcAddress(oclib, 'clCreateProgramWithBinary', ADDRESSOF(CreateProgramWithBinary));
	(*VERSION_1_2 *)
		GetProcAddress(oclib, 'clCreateProgramWithBuiltInKernels', ADDRESSOF(CreateProgramWithBuiltInKernels));

	GetProcAddress(oclib, 'clRetainProgram', ADDRESSOF(RetainProgram));
	GetProcAddress(oclib, 'clReleaseProgram', ADDRESSOF(ReleaseProgram));
	GetProcAddress(oclib, 'clBuildProgram', ADDRESSOF(BuildProgram));
	(* VERSION_1_2 *)
		GetProcAddress(oclib, 'clCompileProgram', ADDRESSOF(CompileProgram));
		GetProcAddress(oclib, 'clLinkProgram', ADDRESSOF(LinkProgram));
		GetProcAddress(oclib, 'clUnloadPlatformCompiler', ADDRESSOF(UnloadPlatformCompiler));

	GetProcAddress(oclib, 'clGetProgramInfo', ADDRESSOF(GetProgramInfo));
	GetProcAddress(oclib, 'clGetProgramBuildInfo', ADDRESSOF(GetProgramBuildInfo));
	(*  Kernel Object APIs *)
	GetProcAddress(oclib, 'clCreateKernel', ADDRESSOF(CreateKernel));
	GetProcAddress(oclib, 'clCreateKernelsInProgram', ADDRESSOF(CreateKernelsInProgram));
	GetProcAddress(oclib, 'clRetainKernel', ADDRESSOF(RetainKernel));
	GetProcAddress(oclib, 'clReleaseKernel', ADDRESSOF(ReleaseKernel));
	GetProcAddress(oclib, 'clSetKernelArg', ADDRESSOF(SetKernelArg));
	GetProcAddress(oclib, 'clGetKernelInfo', ADDRESSOF(GetKernelInfo));
	 (* VERSION_1_2 *)
		GetProcAddress(oclib, 'clGetKernelArgInfo', ADDRESSOF(GetKernelArgInfo));

	GetProcAddress(oclib, 'clGetKernelWorkGroupInfo', ADDRESSOF(GetKernelWorkGroupInfo));
	(*  Event Object APIs *)
	GetProcAddress(oclib, 'clWaitForEvents', ADDRESSOF(WaitForEvents));
	GetProcAddress(oclib, 'clGetEventInfo', ADDRESSOF(GetEventInfo));
	(* VERSION_1_1 *)	
		GetProcAddress(oclib, 'clCreateUserEvent', ADDRESSOF(CreateUserEvent));
	
	GetProcAddress(oclib, 'clRetainEvent', ADDRESSOF(RetainEvent));
	GetProcAddress(oclib, 'clReleaseEvent', ADDRESSOF(ReleaseEvent));
	(* VERSION_1_1 *)
		GetProcAddress(oclib, 'clSetUserEventStatus', ADDRESSOF(SetUserEventStatus));
		GetProcAddress(oclib, 'clSetEventCallback', ADDRESSOF(SetEventCallback));
	(*  Profiling APIs *)
	GetProcAddress(oclib, 'clGetEventProfilingInfo', ADDRESSOF(GetEventProfilingInfo));
	(*  Flush and Finish APIs *)
	GetProcAddress(oclib, 'clFlush', ADDRESSOF(Flush));
	GetProcAddress(oclib, 'clFinish', ADDRESSOF(Finish));
	(*  Enqueued Commands APIs *)
	GetProcAddress(oclib, 'clEnqueueReadBuffer', ADDRESSOF(EnqueueReadBuffer));
	(* VERSION_1_1 *)
		GetProcAddress(oclib, 'clEnqueueReadBufferRect', ADDRESSOF(EnqueueReadBufferRect));
	GetProcAddress(oclib, 'clEnqueueWriteBuffer', ADDRESSOF(EnqueueWriteBuffer));
	(* VERSION_1_1 *)
		GetProcAddress(oclib, 'clEnqueueWriteBufferRect', ADDRESSOF(EnqueueWriteBufferRect));

	(* VERSION_1_2 *)
		GetProcAddress(oclib, 'clEnqueueFillBuffer', ADDRESSOF(EnqueueFillBuffer));
	GetProcAddress(oclib, 'clEnqueueCopyBuffer', ADDRESSOF(EnqueueCopyBuffer));
	(* VERSION_1_1 *)
		GetProcAddress(oclib, 'clEnqueueCopyBufferRect', ADDRESSOF(EnqueueCopyBufferRect));

	GetProcAddress(oclib, 'clEnqueueReadImage', ADDRESSOF(EnqueueReadImage));
	GetProcAddress(oclib, 'clEnqueueWriteImage', ADDRESSOF(EnqueueWriteImage));
	(* VERSION_1_2 *)
		GetProcAddress(oclib, 'clEnqueueFillImage', ADDRESSOF(EnqueueFillImage));

	GetProcAddress(oclib, 'clEnqueueCopyImage', ADDRESSOF(EnqueueCopyImage));
	GetProcAddress(oclib, 'clEnqueueCopyImageToBuffer', ADDRESSOF(EnqueueCopyImageToBuffer));
	GetProcAddress(oclib, 'clEnqueueCopyBufferToImage', ADDRESSOF(EnqueueCopyBufferToImage));
	GetProcAddress(oclib, 'clEnqueueMapBuffer', ADDRESSOF(EnqueueMapBuffer));
	GetProcAddress(oclib, 'clEnqueueMapImage', ADDRESSOF(EnqueueMapImage));
	GetProcAddress(oclib, 'clEnqueueUnmapMemObject', ADDRESSOF(EnqueueUnmapMemObject));
	(* VERSION_1_2 *)
		GetProcAddress(oclib, 'clEnqueueMigrateMemObjects', ADDRESSOF(EnqueueMigrateMemObjects));

	GetProcAddress(oclib, 'clEnqueueNDRangeKernel', ADDRESSOF(EnqueueNDRangeKernel));
	GetProcAddress(oclib, 'clEnqueueTask', ADDRESSOF(EnqueueTask));
	GetProcAddress(oclib, 'clEnqueueNativeKernel', ADDRESSOF(EnqueueNativeKernel));
	(* VERSION_1_2 *)
		GetProcAddress(oclib, 'clEnqueueMarkerWithWaitList', ADDRESSOF(EnqueueMarkerWithWaitList));
		GetProcAddress(oclib, 'clEnqueueBarrierWithWaitList', ADDRESSOF(EnqueueBarrierWithWaitList));
		(* GetProcAddress(oclib, 'clSetPrintfCallback', ADDRESSOF(SetPrintfCallback)); *)

	(* VERSION_1_2 *)
	(* Extension function access*)
		GetProcAddress(oclib, 'clGetExtensionFunctionAddressForPlatform', ADDRESSOF(GetExtensionFunctionAddressForPlatform));

	
	(* DEPRECATED functions*)
	(* DEPRECEATED_1_0 *)
		GetProcAddress(oclib, 'clSetCommandQueueProperty', ADDRESSOF(SetCommandQueueProperty));

	(* DEPRECEATED_1_1 *)
		GetProcAddress(oclib, 'clCreateImage2D', ADDRESSOF(CreateImage2D));
		GetProcAddress(oclib, 'clCreateImage3D', ADDRESSOF(CreateImage3D));
		GetProcAddress(oclib, 'clEnqueueMarker', ADDRESSOF(EnqueueMarker));
		GetProcAddress(oclib, 'clEnqueueWaitForEvents', ADDRESSOF(EnqueueWaitForEvents));
		GetProcAddress(oclib, 'clEnqueueBarrier', ADDRESSOF(EnqueueBarrier));
		GetProcAddress(oclib, 'clUnloadCompiler', ADDRESSOF(UnloadCompiler));
		(* Extension function access*)
		GetProcAddress(oclib, 'clGetExtensionFunctionAddress', ADDRESSOF(GetExtensionFunctionAddress));

END Init;

PROCEDURE OnClose;
VAR res: BOOLEAN;
BEGIN
	IF oclib # NIL THEN
	       res := HostLibs.FreeLibrary(oclib);
	       KernelLog.String(libname); KernelLog.String(" unloaded."); KernelLog.Ln;
	END;
END OnClose;

BEGIN
	Init;
	Modules.InstallTermHandler(OnClose)
END OpenCL.

