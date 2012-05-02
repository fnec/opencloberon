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
	S:=SYSTEM, CL := OpenCL, Utils := OpenCLUtils;

TYPE
	IVector = ARRAY [*] OF LONGINT;

	KillerMsg = OBJECT
	END KillerMsg;

	Window* =  OBJECT(WM.BufferWindow)
	VAR
		timer: Kernel.MilliTimer;
		alive, animated: BOOLEAN;
		 stitle: ARRAY 128 OF CHAR;

		PROCEDURE &New();
		BEGIN
			Init(inputImage.width, inputImage.height, TRUE);
			manager := WM.GetDefaultManager();
			manager.Add(100, 100, SELF, {WM.FlagFrame, WM.FlagClose, WM.FlagNoResizing});
			SetTitle(Strings.NewString("SimpleImageCL:"));
			animated := FALSE;
			alive := TRUE;
			angle := 0;
			RotateImage;
		END New;

		PROCEDURE KeyEvent* (ucs: LONGINT; flags: SET; keysym: LONGINT);
		BEGIN
			CASE CHR(ucs) OF
			 "r" : angle  := angle + 0.1; RotateImage;
			| "l": angle := angle - 0.1; RotateImage;
			| "a" : animated := ~animated; RotateImage;
			| "q" : Close;
			| "s": SaveImage;
			ELSE
			END;
		END KeyEvent;

		PROCEDURE Draw*(canvas : WMGraphics.Canvas; w, h, q : LONGINT);
		BEGIN
			Draw^(canvas, w, h, 0)
		END Draw;

		PROCEDURE Close*;
		BEGIN
			alive := FALSE;
			Close^;
			window := NIL;
		END Close;

		(* calculate execution time for the event *)
		PROCEDURE ExecutionTime(name: ARRAY OF CHAR; ke, re: CL.cl_event);
		VAR ksec, rsec: LONGREAL;
			err: LONGINT;
			endtime, starttime: HUGEINT;
			stime: ARRAY 128 OF CHAR;
		BEGIN
			COPY(name, stitle);
			err := CL.clGetEventProfilingInfo(ke , CL.PROFILING_COMMAND_END, S.SIZEOF(HUGEINT), S.ADR(endtime),0);
			err := CL.clGetEventProfilingInfo(ke, CL.PROFILING_COMMAND_START, S.SIZEOF(HUGEINT), S.ADR(starttime), 0);

			ksec := 1.0D-3*(endtime-starttime);   (* ns -> us *)

			Strings.FloatToStr(ksec, 0,1,0, stime);
			Strings.Append(stitle, stime);
			Strings.Append(stitle, ", ");

			err := CL.clGetEventProfilingInfo(re , CL.PROFILING_COMMAND_END, S.SIZEOF(HUGEINT), S.ADR(endtime),0);
			err := CL.clGetEventProfilingInfo(re, CL.PROFILING_COMMAND_START, S.SIZEOF(HUGEINT), S.ADR(starttime), 0);

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
				IF angle>1000.0 THEN angle :=0.0; END;

				 Kernel.SetTimer(timer,0);

	     		err := CL.clSetKernelArg(kernel, 0, S.SIZEOF(CL.cl_mem), S.ADR(inputImageMem));
	     		IF err # CL.SUCCESS THEN
					 KernelLog.String("ERROR clSetKernelArg-0: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
					 RETURN
				END;
	     		err := CL.clSetKernelArg(kernel, 1, S.SIZEOF(CL.cl_mem), S.ADR(outputImageMem));
	     		IF err # CL.SUCCESS THEN
					 KernelLog.String("ERROR clSetKernelArg-1: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
					 RETURN
				END;

	     		err := CL.clSetKernelArg(kernel, 2, S.SIZEOF(CL.cl_float),  S.ADR(angle));
	     		IF err # CL.SUCCESS THEN
					 KernelLog.String("ERROR clSetKernelArg-2: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
					 RETURN
				END;

        			err := CL.clEnqueueNDRangeKernel(commands, kernel, 2, 0, S.ADR(globalWorkSize[0]), 0, 0, 0, S.ADR(kernelEvent));
	     		IF err # CL.SUCCESS THEN
					 KernelLog.String("ERROR clEnqueueNDRangeKernel: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
					 RETURN
				END;

				(* Wait for the the event, i.e. until the kernel is completed *)
				err := CL.clWaitForEvents(1, S.ADR(kernelEvent));

        			(* Read the pixel data into the output image *)
        			origin[0] := 0; origin[1] := 0; origin[2] := 0;
        			region[0] := inputImage.width; region[1] := inputImage.height; region [2] := 1;

				err := CL.clEnqueueReadImage(commands, outputImageMem, CL.CL_TRUE, S.ADR(origin[0]), S.ADR(region[0]),  inputImage.width * S.SIZEOF(CL.cl_uint), 0, outputImage.adr, 0, 0, S.ADR(readEvent));
				IF err # CL.SUCCESS THEN
					KernelLog.String("ERROR clEnqueueReadImage: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
					RETURN
				END;

			 	(* Wait for the the event, i.e. until the result is read *)
				err := CL.clWaitForEvents(1, S.ADR(readEvent));

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
			IF  animated THEN;
				RotateImage;
				angle := angle + 0.1;
			END;
		END;
	END Window;

VAR
		out: Streams.Writer;

		window : Window;
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

		kernelsource: CL.PChar;

		angle : REAL;
		inited : BOOLEAN;

		globalWorkSize: IVector;

		origin, region: POINTER TO ARRAY OF CL.size_t;


PROCEDURE InitCL(): BOOLEAN;
VAR
	err: LONGINT;
	imageSupport: LONGINT;
	properties: HUGEINT; (* CL.bit_field *)
	(*bufwritten: LONGINT;*)
	buf: ARRAY 4096 OF CHAR;
	bres: BOOLEAN;
BEGIN

	err := CL.clGetPlatformIDs( 0, 0, S.ADR(nplatforms) );
	out.String("clGetPlatformIDs nplatforms: "); out.String(Utils.GetError(err)); out.Ln;
	IF (err # CL.SUCCESS) OR (nplatforms=0) THEN
		out.String('Error: Cannot get # of platforms!'); out.Ln; out.Update;
		RETURN FALSE
	END;

	NEW(platformids, nplatforms);

	err := CL.clGetPlatformIDs( nplatforms, S.ADR(platformids[0]), 0 );
	out.String("clGetPlatformIDs : "); out.String(Utils.GetError(err)); out.Ln;
	IF (err # CL.SUCCESS) THEN
		out.String('Error: Cannot get platforms!'); out.Ln; out.Update;
		RETURN FALSE
	END;

    	platform := platformids[0];

	(*  Devices  *)

	 err := CL.clGetDeviceIDs (platform, CL.DEVICE_TYPE_GPU, 0, 0 , S.ADR(ndevices));
      IF (err # CL.SUCCESS) OR (ndevices = 0) THEN
	        out.String("clGetDeviceIDs Error: "); out.String(Utils.GetError(err)); out.Ln;
          out.String('Error: Cannot get number of GPU devices!'); out.Ln; out.Update;
          RETURN FALSE
       END;

	NEW(deviceids, ndevices);
	err := CL.clGetDeviceIDs(platform, CL.DEVICE_TYPE_GPU, ndevices, S.ADR(deviceids[0]), 0);
	out.String("clGetDeviceIDs : "); out.String(Utils.GetError(err)); out.Ln;
	IF (err # CL.SUCCESS) THEN
		out.String('Error: Cannot get devices!'); out.Ln; out.Update;
		RETURN FALSE
	END;
	deviceid := deviceids[0];


	err := CL.clGetDeviceInfo(deviceid, CL.DEVICE_IMAGE_SUPPORT, S.SIZEOF(CL.cl_int), S.ADR(imageSupport), 0);
	IF err = CL.SUCCESS THEN
		IF imageSupport = 0 THEN
			 KernelLog.String("No Image Support"); KernelLog.Ln;
			 RETURN FALSE;;
		 END;
	ELSE
		 KernelLog.String("ERROR clGetDeviceInfo: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		 RETURN FALSE;
	END;

	context := CL.clCreateContext(0, 1, S.ADR(deviceid), 0 , 0, err);
	IF err # CL.SUCCESS THEN
		 KernelLog.String("ERROR clCreateContext: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		 RETURN FALSE;
	END;

	(* with event profile *)
	properties := CL.QUEUE_PROFILING_ENABLE + CL.QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE;
	commands := CL.clCreateCommandQueue(context, deviceid, properties , err);
	IF err # CL.SUCCESS THEN
		 KernelLog.String("ERROR clCreateCommandQueue: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		 RETURN FALSE;
	END;

	kernelsource := MyProgramSource();
	prog := CL.clCreateProgramWithSource(context, 1, S.ADR(kernelsource), 0, err);
	IF err # CL.SUCCESS THEN
		 KernelLog.String("ERROR clCreateProgramWithSource: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		 RETURN FALSE;
	END;

(*	err := CL.clGetProgramInfo(prog, CL.PROGRAM_SOURCE, LEN(buf), S.ADR(buf[0]), 0);
	KernelLog.String("clGetProgramInfoSource= "); KernelLog.String(buf); KernelLog.Ln;
*)
	err := CL.clBuildProgram(prog, 0, 0, "", 0, 0);
	IF err # CL.SUCCESS THEN
		KernelLog.String("ERROR clBuildProgram: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		err := CL.clGetProgramBuildInfo(prog, deviceid, CL.PROGRAM_BUILD_LOG, LEN(buf), S.ADR(buf[0]), 0);
		KernelLog.String("Build Log : "); KernelLog.Ln;
		KernelLog.String(buf); KernelLog.Ln;
		RETURN FALSE;
	END;

	kernel := CL.clCreateKernel(prog, "rotateImage", err);
	IF err # CL.SUCCESS THEN
		 KernelLog.String("ERROR clCreateKernel: ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		 RETURN FALSE;
	END;

	RETURN TRUE;
END InitCL;

 PROCEDURE initImageMem(inputImage0 :Raster.Image);
 VAR imageFormat, imfmt: CL.cl_image_format;

 	err, ret: LONGINT;
 	tmp: LONGINT;
 BEGIN
        (* Create the memory object for the input- and output image *)

		NEW(origin,3); 	NEW(region,3);
		globalWorkSize := [inputImage0.width, inputImage0.height];

		imageFormat.image_channel_order := CL.RGBA;
		imageFormat.image_channel_data_type := CL.UNSIGNED_INT8;

        inputImageMem := CL.clCreateImage2D(
            context, CL.MEM_READ_ONLY+ CL.MEM_USE_HOST_PTR,
            imageFormat, inputImage0.width, inputImage0.height,
            inputImage0.width * S.SIZEOF(CL.cl_uint), inputImage0.adr, err);
	   IF err # CL.SUCCESS THEN
		  KernelLog.String("ERROR inputImageMem clCreateImage2D: ");  KernelLog.String(Utils.GetError(err));
		  KernelLog.Ln;
	   END;

	  (* create empty outputImageMem with the same size and type *)
        outputImageMem := CL.clCreateImage2D(
            context, CL.MEM_WRITE_ONLY,
            imageFormat, inputImage0.width, inputImage0.height, 0, 0, err);
 	   IF err # CL.SUCCESS THEN
		  KernelLog.String("ERROR outputImageMem clCreateImage2D: ");  KernelLog.String(Utils.GetError(err));
		  KernelLog.Ln;
	   END;
(*	   err := CL.clGetImageInfo(inputImageMem, CL.IMAGE_FORMAT, S.SIZEOF(CL.cl_image_format), S.ADR(imfmt), S.ADR(ret));
	   IF err # CL.SUCCESS THEN
		  KernelLog.String("ERROR clGetImageInfo - Format: ");  KernelLog.String(Utils.GetError(err));
		  KernelLog.Ln;
	  END;
	  KernelLog.String("inputImage channel_order: ");  KernelLog.String(Utils.ImageFormatString(imfmt.image_channel_order)^); KernelLog.Ln;
  	  KernelLog.String("inputImage image_channel_data_type: ");  KernelLog.String(Utils.ImageFormatString(imfmt.image_channel_data_type)^); KernelLog.Ln;
	  err := CL.clGetImageInfo(inputImageMem, CL.IMAGE_WIDTH, S.SIZEOF(CL.csize_t), S.ADR(tmp), S.ADR(ret));
	  KernelLog.String("width= "); KernelLog.Int(tmp, 0); KernelLog.Ln;

	  err := CL.clGetImageInfo(inputImageMem, CL.IMAGE_HEIGHT, S.SIZEOF(CL.csize_t), S.ADR(tmp), S.ADR(ret));
	  KernelLog.String("height= "); KernelLog.Int(tmp, 0); KernelLog.Ln;
*)
END initImageMem;


PROCEDURE Open*(ctx: Commands.Context);
VAR fname: ARRAY 128 OF CHAR;

BEGIN
  IF ~ ctx.arg.GetString(fname) THEN RETURN END;

  inputImage:= WMGraphics.LoadImage(fname, FALSE);
  IF inputImage = NIL THEN
  	KernelLog.String(fname); KernelLog.String(" Not Loaded"); KernelLog.Ln;
  RETURN
  END;

  KernelLog.String(fname); KernelLog.String("  loaded.."); KernelLog.Ln;

  NEW(outputImage);
  Raster.Create(outputImage, inputImage.width, inputImage.height, Raster.BGRA8888);

  IF ~ InitCL() THEN RETURN END;

  initImageMem(inputImage);
 	inited := TRUE;
  IF window = NIL THEN
	NEW(window);
 END;
END Open;


PROCEDURE Cleanup;
VAR die : KillerMsg;
	 msg : WMMessages.Message;
	 m : WM.WindowManager;
	 err: LONGINT;

BEGIN {EXCLUSIVE}
	NEW(die); msg.ext := die; msg.msgType := WMMessages.MsgExt;
	m := WM.GetDefaultManager();
	m.Broadcast(msg);
	AWAIT(window = NIL);
	(* Free resources *)
	IF inited THEN

		err := CL.clReleaseMemObject(inputImageMem);
		err := CL.clReleaseMemObject(outputImageMem);
		err := CL.clReleaseKernel(kernel);
		err := CL.clReleaseProgram(prog);
		err := CL.clReleaseCommandQueue(commands);
		err := CL.clReleaseContext(context);
	END;
END Cleanup;


PROCEDURE MyProgramSource(): CL.PChar;
VAR sw: Streams.StringWriter;
      buf: CL.PChar;
BEGIN
NEW(sw,1024);
	   sw.Ln;
        sw.String("const sampler_t samplerIn =") ; sw.Ln;
        sw.String("    CLK_NORMALIZED_COORDS_FALSE |"); sw.Ln;
        sw.String("    CLK_ADDRESS_CLAMP |"); sw.Ln;
        sw.String("    CLK_FILTER_NEAREST; "); sw.Ln;
        sw.Ln;
        sw.String("const sampler_t samplerOut =") ; sw.Ln;
        sw.String("    CLK_NORMALIZED_COORDS_FALSE |"); sw.Ln;
        sw.String("    CLK_ADDRESS_CLAMP |"); sw.Ln;
        sw.String("    CLK_FILTER_NEAREST;") ; sw.Ln;
         sw.Ln;
        sw.String("__kernel void rotateImage("); sw.Ln;
        sw.String("    __read_only  image2d_t sourceImage, "); sw.Ln;
        sw.String("    __write_only image2d_t targetImage, "); sw.Ln;
        sw.String("    float angle)"); sw.Ln;
        sw.String("{"); sw.Ln;
        sw.String("    int gidX = get_global_id(0);"); sw.Ln;
        sw.String("    int gidY = get_global_id(1);"); sw.Ln;
        sw.String("    int w = get_image_width(sourceImage);"); sw.Ln;
        sw.String("    int h = get_image_height(sourceImage);"); sw.Ln;
        sw.String("    int cx = w/2;"); sw.Ln;
        sw.String("    int cy = h/2;"); sw.Ln;
        sw.String("    int dx = gidX-cx;"); sw.Ln;
        sw.String("    int dy = gidY-cy;"); sw.Ln;
        sw.String("    float ca = cos(angle);"); sw.Ln;
        sw.String("    float sa = sin(angle);"); sw.Ln;
        sw.String("    int inX = (int)(cx+ca*dx-sa*dy);"); sw.Ln;
        sw.String("    int inY = (int)(cy+sa*dx+ca*dy);"); sw.Ln;
        sw.String("    int2 posIn = {inX, inY};"); sw.Ln;
        sw.String("    int2 posOut = {gidX, gidY};"); sw.Ln;
        sw.String("    uint4 pixel = read_imageui(sourceImage, samplerIn, posIn);"); sw.Ln;
        sw.String("    write_imageui(targetImage, posOut, pixel);") ; sw.Ln;
        sw.String("}"); sw.Ln;
 NEW(buf, sw.Pos());
 sw.Get(buf^);
 RETURN S.VAL(CL.PChar, S.ADR(buf[0]));

END MyProgramSource;

BEGIN
	Modules.InstallTermHandler(Cleanup);
	Raster.InitMode(mode, Raster.srcCopy);
	Streams.OpenWriter(out, KernelLog.Send);
END MyImageRotateCL.

SystemTools.FreeDownTo OpenCL ~

SystemTools.Free  MyImageRotateCL~

MyImageRotateCL.Open "mars.png" ~

MyImageRotateCL.Open "BluebottlePic0.png" ~

MyImageRotateCL.Open "test.bmp"

MyImageRotateCL.Open "WMIcons.tar://WMKernelLog.png" ~


