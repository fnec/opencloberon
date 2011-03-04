MODULE OpenCLBuild; (** AUTHOR "fnecati"; PURPOSE "opencl program syntax checker"; *)

IMPORT Modules, Strings, WMComponents, WMMessages, WMRestorable, WMEditors, Commands,
	WM:=WMWindowManager, WMGraphics, WMStandardComponents,
	CL := OpenCL, Utils:=OpenCLUtils, S:=SYSTEM, KernelLog;

(*
   typical todo's:
   
  - DragNDrop *.cl files to cleditor
  - load and save as cl file
  - comand line build.
   ...
   binary IR previewer 
   add OpenCL syntax to SyntaxHighlighter.XML or a new one.
   .. integrate to PET ??  
*)

CONST
	WindowWidth = 600; WindowHeight = 600;
		
TYPE 

	KillerMsg = OBJECT
	END KillerMsg;
	
	Window = OBJECT(WMComponents.FormWindow)
	VAR 
	      cleditor, logcleditor, optionscleditor: WMEditors.Editor;
	      cbut: WMStandardComponents.Button;
		      
	PROCEDURE CreateForm(): WMComponents.VisualComponent;
	VAR 
			label : WMStandardComponents.Label;
			panel : WMStandardComponents.Panel;
			toolbar: WMStandardComponents.Panel;
			vsizer : WMStandardComponents.Resizer;
			grpanel: WMStandardComponents.GroupPanel;
			
	BEGIN
		NEW(panel); panel.bounds.SetExtents(WindowWidth, WindowHeight); panel.takesFocus.Set(TRUE);
		
		NEW(toolbar); toolbar.bounds.SetHeight(20); toolbar.alignment.Set(WMComponents.AlignTop);
		toolbar.fillColor.Set(0DDDDDDFFH);
		panel.AddContent(toolbar);
		
		(* build button *)
		NEW(cbut); cbut.bounds.SetWidth(100); cbut.caption.SetAOC("Build");  cbut.alignment.Set(WMComponents.AlignLeft);
		toolbar.AddContent(cbut);

		NEW(label); label.bounds.SetWidth(80); label.caption.SetAOC(" with Options: "); 
		label.alignment.Set(WMComponents.AlignLeft);
		toolbar.AddContent(label);
		
		(* options cleditor *)
		NEW(optionscleditor); 
		optionscleditor.alignment.Set(WMComponents.AlignLeft); optionscleditor.bounds.SetWidth(400);
		optionscleditor.tv.showBorder.Set(TRUE);
		optionscleditor.multiLine.Set(FALSE);
		optionscleditor.SetAsString("-cl-mad-enable");
		toolbar.AddContent(optionscleditor);
		
		
		NEW(grpanel); grpanel.alignment.Set(WMComponents.AlignClient);
		grpanel.fillColor.Set(0FFFFFFFFH); grpanel.caption.SetAOC("OpenCL source code:");
		panel.AddContent(grpanel);
		
		(* opencl source cleditor *)							
		NEW(cleditor); 
		cleditor.alignment.Set(WMComponents.AlignClient); 
		cleditor.tv.showBorder.Set(TRUE);
		cleditor.highlighting.SetAOC("C");
		cleditor.multiLine.Set(TRUE);
		cleditor.tv.showLineNumbers.Set(TRUE);
		grpanel.AddContent(cleditor);	
	
		NEW(toolbar); toolbar.bounds.SetHeight(100); toolbar.alignment.Set(WMComponents.AlignBottom);
		panel.AddContent(toolbar);

		(* resizer *)
		NEW(vsizer); vsizer.alignment.Set(WMComponents.AlignTop);	vsizer.bounds.SetHeight(4);
		 vsizer.fillColor.Set(0FF0000FFH); 
		toolbar.AddContent(vsizer);
		
		NEW(grpanel); grpanel.bounds.SetHeight(100); grpanel.alignment.Set(WMComponents.AlignClient);
		grpanel.fillColor.Set(0DDDDDDDDH); grpanel.caption.SetAOC("Build Log:");
		toolbar.AddContent(grpanel);
		
		(* build result cleditor *)		
		NEW(logcleditor); 
		logcleditor.alignment.Set(WMComponents.AlignClient); 
		logcleditor.tv.showBorder.Set(TRUE);
				
		logcleditor.multiLine.Set(TRUE);
		grpanel.AddContent(logcleditor);	
						
		RETURN panel
	END CreateForm;
	
	PROCEDURE &New(c : WMRestorable.Context);
	VAR 
		vc : WMComponents.VisualComponent;
	BEGIN
		 vc := CreateForm();
		 Init(vc.bounds.GetWidth(), vc.bounds.GetHeight(), FALSE);
		 cbut.onClick.Add(CLBuild);
		 SetContent(vc);
		SetTitle(Strings.NewString("OpenCLBuild"));
		(* SetIcon(WMGraphics.LoadImage("OpenCL.png", TRUE)); *)
		IF c # NIL THEN
			(** todo: make opencl source cleditor and options cleditor  restorable *)
			WMRestorable.AddByContext(SELF, c)
		ELSE
			WM.DefaultAddWindow(SELF) ;
		END;
	END New;
	
	PROCEDURE CLBuild(sender, data : ANY);
	VAR 
	      options: ARRAY 128 OF CHAR;
	      err: LONGINT;
	      pbuf: CL.PChar;
     		prog      : CL.cl_program;       (* compute program *)
     		status: CL.cl_build_status; 
     		binarysize: CL.csize_t;
     		
	BEGIN
	IF clinited THEN
	 		cleditor.GetAsString(buf);
	 		optionscleditor.GetAsString(options);
	 		
	 		pbuf := S.VAL(CL.PChar, S.ADR(buf[0]));
			prog := CL.clCreateProgramWithSource(context, 1, S.ADR(pbuf), 0, err);
			IF prog # 0 THEN		
				
				err := CL.clBuildProgram(prog, 0, NIL, S.ADR(options[0]), 0, 0);
				KernelLog.String("Build error: "); KernelLog.Int(err, 0); KernelLog.String(" -> ");  KernelLog.String(Utils.ErrorToStr(err)); KernelLog.Ln; 
					
				IF err  # CL.SUCCESS THEN
						KernelLog.String("Build Status = "); KernelLog.Int(status, 0); KernelLog.Ln; 
						err := CL.clGetProgramBuildInfo(prog, deviceids,CL.PROGRAM_BUILD_LOG, LEN(log), S.ADR(log[0]), 0);
						logcleditor.SetAsString(log);
				ELSE
					err := CL.clGetProgramInfo(prog, CL.PROGRAM_BINARY_SIZES, S.SIZEOF(CL.csize_t), S.ADR(binarysize), 0);
					IF err = CL.SUCCESS THEN
					  KernelLog.String("Program Binary Size= "); KernelLog.Int(binarysize, 0);  KernelLog.String(" bytes."); KernelLog.Ln; 
					END;
					logcleditor.SetAsString("SUCCESS"); 
				END;					
			END;				
			err := CL.clReleaseProgram(prog);	
	 END;
	END CLBuild;
	
	PROCEDURE Close;
	BEGIN
		Close^;
		wind := NIL
	END Close;

	PROCEDURE Handle(VAR x: WMMessages.Message);
	BEGIN
		IF (x.msgType = WMMessages.MsgExt) & (x.ext # NIL) THEN
			IF (x.ext IS KillerMsg) THEN Close
			ELSIF (x.ext IS WMRestorable.Storage) THEN
				x.ext(WMRestorable.Storage).Add("OpenCLBuild", "OpenCLBuild.Restore", SELF, NIL)
			ELSE Handle^(x)
			END
		ELSE Handle^(x)
		END
		END Handle;
			
	BEGIN
	
	END Window;
	
VAR 
		wind: Window;
		
		platformids: CL.cl_platform_id;
		deviceids : CL.cl_device_id;
		context : CL.cl_context;
		commands : CL.cl_command_queue;  
          clinited: BOOLEAN;
 		buf: ARRAY 32768 OF CHAR; (* if kernel size is not enough increase size  *)
 		log: ARRAY 1024 OF CHAR; 
             
PROCEDURE InitCL;
VAR err, err1, err2, err3: LONGINT;
BEGIN
	clinited := FALSE;
	err := CL.clGetPlatformIDs( 1, S.ADR(platformids), 0 ); 
	IF err # CL.SUCCESS THEN 
		KernelLog.String(Utils.ErrorToStr(err)); KernelLog.Ln;  
		RETURN
	END;
	err1 := CL.clGetDeviceIDs(platformids, CL.DEVICE_TYPE_ALL, 1, S.ADR(deviceids), 0);
	IF err1 # CL.SUCCESS THEN 
		KernelLog.String(Utils.ErrorToStr(err1)); KernelLog.Ln;  
		RETURN
	END;
	
	context := CL.clCreateContext(0, 1, S.ADR(deviceids), NIL , 0, err2);
	IF err2# CL.SUCCESS THEN 
		KernelLog.String(Utils.ErrorToStr(err2)); KernelLog.Ln;  
		RETURN
	END;
	
	commands := CL.clCreateCommandQueue(context, deviceids, 0, err3);
		IF err3 # CL.SUCCESS THEN 
		KernelLog.String(Utils.ErrorToStr(err3)); KernelLog.Ln;  
		RETURN
	END;

      clinited := (err = 0) & (err1 = 0) & (err2 = 0) & (err3 = 0) & (context # 0) & (commands # 0);
END InitCL;

(* open build test Window *)
PROCEDURE Open*;
BEGIN
IF wind = NIL THEN	
	NEW(wind, NIL);  
END;
END Open;


PROCEDURE Restore*(context : WMRestorable.Context);
BEGIN
IF wind = NIL THEN
	NEW(wind, context)
END;	
END Restore;

PROCEDURE Cleanup;
VAR die : KillerMsg;
	 msg : WMMessages.Message;
	 m : WM.WindowManager;
	 err: LONGINT;
BEGIN {EXCLUSIVE}
	NEW(die);
	msg.ext := die;
	msg.msgType := WMMessages.MsgExt;
	m := WM.GetDefaultManager();
	m.Broadcast(msg);
	AWAIT(wind = NIL);

	IF clinited THEN
		err := CL.clReleaseContext(context);	
		err := CL.clReleaseCommandQueue(commands);
	END;	
END Cleanup;

(* build test from command line:
  OpenCLBuild.This
  	"__kernel void sum ( ) 
  		{ 
  		} " ~
 *)
  
PROCEDURE This*(context : Commands.Context);
BEGIN
	
END This;

(* build test from file:
OpenCLBuild.ThisFile Mandelbrod.cl ~ 
 *)
 
PROCEDURE ThisFile*(context : Commands.Context);
BEGIN
	
END ThisFile;


BEGIN
Modules.InstallTermHandler(Cleanup);
InitCL;
END OpenCLBuild.

SystemTools.Free OpenCLBuild ~ 

OpenCLBuild.Open ~ 

(*
Write your OpenCL programs into Source code editor (upper editor) and press to Build button
if there is no error SUCCESS printed to Build log (bottom editor), otherwise, type of error and its 
position is displayed.

Build options, if your program requires,  can be written into Options Textfield (top editor). 
See Khronos_OpenCL_Specification.pdf for other build options.

*)
