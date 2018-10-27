MODULE OpenCLInfo; (** AUTHOR "fnecati"; PURPOSE "Prints OpenCL properties of GPU"; *)

IMPORT CL:=OpenCL, S:=SYSTEM, KernelLog, Streams, Strings, Utils:=OpenCLUtils;

TYPE
	Int3Array = ARRAY 3 OF CL.size_t;

VAR
	wr: Streams.Writer;

(** Show OpenCL infos *)
PROCEDURE Show*;
VAR i, j, k: LONGINT;
	err: LONGINT; (* error code returned from api calls*)
	nplatforms : LONGINT; (*CL.cl_uint;*)
	platformids  :POINTER TO ARRAY OF CL.cl_platform_id;
	ndevices :  CL.cl_int;
	deviceids : POINTER TO ARRAY OF CL.cl_device_id;
	context : CL.cl_context;
	buf  :  ARRAY 1024 OF  CHAR;
	(* bufwritten: LONGINT;*)
	computeunits: CL.cl_uint;
	dumy: LONGINT;
	udumy: CL.cl_uint;
	sdumy: CL.size_t;
	hdumy: HUGEINT;

	memsize: CL.cl_ulong;
	devtype: HUGEINT; (* CL.cl_bitfield *)
	workitemsize: Int3Array;
	nv_extension_query: BOOLEAN;

	nimageformats: LONGINT;
	imageformats: POINTER TO ARRAY OF CL.cl_image_format;

