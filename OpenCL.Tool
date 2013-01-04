OpenCL bindings for A2- LinuxAos and WinAos.

# For UnixAos, compile:
Compiler.Compile 
	opencloberon/Unix.OpenCL.Mod 
	opencloberon/Unix.OpenCLext.Mod 
	opencloberon/Unix.OpenCLGL.Mod
	~

# For WinAos, compile :
Compiler.Compile 
	opencloberon/Win32.OpenCL.Mod 
	opencloberon/Win32.OpenCLext.Mod 
	opencloberon/Win32.OpenCLGL.Mod
	~

# Compile Utilities:
Compiler.Compile 
	opencloberon/OpenCLUtils.Mod 
	opencloberon/OpenCLInfo.Mod 
	opencloberon/OpenCLBuild.Mod 
	~

# Demos:
Compiler.Compile
	opencloberon/OpenCLVectorSquare.Mod
	opencloberon/OpenCLVectorSquare1.Mod
	opencloberon/MySimpleMandelbrotCL.Mod
	opencloberon/MyMandelbrotCL.Mod
	opencloberon/OpenCLEvents.Mod
	opencloberon/MyImageRotateCL.Mod
	opencloberon/MyJuliasetCL.Mod
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