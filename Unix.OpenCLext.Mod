MODULE OpenCLext; (** AUTHOR "fnecati"; PURPOSE "OpenCL binding for cl_ext.h, LinuxAos"; *)
IMPORT SYSTEM, CL:=OpenCL, KernelLog;

(*! cl_ext.h *)
(*******************************************************************************
 * Copyright (c) 2008-2010 The Khronos Group Inc.
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
 ******************************************************************************)


 (* EXTENSIONS,  ext.h *)

(*  khr_fp64 extension - no extension #define since it has no functions  *)
CONST
	 DEVICE_DOUBLE_FP_CONFIG* =1032H;

(*  khr_fp16 extension - no extension #define since it has no functions  *)
	DEVICE_HALF_FP_CONFIG* =          1033H;

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

 CONST
  cl_APPLE_SetMemObjectDestructor* = 1;

(* VERSION_1_0 *)
TYPE
  TclSetMemObjectDestructorAPPLE* = PROCEDURE {C}(
                                        memobj: CL.cl_mem; (* memobj *)
                                        pfn_notify: ADDRESS;(* /*pfn_notify*/)( cl_mem /* memobj */, void* /*user_data*/*)
                                        user_data: ADDRESS(*user_data *)
                                        ): CL.cl_int;

VAR
  clSetMemObjectDestructorAPPLE-: TclSetMemObjectDestructorAPPLE;


(* Context Logging Functions
 *
 * The next three convenience functions are intended to be used as the pfn_notify parameter to clCreateContext().
 * Please check for the "cl_APPLE_ContextLoggingFunctions" extension using clGetDeviceInfo(CL_DEVICE_EXTENSIONS)
 * before using.
 *
 * clLogMessagesToSystemLog fowards on all log messages to the Apple System Logger
 *)
CONST
  cl_APPLE_ContextLoggingFunctions* = 1;

(* VERSION_1_0 *)
TYPE
  TclLogMessagesToSystemLogAPPLE* = PROCEDURE {C}(
                                            CONST  errstr: ARRAY OF CHAR;  (* errstr *)
                                            private_info: ADDRESS;        (* private_info *)
                                            cb: CL.size_t;                        (* cb *)
                                            user_data: ADDRESS                  (* user_data *)
                                            ): CL.cl_int;


(* VERSION_1_0 *)
(* clLogMessagesToStdout sends all log messages to the file descriptor stdout *)
  TclLogMessagesToStdoutAPPLE* = PROCEDURE {C}(
                                            CONST  errstr: ARRAY OF CHAR;  (* errstr *)
                                            private_info: ADDRESS;      (* private_info *)
                                            cb: CL.size_t;                        (* cb *)
                                            user_data: ADDRESS                  (* user_data *)
                                            ): CL.cl_int;

(* VERSION_1_0 *)
(* clLogMessagesToStderr sends all log messages to the file descriptor stderr *)
  TclLogMessagesToStderrAPPLE* = PROCEDURE {C}(
                                          CONST  errstr: ARRAY OF CHAR;  (* errstr *)
                                          private_info: ADDRESS;   (* private_info *)
                                          cb: CL.size_t;         (* cb *)
                                          user_data: ADDRESS                  (* user_data *)
                                          ): CL.cl_int;


VAR
  clLogMessagesToSystemLogAPPLE-: TclLogMessagesToSystemLogAPPLE;
  clLogMessagesToStdoutAPPLE-: TclLogMessagesToStdoutAPPLE;
  clLogMessagesToStderrAPPLE-: TclLogMessagesToStderrAPPLE;


CONST
	(*  khr_icd extension *)
	 cl_khr_icd* = 1;

	(*  platform_info *)
	(*  Accepted as <param_name> to the function clGetPlatformInfo  *)
	CL_PLATFORM_ICD_SUFFIX_KHR* = 0920H;

	(* Additional Error Codes  *)
	(* Returned by clGetPlatformIDs when no platforms are found *)
	CL_PLATFORM_NOT_FOUND_KHR* = -1001;

TYPE
	TclIcdGetPlatformIDsKHR* = PROCEDURE {C}  (num_entries:  CL.cl_uint ; platforms:  CL.cl_platform_id; num_platforms : ADDRESS):  CL.cl_int;
VAR
	clIcdGetPlatformIDsKHR-: TclIcdGetPlatformIDsKHR;

(* *****************************************
 cl_nv_device_attribute_query extension
***************************************** *)
(*  nv_device_attribute_query extension - no extension #define since it has no functions *)
CONST
	CL_DEVICE_COMPUTE_CAPABILITY_MAJOR_NV* = 4000H;
	CL_DEVICE_COMPUTE_CAPABILITY_MINOR_NV* = 4001H;
	CL_DEVICE_REGISTERS_PER_BLOCK_NV* = 4002H;
	CL_DEVICE_WARP_SIZE_NV* = 4003H;
	CL_DEVICE_GPU_OVERLAP_NV* = 4004H;
	CL_DEVICE_KERNEL_EXEC_TIMEOUT_NV* = 4005H;
	CL_DEVICE_INTEGRATED_MEMORY_NV* = 4006H;


(* ********************************
 cl_amd_device_attribute_query
******************************** *)
CONST
  (*  Accepted as the <param_name> parameter of clGetDeviceInfo. Return the
    offset in nano-seconds between an event timestamp and Epoch.  *)
	CL_DEVICE_PROFILING_TIMER_OFFSET_AMD* = 4036H;

(* VERSION_1_1 *)
    (* **********************************
     cl_ext_device_fission extension
    ********************************** *)
  CONST
    cl_ext_device_fission*   = 1;

  TYPE
    (*
    clReleaseDeviceEXT decrements the <device> reference count. After the
    reference count reaches zero, the object shall be destroyed and associated
    resources released for reuse by the system.

    clReleaseDeviceEXT returns CL_SUCCESS if the function is executed
    successfully or the device is a root level device. It returns
    CL_INVALID_DEVICE if the <device> is not a valid device.
    *)
    TclReleaseDeviceEXT* = PROCEDURE {C} ( device: CL.cl_device_id ): CL.cl_int;
VAR
    clReleaseDeviceEXT- : TclReleaseDeviceEXT;
    (*
    clReleaseDeviceEXT returns CL_SUCCESS if the function is executed
    successfully or the device is a root level device. It returns
    CL_INVALID_DEVICE if the <device> is not a valid device.

    CAUTION: Since root level devices are generally returned by a clGet call
    (clGetDeviceIDs) and not a clCreate call, the user generally does not own a
    reference count for root level devices. The reference count attached to a
    device retured from clGetDeviceIDs is owned by the implementation.
    Developers need to be careful when releasing cl_device_ids to always balance
    clCreateSubDevicesEXT or clRetainDeviceEXT with each call to
    clReleaseDeviceEXT for the device. By convention, software layers that own
    a reference count should be themselves responsible for releasing it.
    *)
TYPE
    TclRetainDeviceEXT* = PROCEDURE {C}( device: CL.cl_device_id (*device*)): CL.cl_int;

VAR
    clRetainDeviceEXT- : TclRetainDeviceEXT;

TYPE
  	cl_device_partition_property_ext* = CL.cl_ulong;

    (*
    clCreateSubDevicesEXT creates an array of sub-devices that each reference a
    nonintersecting set of compute units within <in_device>, according to a
    partition scheme given by the <cl_device_partition_property_ext> list. The
    output sub-devices may be used in every way that the root device can be
    used, including building programs, further calls to clCreateSubDevicesEXT
    and creating command queues. They may also be used within any context
    created using the in_device or parent/ancestor thereof. When a command
    queue is created against a sub-device, the commands enqueued on that queue
    are executed only on the sub-device.

    in_device - The device to be partitioned

    num_entries - The number of cl_device_ids that will fit in the array pointed
        to by <out_devices>. If <out_devices> is not NULL, <num_entries> must be
        greater than zero.

    out_devices - On output, the array pointed to by <out_devices> will contain
        up to <num_entries> sub-devices. If the <out_devices> argument is NULL,
        it is ignored. The number of cl_device_ids returned is the minimum of
        <num_entries> and the number of devices created by the partition scheme.

    num_devices - On output, the number of devices that the <in_device> may be
        partitioned in to according to the partitioning scheme given by
        <properties>. If num_devices is NULL, it is ignored.

    properties - A zero terminated list of device fission {property-value,
        cl_int[]} pairs that describe how to partition the device into
        sub-devices.  <properties> may not be NULL. Only one of
        CL_DEVICE_PARTITION_EQUALLY_EXT, CL_DEVICE_PARTITION_BY_COUNTS_EXT,
        CL_DEVICE_PARTITION_BY_NAMES_EXT or
        CL_DEVICE_PARTITION_BY_AFFINITY_DOMAIN_EXT may be used in the same
        properties list. Available properties are:

        CL_DEVICE_PARTITION_EQUALLY_EXT - Split the aggregate device into as
            many smaller aggregate devices as can be created, each containing N
            compute units. The value N is passed as the value accompanying this
            property.  If N does not divide evenly into
            CL_DEVICE_MAX_COMPUTE_UNITS then the remaining compute units are
            not used.

            Example: To divide a device containing 16 compute units into two
            sub-devices, each containing 8 compute units, pass:

                { CL_DEVICE_PARTITION_EQUALLY_EXT, 8,
                  CL_PROPERTIES_LIST_END_EXT }

        CL_DEVICE_PARTITION_BY COUNTS_EXT - This property is followed by a
            CL_PARTITION_BY_COUNTS_LIST_END_EXT terminated list of compute unit
            counts. For each non-zero count M in the list, a sub-device is
            created with M compute units in it.
            CL_PARTITION_BY_COUNTS_LIST_END_EXT is defined to be 0.

            Example: to split a four compute unit device into two sub-devices,
            each containing two compute units, pass:

                { CL_DEVICE_PARTITION_BY_COUNTS_EXT,
                  2, 2, CL_PARTITION_BY_COUNTS_LIST_END_EXT,
                  CL_PROPERTIES_LIST_END_EXT }

            The first 2 means put two compute units in the first sub-device. The
            second 2 means put two compute units in the second sub-device.
            CL_PARTITION_BY_COUNTS_LIST_END_EXT terminates the list of
            sub-devices.  CL_PROPERTIES_LIST_END_EXT terminates the list of
            properties.  The total number of compute units specified may not
            exceed the number of compute units in the device.

        CL_DEVICE_PARTITION_BY NAMES_EXT - This property is followed by a list
            of compute unit names. Each list starts with a
            CL_PARTITION_BY_NAMES_LIST_END_EXT terminated list of compute unit
            names.  Compute unit names are integers that count up from zero to
            the number of compute units less one.
            CL_PARTITION_BY_NAMES_LIST_END_EXT is defined to be -1. Only
            one sub-device may be created at a time with this selector. An
            individual compute unit name may not appear more than once in the
            sub-device description.

            Example: To create a three compute unit sub-device using compute
            units, { 0, 1, 3 }, pass:

                { CL_DEVICE_PARTITION_BY NAMES_EXT,
                  0, 1, 3, CL_PARTITION_BY_NAMES_LIST_END_EXT,
                  CL_PROPERTIES_LIST_END_EXT }

            The meaning of these numbers are, in order:
              0 the name of the first compute unit in the sub-device
              1 the name of the second compute unit in the sub-device
              3 the name of the third compute unit in the sub-device
              CL_PROPERTIES_LIST_END_EXT list terminator for the list of
                  properties

        CL_DEVICE_PARTITION_BY_AFFINITY_DOMAIN_EXT - Split the device into
            smaller aggregate devices containing one or more compute units
            that all share part of a cache hierarchy. The value accompanying
            this property may be drawn from the following CL_AFFINITY_DOMAIN
            list:

            CL_AFFINITY_DOMAIN_NUMA_EXT - Split the device into sub-devices
                comprised of compute units that share a NUMA band.

            CL_AFFINITY_DOMAIN_L4_CACHE_EXT - Split the device into sub-devices
                comprised of compute units that share a level 4 data cache.

            CL_AFFINITY_DOMAIN_L3_CACHE_EXT - Split the device into sub-devices
                comprised of compute units that share a level 3 data cache.

            CL_AFFINITY_DOMAIN_L2_CACHE_EXT - Split the device into sub-devices
                comprised of compute units that share a level 2 data cache.

            CL_AFFINITY_DOMAIN_L1_CACHE_EXT - Split the device into sub-devices
                comprised of compute units that share a level 1 data cache.

            CL_AFFINITY_DOMAIN_NEXT_FISSIONABLE_EXT - Split the device along the
                next fissionable CL_AFFINITY_DOMAIN.  The implementation shall
                find the first level along which the device or sub-device may be
                further subdivided in the order NUMA, L4, L3, L2, L1, and
                fission the device into sub-devices comprised of compute units
                that share memory sub-systems at this level. The user may
                determine what happened by calling
                clGetDeviceInfo(CL_DEVICE_PARTITION_STYLE_EXT) on the
                sub-devices.

            Example: To split a non-NUMA device along the outermost cache level
            (if any), pass:

                { CL_DEVICE_PARTITION_BY_AFFINITY_DOMAIN_EXT,
                  CL_AFFINITY_DOMAIN_NEXT_FISSIONABLE_EXT,
                  CL_PROPERTIES_LIST_END_EXT }

        CL_PROPERTIES_LIST_END_EXT - A list terminator for a properties list.


        The following values may be returned by clCreateSubDevicesEXT:

    CL_SUCCESS - The command succeeded.

    CL_INVALID_VALUE - The properties key is unknown, or the indicated partition
        style (CL_DEVICE_PARTITION_BY_AFFINITY_DOMAIN_EXT,
        CL_DEVICE_PARTITION_EQUALLY_EXT, CL_DEVICE_PARTITION_BY NAMES_EXT or
        CL_DEVICE_PARTITION_BY COUNTS_EXT) is not supported for this device by
        the implementation. On an OpenCL 1.1 implementation, these cases return
        CL_INVALID_PROPERTY instead, to be consistent with clCreateContext
        behavior.

    CL_INVALID_VALUE - num_entries is zero and out_devices is not NULL, or both
        out_devices and num_devices are NULL.

    CL_DEVICE_PARTITION_FAILED_EXT - The indicated partition scheme is supported
        by the implementation, but the implementation can not further partition
        the device in this way. For example,
        CL_DEVICE_PARTITION_BY_AFFINITY_DOMAIN_EXT was requested, but all
        compute units in in_device share the same cache at the level requested.

    CL_INVALID_PARTITION_COUNT_EXT - The total number of compute units requested
        exceeds CL_DEVICE_MAX_COMPUTE_UNITS, or the number of compute units for
        any one sub-device is less than 1, or the number of sub-devices
        requested exceeds CL_DEVICE_MAX_COMPUTE_UNITS.

    CL_INVALID_PARTITION_NAME_EXT - A compute unit name appearing in a name list
        following CL_DEVICE_PARTITION_BY NAMES_EXT is not in the range
        [-1, number of compute units - 1].

    CL_INVALID_DEVICE - The in_device is not a valid device. The in_device is
        not a device in context.
    *)

     TclCreateSubDevicesEXT* = PROCEDURE {C}(
                            in_device: CL.cl_device_id; (*in_device*)
                            properties: ADDRESS; (* ARRAY OF cl_device_partition_property_ext *)
                            num_entries: CL.cl_uint; (*num_entries*)
                            out_devices: ADDRESS; (* ARRAY OF cl_device_id *)
                            num_devices: ADDRESS (*CL.cl_uint *)
                            ): CL.cl_int;
VAR
      clCreateSubDevicesEXT-: TclCreateSubDevicesEXT;

CONST
    (* Accepted as a property name in the <properties> parameter of
    clCreateSubDeviceEXT: *)
    (* cl_device_partition_property_ext *)
	CL_DEVICE_PARTITION_EQUALLY_EXT* = 4050H;
	CL_DEVICE_PARTITION_BY_COUNTS_EXT* = 4051H;
	CL_DEVICE_PARTITION_BY_NAMES_EXT* = 4052H;
	CL_DEVICE_PARTITION_BY_AFFINITY_DOMAIN_EXT* = 4053H;

    (* clDeviceGetInfo selectors *)
    (*
    Accepted as a property being queried in the <param_name> argument of
    clGetDeviceInfo:

    clGetDeviceInfo - If the device is a sub-device created by
        clCreateSubDevicesEXT, then the value returned for
        CL_DEVICE_MAX_COMPUTE_UNITS is the number of compute units in the
        sub-device. The CL_DEVICE_VENDOR_ID may be different from the parent
        device CL_DEVICE_VENDOR_ID, but should be the same for all devices and
        sub-devices that can share a binary executable, such as that returned
        from clGetProgramInfo(CL_PROGRAM_BINARIES). Other selectors such as
        CL_DEVICE_GLOBAL_MEM_CACHE_SIZE may optionally change value to better
        reflect the behavior of the sub-device in an implementation defined
        manner.
    The following selectors are added for clGetDeviceInfo:
    *)

    (*
      CL_DEVICE_PARENT_DEVICE_EXT - a selector to get the cl_device_id for
      the parent cl_device_id to which the sub-device belongs.
      (Sub-division can be multi-level.) If the device is a root level
      device, then it will return NULL.
    *)
      CL_DEVICE_PARENT_DEVICE_EXT* = 4054H;
    (*
      CL_DEVICE_PARTITION_TYPES_EXT - a selector to get a list of supported
      partition types for partitioning a device. The return type is an
      array of cl_device partition property ext values drawn from the
      following list:

      CL_DEVICE_PARTITION_BY_AFFINITY_DOMAIN_EXT
      CL_DEVICE_PARTITION_BY COUNTS_EXT
      CL_DEVICE_PARTITION_BY NAMES_EXT
      CL_DEVICE_PARTITION_EQUALLY_EXT

      The implementation shall return at least one property from the above
      list.  However, when a partition style is found within this list,
      the partition style is not required to work in every case. For
      example, a device might support partitioning by affinity domain, but
      not along NUMA domains.
    *)
      CL_DEVICE_PARTITION_TYPES_EXT* = 4055H;

    (*
      CL_DEVICE_AFFINITY_DOMAINS_EXT - a selector to get a list of supported
      affinity domains for partitioning the device using the
      CL_DEVICE_PARTITION_BY_AFFINITY_DOMAIN_EXT partition style. The
      return type is an array of cl_device_partition_property_ext values.
      The values shall come from the list:

      CL_AFFINITY_DOMAIN_L1_CACHE_EXT
      CL_AFFINITY_DOMAIN_L2_CACHE_EXT
      CL_AFFINITY_DOMAIN_L3_CACHE_EXT
      CL_AFFINITY_DOMAIN_L4_CACHE_EXT
      CL_AFFINITY_DOMAIN_NUMA_EXT

      If no partition style is supported then the size of the returned
      array is zero.  Even though a device has a NUMA, or particular
      cache level, an implementation may elect not to provide fissioning
      at that level.
    *)
      CL_DEVICE_AFFINITY_DOMAINS_EXT* = 4056H;
    (*
      CL_DEVICE_REFERENCE_COUNT_EXT Return the device
      reference count.  The return type is cl_uint. If the device is a
      root level device, a reference count of 1 is returned.
    *)
      CL_DEVICE_REFERENCE_COUNT_EXT* = 4057H;
    (*
      CL_DEVICE_PARTITION_STYLE_EXT - a selector to get the
      cl_device_partition_property_ext list used to create the sub-device.
      If the device is a root level device then a list consisting of
      { CL_PROPERTIES_LIST_END_EXT} is returned. If the property on device
      creation was (CL_DEVICE_PARTITION BY_AFFINITY_DOMAIN_EXT,
      CL_AFFINITY_DOMAIN_NEXT_FISSIONABLE) then
      CL_AFFINITY_DOMAIN_NEXT_FISSIONABLE will be replaced by the symbol
      representing the actual CL_AFFINITY DOMAIN used
      (e.g. CL_AFFINITY_DOMAIN_NUMA). The returned value is an array of
      cl_device_partition_property_ext. The length of the array is
      obtained from the size returned by the param size value ret
      parameter to the function.
    *)
      CL_DEVICE_PARTITION_STYLE_EXT* = 4058H;

    (*! error codes *)
    (*
      Returned by clCreateSubDevicesEXT when the indicated partition scheme is
      supported by the implementation, but the implementation can not further
      partition the device in this way.
    *)
      CL_DEVICE_PARTITION_FAILED_EXT* = -1057;
    (*
      Returned by clCreateSubDevicesEXT when the total number of compute units
      requested exceeds CL_DEVICE_MAX_COMPUTE_UNITS, or the number of compute
      units for any one sub-device is less than 1.
    *)
      CL_INVALID_PARTITION_COUNT_EXT* = -1058;
    (*
      Returned by clCreateSubDevicesEXT when a compute unit name appearing in a
      name list following CL_DEVICE_PARTITION_BY_NAMES_EXT is not in range.
    *)
      CL_INVALID_PARTITION_NAME_EXT* = -1059;

    (*
      Accepted as a property name, when accompanying the
      CL_DEVICE_PARITION_BY_AFFINITY_DOMAIN_EXT property, in the <properties>
      parameter of clCreateSubDeviceEXT:
    *)
    (* CL_AFFINITY_DOMAINs *)
      CL_AFFINITY_DOMAIN_L1_CACHE_EXT* = 1H;
      CL_AFFINITY_DOMAIN_L2_CACHE_EXT* = 2H;
      CL_AFFINITY_DOMAIN_L3_CACHE_EXT* = 3H;
      CL_AFFINITY_DOMAIN_L4_CACHE_EXT* = 4H;
      CL_AFFINITY_DOMAIN_NUMA_EXT* = 10H;
      CL_AFFINITY_DOMAIN_NEXT_FISSIONABLE_EXT* = 100H;


    (* cl_device_partition_property_ext list terminators *)

      (*
        Accepted as the property list terminator in the <properties> parameter of
        clCreateSubDeviceEXT:
      *)
      CL_PROPERTIES_LIST_END_EXT* = SYSTEM.VAL(cl_device_partition_property_ext, 0);

      (*
        Accepted as the partition counts list terminator in the <properties>
        parameter of clCreateSubDeviceEXT:
      *)
      CL_PARTITION_BY_COUNTS_LIST_END_EXT* = SYSTEM.VAL(cl_device_partition_property_ext, 0);

      (*
        Accepted as the partition names list terminator in the <properties>
        parameter of clCreateSubDeviceEXT:
      *)
      CL_PARTITION_BY_NAMES_LIST_END_EXT* = SYSTEM.VAL(cl_device_partition_property_ext, -1);

    (* cl_ext_atomic_counters_32 and cl_ext_atomic_counters_64 extensions
     * no extension #define since they have no functions
     *)
      CL_DEVICE_MAX_ATOMIC_COUNTERS_EXT* = 4032H;

(* ENDIF CL_VERSION_1_1*)

(* IF CL_VERSION_1_0 *)
    (***********************************
     * cl_ext_migrate_memobject extension definitions
     ***********************************)
      cl_ext_migrate_memobject* = 1;

TYPE
    cl_mem_migration_flags_ext* = CL.cl_bitfield;

CONST
    (* Besides a value of zero, the following cl_mem_migration_flags_ext values are
      allowed: *)
    CL_MIGRATE_MEM_OBJECT_HOST_EXT* = 1H;
    (* Returned in the <param_value> parameter of the clGetEventInfo when
      <param_name> is CL_EVENT_COMMAND_TYPE: *)
    CL_COMMAND_MIGRATE_MEM_OBJECT_EXT* = 4040H;

TYPE
	TclEnqueueMigrateMemObjectEXT* = PROCEDURE {C}(
                                  command_queue: CL.cl_command_queue;
                                  num_mem_objects: CL.cl_uint;
                                  mem_objects: ADDRESS; (* ARRAY OF CL.cl_mem *)
                                  flags: cl_mem_migration_flags_ext;
                                  num_events_in_wait_list: CL.cl_uint;
                                  event_wait_list: ADDRESS; (* ARRAY OF cl_event *)
                                  event: ADDRESS (* cl_event *)
                                  ): CL.cl_int;

VAR
    clEnqueueMigrateMemObjectEXT-: TclEnqueueMigrateMemObjectEXT;
(* ENDIF *)

PROCEDURE GetExtensionFunctionAddress*(CONST funcname: ARRAY OF CHAR): ADDRESS;
VAR adres: ADDRESS;
BEGIN
	adres := CL.clGetExtensionFunctionAddress(funcname);
	IF ( adres=0) & CL.debug THEN
		KernelLog.String("ERROR: Extension function: "); KernelLog.String(funcname); KernelLog.String(" NOT found");  KernelLog.Ln;
	END;
	ASSERT(adres # 0, 302);
	RETURN adres;
END GetExtensionFunctionAddress;


PROCEDURE Init;
BEGIN
	clIcdGetPlatformIDsKHR := SYSTEM.VAL(TclIcdGetPlatformIDsKHR, GetExtensionFunctionAddress('clIcdGetPlatformIDsKHR'));

	(* CL_VERSION_1_0 *)
	clSetMemObjectDestructorAPPLE := SYSTEM.VAL(TclSetMemObjectDestructorAPPLE, GetExtensionFunctionAddress('clSetMemObjectDestructorAPPLE'));
	clLogMessagesToSystemLogAPPLE := SYSTEM.VAL(TclLogMessagesToSystemLogAPPLE, GetExtensionFunctionAddress('clLogMessagesToSystemLogAPPLE'));
	clLogMessagesToStdoutAPPLE := SYSTEM.VAL(TclLogMessagesToStdoutAPPLE, GetExtensionFunctionAddress('clLogMessagesToStdoutAPPLE'));
	clLogMessagesToStderrAPPLE := SYSTEM.VAL(TclLogMessagesToStderrAPPLE, GetExtensionFunctionAddress('clLogMessagesToStderrAPPLE'));

	(* CL_VERSION_1_1*)
	clReleaseDeviceEXT := SYSTEM.VAL(TclReleaseDeviceEXT, GetExtensionFunctionAddress('clReleaseDeviceEXT'));
	clRetainDeviceEXT := SYSTEM.VAL(TclRetainDeviceEXT, GetExtensionFunctionAddress('clRetainDeviceEXT'));
	clCreateSubDevicesEXT := SYSTEM.VAL(TclCreateSubDevicesEXT, GetExtensionFunctionAddress('clCreateSubDevicesEXT'));

	(* CL_VERSION_1_0 *)
	clEnqueueMigrateMemObjectEXT := SYSTEM.VAL(TclEnqueueMigrateMemObjectEXT, GetExtensionFunctionAddress('clEnqueueMigrateMemObjectEXT'));

END Init;

BEGIN

  Init;

END OpenCLext.

