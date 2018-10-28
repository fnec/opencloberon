# OpenCL bindings for A2- LinuxAos and WinAos.
# https://github.com/fnec/opencloberon


# For UNIX and WIN platforms, compile:
Compiler.Compile
	opencloberon/OpenCL.Mod
	opencloberon/OpenCLext.Mod
	opencloberon/OpenCLGL.Mod
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
	opencloberon/OpenCLVectorSquare2.Mod
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

 System.FreeDownTo OpenCL ~ 
