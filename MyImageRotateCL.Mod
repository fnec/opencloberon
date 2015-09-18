MODULE MyImageRotateCL; (** AUTHOR "fnecati"; PURPOSE "A demo for image rotation using OpenCL"; *)
(*
	kernel program adapted from:
	JOCL - Java bindings for OpenCL
	Copyright 2010 Marco Hutter - http://www.jocl.org/

  A simple example demonstrating image handling between OpenCLOberon
  and Aos WM. It shows an animation of a rotating image,
  which is rotated using an OpenCL kernel involving some
  basic image operations.
 *)

IMPORT
	Raster, WMRectangles, WMGraphics, Modules, Strings, Kernel, Commands,
	WM := WMWindowManager,  WMMessages, KernelLog, WMDialogs, Streams,
	CL := OpenCL, Utils := OpenCLUtils;

TYPE
	IVector = ARRAY [*] OF LONGINT;

	KillerMsg = OBJECT
	END KillerMsg;

	Window* =  OBJECT(WM.BufferWindow)
	VAR
		timer: Kernel.MilliTimer;
		alive, animated: BOOLEAN;
		stitle: ARRAY 128 OF CHAR;


    		inputImage: Raster.Image; (* input image *)
    		outputImage: Raster.Image; (* output image *)
		mode: Raster.Mode;

		platformids: POINTER TO ARRAY OF CL.cl_platform_id;
		platform: CL.cl_platform_id;
		nplatforms: LONGINT;

		deviceids : POINTER TO ARRAY OF CL.cl_device_id;
		deviceid: CL.cl_device_id;
		ndevices: LONGINT;

		context : CL.cl_context;
		commands : CL.cl_command_queue;
		prog      : CL.cl_program;       (* compute program *)
		kernel    : CL.cl_kernel;         (* compute kernel *)

		inputImageMem   : CL.cl_mem;  (* device memory used for the input image *)
		outputImageMem: CL.cl_mem;  (* device memory used for the output image *)

		kernelsource: Strings.String;

		angle : REAL;
		inited : BOOLEAN;

		globalWorkSize: IVector;

		origin, region: POINTER TO ARRAY OF CL.size_t;
		endrotate: BOOLEAN;

		PROCEDURE &New(inputImage0: Raster.Image);
		BEGIN
			inputImage := inputImage0;
 			
			Init(inputImage.width, inputImage.height, TRUE);
			manager := WM.GetDefaultManager();
			manager.Add(100, 100, SELF, {WM.FlagFrame, WM.FlagClose, WM.FlagNoResizing});
			SetTitle(Strings.NewString("SimpleImageCL:"));

			Raster.InitMode(mode, Raster.srcCopy);
			NEW(outputImage);
			Raster.Create(outputImage, inputImage.width, inputImage.height, Raster.BGRA8888);

			IF ~ InitCL() THEN Close; RETURN END;

			initImageMem(inputImage);
			inited := TRUE;
						
			animated := FALSE;
			alive := TRUE;
			angle := 0;
			RotateImage;
			IncCount;
		END New;

		PROCEDURE InitCL(): BOOLEAN;
		VAR
			err: LONGINT;
			imageSupport: LONGINT;
			properties: HUGEINT; (* CL.bit_field *)

		BEGIN

			err := CL.GetPlatformIDs( 0, 0, ADDRESSOF(nplatforms) );
			out.String("clGetPlatformIDs nplatforms: "); out.String(Utils.GetError(err)); out.Ln;
			IF (err # CL.SUCCESS) OR (nplatforms=0) THEN
				out.String('Error: Cannot get # of platforms!'); out.Ln; out.Update;
				RETURN FALSE
			END;

			NEW(platformids, nplatforms);

			err := CL.GetPlatformIDs( nplatforms, ADDRESSOF(platformids[0]), 0 );
			out.String("clGetPlatformIDs : "); out.String(Utils.GetError(err)); out.Ln;
			IF (err # CL.SUCCESS) THEN
				out.String('Error: Cannot get platforms!'); out.Ln; out.Update;
				RETURN FALSE
			END;

		    	platform := platformids[0];

			(*  Devices  *)

			 err := CL.GetDeviceIDs (platform, CL.DEVICE_TYPE_GPU, 0, 0 , ADDRESSOF(ndevices));
		      IF (err # CL.SUCCESS) OR (ndevices = 0) THEN
			        out.String("clGetDeviceIDs Error: "); out.String(Utils.GetError(err)); out.Ln;
		          out.String('Error: Cannot get number of GPU devices!'); out.Ln; out.Update;
		          RETURN FALSE
		       END;

			NEW(deviceids, ndevices);
			err := CL.GetDeviceIDs(platform, CL.DEVICE_TYPE_GPU, ndevices, ADDRESSOF(deviceids[0]), 0);
			out.String("clGetDeviceIDs : "); out.String(Utils.GetError(err)); out.Ln;
			IF (err # CL.SUCCESS) THEN
				out.String('Error: Cannot get devices!'); out.Ln; out.Update;
				RETURN FALSE
			END;
			deviceid := deviceids[0];


			err := CL.GetDeviceInfo(deviceid, CL.DEVICE_IMAGE_SUPPORT, SIZEOF(CL.cl_int), ADDRESSOF(imageSupport), 0);
			IF err = CL.SUCCESS THEN
				IF imageSupport = 0 THEN
					 KernelLog.String("No Image Support"); KernelLog.Ln;
					 RETURN FALSE;;
				 END;
			ELSE
				 KernelLog.String("ERROR clGetDeviceInfo: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
				 RETURN FALSE;
			END;

			context := CL.CreateContext(0, 1, ADDRESSOF(deviceid), NIL , NIL, err);
			IF err # CL.SUCCESS THEN
				 KernelLog.String("ERROR clCreateContext: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
				 RETURN FALSE;
			END;

			(* with event profile *)
			properties := CL.QUEUE_PROFILING_ENABLE + CL.QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE;
			commands := CL.CreateCommandQueue(context, deviceid, properties , err);
			IF err # CL.SUCCESS THEN
				 KernelLog.String("ERROR clCreateCommandQueue: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
				 RETURN FALSE;
			END;

			kernelsource := MyProgramSource();
			prog := Utils.BuildProgramFromStringSource(context, kernelsource^,"", err);
			IF (prog=0) OR (err # CL.SUCCESS) THEN
				 KernelLog.String("ERROR Utils.BuildProgramFromStringSource: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
				 RETURN FALSE;
			END;

			kernel := CL.CreateKernel(prog, "rotateImage", err);
			IF err # CL.SUCCESS THEN
				 KernelLog.String("ERROR clCreateKernel: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
				 RETURN FALSE;
			END;
			RETURN TRUE;
		END InitCL;

		 PROCEDURE initImageMem(inputImage0 :Raster.Image);
		 VAR imageFormat: CL.cl_image_format;
		 	err: LONGINT;
		 BEGIN
		        (* Create the memory object for the input- and output image *)

				NEW(origin,3); 	NEW(region,3);
				globalWorkSize := [inputImage0.width, inputImage0.height];

				imageFormat.image_channel_order := CL.RGBA;
				imageFormat.image_channel_data_type := CL.UNSIGNED_INT8;

		        inputImageMem := CL.CreateImage2D(
		            context, CL.MEM_READ_ONLY+ CL.MEM_USE_HOST_PTR,
		            imageFormat, inputImage0.width, inputImage0.height,
		            inputImage0.width * SIZEOF(CL.cl_uint), inputImage0.adr, err);
			   IF err # CL.SUCCESS THEN
				  KernelLog.String("ERROR inputImageMem clCreateImage2D: ");  KernelLog.String(Utils.GetError(err));
				  KernelLog.Ln;
			   END;

			  (* create empty outputImageMem with the same size and type *)
		        outputImageMem := CL.CreateImage2D(
		            context, CL.MEM_WRITE_ONLY,
		            imageFormat, inputImage0.width, inputImage0.height, 0, 0, err);
		 	   IF err # CL.SUCCESS THEN
				  KernelLog.String("ERROR outputImageMem clCreateImage2D: ");  KernelLog.String(Utils.GetError(err));
				  KernelLog.Ln;
			   END;
		(*	   err := CL.GetImageInfo(inputImageMem, CL.IMAGE_FORMAT, SIZEOF(CL.cl_image_format), ADDRESSOF(imfmt), ADDRESSOF(ret));
			   IF err # CL.SUCCESS THEN
				  KernelLog.String("ERROR clGetImageInfo - Format: ");  KernelLog.String(Utils.GetError(err));
				  KernelLog.Ln;
			  END;
			  KernelLog.String("inputImage channel_order: ");  KernelLog.String(Utils.ImageFormatString(imfmt.image_channel_order)^); KernelLog.Ln;
		  	  KernelLog.String("inputImage image_channel_data_type: ");  KernelLog.String(Utils.ImageFormatString(imfmt.image_channel_data_type)^); KernelLog.Ln;
			  err := CL.GetImageInfo(inputImageMem, CL.IMAGE_WIDTH, SIZEOF(CL.csize_t), ADDRESSOF(tmp), ADDRESSOF(ret));
			  KernelLog.String("width= "); KernelLog.Int(tmp, 0); KernelLog.Ln;

			  err := CL.GetImageInfo(inputImageMem, CL.IMAGE_HEIGHT, SIZEOF(CL.csize_t), ADDRESSOF(tmp), ADDRESSOF(ret));
			  KernelLog.String("height= "); KernelLog.Int(tmp, 0); KernelLog.Ln;
		*)
		END initImageMem;

		PROCEDURE KeyEvent* (ucs: LONGINT; flags: SET; keysym: LONGINT);
		BEGIN
			CASE CHR(ucs) OF
			 "r" : angle  := angle + 0.1; RotateImage;
			| "l": angle := angle - 0.1; RotateImage;
			| "a" : BEGIN{EXCLUSIVE} animated := ~animated; END; 
			| "q" : Close;
			| "s": SaveImage;
			ELSE
			END;
		END KeyEvent;

		PROCEDURE Handle(VAR m: WMMessages.Message);
		BEGIN
			IF (m.msgType = WMMessages.MsgExt) & (m.ext # NIL) & (m.ext IS KillerMsg) THEN
				Close;
			ELSE Handle^(m)
			END
		END Handle;
	
		PROCEDURE Draw*(canvas : WMGraphics.Canvas; w, h, q : LONGINT);
		BEGIN
			Draw^(canvas, w, h, 0)
		END Draw;

		PROCEDURE Close*;
		VAR err: LONGINT;
		BEGIN
			BEGIN {EXCLUSIVE} alive := FALSE; animated := FALSE; AWAIT(endrotate) END;
			(* Free resources *)
			IF inited THEN
				
				err := CL.ReleaseMemObject(inputImageMem);
				err := CL.ReleaseMemObject(outputImageMem);
				err := CL.ReleaseKernel(kernel);
				err := CL.ReleaseProgram(prog);
				err := CL.ReleaseCommandQueue(commands);
				err := CL.ReleaseContext(context);
			END;
			
			Close^;
			DecCount;
		END Close;

		(* calculate execution time for the event *)
		PROCEDURE ExecutionTime(name: ARRAY OF CHAR; ke, re: CL.cl_event);
		VAR ksec, rsec: LONGREAL;
			err: LONGINT;
			endtime, starttime: HUGEINT;
			stime: ARRAY 128 OF CHAR;
		BEGIN
			COPY(name, stitle);
			err := CL.GetEventProfilingInfo(ke , CL.PROFILING_COMMAND_END, SIZEOF(HUGEINT), ADDRESSOF(endtime),0);
			err := CL.GetEventProfilingInfo(ke, CL.PROFILING_COMMAND_START, SIZEOF(HUGEINT), ADDRESSOF(starttime), 0);

			ksec := 1.0D-3*(endtime-starttime);   (* ns -> us *)

			Strings.FloatToStr(ksec, 0,1,0, stime);
			Strings.Append(stitle, stime);
			Strings.Append(stitle, ", ");

			err := CL.GetEventProfilingInfo(re , CL.PROFILING_COMMAND_END, SIZEOF(HUGEINT), ADDRESSOF(endtime),0);
			err := CL.GetEventProfilingInfo(re, CL.PROFILING_COMMAND_START, SIZEOF(HUGEINT), ADDRESSOF(starttime), 0);

			rsec := 1.0D-3*(endtime-starttime);   (* ns -> us *)
			Strings.FloatToStr(rsec, 0,1,0, stime);
			Strings.Append(stitle, stime);
			Strings.Append(stitle, " us.");
		END ExecutionTime;

		PROCEDURE RotateImage;
		VAR err: LONGINT;
			elapsed: LONGINT;
			str1 : ARRAY 128 OF CHAR;
			kernelEvent, readEvent: CL.cl_event;
		BEGIN
				BEGIN {EXCLUSIVE} endrotate:= FALSE END;
				IF angle>1000.0 THEN angle :=0.0; END;

				 Kernel.SetTimer(timer,0);

	     		err := CL.SetKernelArg(kernel, 0, SIZEOF(CL.cl_mem), ADDRESSOF(inputImageMem));
	     		IF err # CL.SUCCESS THEN
					 KernelLog.String("ERROR clSetKernelArg-0: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
					 RETURN
				END;
	     		err := CL.SetKernelArg(kernel, 1, SIZEOF(CL.cl_mem), ADDRESSOF(outputImageMem));
	     		IF err # CL.SUCCESS THEN
					 KernelLog.String("ERROR clSetKernelArg-1: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
					 RETURN
				END;

	     		err := CL.SetKernelArg(kernel, 2, SIZEOF(CL.cl_float),  ADDRESSOF(angle));
	     		IF err # CL.SUCCESS THEN
					 KernelLog.String("ERROR clSetKernelArg-2: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
					 RETURN
				END;

        			err := CL.EnqueueNDRangeKernel(commands, kernel, 2, 0, ADDRESSOF(globalWorkSize[0]), 0, 0, 0, ADDRESSOF(kernelEvent));
	     		IF err # CL.SUCCESS THEN
					 KernelLog.String("ERROR clEnqueueNDRangeKernel: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
					 RETURN
				END;

				(* Wait for the the event, i.e. until the kernel is completed *)
				err := CL.WaitForEvents(1, ADDRESSOF(kernelEvent));

        			(* Read the pixel data into the output image *)
        			origin[0] := 0; origin[1] := 0; origin[2] := 0;
        			region[0] := inputImage.width; region[1] := inputImage.height; region [2] := 1;

				err := CL.EnqueueReadImage(commands, outputImageMem, CL.CL_TRUE, ADDRESSOF(origin[0]), ADDRESSOF(region[0]),  inputImage.width * SIZEOF(CL.cl_uint), 0, outputImage.adr, 0, 0, ADDRESSOF(readEvent));
				IF err # CL.SUCCESS THEN
					KernelLog.String("ERROR clEnqueueReadImage: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
					RETURN
				END;

			 	(* Wait for the the event, i.e. until the result is read *)
				err := CL.WaitForEvents(1, ADDRESSOF(readEvent));

				Raster.Copy(outputImage,img, 0,0, img.width, img.height, 0, 0, mode);
				Invalidate(WMRectangles.MakeRect(0, 0, GetWidth(), GetHeight()));

				(*  write timing info  *)
				elapsed := Kernel.Elapsed(timer);
				Strings.IntToStr(elapsed, str1);

			 (*  write timing info for kernels, readbuffer *)
				ExecutionTime("SimpleImageCL:kernel, read time: ",kernelEvent, readEvent);
				Strings.Append(stitle, ", Total:");
				Strings.Append(stitle, str1);
				Strings.Append(stitle, " ms.");
				SetTitle(Strings.NewString(stitle));
				
				BEGIN {EXCLUSIVE} endrotate:= TRUE END;
				(* out.String(stitle); out.Ln; out.Update; *)
		END RotateImage;

		PROCEDURE SaveImage;
		VAR res: LONGINT;
			fname: ARRAY 128 OF CHAR;
		BEGIN
		fname:="simpleimage.bmp";
		IF WMDialogs.QueryString(" Save File name: ",fname)=WMDialogs.ResOk THEN
				WMGraphics.StoreImage(img,fname,res);
		END;
		END SaveImage;

	BEGIN  {ACTIVE}
		WHILE alive DO
			BEGIN {EXCLUSIVE} AWAIT(animated) END;
			RotateImage;
			angle := angle + 0.1;
		END;
	END Window;


VAR
		out: Streams.Writer;
		nofWindows: LONGINT;

PROCEDURE Open*(ctx: Commands.Context);
VAR fname: ARRAY 128 OF CHAR;
	 img: Raster.Image;
	 window: Window;
BEGIN
	IF ~ ctx.arg.GetString(fname) THEN RETURN END;

	img := WMGraphics.LoadImage(fname, FALSE);
	IF img = NIL THEN
		KernelLog.String(fname); KernelLog.String(" Not Loaded"); KernelLog.Ln;
		RETURN
	END;

	KernelLog.String(fname); KernelLog.String("  loaded.."); KernelLog.Ln;


	NEW(window, img);

END Open;


PROCEDURE IncCount;
BEGIN {EXCLUSIVE}
	INC(nofWindows)
END IncCount;

PROCEDURE DecCount;
BEGIN {EXCLUSIVE}
	DEC(nofWindows)
END DecCount;

PROCEDURE Cleanup*;
VAR die : KillerMsg;
	 msg : WMMessages.Message;
	 m : WM.WindowManager;
BEGIN {EXCLUSIVE}
	NEW(die);
	msg.ext := die;
	msg.msgType := WMMessages.MsgExt;
	m := WM.GetDefaultManager();
	m.Broadcast(msg);
	AWAIT(nofWindows = 0)
END Cleanup;


PROCEDURE MyProgramSource(): Strings.String;
VAR 
      buf: Strings.String;
BEGIN
	NEW(buf, 1200);

buf^ :="
const sampler_t samplerIn =
            CLK_NORMALIZED_COORDS_FALSE |
            CLK_ADDRESS_CLAMP |
            CLK_FILTER_NEAREST;

const sampler_t samplerOut =
            CLK_NORMALIZED_COORDS_FALSE |
            CLK_ADDRESS_CLAMP |
            CLK_FILTER_NEAREST;
            
__kernel void rotateImage(
		__read_only  image2d_t sourceImage, 
		__write_only image2d_t targetImage, 
		float angle)
 {
   int gidX = get_global_id(0);
   int gidY = get_global_id(1);
   int w = get_image_width(sourceImage);
   int h = get_image_height(sourceImage);
   int cx = w/2;
   int cy = h/2;
   int dx = gidX-cx;
   int dy = gidY-cy;
   float ca = cos(angle);
   float sa = sin(angle);
   int inX = (int)(cx+ca*dx-sa*dy);
   int inY = (int)(cy+sa*dx+ca*dy);
   int2 posIn = {inX, inY};
   int2 posOut = {gidX, gidY};
   uint4 pixel = read_imageui(sourceImage, samplerIn, posIn);            
   write_imageui(targetImage, posOut, pixel);
}
";

	RETURN buf;
END MyProgramSource;

BEGIN
	Modules.InstallTermHandler(Cleanup);
	Streams.OpenWriter(out, KernelLog.Send);
END MyImageRotateCL.

SystemTools.FreeDownTo OpenCL ~

SystemTools.Free  MyImageRotateCL~

MyImageRotateCL.Open "mars.png" ~

MyImageRotateCL.Open "BluebottlePic0.png" ~

MyImageRotateCL.Open "test.bmp"

MyImageRotateCL.Open "WMIcons.tar://WMKernelLog.png" ~


