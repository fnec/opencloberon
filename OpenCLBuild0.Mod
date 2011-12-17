MODULE OpenCLBuild0; (** AUTHOR "fnecati"; PURPOSE "opencl program syntax checker"; *)

IMPORT Modules, Strings, WMComponents, WMMessages, WMRestorable, WMEditors, Commands,
	WM:=WMWindowManager, WMGraphics, WMStandardComponents, WMDocumentEditor, 
	UndoManager, KernelLog, XML,
	S:=SYSTEM;

(*
   typical todo's:
   
	- DragNDrop *.cl files to cleditor
	- make CL specific syntax highlighter
	- command line build test.
	-  etc.
	
	To open *.cl files from File Manager with OpenCLBuild, append the following <Section name="cl"> part
	 to Filehandlers section in Configuration.XML file.
	 

		<Section name="Filehandlers">
		<!-- use lower case for extensions, sort lexographically -->	

			....
			....
		
			<Section name="cl">
					<Setting name="Open" value="OpenCLBuild.Open"/>
			</Section>
		
			...
			...
		
		</Section>	
*)

CONST
	WindowWidth = 700; WindowHeight = 500;
		
TYPE 

	KillerMsg = OBJECT
	END KillerMsg;
	
	Window = OBJECT(WMComponents.FormWindow)
	VAR 
	      cleditor: WMDocumentEditor.Editor;
	      logcleditor, optionscleditor: WMEditors.Editor;
	      cbut: WMStandardComponents.Button;
		um: UndoManager.UndoManager;
		    
	PROCEDURE CreateForm(): WMComponents.VisualComponent;
	VAR 
			label : WMStandardComponents.Label;
			panel, tpanel : WMStandardComponents.Panel; (* main and editor panel *)
			toolbar, statusbar: WMStandardComponents.Panel;
			vsizer : WMStandardComponents.Resizer; 
			grpanel: WMStandardComponents.GroupPanel; (* groupbox panel *)
			
	BEGIN
		(*  Main Panel holding the tabs, toolbar and contents  *)
		
		NEW(panel); panel.alignment.Set(WMComponents.AlignClient); panel.fillColor.Set(0FFFFFFFFH); panel.takesFocus.Set(TRUE);
	
		NEW(toolbar); toolbar.bounds.SetHeight(20); toolbar.alignment.Set(WMComponents.AlignTop);
		toolbar.fillColor.Set(0DDDDDDFFH);
		panel.AddContent(toolbar);
		
		(* build button *)
		NEW(cbut); cbut.bounds.SetWidth(100); cbut.caption.SetAOC("Build");  cbut.alignment.Set(WMComponents.AlignLeft);
		 cbut.onClick.Add(CLBuild);
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
		
		(* Editor area*)		
		NEW(tpanel); tpanel.alignment.Set(WMComponents.AlignClient);
		tpanel.fillColor.Set(0FFDFFH);
		panel.AddContent(tpanel);
		
		(* group panel, source *)
		NEW(grpanel); grpanel.alignment.Set(WMComponents.AlignClient);
		grpanel.fillColor.Set(0FFFFFFFFH); grpanel.caption.SetAOC("OpenCL source code:");
		tpanel.AddContent(grpanel);
		
		(* opencl source cleditor *)							
		NEW(cleditor); 
		cleditor.alignment.Set(WMComponents.AlignClient); 
		(* cleditor.SetToolbar(WMDocumentEditor.All-WMDocumentEditor.FormatButton);*)
		cleditor.SetToolbar(WMDocumentEditor.All);
		cleditor.editor.highlighting.SetAOC("C"); (*? or  put cl types to SytaxHighlighter.XML, Configuration.XML *)
		cleditor.editor.tv.showLineNumbers.Set(TRUE);
		cleditor.editor.tv.showBorder.Set(TRUE);

		NEW(statusbar); statusbar.alignment.Set(WMComponents.AlignBottom);
		statusbar.fillColor.Set(0FFDFFH); statusbar.bounds.SetHeight(130);
		
		grpanel.AddContent(statusbar);		
		grpanel.AddContent(cleditor);					

		(* resizer *)
		NEW(vsizer); vsizer.alignment.Set(WMComponents.AlignTop);	vsizer.bounds.SetHeight(4);
		 vsizer.fillColor.Set(0FF0000FFH); 
		statusbar.AddContent(vsizer);
				
		NEW(grpanel); grpanel.bounds.SetHeight(100); grpanel.alignment.Set(WMComponents.AlignClient);
		grpanel.fillColor.Set(0DDDDDDDDH); grpanel.caption.SetAOC("Build Log:");
		statusbar.AddContent(grpanel);
		
		(* build result log editor *)
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
		IncCount;
		 vc := CreateForm();
		 Init(WindowWidth, WindowHeight, FALSE);
		 SetContent(vc);
		SetTitle(Strings.NewString("OpenCLBuild0"));
		(* SetIcon(WMGraphics.LoadImage("OpenCL.png", TRUE)); *)
		SetIcon(WMGraphics.LoadImage("WMBuilder.tar://structure.png", TRUE)); 
		
		IF c # NIL THEN (* restore *)
			WMRestorable.AddByContext(SELF, c);
			IF c.appData # NIL THEN
				cleditor.FromXml(c.appData(XML.Element));
				Resized(GetWidth(), GetHeight())
			END
		ELSE
			WM.DefaultAddWindow(SELF) ;
		END;
		NEW(um, 100, TRUE);
		cleditor.editor.text.SetUndoManager(um);
		cleditor.editor.SetUndoManager(um);
	END New;
	
	PROCEDURE CLBuild(sender, data : ANY);
	VAR 
	      options: ARRAY 256 OF CHAR;
	      err: LONGINT;

	BEGIN
		IF clinited THEN
		 END;
	END CLBuild;
	
	PROCEDURE Close;
	BEGIN
		Close^;
		DecCount;
	END Close;

	PROCEDURE Handle(VAR x: WMMessages.Message);
	VAR data : XML.Element;
	BEGIN
		IF (x.msgType = WMMessages.MsgExt) & (x.ext # NIL) THEN
			IF (x.ext IS KillerMsg) THEN Close
			ELSIF (x.ext IS WMRestorable.Storage) THEN
				NEW(data); data.SetName("OpenCLBuild0Data");
				cleditor.ToXml(data);			
				x.ext(WMRestorable.Storage).Add("OpenCLBuild0", "OpenCLBuild0.Restore", SELF, data)
			ELSE Handle^(x)
			END
		ELSE Handle^(x)
		END
		END Handle;
		
	BEGIN
	
	END Window;
	
VAR
	nofWindows : LONGINT;
	

	clinited: BOOLEAN;
	buf: ARRAY 32768 OF CHAR; (* if kernel size is not enough increase size  *)
	log: ARRAY 1024 OF CHAR; 
             
PROCEDURE InitCL;
VAR err, err1, err2, err3: LONGINT;
BEGIN
	clinited := FALSE;
END InitCL;

(* open *.cl file *)
PROCEDURE Open*(context : Commands.Context); (**  [filename] ~ *)
VAR 
	wind: Window;
	filename : ARRAY 256 OF CHAR;
BEGIN
	NEW(wind, NIL);  
	IF context.arg.GetString(filename) THEN
		wind.cleditor.Load(filename, "UTF-8");
	END;
END Open;

PROCEDURE Restore*(context : WMRestorable.Context);
VAR
	winstance: Window;
BEGIN
	NEW(winstance, context)
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
	AWAIT(nofWindows = 0);
	
	IF clinited THEN

	END;	

END Cleanup;

PROCEDURE IncCount;
BEGIN {EXCLUSIVE}
	INC(nofWindows)
END IncCount;

PROCEDURE DecCount;
BEGIN {EXCLUSIVE}
	DEC(nofWindows)
END DecCount;

BEGIN
	Modules.InstallTermHandler(Cleanup);
	InitCL;
END OpenCLBuild0.

SystemTools.Free OpenCLBuild0 ~ 

OpenCLBuild0.Open vectorsquare.cl ~ 

(*
Write your OpenCL programs into Source code editor (upper editor) and press to Build button
if there is no error SUCCESS printed to Build log (bottom editor), otherwise, type of error and its 
position is displayed.

Build options, if your program requires,  can be written into Options Textfield (top editor). 
See Khronos_OpenCL_Specification.pdf for other build options.

*)
