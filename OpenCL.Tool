OpenCL bindings for A2- LinuxAos and WinAos.

# For UnixAos, compile:
Compiler.Compile Unix.OpenCL.Mod Unix.OpenCLext.Mod Unix.OpenCLGL.Mod~

# For WinAos, compile :
Compiler.Compile Win32.OpenCL.Mod Win32.OpenCLext.Mod Win32.OpenCLGL.Mod~

# Compile Utilities:
Compiler.Compile OpenCLUtils.Mod OpenCLInfo.Mod OpenCLBuild.Mod ~

# Demos:
Compiler.Compile
	OpenCLVectorSquare.Mod
	OpenCLVectorSquare1.Mod
	MySimpleMandelbrotCL.Mod
	MyMandelbrotCL.Mod
	OpenCLEvents.Mod
	MyImageRotateCL.Mod
	MyJuliasetCL.Mod
~

# Run demos:
	OpenCLInfo.Show ~  # display opencl info

	OpenCLVectorSquare.Test ~
	OpenCLVectorSquare1.Test ~
	OpenCLEvents.Test ~

	MyMandelbrotCL.Open ~
	MySimpleMandelbrotCL.Open ~
	MyImageRotateCL.Open "BluebottlePic0.png" ~
	MyJuliasetCL.Open ~
	OpenCLBuild.Open ~  # opencl kernel source compile testing.

 # remove all modules till OpenCL:

 SystemTools.FreeDownTo OpenCL ~ 