BEGIN

	err := CL.GetPlatformIDs(0, 0 , ADDRESSOF(nplatforms));
	IF (err  # CL.SUCCESS) THEN
		 wr.String('Error: Cannot get number of platforms!'); wr.Ln; wr.Update;
		RETURN;
	END;

	wr.String("# platforms found = "); wr.Int(nplatforms,0); wr.Ln; wr.Update;

	NEW(platformids, nplatforms);
	err := CL.GetPlatformIDs( nplatforms, ADDRESSOF(platformids[0]), 0 );
	IF (err # CL.SUCCESS) THEN
		wr.String('Error: Cannot get platforms!'); wr.Ln; wr.Update;
		RETURN
	END;

	 FOR i := 0 TO nplatforms-1 DO
		wr.String('Platform info '); wr.Int(i,0); wr.Ln;

		err := CL.GetPlatformInfo(platformids[i], CL.PLATFORM_PROFILE, LEN(buf), ADDRESSOF(buf[0]), 0);
		wr.String('PROFILE: '); wr.String(buf); wr.Ln;

		err := CL.GetPlatformInfo(platformids[i],CL.PLATFORM_VERSION, LEN(buf), ADDRESSOF(buf[0]), 0);
		wr.String('VERSION: '); wr.String(buf); wr.Ln;

		err := CL.GetPlatformInfo(platformids[i],CL.PLATFORM_NAME, LEN(buf), ADDRESSOF(buf[0]), 0);
		wr.String('NAME: '); wr.String(buf); wr.Ln;

		err := CL.GetPlatformInfo(platformids[i],CL.PLATFORM_VENDOR, LEN(buf), ADDRESSOF(buf[0]), 0);
		wr.String('VENDOR: '); wr.String(buf); wr.Ln;

		err := CL.GetPlatformInfo(platformids[i], CL.PLATFORM_EXTENSIONS, LEN(buf), ADDRESSOF(buf[0]), 0);
		wr.String('EXTENSIONS: '); wr.String(buf); wr.Ln;

		 wr.Update;

		(*  Devices  *)

		err := CL.GetDeviceIDs (platformids[i], CL.DEVICE_TYPE_ALL, 0, 0 , ADDRESSOF(ndevices));
		IF (err # CL.SUCCESS) THEN
			wr.String("clGetDeviceIDs Error: "); wr.String(Utils.GetError(err)); wr.Ln;
			wr.String('Error: Cannot get number of devices!'); wr.Ln; wr.Update;
			RETURN
		END;

		wr.Int(ndevices, 0); wr.String(" device(s) found"); wr.Ln; wr.Update;

		IF ndevices =0 THEN RETURN END;

		NEW(deviceids, ndevices);

		err := CL.GetDeviceIDs(platformids[i], CL.DEVICE_TYPE_ALL, ndevices, ADDRESSOF(deviceids[0]), 0);
		IF (err # CL.SUCCESS) THEN
			wr.String("clGetDeviceIDs Error: "); wr.String(Utils.GetError(err)); wr.Ln;
			wr.String('Error: Cannot get number of devices-2!'); wr.Ln; wr.Update;
			RETURN
		END;

		FOR j := 0 TO ndevices-1 DO

			wr.String("*****************************************"); wr.Ln;
			wr.String('Device info:  '); wr.Int(j,0); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_NAME, LEN(buf), ADDRESSOF(buf[0]), 0);
			wr.String("DEVICE NAME: "); wr.String(buf); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_VENDOR, LEN(buf), ADDRESSOF(buf[0]), 0);
			wr.String("DEVICE VENDOR: "); wr.String(buf); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DRIVER_VERSION, LEN(buf), ADDRESSOF(buf[0]), 0);
			wr.String("DRIVER VERSION: "); wr.String(buf); wr.Ln;

			 err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_VERSION, LEN(buf), ADDRESSOF(buf[0]), 0);
			wr.String("DEVICE VERSION: "); wr.String(buf); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_OPENCL_C_VERSION, LEN(buf), ADDRESSOF(buf[0]), 0);
			wr.String("DEVICE_OPENCL_C_VERSION: "); wr.String(buf); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_TYPE,  SIZEOF(HUGEINT), ADDRESSOF(devtype), 0);
			wr.String("DEVICE_TYPE: ");
			IF devtype = CL.DEVICE_TYPE_CPU THEN   wr.String("DEVICE_TYPE_CPU");
			ELSIF  devtype = CL.DEVICE_TYPE_GPU THEN wr.String("DEVICE_TYPE_GPU");
			ELSIF  devtype = CL.DEVICE_TYPE_ACCELERATOR  THEN   wr.String("DEVICE_TYPE_ACCELERATOR");
			ELSIF  devtype = CL.DEVICE_TYPE_CUSTOM THEN wr.String("DEVICE_TYPE_CUSTOM");
			ELSIF  devtype = CL.DEVICE_TYPE_DEFAULT THEN wr.String("DEVICE_TYPE_DEFAULT");
			END;
			wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_MAX_COMPUTE_UNITS, SIZEOF(CL.cl_uint), ADDRESSOF(computeunits), 0);
			wr.String("DEVICE_MAX_COMPUTE_UNITS: "); wr.Int(computeunits,0); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_MAX_WORK_ITEM_DIMENSIONS, SIZEOF(CL.cl_uint), ADDRESSOF(udumy), 0);
			wr.String("DEVICE_MAX_WORK_ITEM_DIMENSIONS: "); wr.Int(udumy,0); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_MAX_WORK_ITEM_SIZES,  SIZEOF(Int3Array), ADDRESSOF(workitemsize[0]), 0);
			wr.String("DEVICE_MAX_WORK_ITEM_SIZES: "); wr.Int(workitemsize[0],5); wr.String(" x "); wr.Int(workitemsize[1],0);  wr.String(" x "); wr.Int(workitemsize[2],0); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_MAX_WORK_GROUP_SIZE, SIZEOF(CL.size_t), ADDRESSOF(sdumy), 0);
			wr.String("DEVICE_MAX_WORK_GROUP_SIZE: "); wr.Int(sdumy,0); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_MAX_CLOCK_FREQUENCY, SIZEOF(CL.cl_uint), ADDRESSOF(udumy), 0);
			wr.String("DEVICE_MAX_CLOCK_FREQUENCY: "); wr.Int(udumy,0); wr.String(" MHz"); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_ADDRESS_BITS, SIZEOF(CL.cl_uint), ADDRESSOF(udumy), 0);
			wr.String("DEVICE_ADDRESS_BITS: "); wr.Int(udumy,0); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_MAX_MEM_ALLOC_SIZE, SIZEOF(CL.cl_ulong), ADDRESSOF(memsize), 0);
			wr.String("DEVICE_MAX_MEM_ALLOC_SIZE: "); wr.Int( memsize DIV (1024*1024), 0); wr.String(" MByte"); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_GLOBAL_MEM_SIZE, SIZEOF(CL.cl_ulong), ADDRESSOF(memsize), 0);
			wr.String("DEVICE_GLOBAL_MEM_SIZE: "); wr.Int( memsize DIV (1024*1024), 0); wr.String(" MByte"); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_ERROR_CORRECTION_SUPPORT, SIZEOF(LONGINT), ADDRESSOF(dumy), 0);
			wr.String("DEVICE_ERROR_CORRECTION_SUPPORT: "); IF dumy = CL.CL_FALSE THEN wr.String(" no"); ELSE wr.String(" yes"); END; wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_LOCAL_MEM_TYPE, SIZEOF(CL.cl_uint), ADDRESSOF(udumy), 0);
			wr.String("DEVICE_LOCAL_MEM_TYPE: "); IF udumy = CL.CL_TRUE THEN wr.String(" local"); ELSE wr.String(" global"); END; wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_LOCAL_MEM_SIZE,  SIZEOF(CL.cl_ulong), ADDRESSOF(memsize), 0);
			wr.String("DEVICE_LOCAL_MEM_SIZE: "); wr.Int(memsize DIV 1024 , 0); wr.String(" KByte");  wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_MAX_CONSTANT_BUFFER_SIZE, SIZEOF(CL.cl_ulong), ADDRESSOF(memsize), 0);
			wr.String("DEVICE_MAX_CONSTANT_BUFFER_SIZE: "); wr.Int( memsize DIV 1024, 0);  wr.String(" KByte");  wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_QUEUE_PROPERTIES, SIZEOF(CL.cl_bitfield), ADDRESSOF(hdumy), 0);

			IF CL.QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE IN S.VAL(SET,hdumy)  THEN wr.String("DEVICE_QUEUE_PROPERTIES: QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE"); END; wr.Ln;
			IF CL.QUEUE_PROFILING_ENABLE IN S.VAL(SET,hdumy) THEN wr.String("DEVICE_QUEUE_PROPERTIES: QUEUE_PROFILING_ENABLE"); END; wr.Ln;

			err:= CL.GetDeviceInfo(deviceids[j],CL.DEVICE_IMAGE_SUPPORT, SIZEOF(LONGINT), ADDRESSOF(dumy), 0);
			wr.String("DEVICE_MAGE_SUPPORT: "); IF dumy=1 THEN wr.String(" true"); ELSE wr.String(" false"); END; wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_MAX_READ_IMAGE_ARGS, SIZEOF(CL.cl_uint), ADDRESSOF(udumy), 0);
			wr.String("DEVICE_MAX_READ_IMAGE_ARGS: "); wr.Int(udumy,0); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_MAX_WRITE_IMAGE_ARGS, SIZEOF(CL.cl_uint), ADDRESSOF(udumy), 0);
			wr.String("DEVICE_MAX_WRITE_IMAGE_ARGS: "); wr.Int(udumy,0); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_SINGLE_FP_CONFIG, SIZEOF(CL.cl_bitfield), ADDRESSOF(hdumy), 0);
			wr.String("DEVICE_SINGLE_FP_CONFIG: ");
			IF CL.FP_DENORM IN S.VAL(SET,hdumy)  THEN wr.String(" denorms  "); END;
			IF CL.FP_INF_NAN IN S.VAL(SET,hdumy)  THEN wr.String(" INF-quietNaNs  "); END;
			IF CL.FP_ROUND_TO_NEAREST IN S.VAL(SET,hdumy)  THEN wr.String(" round-to-nearest  "); END;
			IF CL.FP_ROUND_TO_ZERO IN S.VAL(SET,hdumy)  THEN wr.String(" round-to-zero  "); END;
			IF CL.FP_ROUND_TO_INF IN S.VAL(SET,hdumy)  THEN wr.String(" round-to-inf  "); END;
			IF CL.FP_FMA IN S.VAL(SET,hdumy)  THEN wr.String(" fma  "); END;
			wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_IMAGE2D_MAX_WIDTH, SIZEOF(CL.size_t), ADDRESSOF(sdumy), 0);
			wr.String("DEVICE_IMAGE <dim> "); wr.Ln;
			wr.String("     IMAGE2D_MAX_WIDTH: "); wr.Int(sdumy,0); wr.Ln;
			
			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_IMAGE2D_MAX_HEIGHT, SIZEOF(CL.size_t), ADDRESSOF(sdumy), 0);
			wr.String("     IMAGE2D_MAX_HEIGHT: "); wr.Int(sdumy,0); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_IMAGE3D_MAX_WIDTH, SIZEOF(CL.size_t), ADDRESSOF(sdumy), 0);
			wr.String("     IMAGE3D_MAX_WIDTH: "); wr.Int(sdumy,0); wr.Ln;
			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_IMAGE3D_MAX_HEIGHT, SIZEOF(CL.size_t), ADDRESSOF(sdumy), 0);
	             wr.String("     IMAGE3D_MAX_HEIGHT: "); wr.Int(sdumy,0); wr.Ln;
			
			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_IMAGE3D_MAX_DEPTH, SIZEOF(CL.size_t), ADDRESSOF(sdumy), 0);
			wr.String("     IMAGE3D_MAX_DEPTH: "); wr.Int(sdumy,0); wr.Ln;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_EXTENSIONS, LEN(buf), ADDRESSOF(buf[0]), 0);
			wr.String("DEVICE EXTENSIONS: "); wr.String(buf); wr.Ln;

			nv_extension_query:= FALSE;

			IF Strings.Pos("cl_nv_device_attribute_query", buf) # -1 THEN 	nv_extension_query:= TRUE; END;		
			IF nv_extension_query THEN
				err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_COMPUTE_CAPABILITY_MAJOR_NV, SIZEOF(LONGINT), ADDRESSOF(dumy), 0);
				wr.String("     DEVICE_COMPUTE_CAPABILITY_NV: "); wr.Int(dumy,0); wr.String(".");
				err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_COMPUTE_CAPABILITY_MINOR_NV, SIZEOF(LONGINT), ADDRESSOF(dumy), 0);
				wr.Int(dumy,0); wr.Ln;

				wr.String("     NUMBER_OF_MULTIPROCESSORS: "); wr.Int(computeunits,0); wr.Ln; (* same as compute units *);
				wr.String("     NUMBER_OF_CUDA_CORES: ? "); wr.Ln;

				err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_WARP_SIZE_NV, SIZEOF(LONGINT), ADDRESSOF(dumy), 0);
				wr.String("     DEVICE_WARP_SIZE_NV: "); wr.Int(dumy,0); wr.Ln;

				err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_GPU_OVERLAP_NV, SIZEOF(LONGINT), ADDRESSOF(dumy), 0);
				wr.String("     DEVICE_GPU_OVERLAP_NV: "); IF dumy = CL.CL_TRUE THEN wr.String(" true"); ELSE wr.String(" false"); END; wr.Ln;

				err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_KERNEL_EXEC_TIMEOUT_NV, SIZEOF(LONGINT), ADDRESSOF(dumy), 0);
				wr.String("     DEVICE_KERNEL_EXEC_TIMEOUT_NV: "); IF dumy = CL.CL_TRUE THEN wr.String(" true"); ELSE wr.String(" false"); END; wr.Ln;

				err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_INTEGRATED_MEMORY_NV, SIZEOF(LONGINT), ADDRESSOF(dumy), 0);
				wr.String("     DEVICE_INTEGRATED_MEMORY_NV: "); IF dumy = CL.CL_TRUE THEN wr.String(" true"); ELSE wr.String(" false"); END; wr.Ln;
			END;

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_PREFERRED_VECTOR_WIDTH_CHAR, SIZEOF(LONGINT), ADDRESSOF(dumy), 0);
			wr.String("DEVICE_PREFERRED_VECTOR_WIDTH < t >: ");
			wr.String(" CHAR  "); wr.Int(dumy,0);

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_PREFERRED_VECTOR_WIDTH_SHORT, SIZEOF(LONGINT), ADDRESSOF(dumy), 0);
			wr.String(", SHORT "); wr.Int(dumy,0);

			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_PREFERRED_VECTOR_WIDTH_INT, SIZEOF(LONGINT), ADDRESSOF(dumy), 0);
			wr.String(", INT "); wr.Int(dumy,0);
			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_PREFERRED_VECTOR_WIDTH_LONG, SIZEOF(LONGINT), ADDRESSOF(dumy), 0);
			wr.String(", LONG "); wr.Int(dumy,0);
			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_PREFERRED_VECTOR_WIDTH_FLOAT, SIZEOF(LONGINT), ADDRESSOF(dumy), 0);
			wr.String(", FLOAT "); wr.Int(dumy,0);
			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_PREFERRED_VECTOR_WIDTH_DOUBLE, SIZEOF(LONGINT), ADDRESSOF(dumy), 0);
			wr.String(", DOUBLE "); wr.Int(dumy,0); wr.Ln;

			(* get supported image formats *)
			context := CL.CreateContext(0, 1, ADDRESSOF(deviceids[j]), NIL , NIL, err);
			IF err # CL.SUCCESS THEN
				wr.String("ERROR: can not create context: "); wr.String(Utils.GetError(err)); wr.Ln; wr.Update;
				RETURN;
			END;

			IF context = 0 THEN
				wr.String('Error: Cannot create context!'); wr.Ln; wr.Update;
				RETURN
			END;

			wr.String("-------------------------------------"); wr.Ln;
			err := CL.GetSupportedImageFormats(context, CL.MEM_READ_ONLY, CL.MEM_OBJECT_IMAGE2D, 0, 0, ADDRESSOF(nimageformats));
			IF err = CL.SUCCESS THEN
				NEW(imageformats, nimageformats);
				err := CL.GetSupportedImageFormats(context, CL.MEM_READ_ONLY, CL.MEM_OBJECT_IMAGE2D, nimageformats, ADDRESSOF(imageformats[0]), 0);
				IF err = CL.SUCCESS THEN
					wr.String(" 2D- Image formats supported MEM_READ_ONLY: "); wr.Int(nimageformats,0); wr.Ln;
					wr.String(" #          Channel order          Channel Type"); wr.Ln; wr.Update;
					FOR k := 0 TO nimageformats-1 DO
						wr.Int(k+1,0); wr.String("             "); wr.String(Utils.ImageFormatString(imageformats[k].image_channel_order)); wr.String("         ");
						wr.String(Utils.ImageFormatString(imageformats[k].image_channel_data_type)); wr.Ln;
					END;
					wr.Update;
				END;
			END;


			wr.String("-------------------------------------"); wr.Ln;
			err := CL.GetSupportedImageFormats(context, CL.MEM_WRITE_ONLY, CL.MEM_OBJECT_IMAGE2D, 0, 0, ADDRESSOF(nimageformats));
			IF err = CL.SUCCESS THEN
				NEW(imageformats, nimageformats);
				err := CL.GetSupportedImageFormats(context, CL.MEM_WRITE_ONLY, CL.MEM_OBJECT_IMAGE2D, nimageformats, ADDRESSOF(imageformats[0]), 0);
				IF err = CL.SUCCESS THEN
					wr.String(" 2D- Image formats supported MEM_WRITE_ONLY: "); wr.Int(nimageformats,0); wr.Ln;
					wr.String(" #          Channel order          Channel Type"); wr.Ln; wr.Update;
					FOR k := 0 TO nimageformats-1 DO
						wr.Int(k+1,0); wr.String("             "); wr.String(Utils.ImageFormatString(imageformats[k].image_channel_order)); wr.String("         ");
						wr.String(Utils.ImageFormatString(imageformats[k].image_channel_data_type)); wr.Ln;
					END;
					wr.Update;
				END;
			END;


			imageformats := NIL;
			wr.String("-------------------------------------"); wr.Ln;
			err := CL.GetSupportedImageFormats(context, CL.MEM_READ_ONLY, CL.MEM_OBJECT_IMAGE3D, 0, 0, ADDRESSOF(nimageformats));
			IF err = CL.SUCCESS THEN
				NEW(imageformats, nimageformats);
				err := CL.GetSupportedImageFormats(context, CL.MEM_READ_ONLY, CL.MEM_OBJECT_IMAGE3D, nimageformats, ADDRESSOF(imageformats[0]), 0);
				IF err = CL.SUCCESS THEN
					wr.String(" 3D- Image formats supported : "); wr.Int(nimageformats,0); wr.Ln;
					wr.String(" #          Channel order          Channel Type"); wr.Ln; wr.Update;
					FOR k := 0 TO nimageformats-1 DO
						wr.Int(k+1,0); wr.String("             "); wr.String(Utils.ImageFormatString(imageformats[k].image_channel_order)); wr.String("         ");
						wr.String(Utils.ImageFormatString(imageformats[k].image_channel_data_type)); wr.Ln;
					END;
					wr.Update;
				END;
			END;

			err := CL.ReleaseContext(context);
			(* *********** *)
			err := CL.GetDeviceInfo(deviceids[j],CL.DEVICE_PROFILE,  LEN(buf), ADDRESSOF(buf[0]), 0);
			 wr.String("DEVICE PROFILE: "); wr.String(buf); wr.Ln;
			(* *********** *)
			
			wr.Update;
		END;
	END;

	deviceids := NIL;
	platformids := NIL;
	wr.String("******************************************"); wr.Ln;
	wr.Update;
END Show;

BEGIN
	Streams.OpenWriter(wr, KernelLog.Send);
END OpenCLInfo.

System.Free OpenCLInfo ~

System.FreeDownTo OpenCL ~


OpenCLInfo.Show ~
