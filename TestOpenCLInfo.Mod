MODULE TestOpenCLInfo;
IMPORT CL:=OpenCL, S:=SYSTEM, KernelLog, Streams, Machine, Strings, Utils:=OpenCLUtils;


TYPE 
	Int3Array=ARRAY 3 OF LONGINT;
	
VAR 
	wr: Streams.Writer;

(* write HUGEINT value as MByte*)	
PROCEDURE WriteHintMB(wr: Streams.Writer; x: HUGEINT );
VAR
	  xi: LONGINT;
BEGIN
 	xi := SHORT(Machine.DivH(x,1024*1024));
	wr.Int(xi,5);	
END WriteHintMB;

(* write HUGEINT value as KByte*)	
PROCEDURE WriteHintKB(wr: Streams.Writer; x: HUGEINT );
VAR
	  xi: LONGINT;
BEGIN
 	xi := SHORT(Machine.DivH(x,1024));
	wr.Int(xi,5);	
END WriteHintKB;

  
(** Show OpenCL infos *)
PROCEDURE Info*;
VAR i, j,k: LONGINT;
 err     : LONGINT; (* error code returned from api calls*)
  platformids  : CL.Pcl_platform_id;
  nplatforms : LONGINT; (*CL.cl_uint;*)
  ndevices :  CL.cl_uint;
  deviceids : CL.Pcl_device_id;
  buf  :  ARRAY 1024 OF  CHAR;
  buflen: LONGINT;
  bufwritten: LONGINT;
  computeunits: LONGINT;
  dumy: LONGINT;
  hdumy: HUGEINT;
  
  idevices: LONGINT;
  memsize: HUGEINT;
  devtype: HUGEINT; (* CL.cl_bitfield *)
  workitemsize: Int3Array;
  nv_extension_query	: BOOLEAN;
