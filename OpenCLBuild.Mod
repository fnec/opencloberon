MODULE OpenCLBuild; (** AUTHOR "fnecati"; PURPOSE "opencl program syntax checker"; *)

IMPORT Modules, Strings, WMComponents, WMMessages, WMRestorable, WMEditors, Commands,
	WM:=WMWindowManager, WMGraphics, WMStandardComponents, WMDocumentEditor,
	UndoManager, KernelLog, XML, WMTrees, Streams,
	CL := OpenCL, Utils:=OpenCLUtils; 

(*
   typical todo's:

	- DragNDrop *.cl files to cleditor
	- make CL specific syntax highlighter
	- command line build test.
	- build according to name of platforms, devices on the left panel.

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
	WindowWidth = 750; WindowHeight = 500;

TYPE

	KillerMsg = OBJECT
	END KillerMsg;

	Window = OBJECT(WMComponents.FormWindow)
	VAR
		cleditor: WMDocumentEditor.Editor;
		logcleditor, optionscleditor, kerneldefineEd: WMEditors.Editor;
		cbut: WMStandardComponents.Button;
 		um: UndoManager.UndoManager;
 		platformviewtree: WMTrees.TreeView;
		platformtree: WMTrees.Tree;
		rootnode, treenode: WMTrees.TreeNode;
		devroot, devtreenode, childnode: WMTrees.TreeNode;
		
	PROCEDURE CreateForm(): WMComponents.VisualComponent;
	VAR
			label : WMStandardComponents.Label;
			lpanel, rpanel, panel, tpanel : WMStandardComponents.Panel; (* main and editor panel *)
			toolbar, statusbar: WMStandardComponents.Panel;
			vsizer, hsizer : WMStandardComponents.Resizer;
			grpanel, grplatform: WMStandardComponents.GroupPanel; (* groupbox panel *)
			i, k: LONGINT;
			str: ARRAY 256 OF CHAR;
			z: CL.size_t;
	BEGIN
		(*  Main Panel holding the tabs, toolbar and contents  *)



		NEW(panel); panel.alignment.Set(WMComponents.AlignClient); panel.fillColor.Set(0FFFFFFFFH); panel.takesFocus.Set(TRUE);

		(* left platform panel *)
		NEW(lpanel);
		lpanel.bounds.SetWidth(150);
		lpanel.alignment.Set(WMComponents.AlignLeft); lpanel.fillColor.Set(0DDDDDDDDH);
		lpanel.takesFocus.Set(TRUE);
		panel.AddContent(lpanel);

		(* platform group panel *)
		NEW(grplatform);
		grplatform.alignment.Set(WMComponents.AlignClient);
		(*grplatform.bounds.SetHeight(200);*)
		(*grplatform.fillColor.Set(0FFCCAAFFH); *)grplatform.caption.SetAOC("Platform Info:");
		lpanel.AddContent(grplatform);
			(* ------ *)
			NEW(platformviewtree);
			(*platformviewtree.bounds.SetHeight(200);*) platformviewtree.fillColor.Set(0FF0000FFH);
			platformviewtree.alignment.Set(WMComponents.AlignClient);
			grplatform.AddContent(platformviewtree);
			platformtree := platformviewtree.GetTree();
			platformtree.Acquire();
				NEW(rootnode);
				platformtree.SetNodeCaption(rootnode, Strings.NewString("PLATFORMS"));
				platformtree.SetRoot(rootnode);
				
				FOR i:=0 TO Utils.NumberOfPlatforms-1 DO
					NEW(treenode);
					str := "Name: "; Strings.Append(str, Utils.platforms[i].name);
					platformtree.SetNodeCaption(treenode, Strings.NewString(str));
					platformtree.AddChildNode(rootnode, treenode);
						NEW(childnode);
						str := "Vendor: "; Strings.Append(str, Utils.platforms[i].vendor);
						platformtree.SetNodeCaption(childnode, Strings.NewString(str));
						platformtree.AddChildNode(treenode, childnode);
						NEW(childnode);
						str := "Profile: "; Strings.Append(str, Utils.platforms[i].profile);
						platformtree.SetNodeCaption(childnode, Strings.NewString(str));
						platformtree.AddChildNode(treenode, childnode);
						NEW(childnode);
						str := "Version: "; Strings.Append(str, Utils.platforms[i].version);
						platformtree.SetNodeCaption(childnode, Strings.NewString(str));
						platformtree.AddChildNode(treenode, childnode);
						NEW(childnode);
						str := "Extensions: "; Strings.Append(str, Utils.platforms[i].extensions);
						platformtree.SetNodeCaption(childnode, Strings.NewString(str));
						platformtree.AddChildNode(treenode, childnode);
						
							(* devices *)
							NEW(devroot);
							platformtree.SetNodeCaption(devroot, Strings.NewString("DEVICES"));
							platformtree.AddChildNode(treenode, devroot);
							
							FOR k := 0 TO Utils.platforms[i].numOfDevices-1 DO
								
								Strings.IntToStr(k, str); Strings.Append(str, ". Device");
								NEW(devtreenode);
								platformtree.SetNodeCaption(devtreenode, Strings.NewString(str));
								platformtree.AddChildNode(devroot, devtreenode);	
								
							
								NEW(childnode);
								str := "Name: "; Strings.Append(str, Utils.platforms[i].devices[k].name);
								platformtree.SetNodeCaption(childnode, Strings.NewString(str));
								platformtree.AddChildNode(devtreenode, childnode);	
								NEW(childnode);
								str := "Vendor: "; Strings.Append(str, Utils.platforms[i].devices[k].vendor);
								platformtree.SetNodeCaption(childnode, Strings.NewString(str));
								platformtree.AddChildNode(devtreenode, childnode);

								NEW(childnode);
								str := "Driver Version: "; Strings.Append(str, Utils.platforms[i].devices[k].driverVersion);
								platformtree.SetNodeCaption(childnode, Strings.NewString(str));
								platformtree.AddChildNode(devtreenode, childnode);
								NEW(childnode);
								str := "Device Version: "; Strings.Append(str, Utils.platforms[i].devices[k].deviceVersion);
								platformtree.SetNodeCaption(childnode, Strings.NewString(str));
								platformtree.AddChildNode(devtreenode, childnode);
								NEW(childnode);
								str := "OpenCL Version: "; Strings.Append(str, Utils.platforms[i].devices[k].openclVersion);
								platformtree.SetNodeCaption(childnode, Strings.NewString(str));
								platformtree.AddChildNode(devtreenode, childnode);
								NEW(childnode);
								str := "Type: "; Strings.Append(str, Utils.platforms[i].devices[k].typestr);
								platformtree.SetNodeCaption(childnode, Strings.NewString(str));
								platformtree.AddChildNode(devtreenode, childnode);

								NEW(childnode);							
								str := "Max Compute Units: "; Strings.AppendInt(str, LONGINT(Utils.platforms[i].devices[k].maxComputeUnits));
								platformtree.SetNodeCaption(childnode, Strings.NewString(str));
								platformtree.AddChildNode(devtreenode, childnode);

								NEW(childnode);
								str := "Max WorkItem Dim: "; Strings.AppendInt(str, LONGINT(Utils.platforms[i].devices[k].maxWorkItemDimension));
								platformtree.SetNodeCaption(childnode, Strings.NewString(str));
								platformtree.AddChildNode(devtreenode, childnode);
								
								NEW(childnode);
								str := "Max WorkItem Sizes: [ "; 
								FOR z := 0 TO LEN(Utils.platforms[i].devices[k].maxWorkItemSize)-1 DO
								
									Strings.AppendInt(str, LONGINT(Utils.platforms[i].devices[k].maxWorkItemSize[k]));
									Strings.Append(str, " ");
								END;
								Strings.Append(str, " ]");
								     
								platformtree.SetNodeCaption(childnode, Strings.NewString(str));
								platformtree.AddChildNode(devtreenode, childnode);
								
								NEW(childnode);								
								str := "Max Group Size: "; Strings.AppendInt(str, LONGINT(Utils.platforms[i].devices[k].maxWorkGroupSize));
								platformtree.SetNodeCaption(childnode, Strings.NewString(str));
								platformtree.AddChildNode(devtreenode, childnode);



							END;
				END;

(*
				NEW(treenode);
				platformtree.SetNodeCaption(treenode, Strings.NewString("NVIDA"));
				platformtree.AddChildNode(rootnode, treenode);
*)
			platformtree.Release();

		NEW(hsizer); hsizer.alignment.Set(WMComponents.AlignRight); hsizer.bounds.SetWidth(4);
		 hsizer.clDefault.Set(0FF00FFH);
		lpanel.AddContent(hsizer);
		(* ---------------- *)

		NEW(toolbar); toolbar.bounds.SetHeight(25); toolbar.alignment.Set(WMComponents.AlignTop);
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
		optionscleditor.alignment.Set(WMComponents.AlignLeft);
		optionscleditor.bounds.SetWidth(300);
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

	(*		(*! kerneldefineEd  *)
		NEW(toolbar); toolbar.bounds.SetHeight(50); toolbar.alignment.Set(WMComponents.AlignTop);
		toolbar.fillColor.Set(0DDDDFFH);
		grpanel.AddContent(toolbar);

		NEW(kerneldefineEd);
		kerneldefineEd.alignment.Set(WMComponents.AlignRight);
		kerneldefineEd.bounds.SetWidth(300);
		kerneldefineEd.tv.showBorder.Set(TRUE);
		kerneldefineEd.multiLine.Set(TRUE);
		(* kerneldefineEd.SetAsString(""); *)
		toolbar.AddContent(kerneldefineEd);

		NEW(vsizer); vsizer.alignment.Set(WMComponents.AlignBottom);	vsizer.bounds.SetHeight(4);
		 vsizer.clDefault.Set(0FFFF00FFH);
		toolbar.AddContent(vsizer);
		(* ************** *)

	*)
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
		 vsizer.clDefault.Set(0FFFF00FFH);
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
			IF (c # NIL) THEN
				Init(c.r - c.l, c.b - c.t, FALSE);
			ELSE
				Init(WindowWidth, WindowHeight, FALSE);
			END;

		 SetContent(vc);
		SetTitle(Strings.NewString("OpenCLBuild"));
		(* SetIcon(WMGraphics.LoadImage("OpenCL.png", TRUE)); *)
		SetIcon(WMGraphics.LoadImage("WMBuilder.tar://structure.png", TRUE));

		IF c # NIL THEN (* restore *)
			WMRestorable.AddByContext(SELF, c);
			IF c.appData # NIL THEN
				cleditor.FromXml(c.appData(XML.Element));
				(*Resized(GetWidth(), GetHeight())*)
			END;
			vc.Invalidate;
		ELSE
			WM.DefaultAddWindow(SELF) ;
		END;
		NEW(um, 1001, TRUE);
		cleditor.editor.text.SetUndoManager(um);
		cleditor.editor.SetUndoManager(um);
	END New;

	PROCEDURE LoadCLFile(filename: ARRAY OF CHAR);
	BEGIN
		cleditor.Load(filename, "UTF-8");
		cleditor.editor.text.SetUndoManager(um)
	END LoadCLFile;

	(** read the kernel source code*)
	PROCEDURE ReadThis*(sr: Streams.Reader);
	VAR ks: ARRAY 1024 OF CHAR;
		i: LONGINT;
		ch: CHAR;
	BEGIN
		sr.SkipWhitespace();
		i :=0;
		ch := sr.Get();
		WHILE (i<1022) & (ch # Streams.EOT) DO
			ks[i] := ch;
			INC(i);
			ch := sr.Get();
		END;
		ks[i]:=0X;
		cleditor.editor.SetAsString(ks);
		cleditor.editor.text.SetUndoManager(um)
	END ReadThis;

	PROCEDURE CLBuild(sender, data : ANY);
	VAR
	      options: ARRAY 256 OF CHAR;
	      err: LONGINT;
	      pbuf: ADDRESS;
     		prog      : CL.cl_program;       (* compute program *)
     		status: CL.cl_build_status;
     		binarysize: CL.size_t;
	BEGIN
	IF clinited THEN
	 		cleditor.editor.GetAsString(buf^);
	 		optionscleditor.GetAsString(options);

	 		pbuf := ADDRESSOF(buf^[0]); (*  in c, this is **buf  *)
			prog := CL.CreateProgramWithSource(context, 1, ADDRESSOF(pbuf), 0, err);
			IF prog # 0 THEN

				err := CL.BuildProgram(prog, 0, 0, options, 0, 0);
				KernelLog.String("Build error: "); KernelLog.Int(err, 0); KernelLog.String(" -> ");  KernelLog.String(Utils.GetError(err)); KernelLog.Ln;

				IF err  # CL.SUCCESS THEN
						KernelLog.String("Build Status = "); KernelLog.Int(status, 0); KernelLog.Ln;
						err := CL.GetProgramBuildInfo(prog, deviceids,CL.PROGRAM_BUILD_LOG, LEN(log), ADDRESSOF(log[0]), 0);
						logcleditor.SetAsString(log);
				ELSE
					err := CL.GetProgramInfo(prog, CL.PROGRAM_BINARY_SIZES, SIZEOF(CL.size_t), ADDRESSOF(binarysize), 0);
					IF err = CL.SUCCESS THEN
					  KernelLog.String("Program Binary Size= "); KernelLog.Int(binarysize, 0);  KernelLog.String(" bytes."); KernelLog.Ln;
					END;
					logcleditor.SetAsString("SUCCESS");
				END;
			END;
			err := CL.ReleaseProgram(prog);
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
				NEW(data); data.SetName("OpenCLBuildData");
				cleditor.ToXml(data);
				x.ext(WMRestorable.Storage).Add("OpenCLBuild", "OpenCLBuild.Restore", SELF, data)
			ELSE Handle^(x)
			END
		ELSE Handle^(x)
		END
		END Handle;

	BEGIN

	END Window;

VAR
	nofWindows : LONGINT;

	platformids: CL.cl_platform_id;
	deviceids : CL.cl_device_id;

	context : CL.cl_context;
	commands : CL.cl_command_queue;

	clinited: BOOLEAN;
	buf: Strings.String; (* 16Kb, if kernel size is not enough increase size, look at the module body  *)
	log: ARRAY 1024 OF CHAR;

PROCEDURE InitCL;
VAR err, err1, err2, err3: LONGINT;
BEGIN
	clinited := FALSE;
	err := CL.GetPlatformIDs( 1, ADDRESSOF(platformids), 0 );
	IF err # CL.SUCCESS THEN
		KernelLog.String(Utils.GetError(err)); KernelLog.Ln;
		RETURN
	END;
	err1 := CL.GetDeviceIDs(platformids, CL.DEVICE_TYPE_ALL, 1, ADDRESSOF(deviceids), 0);
	IF err1 # CL.SUCCESS THEN
		KernelLog.String(Utils.GetError(err1)); KernelLog.Ln;
		RETURN
	END;

	context := CL.CreateContext(0, 1, ADDRESSOF(deviceids), NIL , NIL, err2);
	IF err2# CL.SUCCESS THEN
		KernelLog.String(Utils.GetError(err2)); KernelLog.Ln;
		RETURN
	END;

	commands := CL.CreateCommandQueue(context, deviceids, 0, err3);
		IF err3 # CL.SUCCESS THEN
		KernelLog.String(Utils.GetError(err3)); KernelLog.Ln;
		RETURN
	END;

      clinited := (err = 0) & (err1 = 0) & (err2 = 0) & (err3 = 0) & (context # 0) & (commands # 0);
      ASSERT(clinited, 101);
END InitCL;

(* open *.cl file *)
PROCEDURE Open*(context : Commands.Context); (**  [filename] ~ *)
VAR
	wind: Window;
	filename : ARRAY 256 OF CHAR;
BEGIN
	NEW(wind, NIL);
	IF context.arg.GetString(filename) THEN
		wind.LoadCLFile(filename);
(*		wind.cleditor.Invalidate;*)
	END;
END Open;

(* read kernelsource *)
PROCEDURE ReadThisKernel*(context : Commands.Context); (**  kernel source *)
VAR
	wind: Window;
BEGIN
	NEW(wind, NIL);
	wind.ReadThis(context.arg);

END ReadThisKernel;

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
		err := CL.ReleaseCommandQueue(commands);
		err := CL.ReleaseContext(context);
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
	NEW(buf, 16384); (* buffer for reading texts *)
	Modules.InstallTermHandler(Cleanup);
	InitCL;
END OpenCLBuild.

OpenCLBuild.Open ~ 

SystemTools.Free OpenCLBuild ~

SystemTools.FreeDownTo OpenCL ~

OpenCLBuild.Open  opencloberon/vectorsquare.cl ~


OpenCLBuild.ReadThisKernel  __kernel void empty(float x)
  {

  }

  ~
(*
Write your OpenCL programs into Source code editor (upper editor) and press to Build button
if there is no error SUCCESS printed to Build log (bottom editor), otherwise, type of error and its
position is displayed.

Build options, if your program requires,  can be written into Options Textfield (top editor).
See Khronos_OpenCL_Specification.pdf for other build options.

*)
