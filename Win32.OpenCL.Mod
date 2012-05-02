MODULE OpenCL; (** AUTHOR "fnecati"; PURPOSE "OpenCL-1.2 binding library  for WinAos"; *)
IMPORT S:=SYSTEM,  Modules, KernelLog, Kernel32;

(* ******************************************************************************
 * Copyright (c) 2011 The Khronos Group Inc.
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
	libname="OpenCL.dll";

	debug = TRUE;

(* Use OpenCL Version *)
	VERSION_1_0* = TRUE;
	VERSION_1_1* = TRUE;
	VERSION_1_2* = FALSE;
	DEPRECEATED_1_0* = TRUE;
	DEPRECEATED_1_1* = TRUE;

VAR
	lib-: Kernel32.HMODULE; (* handle to library *)

TYPE

	ADDRESS* = Kernel32.ADDRESS;
	PChar* = POINTER TO ARRAY OF CHAR;
	(*PPChar* = POINTER TO ARRAY OF PChar;*)
	size_t* = S.SIZE;
	Psize_t* = POINTER TO ARRAY OF size_t;

	intptr_t* = size_t;

  	(* scalar types  *)
	cl_char*     = CHAR; (*-127..+128 *)
	cl_uchar*    = CHAR;  (* 0..255 *)
	cl_short*    = INTEGER; (* - 32767..+32768; *)
	cl_ushort*   = INTEGER; (*  0..+65535; *)
	cl_int*      = LONGINT; (*-2147483647..+2147483648;  *)
	cl_uint*     = LONGINT;  (* 0..4294967295;  *)
	cl_long*     = HUGEINT; (* Int64;// 0..184467440773709551615;//-$8000000000000001..+$8000000000000000{9223372036854775808}; //typedef signed   __int64  cl_long; *)
	cl_ulong*    = HUGEINT;

	cl_half*     = INTEGER;
	cl_float*    = REAL;
	cl_double*   = LONGREAL;

(* Macro names and corresponding values defined by OpenCL *)
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

	FLT_DIG*        =  6;
	FLT_MANT_DIG*   =  24;
	FLT_MAX_10_EXP* =  +38;
	FLT_MAX_EXP*    =  +128;
	FLT_MIN_10_EXP* =  -37;
	FLT_MIN_EXP*    =  -125;
	FLT_RADIX*      =  2;
(*     // FLT_MAX*        =  FLT_MAX;
     // FLT_MIN*        =  FLT_MIN;
     // FLT_EPSILON*    =  FLT_EPSILON;
*)
      DBL_DIG*        =  15;
      DBL_MANT_DIG*   =  53;
      DBL_MAX_10_EXP* =  +308;
      DBL_MAX_EXP*    =  +1024;
      DBL_MIN_10_EXP* =  -307;
      DBL_MIN_EXP*    =  -1021;
      DBL_RADIX*      =  2;
(*     // DBL_MAX*        =  DBL_MAX;
     // DBL_MIN*        =  DBL_MIN;
     // DBL_EPSILON*    =  DBL_EPSILON;
*)

TYPE
(* Mirror types to GL types. Mirror types allow us to avoid deciding which headers to load based on whether we are using GL or GLES here. *)
		cl_GLuint* = LONGINT;
		cl_GLint* = LONGINT;;
		cl_GLenum* = LONGINT;


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

TYPE

  cl_char2*  = ARRAY 2 OF  cl_char;
  cl_char4*  = ARRAY 4 OF  cl_char;
  cl_char8*  = ARRAY 8 OF  cl_char;
  cl_char16* = ARRAY 16 OF  cl_char;

  cl_uchar2* = ARRAY 2 OF  cl_uchar;
  cl_uchar4* = ARRAY 4 OF  cl_uchar;
  cl_uchar8* = ARRAY 8 OF  cl_uchar;
  cl_uchar16* = ARRAY 16 OF  cl_uchar;

  cl_short2*  = ARRAY 2 OF  cl_short;
  cl_short4*  = ARRAY 4 OF  cl_short;
  cl_short8*  = ARRAY 8 OF  cl_short;
  cl_short16* = ARRAY 16 OF  cl_short;

  cl_ushort2*  = ARRAY 2 OF  cl_ushort;
  cl_ushort4*  = ARRAY 4 OF  cl_ushort;
  cl_ushort8*  = ARRAY 8 OF  cl_ushort;
  cl_ushort16* = ARRAY 16 OF  cl_ushort;

  cl_int2*  = ARRAY 2 OF  cl_int;
  cl_int4*  = ARRAY 4 OF  cl_int;
  cl_int8*  = ARRAY 8 OF  cl_int;
  cl_int16* = ARRAY 16 OF  cl_int;

  cl_uint2*  = ARRAY 2 OF  cl_uint;
  cl_uint4*  = ARRAY 4 OF  cl_uint;
  cl_uint8*  = ARRAY 8 OF  cl_uint;
  cl_uint16* = ARRAY 16 OF  cl_uint;

  cl_long2*  = ARRAY 2 OF  cl_long;
  cl_long4*  = ARRAY 4 OF  cl_long;
  cl_long8*  = ARRAY 8 OF  cl_long;
  cl_long16* = ARRAY 16 OF  cl_long;

  cl_ulong2*  = ARRAY 2 OF  cl_ulong;
  cl_ulong4*  = ARRAY 4 OF  cl_ulong;
  cl_ulong8*  = ARRAY 8 OF  cl_ulong;
  cl_ulong16* = ARRAY 16 OF  cl_ulong;

  cl_float2*  = ARRAY 2 OF  cl_float;
  cl_float4*  = ARRAY 4 OF  cl_float;
  cl_float8*  = ARRAY 8 OF  cl_float;
  cl_float16* = ARRAY 16 OF  cl_float;

  cl_double2*  = ARRAY 2 OF  cl_double;
  cl_double4*  = ARRAY 4 OF  cl_double;
  cl_double8*  = ARRAY 8 OF  cl_double;
  cl_double16* = ARRAY 16 OF  cl_double;


(* There are no vector types for half *)

(* **************************************************************************** *)


TYPE
	cl_platform_id*    = size_t;
	cl_device_id*      =  size_t;
	cl_context*        = size_t;
	cl_command_queue*  =  size_t;
	cl_mem*            = size_t;
	cl_program*        = size_t;
	cl_kernel*         = size_t;
	cl_event*          = size_t;
	cl_sampler*        = size_t;

	cl_bool* = cl_uint; (*  WARNING!  Unlike cl_ types in cl_platform.h, cl_bool is not guaranteed to be the same size as the bool in kernels. *)
	cl_bitfield*                 = cl_ulong;
	cl_device_type*              = cl_bitfield;
	cl_platform_info*            = cl_uint;
	cl_device_info*              = cl_uint;
	cl_device_fp_config*         = cl_bitfield;
	cl_device_mem_cache_type*    = cl_uint;
	cl_device_local_mem_type*    = cl_uint;
	cl_device_exec_capabilities* = cl_bitfield;
	cl_command_queue_properties* = cl_bitfield;
	cl_device_partition_property* = intptr_t;
	cl_device_affinity_domain* = cl_bitfield;

	cl_context_properties*   = intptr_t;
	cl_context_info*         = cl_uint;
	cl_command_queue_info*   = cl_uint;
	cl_channel_order*        = cl_uint;
	cl_channel_type*         = cl_uint;
	cl_mem_flags*            = cl_bitfield;
	cl_mem_object_type*      = cl_uint;
	cl_mem_info*             = cl_uint;
	cl_mem_migration_flags* = cl_bitfield;
	cl_image_info*           = cl_uint;
	cl_buffer_create_type* = cl_uint;
	cl_addressing_mode*      = cl_uint;
	cl_filter_mode*          = cl_uint;
	cl_sampler_info*         = cl_uint;
	cl_map_flags*            = cl_bitfield;
	cl_program_info*         = cl_uint;
	cl_program_build_info*   = cl_uint;
	cl_program_binary_type* = cl_uint;
	cl_build_status*         = cl_int;
	cl_kernel_info*            = cl_uint;
	cl_kernel_arg_info* = cl_uint;
	cl_kernel_arg_address_qualifier* = cl_uint;
	cl_kernel_arg_access_qualifier* = cl_uint;
	cl_kernel_arg_type_qualifier* = cl_bitfield;
	cl_kernel_work_group_info* = cl_uint;
	cl_event_info*             = cl_uint;
	cl_command_type*           = cl_uint;
	cl_profiling_info*         = cl_uint;

	cl_image_format* =  RECORD
		image_channel_order*     : cl_channel_order;
		image_channel_data_type* : cl_channel_type;
	END ;
(*	Pcl_image_format*        = POINTER TO ARRAY OF cl_image_format;
	Pcl_context_properties*  = POINTER TO ARRAY OF cl_context_properties;
*)
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
		buffer*: cl_mem;
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

	INVALID_VALUE*						= -30;
	INVALID_DEVICE_TYPE*					= -31;
	INVALID_PLATFORM*					= -32;
	INVALID_DEVICE*                           = -33;
	INVALID_CONTEXT*                          = -34;
	INVALID_QUEUE_PROPERTIES*                 = -35;
	INVALID_COMMAND_QUEUE*                    = -36;
	INVALID_HOST_PTR*                         = -37;
	INVALID_MEM_OBJECT*                       = -38;
	INVALID_IMAGE_FORMAT_DESCRIPTOR*          = -39;
	INVALID_IMAGE_SIZE*                       = -40;
	INVALID_SAMPLER*                          = -41;
	INVALID_BINARY*                           = -42;
	INVALID_BUILD_OPTIONS*                    = -43;
	INVALID_PROGRAM*                          = -44;
	INVALID_PROGRAM_EXECUTABLE*               = -45;
	INVALID_KERNEL_NAME*                      = -46;
	INVALID_KERNEL_DEFINITION*                = -47;
	INVALID_KERNEL*                           = -48;
	INVALID_ARG_INDEX*                        = -49;
	INVALID_ARG_VALUE*                        = -50;
	INVALID_ARG_SIZE*                         = -51;
	INVALID_KERNEL_ARGS*                      = -52;
	INVALID_WORK_DIMENSION*                   = -53;
	INVALID_WORK_GROUP_SIZE*                  = -54;
	INVALID_WORK_ITEM_SIZE*                   = -55;
	INVALID_GLOBAL_OFFSET*                    = -56;
	INVALID_EVENT_WAIT_LIST*                  = -57;
	INVALID_EVENT*                            = -58;
	INVALID_OPERATION*                        = -59;
	INVALID_GL_OBJECT*                        = -60;
	INVALID_BUFFER_SIZE*                      = -61;
	INVALID_MIP_LEVEL*                        = -62;
	INVALID_GLOBAL_WORK_SIZE*       = -63;
	INVALID_PROPERTY* = -64;
	INVALID_IMAGE_DESCRIPTOR* = -65;
	INVALID_COMPILER_OPTIONS* = -66;
	INVALID_LINKER_OPTIONS* = -67;
	INVALID_DEVICE_PARTITION_COUNT* = -68;


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


(* cl_device_type - bitfield*)
CONST
	DEVICE_TYPE_DEFAULT* = ASH(1,0);
	DEVICE_TYPE_CPU* = ASH(1,1);
	DEVICE_TYPE_GPU* =  ASH(1,2);
	DEVICE_TYPE_ACCELERATOR* = ASH(1,3);
	DEVICE_TYPE_CUSTOM* = ASH(1,4);
	DEVICE_TYPE_ALL* = 0FFFFFFFFH;


(* cl_device_info *)
   DEVICE_TYPE*                         = 1000H;
   DEVICE_VENDOR_ID*                         = 1001H;
   DEVICE_MAX_COMPUTE_UNITS*                 = 1002H;
  DEVICE_MAX_WORK_ITEM_DIMENSIONS*          = 1003H;
   DEVICE_MAX_WORK_GROUP_SIZE*               = 1004H;
   DEVICE_MAX_WORK_ITEM_SIZES*               = 1005H;
  DEVICE_PREFERRED_VECTOR_WIDTH_CHAR*       = 1006H;
  DEVICE_PREFERRED_VECTOR_WIDTH_SHORT*      = 1007H;
  DEVICE_PREFERRED_VECTOR_WIDTH_INT*        = 1008H;
  DEVICE_PREFERRED_VECTOR_WIDTH_LONG*       = 1009H;
  DEVICE_PREFERRED_VECTOR_WIDTH_FLOAT*      = 100AH;
  DEVICE_PREFERRED_VECTOR_WIDTH_DOUBLE*     = 100BH;
   DEVICE_MAX_CLOCK_FREQUENCY*               = 100CH;
   DEVICE_ADDRESS_BITS*                      = 100DH;
   DEVICE_MAX_READ_IMAGE_ARGS *              = 100EH;
   DEVICE_MAX_WRITE_IMAGE_ARGS*              = 100FH;
   DEVICE_MAX_MEM_ALLOC_SIZE*                = 1010H;
   DEVICE_IMAGE2D_MAX_WIDTH*                 = 1011H;
   DEVICE_IMAGE2D_MAX_HEIGHT*                = 1012H;
   DEVICE_IMAGE3D_MAX_WIDTH*                 = 1013H;
   DEVICE_IMAGE3D_MAX_HEIGHT*                = 1014H;
   DEVICE_IMAGE3D_MAX_DEPTH*                 = 1015H;
   DEVICE_IMAGE_SUPPORT*                     = 1016H;
   DEVICE_MAX_PARAMETER_SIZE*                = 1017H;
   DEVICE_MAX_SAMPLERS*                      = 1018H;
   DEVICE_MEM_BASE_ADDR_ALIGN*               = 1019H;
  DEVICE_MIN_DATA_TYPE_ALIGN_SIZE*          = 101AH;
   DEVICE_SINGLE_FP_CONFIG*                  = 101BH;
   DEVICE_GLOBAL_MEM_CACHE_TYPE*             = 101CH;
  DEVICE_GLOBAL_MEM_CACHELINE_SIZE*         = 101DH;
   DEVICE_GLOBAL_MEM_CACHE_SIZE*             = 101EH;
   DEVICE_GLOBAL_MEM_SIZE*                   = 101FH;
  DEVICE_MAX_CONSTANT_BUFFER_SIZE*          = 1020H;
   DEVICE_MAX_CONSTANT_ARGS*                 = 1021H;
   DEVICE_LOCAL_MEM_TYPE*               = 1022H;
   DEVICE_LOCAL_MEM_SIZE*                    = 1023H;
  DEVICE_ERROR_CORRECTION_SUPPORT*          = 1024H;
  DEVICE_PROFILING_TIMER_RESOLUTION*        = 1025H;
   DEVICE_ENDIAN_LITTLE*                     = 1026H;
   DEVICE_AVAILABLE*                         = 1027H;
   DEVICE_COMPILER_AVAILABLE*                = 1028H;
  DEVICE_EXECUTION_CAPABILITIES*            = 1029H;
   DEVICE_QUEUE_PROPERTIES*                  = 102AH;
   DEVICE_NAME*                              = 102BH;
   DEVICE_VENDOR*                            = 102CH;
   DRIVER_VERSION*                           = 102DH;
   DEVICE_PROFILE*                           = 102EH;
   DEVICE_VERSION*                           = 102FH;
   DEVICE_EXTENSIONS*                        = 1030H;
   DEVICE_PLATFORM*                          = 1031H;

 DEVICE_DOUBLE_FP_CONFIG* =  1032H;
(* 1033H reserved for DEVICE_HALF_FP_CONFIG *)
 DEVICE_PREFERRED_VECTOR_WIDTH_HALF* =  1034H;
 DEVICE_HOST_UNIFIED_MEMORY* =  1035H;
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

	(* cl_device_fp_config - bitfield *)
	FP_DENORM*                             = ASH(1,0);
	FP_INF_NAN*                               = ASH(1,1);
	FP_ROUND_TO_NEAREST*          = ASH(1,2);
	FP_ROUND_TO_ZERO*                = ASH(1,3);
	FP_ROUND_TO_INF*                    = ASH(1,4);
	FP_FMA*                                      = ASH(1,5);
	FP_SOFT_FLOAT*                         = ASH(1,6);
	FP_CORRECTLY_ROUNDED_DIVIDE_SQRT* = ASH(1,7);

	(* cl_device_mem_cache_type *)
	NONE*                                     = 0H;
	READ_ONLY_CACHE *                         = 1H;
	READ_WRITE_CACHE*                         = 2H;

	(* cl_device_local_mem_type *)
	LOCAL*                                    = 1H;
	GLOBAL*                                   = 2H;

	(* cl_device_exec_capabilities - bitfield *)
	EXEC_KERNEL*                              = ASH(1,0);
	EXEC_NATIVE_KERNEL*                       = ASH(1,1);


	(* cl_command_queue_properties - bitfield*)
	QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE*      = ASH(1,0);
	QUEUE_PROFILING_ENABLE*                   = ASH(1,1);


	(* cl_context_info *)
	CONTEXT_REFERENCE_COUNT*                  = 1080H;
	CONTEXT_DEVICES*                      = 1081H;
	CONTEXT_PROPERTIES*                  = 1082H;
	CONTEXT_NUM_DEVICES*	= 1083H;

	(* cl_context_properties *)
	CONTEXT_PLATFORM*                    = 1084H;
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

	(* cl_command_queue_info *)
	QUEUE_CONTEXT*                            = 1090H;
	QUEUE_DEVICE*                             = 1091H;
	QUEUE_REFERENCE_COUNT*                    = 1092H;
	QUEUE_PROPERTIES*                         = 1093H;

	(* cl_mem_flags - bitfield*)
	MEM_READ_WRITE*                           = ASH(1,0);
	MEM_WRITE_ONLY*                           = ASH(1,1);
	MEM_READ_ONLY*                            = ASH(1,2);
	MEM_USE_HOST_PTR*                         = ASH(1,3);
	MEM_ALLOC_HOST_PTR*                       = ASH(1,4);
	MEM_COPY_HOST_PTR*                        = ASH(1,5);
	(*  reserved                                         ASH(1,6); *)
	MEM_HOST_WRITE_ONLY* = ASH(1,7);
	MEM_HOST_READ_ONLY* = ASH(1,8);
	MEM_HOST_NO_ACCESS* = ASH(1,9);

	(* cl_mem_migration_flags - bitfield *)
	MIGRATE_MEM_OBJECT_HOST* = ASH(1,0);
	MIGRATE_MEM_OBJECT_CONTENT_UNDEFINED* = ASH(1,1);


	(* cl_channel_order *)
	R*                                        = 10B0H;
	A*                                        = 10B1H;
	RG*                                       = 10B2H;
	RA*                                       = 10B3H;
	RGB*                                      = 10B4H;
	RGBA*                                     = 10B5H;
	BGRA*                                     = 10B6H;
	ARGB*                                     = 10B7H;
	INTENSITY*                                = 10B8H;
	LUMINANCE*                                = 10B9H;
	Rx* = 10BAH;
	RGx* = 10BBH;
	RGBx* = 10BCH;

	(* cl_channel_type *)
	SNORM_INT8*                               = 10D0H;
	SNORM_INT16*                              = 10D1H;
	UNORM_INT8*                               = 10D2H;
	UNORM_INT16*                              = 10D3H;
	UNORM_SHORT_565*                          = 10D4H;
	UNORM_SHORT_555*                          = 10D5H;
	UNORM_INT_101010*                         = 10D6H;
	SIGNED_INT8*                              = 10D7H;
	SIGNED_INT16*                             = 10D8H;
	SIGNED_INT32*                             = 10D9H;
	UNSIGNED_INT8*                            = 10DAH;
	UNSIGNED_INT16*                           = 10DBH;
	UNSIGNED_INT32*                           = 10DCH;
	HALF_FLOAT*                               = 10DDH;
	FLOAT*                               = 10DEH;

	(* cl_mem_object_type *)
	MEM_OBJECT_BUFFER*                        = 10F0H;
	MEM_OBJECT_IMAGE2D*                       = 10F1H;
	MEM_OBJECT_IMAGE3D*                       = 10F2H;
	MEM_OBJECT_IMAGE2D_ARRAY* = 10F3H;
	MEM_OBJECT_IMAGE1D* = 10F4H;
	MEM_OBJECT_IMAGE1D_ARRAY* = 10F5H;
	MEM_OBJECT_IMAGE1D_BUFFER* = 10F6H;


	(* cl_mem_info *)
	MEM_TYPE*                                 = 1100H;
	MEM_FLAGS*                           = 1101H;
	MEM_SIZE*                                 = 1102H;
	MEM_HOST_PTR*                             = 1103H;
	MEM_MAP_COUNT*                            = 1104H;
	MEM_REFERENCE_COUNT*                      = 1105H;
	MEM_CONTEXT*                              = 1106H;
	MEM_ASSOCIATED_MEMOBJECT* = 1107H;
	MEM_OFFSET* = 1108H;

	(* cl_image_info*)
	IMAGE_FORMAT*                        = 1110H;
	IMAGE_ELEMENT_SIZE*                       = 1111H;
	IMAGE_ROW_PITCH*                          = 1112H;
	IMAGE_SLICE_PITCH*                        = 1113H;
	IMAGE_WIDTH*                              = 1114H;
	IMAGE_HEIGHT*                             = 1115H;
	IMAGE_DEPTH*                              = 1116H;
	IMAGE_ARRAY_SIZE* = 1117H;
	IMAGE_BUFFER* = 1118H;
	IMAGE_NUM_MIP_LEVELS* = 1119H;
	IMAGE_NUM_SAMPLES* = 111AH;

	(* cl_addressing_mode *)
	ADDRESS_NONE*                             = 1130H;
	ADDRESS_CLAMP_TO_EDGE*                    = 1131H;
	ADDRESS_CLAMP*                            = 1132H;
	ADDRESS_REPEAT*                           = 1133H;
	ADDRESS_MIRRORED_REPEAT* = 1134H;

	(* cl_filter_mode *)
	FILTER_NEAREST*                           = 1140H;
	FILTER_LINEAR*                            = 1141H;

	(* cl_sampler_info *)
	SAMPLER_REFERENCE_COUNT*                  = 1150H;
	SAMPLER_CONTEXT*                          = 1151H;
	SAMPLER_NORMALIZED_COORDS*                = 1152H;
	SAMPLER_ADDRESSING_MODE*                  = 1153H;
	SAMPLER_FILTER_MODE*                      = 1154H;

	(* cl_map_flags - bitfield *)
	MAP_READ*                                 = ASH(1,0);
	MAP_WRITE*                                = ASH(1,1);
	MAP_WRITE_INVALIDATE_REGION* = ASH(1,2);

	(* cl_program_info *)
	PROGRAM_REFERENCE_COUNT*          = 1160H;
	PROGRAM_CONTEXT*                          = 1161H;
	PROGRAM_NUM_DEVICES*                   = 1162H;
	PROGRAM_DEVICES*                            = 1163H;
	PROGRAM_SOURCE*                            = 1164H;
	PROGRAM_BINARY_SIZES*                    = 1165H;
	PROGRAM_BINARIES*                           = 1166H;
	PROGRAM_NUM_KERNELS* = 1167H;
	PROGRAM_KERNEL_NAMES* = 1168H;

	(* cl_program_build_info*)
	PROGRAM_BUILD_STATUS*                    = 1181H;
	PROGRAM_BUILD_OPTIONS*                = 1182H;
	PROGRAM_BUILD_LOG*                        = 1183H;
	PROGRAM_BINARY_TYPE* = 1184H;

	(* cl_program_binary_type *)
	PROGRAM_BINARY_TYPE_NONE* = 0H;
	PROGRAM_BINARY_TYPE_COMPILED_OBJECT* = 1H;
	PROGRAM_BINARY_TYPE_LIBRARY* = 2H;
	PROGRAM_BINARY_TYPE_EXECUTABLE* = 4H;

	(* cl_build_status *)
	BUILD_SUCCESS*                            = 0;
	BUILD_NONE*                               = -1;
	BUILD_ERROR*                              = -2;
	BUILD_IN_PROGRESS*                   = -3;

	(* cl_kernel_info *)
	KERNEL_FUNCTION_NAME*                     = 1190H;
	KERNEL_NUM_ARGS*                          = 1191H;
	KERNEL_REFERENCE_COUNT*                   = 1192H;
	KERNEL_CONTEXT*                           = 1193H;
	KERNEL_PROGRAM*                           = 1194H;
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

	(* cl_kernel_work_group_info *)
	KERNEL_WORK_GROUP_SIZE*                   = 11B0H;
	KERNEL_COMPILE_WORK_GROUP_SIZE*          = 11B1H;
	KERNEL_LOCAL_MEM_SIZE*                    = 11B2H;
	KERNEL_PREFERRED_WORK_GROUP_SIZE_MULTIPLE* = 11B3H;
	KERNEL_PRIVATE_MEM_SIZE* = 11B4H;
	KERNEL_GLOBAL_WORK_SIZE* =11B5H;

	(* cl_event_info *)
	EVENT_COMMAND_QUEUE*                      = 11D0H;
	EVENT_COMMAND_TYPE*                       = 11D1H;
	EVENT_REFERENCE_COUNT*                    = 11D2H;
	EVENT_COMMAND_EXECUTION_STATUS*           = 11D3H;
	EVENT_CONTEXT* = 11DH;

	(* cl_command_type *)
	COMMAND_NDRANGE_KERNEL*                   = 11F0H;
	COMMAND_TASK*                             = 11F1H;
	COMMAND_NATIVE_KERNEL*                    = 11F2H;
	COMMAND_READ_BUFFER*                      = 11F3H;
	COMMAND_WRITE_BUFFER*                     = 11F4H;
	COMMAND_COPY_BUFFER*                      = 11F5H;
	COMMAND_READ_IMAGE*                       = 11F6H;
	COMMAND_WRITE_IMAGE*                      = 11F7H;
	COMMAND_COPY_IMAGE*                       = 11F8H;
	COMMAND_COPY_IMAGE_TO_BUFFER*             = 11F9H;
	COMMAND_COPY_BUFFER_TO_IMAGE*             = 11FAH;
	COMMAND_MAP_BUFFER*                       = 11FBH;
	COMMAND_MAP_IMAGE*                        = 11FCH;
	COMMAND_UNMAP_MEM_OBJECT*                 = 11FDH;
	COMMAND_MARKER*                           = 11FEH;
   	COMMAND_ACQUIRE_GL_OBJECTS*                  = 11FFH;
	COMMAND_RELEASE_GL_OBJECTS*           = 1200H;
	COMMAND_READ_BUFFER_RECT*               = 1201H;
	COMMAND_WRITE_BUFFER_RECT*               = 1202H;
	COMMAND_COPY_BUFFER_RECT* = 1203H;
	COMMAND_USER* = 1204H;
	COMMAND_BARRIER* = 1205H;
	COMMAND_MIGRATE_MEM_OBJECTS* = 1206H;
	COMMAND_FILL_BUFFER* = 1207H;
	COMMAND_FILL_IMAGE* = 1208H;

	(* command execution status *)
	COMPLETE*                                 = 0H;
	RUNNING*                                  = 1H;
	SUBMITTED*                                = 2H;
	QUEUED*                                   = 3H;

	(* cl_buffer_create_type  *)
	BUFFER_CREATE_TYPE_REGION* = 1220H;

	(* cl_profiling_info *)
	PROFILING_COMMAND_QUEUED*                 = 1280H;
	PROFILING_COMMAND_SUBMIT*                 = 1281H;
	PROFILING_COMMAND_START*                  = 1282H;
	PROFILING_COMMAND_END*                    = 1283H;

(* ************************************************************************** *)
(* ************************************************************************** *)
(*! EXTENSIONS, cl_ext.h *)
(* Revision: 11928  on Date: 2010-07-13 09:04:56 -0700 (Tue, 13 Jul 2010)  *)

(* cl_ext.h contains OpenCL extensions which don't have external
 (OpenGL, D3D) dependencies. *)


CONST
	(* cl_khr_fp64 extension - no extension #define since it has no functions  *)
	(*DEVICE_DOUBLE_FP_CONFIG* = 1032H; allready defined above*)

	(* cl_khr_fp16 extension - no extension #define since it has no functions  *)
	DEVICE_HALF_FP_CONFIG* = 1033H;

(* Memory object destruction
 *
 * Apple extension for use to manage externally allocated buffers used with cl_mem objects with CL_MEM_USE_HOST_PTR
 *
 * Registers a user callback function that will be called when the memory object is deleted and its resources
 * freed. Each call to clSetMemObjectCallbackFn registers the specified user callback function on a callback
 * stack associated with memobj. The registered user callback functions are called in the reverse order in
 * which they were registered. The user callback functions are called and then the memory object is deleted
 * and its resources freed. This provides a mechanism for the application (and libraries) using memobj to be
 * notified when the memory referenced by host_ptr, specified when the memory object is created and used as
 * the storage bits for the memory object, can be reused or freed.
 *
 * The application may not call CL api's with the cl_mem object passed to the pfn_notify.
 *
 * Please check for the "cl_APPLE_SetMemObjectDestructor" extension using clGetDeviceInfo(CL_DEVICE_EXTENSIONS)
 * before using.
 *)

	cl_APPLE_SetMemObjectDestructor* = 1;

TYPE TSetMemObjectDestructorAPPLE* = PROCEDURE {WINAPI}(memobj: cl_mem; user_data: ADDRESS);

VAR
clSetMemObjectDestructorAPPLE- :PROCEDURE {WINAPI} ( memobj: cl_mem;
                                        pfn_notify: TSetMemObjectDestructorAPPLE;
                                        user_data: ADDRESS ): cl_int;



 (*! Context Logging Functions *)
 (*
 * The next three convenience functions are intended to be used as the pfn_notify parameter to clCreateContext().
 * Please check for the "cl_APPLE_ContextLoggingFunctions" extension using clGetDeviceInfo(CL_DEVICE_EXTENSIONS)
 * before using.
 *
 * clLogMessagesToSystemLog fowards on all log messages to the Apple System Logger
 *)

CONST cl_APPLE_ContextLoggingFunctions* = 1;

VAR
clLogMessagesToSystemLogAPPLE-: PROCEDURE {WINAPI} (CONST errstr: ARRAY OF CHAR;
                                            private_info: ADDRESS;
                                            cb: size_t;
                                           user_data: ADDRESS);

(* clLogMessagesToStdout sends all log messages to the file descriptor stdout *)
clLogMessagesToStdoutAPPLE-: PROCEDURE {WINAPI} (CONST errstr: ARRAY OF CHAR;
                                            private_info: ADDRESS;
                                            cb: size_t;
                                           user_data: ADDRESS);

(* clLogMessagesToStderr sends all log messages to the file descriptor stderr *)
clLogMessagesToStderrAPPLE-: PROCEDURE {WINAPI} (CONST errstr: ARRAY OF CHAR;
                                            private_info: ADDRESS;
                                            cb: size_t;
                                           user_data: ADDRESS);


(* ***********************
* cl_khr_icd extension *
*********************** *)
CONST
cl_khr_icd* = 1;

(* cl_platform_info    *)
	PLATFORM_ICD_SUFFIX_KHR* =       0920H;

(* Additional Error Codes  *)
	PLATFORM_NOT_FOUND_KHR* =  -1001;

TYPE TclIcdGetPlatformIDsKHRfn* =  PROCEDURE {WINAPI} (num_entries: cl_uint; platforms: cl_platform_id; VAR num_platforms: cl_uint): cl_int;

VAR
clIcdGetPlatformIDsKHR-: PROCEDURE {WINAPI}(num_entries: cl_uint;  platforms:  cl_platform_id;  VAR num_platforms: cl_uint): cl_int;

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
TclGetPlatformIDs* = PROCEDURE {WINAPI} (  num_entries   : cl_uint;     platforms     : ADDRESS;   num_platforms : ADDRESS): cl_int;
TclGetPlatformInfo* =  PROCEDURE {WINAPI} ( iplatform : cl_platform_id;  param_name : cl_platform_info;  value_size : size_t;  value  : ADDRESS;  size_ret : ADDRESS (* size_t *)  ): cl_int;

(*!  Device APIs *)
TclGetDeviceIDs* = PROCEDURE {WINAPI} ( iplatform :  cl_platform_id ; device_type: cl_device_type; num_entries: cl_uint; devices : ADDRESS;    num_devices :  ADDRESS): cl_int;
TclGetDeviceInfo* = PROCEDURE {WINAPI} (device: cl_device_id; param_name: cl_device_info; value_size: size_t; param_value: ADDRESS; size_ret : ADDRESS (* size_t *)): cl_int;


(* VERSION_1_2 *)
TclCreateSubDevices* = PROCEDURE {WINAPI} (in_device: cl_device_id; properties: cl_device_partition_property;
                   num_devices: cl_uint;
                   out_devices: ADDRESS (* cl_device_id*);
                   VAR num_devices_ret: cl_uint ): cl_int;

TclRetainDevice* = PROCEDURE {WINAPI} (device: cl_device_id) : cl_int;
TclReleaseDevice* = PROCEDURE {WINAPI}(device: cl_device_id): cl_int;


(*!  Context APIs *)

  TContextNotify* = PROCEDURE {WINAPI} (name: PChar; data: ADDRESS; size: size_t; data2: ADDRESS);

(* VERSION_1_0 *)
TclCreateContext* = PROCEDURE {WINAPI}(  properties : ADDRESS (*Pcl_context_properties*) ; num_devices  : cl_uint;  devices : ADDRESS;  pfn_notify : ADDRESS (*TContextNotify*) ; user_data: ADDRESS; VAR errcode_ret :  cl_int): cl_context;

TclCreateContextFromType* = PROCEDURE {WINAPI} (
  properties      : ADDRESS; (*Pcl_context_properties *)
  device_type     : cl_device_type;
  pf_notify          : TContextNotify;
  user_data       : ADDRESS;
  VAR errcode_ret :  cl_int
  ): cl_context;

TclRetainContext * = PROCEDURE {WINAPI} (context: cl_context): cl_int;

 TclReleaseContext * = PROCEDURE {WINAPI} (context: cl_context): cl_int;

 TclGetContextInfo* = PROCEDURE {WINAPI}(
  context       : cl_context;
  param_name    : cl_context_info;
  param_value_size    : size_t;
  param_value         : ADDRESS;
  param_value_size_ret  : ADDRESS (* size_t *)
  ): cl_int;

(*!  Command Queue APIs *)
TclCreateCommandQueue* = PROCEDURE {WINAPI}( context : cl_context;  device : cl_device_id;  properties : cl_command_queue_properties ;  VAR errcode_ret:  cl_int ): cl_command_queue;

TclRetainCommandQueue* = PROCEDURE {WINAPI} (command_queue : cl_command_queue): cl_int;
TclReleaseCommandQueue* = PROCEDURE {WINAPI} (command_queue : cl_command_queue): cl_int;

TclGetCommandQueueInfo* = PROCEDURE {WINAPI}(
  command_queue: cl_command_queue;
  param_name   : cl_command_queue_info;
  param_value_size   : size_t;
  param_value        : ADDRESS;
  param_value_size_ret : ADDRESS (* size_t *)
  ): cl_int;


(*!  Memory Object APIs *)
 TclCreateBuffer* = PROCEDURE {WINAPI}(context : cl_context;  flags : cl_mem_flags; size : size_t; host_ptr : ADDRESS; VAR errcode_ret	: cl_int ): cl_mem;


(*VERSION_1_1*)
TclCreateSubBuffer* = PROCEDURE {WINAPI} ( buffer: cl_mem;
                  flags: cl_mem_flags;
                  buffer_create_type: cl_buffer_create_type;
                  buffer_create_info: ADDRESS;
                  VAR errcode_ret: cl_int): cl_mem;

(*  VERSION_1_2 *)
 TclCreateImage* = PROCEDURE {WINAPI} (context: cl_context;
              flags: cl_mem_flags;
              image_format: cl_image_format;
              image_desc: cl_image_desc;
              host_ptr: ADDRESS;
              VAR errcode_ret: cl_int): cl_mem;

(* VERSION_1_0 *)
TclRetainMemObject* = PROCEDURE {WINAPI} (memobj: cl_mem): cl_int;
TclReleaseMemObject* = PROCEDURE {WINAPI} (memobj: cl_mem): cl_int;

TclGetSupportedImageFormats* = PROCEDURE {WINAPI}(
  context		    	: cl_context;
  flags 			    : cl_mem_flags;
  image_type 		  : cl_mem_object_type;
  num_entries 		: cl_uint;
  image_formats   : ADDRESS; (* Pcl_image_format *)
   num_image_formats : cl_uint
  ): cl_int;

 TclGetMemObjectInfo* = PROCEDURE {WINAPI} (
  image      	: cl_mem;
  param_name    : cl_mem_info;
  param_value_size    : size_t;
  param_value     	  : ADDRESS;
   param_value_size_ret  : ADDRESS (* size_t *)
  ): cl_int;

TclGetImageInfo* = PROCEDURE {WINAPI}(
  image         : cl_mem;
  param_name    : cl_image_info;
  param_value_size  : size_t;
  param_value         : ADDRESS;
   param_value_size_ret  : ADDRESS (* size_t *)
  ): cl_int;

(* VERSION_1_1 *)
 TMemObjectDestructorCallback* = PROCEDURE {WINAPI} (memobj: cl_mem; user_data:ADDRESS);

TclSetMemObjectDestructorCallback* = PROCEDURE {WINAPI} (memobj: cl_mem;
                                    pfn_notify: TMemObjectDestructorCallback;
                                    user_data: ADDRESS):  cl_int;


(*!  Sampler APIs *)
(* VERSION_1_0*)
TclCreateSampler* = PROCEDURE {WINAPI} (
  context         : cl_context;
  normalized_coords  : cl_bool;
  addressing_mode       : cl_addressing_mode;
  filter_mode     : cl_filter_mode;
   VAR errcode_ret :  cl_int
  ): cl_sampler;

TclRetainSampler* = PROCEDURE {WINAPI} (sampler: cl_sampler): cl_int;

 TclReleaseSampler* = PROCEDURE {WINAPI} (sampler: cl_sampler): cl_int;

 TclGetSamplerInfo* = PROCEDURE {WINAPI}(
  sampler      : cl_sampler;
  param_name   : cl_sampler_info;
  param_value_size   : size_t;
  param_value        : ADDRESS;
   param_value_size_ret : ADDRESS (* size_t *)
  ): cl_int;


(*!  Program Object APIs *)
TclCreateProgramWithSource* = PROCEDURE {WINAPI}( context  : cl_context;  count  : cl_uint; strings : ADDRESS; lengths  : ADDRESS (*Psize_t*);   VAR errcode_ret :  cl_int  ): cl_program;

  PByte* = POINTER TO ARRAY OF CHAR;
  PPByte* = POINTER TO ARRAY OF PByte;


TclCreateProgramWithBinary* = PROCEDURE {WINAPI} (
  context     : cl_context;
  num_devices : cl_uint;
  device_list : ADDRESS; (*Pcl_device_id *)
  lengths     : ADDRESS; (*Psize_t *)
  binaries    : ADDRESS; (*PPByte *)
  binary_status: ADDRESS; (* cl_int *)
  VAR errcode_ret: cl_int
  ): cl_program;

(* VERSION_1_2 *)
TclCreateProgramWithBuiltInKernels* = PROCEDURE {WINAPI}(context: cl_context;
                                  num_devices: cl_uint;
                                  device_list: cl_device_id;
                                  kernel_names: PChar;
                                  VAR errcode_ret: cl_int): cl_program;

(* VERSION_1_0 *)
TclRetainProgram* = PROCEDURE {WINAPI} (iprogram: cl_program): cl_int;
TclReleaseProgram* = PROCEDURE {WINAPI} (iprogram: cl_program): cl_int;

TProgramNotify* =  PROCEDURE {WINAPI} (iprogram: cl_program; user_data: ADDRESS);

TclBuildProgram* = PROCEDURE {WINAPI} (iprogram: cl_program; num_devices:  cl_uint;  device_list: ADDRESS; CONST options: ARRAY OF CHAR; notify: ADDRESS (*TProgramNotify*);  user_data: ADDRESS ): cl_int;

(* VERSION_1_2 *)
TclCompileProgram* = PROCEDURE {WINAPI}(program: cl_program;
                 num_devices: cl_uint;
                 device_list: ADDRESS (*cl_device_id*);
                 CONST options: ARRAY OF CHAR;
                 num_input_headers: cl_uint;
                 input_headers: ADDRESS (* cl_program*);
                 header_include_names: ADDRESS;
                pfn_notify :TProgramNotify;
                 user_data: ADDRESS): cl_int;

TclLinkProgram* = PROCEDURE {WINAPI}(context: cl_context;
              num_devices: cl_uint;
              device_list: ADDRESS (*cl_device_id*);
              CONST options: ARRAY OF CHAR;
              num_input_programs: cl_uint;
              input_programs: ADDRESS (*cl_program *);
              pfn_notify:TProgramNotify;
              user_data: ADDRESS;
              VAR errcode_ret: cl_int ): cl_program;

TclUnloadPlatformCompiler* = PROCEDURE {WINAPI}(platform: cl_platform_id ): cl_int;

(* VERSION_1_0*)
TclGetProgramInfo* = PROCEDURE {WINAPI} (
  iprogram : cl_program;
  param_name: cl_program_info;
  param_value_size: size_t;
  param_value         : ADDRESS;
   param_value_size_ret  : ADDRESS (* size_t *)
  ): cl_int;

TclGetProgramBuildInfo* = PROCEDURE {WINAPI} (
  iprogram      : cl_program;
  device        : cl_device_id;
  param_name    : cl_program_build_info;
  param_value_size    : size_t;
  param_value         : ADDRESS;
   param_value_size_ret  : ADDRESS (* size_t *)
  ): cl_int;

(*!  Kernel Object APIs *)
TclCreateKernel* = PROCEDURE {WINAPI}(iprogram: cl_program;   CONST kernel_name: ARRAY OF CHAR;   VAR  errcode_ret: cl_int ): cl_kernel;

TclCreateKernelsInProgram* = PROCEDURE {WINAPI} (
  iprogram      : cl_program;
  num_kernels   : cl_uint;
  kernels       : ADDRESS; (*Pcl_kernel *)
  num_kernels_ret   : ADDRESS (* cl_uint *)
  ): cl_int;

TclRetainKernel* = PROCEDURE {WINAPI} (kernel: cl_kernel): cl_int;
TclReleaseKernel* = PROCEDURE {WINAPI} (kernel: cl_kernel): cl_int;

 TclSetKernelArg* = PROCEDURE {WINAPI} (
  kernel    : cl_kernel;
  arg_index : cl_uint;
  arg_size  : size_t;
  arg_value : ADDRESS
  ): cl_int;

TclGetKernelInfo* = PROCEDURE {WINAPI} (
  kernel        : cl_kernel;
  param_name    : cl_kernel_info;
  param_value_size    : size_t;
  param_value         : ADDRESS;
  param_value_size_ret  : ADDRESS (* size_t *)
  ): cl_int;

(* VERSION_1_2 *)
TclGetKernelArgInfo* = PROCEDURE {WINAPI}(kernel: cl_kernel;
                   arg_indx: cl_uint;
                   param_name: cl_kernel_arg_info;
                   param_value_size: size_t;
                   param_value: ADDRESS;
                   param_value_size_ret: ADDRESS): cl_int;

TclGetKernelWorkGroupInfo* = PROCEDURE {WINAPI}(kernel: cl_kernel; device: cl_device_id; param_name: cl_kernel_work_group_info; value_size: size_t; value: ADDRESS; size_ret : ADDRESS ): cl_int;

(*!  Event Object APIs *)
TclWaitForEvents* = PROCEDURE {WINAPI} (
  num_events  : cl_uint;
  event_list  : ADDRESS
  ): cl_int;

 TclGetEventInfo* = PROCEDURE {WINAPI} (
  event         : cl_event;
  param_name    : cl_event_info;
  param_value_size    : size_t;
  param_value         : ADDRESS;
  param_value_size_ret  : ADDRESS (* size_t *)
  ): cl_int;

(* VERSION_1_1 *)
TclCreateUserEvent* = PROCEDURE {WINAPI}(context: cl_context; VAR errcode_ret: cl_int): cl_event;

(* VERSION_1_0 *)
TclRetainEvent* = PROCEDURE {WINAPI} (event: cl_event): cl_int;
TclReleaseEvent* = PROCEDURE {WINAPI} (event: cl_event): cl_int;

(* VERSION_1_1 *)
TclSetUserEventStatus* = PROCEDURE {WINAPI}(event: cl_event; execution_status: cl_int): cl_int;

TSetEventCallback* = PROCEDURE (event: cl_event; user_data: ADDRESS);

TclSetEventCallback* = PROCEDURE {WINAPI}( event: cl_event;
                    command_exec_callback_type: cl_int;
                    pfn_notify: TSetEventCallback;
                    user_data: ADDRESS): cl_int;

(*!  Profiling APIs *)
TclGetEventProfilingInfo * = PROCEDURE {WINAPI} (
  event         : cl_event;
  param_name    : cl_profiling_info;
  param_value_size    : size_t;
  param_value         : ADDRESS;
  param_value_size_ret  : ADDRESS (* size_t *)
  ): cl_int;


(*!  Flush and Finish APIs *)
 TclFlush * = PROCEDURE {WINAPI} (command_queue: cl_command_queue): cl_int;
 TclFinish* = PROCEDURE {WINAPI} (command_queue: cl_command_queue): cl_int;

  (*!  Enqueued Commands APIs *)
TclEnqueueReadBuffer* = PROCEDURE {WINAPI} (
  command_queue : cl_command_queue;
  buffer        : cl_mem;
  blocking_read : cl_bool;
  offset        : size_t;
  cb            : size_t;
  ptr           : ADDRESS;
  num_events_in_wait_list    : cl_uint;
  event_wait_list   :ADDRESS ;
  event         : ADDRESS
  ): cl_int;



(* VERSION_1_1 *)
TclEnqueueReadBufferRect * = PROCEDURE {WINAPI} (command_queue: cl_command_queue;
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
                        event: ADDRESS (*cl_event*)):cl_int;


TclEnqueueWriteBuffer * = PROCEDURE {WINAPI} ( command_queue: cl_command_queue;
	buffer : cl_mem;
	blocking_write : cl_bool;
	offset : size_t;
  	cb              : size_t;
  	ptr             : ADDRESS;
  	num_events_in_wait_list      : cl_uint;
  	event_wait_list     : ADDRESS;
  	event           : ADDRESS
  	): cl_int;

(* VERSION_1_1*)
TclEnqueueWriteBufferRect* = PROCEDURE {WINAPI} (command_queue: cl_command_queue;
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
                         event: ADDRESS (*cl_event *)): cl_int;

TclEnqueueFillBuffer* = PROCEDURE {WINAPI}(command_queue: cl_command_queue;
                    buffer: cl_mem;
                    pattern: ADDRESS;
                    pattern_size: size_t;
                    offset: size_t;
                    size: size_t;
                    num_events_in_wait_list: cl_uint;
                    event_wait_list: ADDRESS (* cl_event *);
                    event: ADDRESS (*cl_event *)): cl_int;

TclEnqueueCopyBuffer* = PROCEDURE {WINAPI} (
	command_queue : cl_command_queue;
	src_buffer    : cl_mem;
	dst_buffer    : cl_mem;
	src_offset    : size_t;
	dst_offset    : size_t;
	sizex            : size_t;
	num_events_in_wait_list    : cl_uint;
	event_wait_list   : ADDRESS; (*Pcl_event*)
	event         : ADDRESS (*Pcl_event *)
  ): cl_int;

TclEnqueueCopyBufferRect* = PROCEDURE {WINAPI}(command_queue: cl_command_queue;
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
                       event: ADDRESS(*cl_event *)): cl_int;

TclEnqueueReadImage * = PROCEDURE {WINAPI} (
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
	event         : ADDRESS (*Pcl_event*)
	): cl_int;

TclEnqueueWriteImage * = PROCEDURE {WINAPI} (
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
	event           : ADDRESS (*Pcl_event*)
	): cl_int;

(* VERSION_1_2 *)
TclEnqueueFillImage* = PROCEDURE {WINAPI} (command_queue: cl_command_queue;
                   image: cl_mem;
                   fill_color: ADDRESS;
                   origin: ADDRESS; (* origin[3] *)
                   region: ADDRESS;(* region[3] *)
                   num_events_in_wait_list: cl_uint;
                   event_wait_list: ADDRESS (*cl_event *);
                   event: ADDRESS (*cl_event *)): cl_int;

TclEnqueueCopyImage* = PROCEDURE {WINAPI} (
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

TclEnqueueCopyImageToBuffer* = PROCEDURE {WINAPI} (
  command_queue : cl_command_queue;
  src_image     : cl_mem;
  dst_buffer    : cl_mem;
  src_origin    : ADDRESS; (* src_origin[3] *)
  region        : ADDRESS; (* region[3] *)
  dst_offset    : size_t;
  num_events_in_wait_list    : cl_uint;
  event_wait_list     : ADDRESS; (*Pcl_event;*)
  event           : ADDRESS (*Pcl_event*)
  ): cl_int;

TclEnqueueCopyBufferToImage* = PROCEDURE {WINAPI}(
 command_queue : cl_command_queue;
  src_buffer    : cl_mem;
  dst_image     : cl_mem;
  src_offset    : size_t;
  dst_origin    : ADDRESS; (* dst_origin[3] *)
  region        : ADDRESS; (* region[3] *)
  num_events_in_wait_list    : cl_uint;
  event_wait_list     : ADDRESS; (*Pcl_event;*)
  event           : ADDRESS (*Pcl_event*)
  ): cl_int;

TclEnqueueMapBuffer* = PROCEDURE {WINAPI}(
  command_queue   : cl_command_queue;
  buffer          : cl_mem;
  blocking_map    : cl_bool;
  map_flags       : cl_map_flags;
  offset          : size_t;
  sizex              : size_t;
  num_events_in_wait_list      : cl_uint;
  event_wait_list     : ADDRESS; (*Pcl_event;*)
  event           : ADDRESS; (*Pcl_event*)
   VAR errcode_ret		: cl_int
  ): ADDRESS;

TclEnqueueMapImage* = PROCEDURE {WINAPI}(
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

TclEnqueueUnmapMemObject* = PROCEDURE {WINAPI}(
  command_queue : cl_command_queue;
  memobj        : cl_mem;
  mapped_ptr    : ADDRESS;
  num_events_in_wait_list    : cl_uint;
  event_wait_list     : ADDRESS; (*Pcl_event;*)
  event           : ADDRESS (*Pcl_event*)
   ): cl_int;

(* VERSION_1_2 *)
TclEnqueueMigrateMemObjects* = PROCEDURE {WINAPI}(command_queue: cl_command_queue;
                           num_mem_objects: cl_uint;
                           mem_objects: ADDRESS (* cl_mem *);
                           flags: cl_mem_migration_flags;
                           num_events_in_wait_list: cl_uint;
                           event_wait_list: ADDRESS (*cl_event *);
                           event: ADDRESS (*cl_event *)): cl_int;

TclEnqueueNDRangeKernel* = PROCEDURE {WINAPI}(
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

TclEnqueueTask* = PROCEDURE {WINAPI}(
  command_queue : cl_command_queue;
  kernel        : cl_kernel;
  num_events_in_wait_list    : cl_uint;
  event_wait_list     : ADDRESS; (*Pcl_event;*)
  event           : ADDRESS (*Pcl_event*)
  ): cl_int;

TEnqueueNativeKernel* =  PROCEDURE {WINAPI} (userdata: ADDRESS);

TclEnqueueNativeKernel* = PROCEDURE {WINAPI} (
  command_queue   : cl_command_queue;
  user_func       : TEnqueueNativeKernel;
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
TclEnqueueMarkerWithWaitList* = PROCEDURE {WINAPI} (command_queue: cl_command_queue;
                            num_events_in_wait_list: cl_uint;
                            event_wait_list: ADDRESS (*cl_event *);
                            event: ADDRESS (*cl_event *)): cl_int;

TclEnqueueBarrierWithWaitList* = PROCEDURE {WINAPI} (command_queue: cl_command_queue;
                             num_events_in_wait_list: cl_uint;
                           event_wait_list: ADDRESS (*cl_event *);
                            event: ADDRESS (*cl_event *)): cl_int;

TSetPrintfCallback* = PROCEDURE (program: cl_context;  printf_data_len: cl_uint; printf_data_ptr: PChar; user_data: ADDRESS);

TclSetPrintfCallback* = PROCEDURE {WINAPI} (context: cl_context; pfn_notify: TSetPrintfCallback; user_data: ADDRESS): cl_int;

(*! Extension function access*)
 (*
 * Returns the extension function address for the given function name,
 * or NULL if a valid function can not be found.  The client must
 * check to make sure the address is not NULL, before using or
 * calling the returned function address.
 *)

(* VERSION_1_2 *)
TclGetExtensionFunctionAddressForPlatform* = PROCEDURE {WINAPI} (platform: cl_platform_id; CONST func_name:  ARRAY OF CHAR): ADDRESS;


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
  TclSetCommandQueueProperty* = PROCEDURE {WINAPI}(
  command_queue       : cl_command_queue;
  properties          : cl_command_queue_properties;
  enable              : cl_bool;
  VAR old_properties  : cl_command_queue_properties
  ): cl_int;

(*  VERSION_1_1_DEPRECATED *)
 TclCreateImage2D* = PROCEDURE {WINAPI}(
  context         : cl_context;
  flags   	      : cl_mem_flags;
  CONST image_format    : cl_image_format;
  image_width     : size_t;
  image_height    : size_t;
  image_row_pitch : size_t;
  host_ptr        : ADDRESS;
   VAR errcode_ret		: cl_int
  ): cl_mem;

TclCreateImage3D* = PROCEDURE {WINAPI}(
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

	TclEnqueueMarker* = PROCEDURE {WINAPI} (command_queue: cl_command_queue; event: ADDRESS ): cl_int;
	TclEnqueueWaitForEvents* = PROCEDURE {WINAPI} (command_queue: cl_command_queue; num_events: cl_uint; event_list: ADDRESS ): cl_int;
	TclEnqueueBarrier* = PROCEDURE {WINAPI} (command_queue: cl_command_queue): cl_int;

	TclUnloadCompiler* = PROCEDURE {WINAPI}(): cl_int;
	TclGetExtensionFunctionAddress* = PROCEDURE {WINAPI}(CONST funcname: ARRAY OF CHAR): ADDRESS;

VAR
	(* Platform APIs *)
	clGetPlatformIDs- : TclGetPlatformIDs;
	clGetPlatformInfo- : TclGetPlatformInfo;
	(*  Device APIs *)
	clGetDeviceIDs- : TclGetDeviceIDs;
	clGetDeviceInfo- : TclGetDeviceInfo;
	clCreateSubDevices- : TclCreateSubDevices;
	clRetainDevice- : TclRetainDevice;
	clReleaseDevice- : TclReleaseDevice;
	(*  Context APIs *)
	clCreateContext- : TclCreateContext;
	clCreateContextFromType- : TclCreateContextFromType;
	clRetainContext- : TclRetainContext;
	clReleaseContext- : TclReleaseContext;
	clGetContextInfo- : TclGetContextInfo;
	(*  Command Queue APIs *)
	clCreateCommandQueue- : TclCreateCommandQueue;
	clRetainCommandQueue- : TclRetainCommandQueue;
	clReleaseCommandQueue- : TclReleaseCommandQueue;
	clGetCommandQueueInfo- : TclGetCommandQueueInfo;
	(*  Memory Object APIs *)
	clCreateBuffer- : TclCreateBuffer;
	clCreateSubBuffer- : TclCreateSubBuffer;
	clCreateImage- : TclCreateImage;
	clRetainMemObject- : TclRetainMemObject;
	clReleaseMemObject- : TclReleaseMemObject;
	clGetSupportedImageFormats- : TclGetSupportedImageFormats;
	clGetMemObjectInfo- : TclGetMemObjectInfo;
	clGetImageInfo- : TclGetImageInfo;
	clSetMemObjectDestructorCallback- : TclSetMemObjectDestructorCallback;
	(*  Sampler APIs *)
	clCreateSampler- : TclCreateSampler;
	clRetainSampler- : TclRetainSampler;
	clReleaseSampler- : TclReleaseSampler;
	clGetSamplerInfo- : TclGetSamplerInfo;
	(*  Program Object APIs *)
	clCreateProgramWithSource- : TclCreateProgramWithSource;
	clCreateProgramWithBinary- : TclCreateProgramWithBinary;
	clCreateProgramWithBuiltInKernels- : TclCreateProgramWithBuiltInKernels;
	clRetainProgram- : TclRetainProgram;
	clReleaseProgram- : TclReleaseProgram;
	clBuildProgram- : TclBuildProgram;
	clCompileProgram- : TclCompileProgram;
	clLinkProgram- : TclLinkProgram;
	clUnloadPlatformCompiler- : TclUnloadPlatformCompiler;
	clGetProgramInfo- : TclGetProgramInfo;
	clGetProgramBuildInfo- : TclGetProgramBuildInfo;
	(*  Kernel Object APIs *)
	clCreateKernel- : TclCreateKernel;
	clCreateKernelsInProgram- : TclCreateKernelsInProgram;
	clRetainKernel- : TclRetainKernel;
	clReleaseKernel- : TclReleaseKernel;
	clSetKernelArg- : TclSetKernelArg;
	clGetKernelInfo- : TclGetKernelInfo;
	clGetKernelArgInfo- : TclGetKernelArgInfo;
	clGetKernelWorkGroupInfo- : TclGetKernelWorkGroupInfo;
	(*  Event Object APIs *)
	clWaitForEvents- : TclWaitForEvents;
	clGetEventInfo- : TclGetEventInfo;
	clCreateUserEvent- : TclCreateUserEvent;
	clRetainEvent- : TclRetainEvent;
	clReleaseEvent- : TclReleaseEvent;
	clSetUserEventStatus- : TclSetUserEventStatus;
	clSetEventCallback- : TclSetEventCallback;
	(*  Profiling APIs *)
	clGetEventProfilingInfo- : TclGetEventProfilingInfo;
	(*  Flush and Finish APIs *)
	clFlush- : TclFlush;
	clFinish- : TclFinish;
	(*  Enqueued Commands APIs *)
	clEnqueueReadBuffer- : TclEnqueueReadBuffer;
	clEnqueueReadBufferRect- : TclEnqueueReadBufferRect;
	clEnqueueWriteBuffer- : TclEnqueueWriteBuffer;
	clEnqueueWriteBufferRect- : TclEnqueueWriteBufferRect;
	clEnqueueFillBuffer- : TclEnqueueFillBuffer;
	clEnqueueCopyBuffer- : TclEnqueueCopyBuffer;
	clEnqueueCopyBufferRect- : TclEnqueueCopyBufferRect;
	clEnqueueReadImage- : TclEnqueueReadImage;
	clEnqueueWriteImage- : TclEnqueueWriteImage;
	clEnqueueFillImage- : TclEnqueueFillImage;
	clEnqueueCopyImage- : TclEnqueueCopyImage;
	clEnqueueCopyImageToBuffer- : TclEnqueueCopyImageToBuffer;
	clEnqueueCopyBufferToImage- : TclEnqueueCopyBufferToImage;
	clEnqueueMapBuffer- : TclEnqueueMapBuffer;
	clEnqueueMapImage- : TclEnqueueMapImage;
	clEnqueueUnmapMemObject- : TclEnqueueUnmapMemObject;
	clEnqueueMigrateMemObjects- : TclEnqueueMigrateMemObjects;
	clEnqueueNDRangeKernel- : TclEnqueueNDRangeKernel;
	clEnqueueTask- : TclEnqueueTask;
	clEnqueueNativeKernel- : TclEnqueueNativeKernel;
	clEnqueueMarkerWithWaitList - : TclEnqueueMarkerWithWaitList;
	clEnqueueBarrierWithWaitList- : TclEnqueueBarrierWithWaitList;
	clSetPrintfCallback- : TclSetPrintfCallback;
	(* Extension function access*)
	clGetExtensionFunctionAddressForPlatform- : TclGetExtensionFunctionAddressForPlatform;

	(*! DEPRECATED functions *)
	(*  Command Queue APIs *)
	clSetCommandQueueProperty- : TclSetCommandQueueProperty;
	(*  Memory Object APIs *)
	clCreateImage2D- : TclCreateImage2D;
	clCreateImage3D- : TclCreateImage3D;
	(*  Enqueued Commands APIs *)
	clEnqueueMarker- : TclEnqueueMarker;
	clEnqueueWaitForEvents- : TclEnqueueWaitForEvents;
	clEnqueueBarrier- : TclEnqueueBarrier;
	(*  Program Object APIs *)
	clUnloadCompiler- : TclUnloadCompiler;
	(* Extension function access*)
	clGetExtensionFunctionAddress- : TclGetExtensionFunctionAddress;


(* winaos Kernel32.GetProcAddress function wrapper *)
PROCEDURE GetProcAddress*(CONST fname: ARRAY OF CHAR): ADDRESS;
VAR adres: ADDRESS;
BEGIN
	Kernel32.GetProcAddress(lib, fname, adres);
	IF ( adres=0) & debug THEN
		KernelLog.String("ERROR: function: "); KernelLog.String(fname); KernelLog.String(" NOT found");  KernelLog.Ln;
	END;
	ASSERT(adres # 0, 301);
	RETURN adres;
END GetProcAddress;


 (*! *********************************** *)

PROCEDURE Init;
BEGIN
	(* load the DLL *)
	lib := Kernel32.LoadLibrary(libname);
	IF lib = 0 THEN
		KernelLog.String("ERROR: ");KernelLog.String(libname); KernelLog.String(" NOT loaded.");  KernelLog.Ln;
	END;
	ASSERT(lib # 0, 300);
	KernelLog.String(libname); KernelLog.String(" loaded.");  KernelLog.Ln;

	(* Platform APIs *)
	clGetPlatformIDs := S.VAL(TclGetPlatformIDs, GetProcAddress("clGetPlatformIDs"));
	clGetPlatformInfo := S.VAL(TclGetPlatformInfo, GetProcAddress("clGetPlatformInfo"));

	(*  Device APIs *)
	clGetDeviceIDs := S.VAL(TclGetDeviceIDs, GetProcAddress("clGetDeviceIDs"));
	clGetDeviceInfo := S.VAL(TclGetDeviceInfo, GetProcAddress("clGetDeviceInfo"));
	IF VERSION_1_2 THEN
		clCreateSubDevices := S.VAL(TclCreateSubDevices, GetProcAddress("clCreateSubDevices"));
		clRetainDevice := S.VAL(TclRetainDevice, GetProcAddress("clRetainDevice"));
		clReleaseDevice := S.VAL(TclReleaseDevice, GetProcAddress("clReleaseDevice"));
	END;
	(*  Context APIs *)
	clCreateContext := S.VAL(TclCreateContext, GetProcAddress("clCreateContext"));
	clCreateContextFromType := S.VAL(TclCreateContextFromType, GetProcAddress("clCreateContextFromType"));
	clRetainContext := S.VAL(TclRetainContext, GetProcAddress("clRetainContext"));
	clReleaseContext := S.VAL(TclReleaseContext, GetProcAddress("clReleaseContext"));
	clGetContextInfo := S.VAL(TclGetContextInfo, GetProcAddress("clGetContextInfo"));

	(*  Command Queue APIs *)
	clCreateCommandQueue := S.VAL(TclCreateCommandQueue, GetProcAddress("clCreateCommandQueue"));
	clRetainCommandQueue := S.VAL(TclRetainCommandQueue, GetProcAddress("clRetainCommandQueue"));
	clReleaseCommandQueue := S.VAL(TclReleaseCommandQueue, GetProcAddress("clReleaseCommandQueue"));
	clGetCommandQueueInfo := S.VAL(TclGetCommandQueueInfo, GetProcAddress("clGetCommandQueueInfo"));

	(*  Memory Object APIs *)
	clCreateBuffer := S.VAL(TclCreateBuffer, GetProcAddress("clCreateBuffer"));
	IF VERSION_1_1 THEN
		clCreateSubBuffer := S.VAL(TclCreateSubBuffer, GetProcAddress("clCreateSubBuffer"));
	END;

	IF VERSION_1_2 THEN
		clCreateImage := S.VAL(TclCreateImage, GetProcAddress("clCreateImage"));
	END;

	clRetainMemObject := S.VAL(TclRetainMemObject, GetProcAddress("clRetainMemObject"));
	clReleaseMemObject := S.VAL(TclReleaseMemObject, GetProcAddress("clReleaseMemObject"));
	clGetSupportedImageFormats := S.VAL(TclGetSupportedImageFormats, GetProcAddress("clGetSupportedImageFormats"));
	clGetMemObjectInfo := S.VAL(TclGetMemObjectInfo, GetProcAddress("clGetMemObjectInfo"));
	clGetImageInfo := S.VAL(TclGetImageInfo, GetProcAddress("clGetImageInfo"));
	IF VERSION_1_1 THEN
		clSetMemObjectDestructorCallback := S.VAL(TclSetMemObjectDestructorCallback, GetProcAddress("clSetMemObjectDestructorCallback"));
	END;

	(*  Sampler APIs *)
	clCreateSampler := S.VAL(TclCreateSampler, GetProcAddress("clCreateSampler"));
	clRetainSampler := S.VAL(TclRetainSampler, GetProcAddress("clRetainSampler"));
	clReleaseSampler := S.VAL(TclReleaseSampler, GetProcAddress("clReleaseSampler"));
	clGetSamplerInfo := S.VAL(TclGetSamplerInfo, GetProcAddress("clGetSamplerInfo"));

	(*  Program Object APIs *)
	clCreateProgramWithSource := S.VAL(TclCreateProgramWithSource, GetProcAddress("clCreateProgramWithSource"));
	clCreateProgramWithBinary := S.VAL(TclCreateProgramWithBinary, GetProcAddress("clCreateProgramWithBinary"));

	IF VERSION_1_2 THEN
		clCreateProgramWithBuiltInKernels := S.VAL(TclCreateProgramWithBuiltInKernels, GetProcAddress("clCreateProgramWithBuiltInKernels"));
	END;

	clRetainProgram := S.VAL(TclRetainProgram, GetProcAddress("clRetainProgram"));
	clReleaseProgram := S.VAL(TclReleaseProgram, GetProcAddress("clReleaseProgram"));
	clBuildProgram := S.VAL(TclBuildProgram, GetProcAddress("clBuildProgram"));
	IF VERSION_1_2 THEN
		clCompileProgram := S.VAL(TclCompileProgram, GetProcAddress("clCompileProgram"));
		clLinkProgram := S.VAL(TclLinkProgram, GetProcAddress("clLinkProgram"));
		clUnloadPlatformCompiler := S.VAL(TclUnloadPlatformCompiler, GetProcAddress("clUnloadPlatformCompiler"));
	END;

	clGetProgramInfo := S.VAL(TclGetProgramInfo, GetProcAddress("clGetProgramInfo"));
	clGetProgramBuildInfo := S.VAL(TclGetProgramBuildInfo, GetProcAddress("clGetProgramBuildInfo"));

	(*  Kernel Object APIs *)
	clCreateKernel := S.VAL(TclCreateKernel, GetProcAddress("clCreateKernel"));
	clCreateKernelsInProgram := S.VAL(TclCreateKernelsInProgram, GetProcAddress("clCreateKernelsInProgram"));
	clRetainKernel := S.VAL(TclRetainKernel, GetProcAddress("clRetainKernel"));
	clReleaseKernel := S.VAL(TclReleaseKernel, GetProcAddress("clReleaseKernel"));
	clSetKernelArg := S.VAL(TclSetKernelArg, GetProcAddress("clSetKernelArg"));
	clGetKernelInfo := S.VAL(TclGetKernelInfo, GetProcAddress("clGetKernelInfo"));
	IF VERSION_1_2 THEN
		clGetKernelArgInfo := S.VAL(TclGetKernelArgInfo, GetProcAddress("clGetKernelArgInfo"));
	END;
	clGetKernelWorkGroupInfo := S.VAL(TclGetKernelWorkGroupInfo, GetProcAddress("clGetKernelWorkGroupInfo"));

	(*  Event Object APIs *)
	clWaitForEvents := S.VAL(TclWaitForEvents, GetProcAddress("clWaitForEvents"));
	clGetEventInfo := S.VAL(TclGetEventInfo, GetProcAddress("clGetEventInfo"));
	IF VERSION_1_1 THEN
		clCreateUserEvent := S.VAL(TclCreateUserEvent, GetProcAddress("clCreateUserEvent"));
	END;
	clRetainEvent := S.VAL(TclRetainEvent, GetProcAddress("clRetainEvent"));
	clReleaseEvent := S.VAL(TclReleaseEvent, GetProcAddress("clReleaseEvent"));
	IF VERSION_1_1 THEN
		clSetUserEventStatus := S.VAL(TclSetUserEventStatus, GetProcAddress("clSetUserEventStatus"));
		clSetEventCallback := S.VAL(TclSetEventCallback, GetProcAddress("clSetEventCallback"));
	END;

	(*  Profiling APIs *)
	clGetEventProfilingInfo := S.VAL(TclGetEventProfilingInfo, GetProcAddress("clGetEventProfilingInfo"));

	(*  Flush and Finish APIs *)
	clFlush := S.VAL(TclFlush, GetProcAddress("clFlush"));
	clFinish := S.VAL(TclFinish, GetProcAddress("clFinish"));

	(*  Enqueued Commands APIs *)
	clEnqueueReadBuffer := S.VAL(TclEnqueueReadBuffer, GetProcAddress("clEnqueueReadBuffer"));
	IF VERSION_1_1 THEN
		clEnqueueReadBufferRect := S.VAL(TclEnqueueReadBufferRect, GetProcAddress("clEnqueueReadBufferRect"));
	END;
	clEnqueueWriteBuffer := S.VAL(TclEnqueueWriteBuffer, GetProcAddress("clEnqueueWriteBuffer"));
	IF VERSION_1_1 THEN
		clEnqueueWriteBufferRect := S.VAL(TclEnqueueWriteBufferRect, GetProcAddress("clEnqueueWriteBufferRect"));
	END;
	IF VERSION_1_2 THEN
		clEnqueueFillBuffer := S.VAL(TclEnqueueFillBuffer, GetProcAddress("clEnqueueFillBuffer"));
	END;
	clEnqueueCopyBuffer := S.VAL(TclEnqueueCopyBuffer, GetProcAddress("clEnqueueCopyBuffer"));
	IF VERSION_1_1 THEN
		clEnqueueCopyBufferRect := S.VAL(TclEnqueueCopyBufferRect, GetProcAddress("clEnqueueCopyBufferRect"));
	END;

	clEnqueueReadImage := S.VAL(TclEnqueueReadImage, GetProcAddress("clEnqueueReadImage"));
	clEnqueueWriteImage := S.VAL(TclEnqueueWriteImage, GetProcAddress("clEnqueueWriteImage"));
	IF VERSION_1_2 THEN
		clEnqueueFillImage := S.VAL(TclEnqueueFillImage, GetProcAddress("clEnqueueFillImage"));
	END;
	clEnqueueCopyImage := S.VAL(TclEnqueueCopyImage, GetProcAddress("clEnqueueCopyImage"));
	clEnqueueCopyImageToBuffer := S.VAL(TclEnqueueCopyImageToBuffer, GetProcAddress("clEnqueueCopyImageToBuffer"));
	clEnqueueCopyBufferToImage := S.VAL(TclEnqueueCopyBufferToImage, GetProcAddress("clEnqueueCopyBufferToImage"));
	clEnqueueMapBuffer := S.VAL(TclEnqueueMapBuffer, GetProcAddress("clEnqueueMapBuffer"));
	clEnqueueMapImage := S.VAL(TclEnqueueMapImage, GetProcAddress("clEnqueueMapImage"));
	clEnqueueUnmapMemObject := S.VAL(TclEnqueueUnmapMemObject, GetProcAddress("clEnqueueUnmapMemObject"));
	IF VERSION_1_2 THEN
		clEnqueueMigrateMemObjects := S.VAL(TclEnqueueMigrateMemObjects, GetProcAddress("clEnqueueMigrateMemObjects"));
	END;
	clEnqueueNDRangeKernel := S.VAL(TclEnqueueNDRangeKernel, GetProcAddress("clEnqueueNDRangeKernel"));
	clEnqueueTask := S.VAL(TclEnqueueTask, GetProcAddress("clEnqueueTask"));
	clEnqueueNativeKernel := S.VAL(TclEnqueueNativeKernel, GetProcAddress("clEnqueueNativeKernel"));
	IF VERSION_1_2 THEN
		clEnqueueMarkerWithWaitList := S.VAL(TclEnqueueMarkerWithWaitList, GetProcAddress("clEnqueueMarkerWithWaitList"));
		clEnqueueBarrierWithWaitList := S.VAL(TclEnqueueBarrierWithWaitList, GetProcAddress("clEnqueueBarrierWithWaitList"));
		clSetPrintfCallback := S.VAL(TclSetPrintfCallback, GetProcAddress("clSetPrintfCallback"));
	END;

	IF VERSION_1_2 THEN
	(* Extension function access*)
		clGetExtensionFunctionAddressForPlatform := S.VAL(TclGetExtensionFunctionAddressForPlatform, GetProcAddress("clGetExtensionFunctionAddressForPlatform"));
	END;

	(* DEPRECATED functions*)
	IF DEPRECEATED_1_0 THEN
		clSetCommandQueueProperty := S.VAL(TclSetCommandQueueProperty, GetProcAddress("clSetCommandQueueProperty"));
	END;
	IF DEPRECEATED_1_1 THEN
		clCreateImage2D := S.VAL(TclCreateImage2D, GetProcAddress("clCreateImage2D"));
		clCreateImage3D := S.VAL(TclCreateImage3D, GetProcAddress("clCreateImage3D"));
		clEnqueueMarker := S.VAL(TclEnqueueMarker, GetProcAddress("clEnqueueMarker"));
		clEnqueueWaitForEvents := S.VAL(TclEnqueueWaitForEvents, GetProcAddress("clEnqueueWaitForEvents"));
		clEnqueueBarrier := S.VAL(TclEnqueueBarrier, GetProcAddress("clEnqueueBarrier"));
		clUnloadCompiler := S.VAL(TclUnloadCompiler, GetProcAddress("clUnloadCompiler"));
		(* Extension function access*)
		clGetExtensionFunctionAddress := S.VAL(TclGetExtensionFunctionAddress, GetProcAddress("clGetExtensionFunctionAddress"));
	END;

END Init;

PROCEDURE OnClose;
VAR res: LONGINT;
BEGIN
	IF lib # Kernel32.NULL THEN
		res := Kernel32.FreeLibrary(lib);
		KernelLog.String(libname); KernelLog.String(" library unloaded.."); KernelLog.Ln;
	END;
END OnClose;

BEGIN
	Init;
	Modules.InstallTermHandler(OnClose)
END OpenCL.