BEGIN 

  err := CL.clGetPlatformIDs(0, 0 , S.ADR(nplatforms));
  IF (err  # CL.SUCCESS) THEN
      wr.String('Error: Cannot get number of platforms!'); wr.Ln; wr.Update;
      RETURN;
  END;

  wr.String("# platforms found = "); wr.Int(nplatforms,0); wr.Ln; wr.Update;
 
  NEW(platformids, nplatforms);
 err := CL.clGetPlatformIDs( nplatforms, S.ADR(platformids[0]), 0 ); 
  IF (err # CL.SUCCESS) THEN
      wr.String('Error: Cannot get platforms!'); wr.Ln; wr.Update;
      RETURN
    END;
    
 
  FOR i := 0 TO nplatforms-1 DO
   
      wr.String('Platform info '); wr.Int(i,0); wr.Ln;
      

     err := CL.clGetPlatformInfo(platformids[i], CL.PLATFORM_PROFILE, LEN(buf), S.ADR(buf[0]), bufwritten); 
      wr.String('PROFILE: '); wr.String(buf); wr.Ln;
      
     err := CL.clGetPlatformInfo(platformids[i],CL.PLATFORM_VERSION, LEN(buf), S.ADR(buf[0]), bufwritten);
      wr.String('VERSION: '); wr.String(buf); wr.Ln;
      
      err := CL.clGetPlatformInfo(platformids[i],CL.PLATFORM_NAME, LEN(buf), S.ADR(buf[0]), bufwritten);
       wr.String('NAME: '); wr.String(buf); wr.Ln;
      
      err := CL.clGetPlatformInfo(platformids[i],CL.PLATFORM_VENDOR, LEN(buf), S.ADR(buf[0]), bufwritten);
      wr.String('VENDOR: '); wr.String(buf); wr.Ln;
      
      err := CL.clGetPlatformInfo(platformids[i], CL.PLATFORM_EXTENSIONS, LEN(buf), S.ADR(buf[0]), bufwritten);
      wr.String('EXTENSIONS: '); wr.String(buf); wr.Ln; 
    
      wr.Update;
      
	(*  Devices  *)

      err := CL.clGetDeviceIDs (platformids[i], CL.DEVICE_TYPE_ALL, 0, 0 , S.ADR(ndevices));
      IF (err # CL.SUCCESS) THEN
	        wr.String("clGetDeviceIDs Error: "); wr.String(Utils.ErrorToStr(err)); wr.Ln; 	       
          wr.String('Error: Cannot get number of devices!'); wr.Ln; wr.Update;
          RETURN
       END;

     
   wr.Int(ndevices, 0); wr.String(" device(s) found"); wr.Ln; wr.Update;

   IF ndevices =0 THEN RETURN END;
   
   NEW(deviceids, ndevices);
	     
      err := CL.clGetDeviceIDs(platformids[i], CL.DEVICE_TYPE_ALL, ndevices, S.ADR(deviceids[0]), 0);
          IF (err # CL.SUCCESS) THEN
	        wr.String("clGetDeviceIDs Error: "); wr.String(Utils.ErrorToStr(err)); wr.Ln; 	
          wr.String('Error: Cannot get number of devices-2!'); wr.Ln; wr.Update;
          RETURN
       END;

         FOR j := 0 TO ndevices-1 DO
   	
         wr.String("*****************************************"); wr.Ln;
          wr.String('Device info:  '); wr.Int(j,0); wr.Ln;
    
          err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_NAME, LEN(buf), S.ADR(buf[0]), bufwritten);
             wr.String("DEVICE NAME: "); wr.String(buf); wr.Ln;

          err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_VENDOR, LEN(buf), S.ADR(buf[0]), bufwritten);
             wr.String("DEVICE VENDOR: "); wr.String(buf); wr.Ln;
             
         err := CL.clGetDeviceInfo(deviceids[j],CL.DRIVER_VERSION, LEN(buf), S.ADR(buf[0]), bufwritten);
             wr.String("DRIVER VERSION: "); wr.String(buf); wr.Ln;

        err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_VERSION, LEN(buf), S.ADR(buf[0]), bufwritten);
             wr.String("DEVICE VERSION: "); wr.String(buf); wr.Ln;
             
   		IF Strings.Pos("OpenCL 1.0", buf) = -1 THEN
		        err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_OPENCL_C_VERSION, LEN(buf), S.ADR(buf[0]), bufwritten);
		        wr.String("DEVICE_OPENCL_C_VERSION: "); wr.String(buf); wr.Ln;
		END;

       err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_TYPE,  S.SIZEOF(HUGEINT), S.ADR(devtype), bufwritten);      	
             wr.String("DEVICE_TYPE: ");
             IF CL.DEVICE_TYPE_CPU IN S.VAL(SET,devtype) THEN   wr.String("DEVICE_TYPE_CPU"); END;
             IF CL.DEVICE_TYPE_GPU IN   S.VAL(SET,devtype) THEN wr.String("DEVICE_TYPE_GPU"); END;
             IF CL.DEVICE_TYPE_ACCELERATOR IN S.VAL(SET,devtype) THEN   wr.String("DEVICE_TYPE_ACCELERATOR"); END;
             IF CL.DEVICE_TYPE_DEFAULT IN S.VAL(SET,devtype) THEN wr.String("DEVICE_TYPE_DEFAULT"); END;
             wr.Ln;

          err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_MAX_COMPUTE_UNITS, S.SIZEOF(LONGINT), S.ADR(computeunits), bufwritten);
             wr.String("DEVICE_MAX_COMPUTE_UNITS: "); wr.Int(computeunits,0); wr.Ln;

         err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_MAX_WORK_ITEM_DIMENSIONS, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("DEVICE_MAX_WORK_ITEM_DIMENSIONS: "); wr.Int(dumy,0); wr.Ln;               
  
          err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_MAX_WORK_ITEM_SIZES,  S.SIZEOF(Int3Array), S.ADR(workitemsize), bufwritten);
             wr.String("DEVICE_MAX_WORK_ITEM_SIZES: "); wr.Int(workitemsize[0],5); wr.String(" x "); wr.Int(workitemsize[1],0);  wr.String(" x "); wr.Int(workitemsize[2],0); wr.Ln;
 
          err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_MAX_WORK_GROUP_SIZE, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("DEVICE_MAX_WORK_GROUP_SIZE: "); wr.Int(dumy,0); wr.Ln;       
             
           err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_MAX_CLOCK_FREQUENCY, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("DEVICE_MAX_CLOCK_FREQUENCY: "); wr.Int(dumy,0); wr.String(" MHz"); wr.Ln;       
 
         err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_ADDRESS_BITS, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("DEVICE_ADDRESS_BITS: "); wr.Int(dumy,0); wr.Ln;       
 
         err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_MAX_MEM_ALLOC_SIZE, S.SIZEOF(HUGEINT), S.ADR(memsize), bufwritten);
             wr.String("DEVICE_MAX_MEM_ALLOC_SIZE: "); WriteHintMB( wr, memsize); wr.String(" MByte"); wr.Ln;
             
         err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_GLOBAL_MEM_SIZE, S.SIZEOF(HUGEINT), S.ADR(memsize), bufwritten);
             wr.String("DEVICE_GLOBAL_MEM_SIZE: "); WriteHintMB( wr, memsize); wr.String(" MByte"); wr.Ln;
 
 
         err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_ERROR_CORRECTION_SUPPORT, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("DEVICE_ERROR_CORRECTION_SUPPORT: "); IF dumy=0 THEN wr.String(" no"); ELSE wr.String(" yes"); END; wr.Ln;
 
        err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_LOCAL_MEM_TYPE, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("DEVICE_LOCAL_MEM_TYPE: "); IF dumy=1 THEN wr.String(" local"); ELSE wr.String(" global"); END; wr.Ln; 
                                     
         err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_LOCAL_MEM_SIZE,  S.SIZEOF(HUGEINT), S.ADR(memsize), bufwritten);
             wr.String("DEVICE_LOCAL_MEM_SIZE: "); WriteHintKB(wr, memsize); wr.String(" KByte");  wr.Ln; 
 
          err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_MAX_CONSTANT_BUFFER_SIZE, S.SIZEOF(HUGEINT), S.ADR(memsize), bufwritten);
             wr.String("DEVICE_MAX_CONSTANT_BUFFER_SIZE: "); WriteHintKB(wr, memsize); wr.String(" KByte");  wr.Ln; 
 
          err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_QUEUE_PROPERTIES, S.SIZEOF(HUGEINT), S.ADR(hdumy), bufwritten);
           
             IF CL.QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE IN S.VAL(SET,hdumy)  THEN wr.String("DEVICE_QUEUE_PROPERTIES: QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE"); END; wr.Ln;
             IF CL.QUEUE_PROFILING_ENABLE IN S.VAL(SET,hdumy) THEN wr.String("DEVICE_QUEUE_PROPERTIES: QUEUE_PROFILING_ENABLE"); END; wr.Ln;
    
		err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_IMAGE_SUPPORT, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("DEVICE_MAGE_SUPPORT: "); IF dumy=1 THEN wr.String(" true"); ELSE wr.String(" false"); END; wr.Ln;      
     
		err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_MAX_READ_IMAGE_ARGS, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("DEVICE_MAX_READ_IMAGE_ARGS: "); wr.Int(dumy,0); wr.Ln;      

		err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_MAX_WRITE_IMAGE_ARGS, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("DEVICE_MAX_WRITE_IMAGE_ARGS: "); wr.Int(dumy,0); wr.Ln;      

    	   err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_SINGLE_FP_CONFIG, S.SIZEOF(HUGEINT), S.ADR(hdumy), bufwritten);
    	   wr.String("DEVICE_SINGLE_FP_CONFIG: ");
          IF CL.FP_DENORM IN S.VAL(SET,hdumy)  THEN wr.String(" denorms  "); END;
          IF CL.FP_INF_NAN IN S.VAL(SET,hdumy)  THEN wr.String(" INF-quietNaNs  "); END;          
	   IF CL.FP_ROUND_TO_NEAREST IN S.VAL(SET,hdumy)  THEN wr.String(" round-to-nearest  "); END;   
          IF CL.FP_ROUND_TO_ZERO IN S.VAL(SET,hdumy)  THEN wr.String(" round-to-zero  "); END;   
	   IF CL.FP_ROUND_TO_INF IN S.VAL(SET,hdumy)  THEN wr.String(" round-to-inf  "); END;         
	   IF CL.FP_FMA IN S.VAL(SET,hdumy)  THEN wr.String(" fma  "); END;  
         wr.Ln;

	
      err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_IMAGE2D_MAX_WIDTH, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
      wr.String("DEVICE_IMAGE <dim> "); wr.Ln;
             wr.String("     IMAGE2D_MAX_WIDTH: "); wr.Int(dumy,0); wr.Ln; 
      err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_IMAGE2D_MAX_HEIGHT, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("     IMAGE2D_MAX_HEIGHT: "); wr.Int(dumy,0); wr.Ln;                          

         err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_IMAGE3D_MAX_WIDTH, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("     IMAGE3D_MAX_WIDTH: "); wr.Int(dumy,0); wr.Ln;               
        err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_IMAGE3D_MAX_HEIGHT, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("     IMAGE3D_MAX_HEIGHT: "); wr.Int(dumy,0); wr.Ln;
      err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_IMAGE3D_MAX_DEPTH, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("     IMAGE3D_MAX_DEPTH: "); wr.Int(dumy,0); wr.Ln;



          err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_EXTENSIONS, LEN(buf), S.ADR(buf[0]), bufwritten);
             wr.String("DEVICE EXTENSIONS: "); wr.String(buf); wr.Ln;

	nv_extension_query:= FALSE;

	IF Strings.Pos("cl_nv_device_attribute_query", buf) # -1 THEN 	nv_extension_query:= TRUE; END;
	IF nv_extension_query THEN
	
	      err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_COMPUTE_CAPABILITY_MAJOR_NV, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("     DEVICE_COMPUTE_CAPABILITY_NV: "); wr.Int(dumy,0); wr.String(".");
             err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_COMPUTE_CAPABILITY_MINOR_NV, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.Int(dumy,0); wr.Ln;
             
             wr.String("     NUMBER_OF_MULTIPROCESSORS: "); wr.Int(computeunits,0); wr.Ln; (* same as compute units *);
             wr.String("     NUMBER_OF_CUDA_CORES: ? "); wr.Ln;
             
             
		err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_WARP_SIZE_NV, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("     DEVICE_WARP_SIZE_NV: "); wr.Int(dumy,0); wr.Ln;  
             
		err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_GPU_OVERLAP_NV, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("     DEVICE_GPU_OVERLAP_NV: "); IF dumy=1 THEN wr.String(" true"); ELSE wr.String(" false"); END; wr.Ln;  

		err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_KERNEL_EXEC_TIMEOUT_NV, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("     DEVICE_KERNEL_EXEC_TIMEOUT_NV: "); IF dumy=1 THEN wr.String(" true"); ELSE wr.String(" false"); END; wr.Ln;         

		err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_INTEGRATED_MEMORY_NV, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
             wr.String("     DEVICE_INTEGRATED_MEMORY_NV: "); IF dumy=1 THEN wr.String(" true"); ELSE wr.String(" false"); END; wr.Ln;   
        END;     
        
      	err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_PREFERRED_VECTOR_WIDTH_CHAR, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
       wr.String("DEVICE_PREFERRED_VECTOR_WIDTH < t >: ");   
       		wr.String(" CHAR  "); wr.Int(dumy,0); 
      	err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_PREFERRED_VECTOR_WIDTH_SHORT, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
			wr.String(", SHORT "); wr.Int(dumy,0); 
	
      	err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_PREFERRED_VECTOR_WIDTH_INT, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
			wr.String(", INT "); wr.Int(dumy,0);
      	err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_PREFERRED_VECTOR_WIDTH_LONG, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
			wr.String(", LONG "); wr.Int(dumy,0);
      	err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_PREFERRED_VECTOR_WIDTH_FLOAT, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
			wr.String(", FLOAT "); wr.Int(dumy,0); 
      	err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_PREFERRED_VECTOR_WIDTH_DOUBLE, S.SIZEOF(LONGINT), S.ADR(dumy), bufwritten);
			wr.String(", DOUBLE "); wr.Int(dumy,0); wr.Ln;
	
	
	
(* *********** *)
         err := CL.clGetDeviceInfo(deviceids[j],CL.DEVICE_PROFILE,  LEN(buf), S.ADR(buf[0]), bufwritten);
             wr.String("DEVICEE PROFILE: "); wr.String(buf); wr.Ln;
(* *********** *)	
	
	
         wr.Update;    
    END; 

  END;    
  
  deviceids := NIL;
  platformids := NIL;    	
wr.String("******************************************"); wr.Ln;
wr.Update;
END Info;

BEGIN

Streams.OpenWriter(wr, KernelLog.Send);
END TestOpenCLInfo.

SystemTools.Free TestOpenCLInfo OpenCLUtils OpenCL~

TestOpenCLInfo.Info ~ 
