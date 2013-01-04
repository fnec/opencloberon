MODULE OpenCLGL; (** AUTHOR "fnecati"; PURPOSE "OpenCL-1.2 cl_gl and cl_gl_ext binding library  for LinuxAos"; *)
IMPORT CL := OpenCL, Unix;

(* ******************************************************************************
 * Copyright (c) 2011 The Khronos Group Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and/or associated documentation files (the
 * "Materials"), to deal in the Materials without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Materials, and to
 * permit persons to whom the Materials are furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Materials.
 *
 * THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * MATERIALS OR THE USE OR OTHER DEALINGS IN THE MATERIALS.
 ***************************************************************************** *)


TYPE

  	(* scalar types  *)
	cl_int = CL.cl_int;
	cl_uint = CL.cl_uint;
	size_t = CL.size_t;

	cl_context = CL.cl_context;
	cl_command_queue  =  CL.cl_command_queue;
	cl_event = CL.cl_event;
	cl_mem = CL.cl_mem;
	cl_mem_flags = CL.cl_bitfield;

	cl_GLuint = CL.cl_GLuint;
	cl_GLint = CL.cl_GLint;;
	cl_GLenum = CL.cl_GLenum;

TYPE
	cl_gl_object_type* =  cl_uint;
	cl_gl_texture_info* = cl_uint;
	cl_gl_platform_info* = cl_uint;
	cl_GLsync* = POINTER TO RECORD END;


(* cl_gl_object_type = 0x2000 - 0x200F enum values are currently taken           *)
CONST
	CL_OBJECT_BUFFER* = 2000H;
 	CL_OBJECT_TEXTURE2D* =2001H;
 	CL_OBJECT_TEXTURE3D* = 2002H;
 	CL_OBJECT_RENDERBUFFER* =2003;
 	CL_OBJECT_TEXTURE2D_ARRAY* =200EH;
 	CL_OBJECT_TEXTURE1D* =200FH;
 	CL_OBJECT_TEXTURE1D_ARRAY* =2010H;
 	CL_OBJECT_TEXTURE_BUFFER* = 2011H;

	(* cl_gl_texture_info *)
	CL_TEXTURE_TARGET* = 2004H;
	CL_MIPMAP_LEVEL* = 2005H;


TYPE
(* VERSION_1_0 *)
TclCreateFromGLBuffer* =  PROCEDURE {C} (context: cl_context;
                     flags: cl_mem_flags;
                     bufobj: cl_GLuint;
                     VAR errcode_ret: cl_int): cl_mem;

(* VERSION_1_2 *)
TclCreateFromGLTexture* = PROCEDURE {C} (context: cl_context;
                      flags: cl_mem_flags;
                      target: cl_GLenum;
                      miplevel: cl_GLint;
                      texture: cl_GLuint;
                      VAR errcode_ret: cl_int): cl_mem;

(* VERSION_1_0 *)
TclCreateFromGLRenderbuffer* = PROCEDURE {C} (context: cl_context;
                           flags: cl_mem_flags;
                           renderbuffer: cl_GLuint;
                           VAR errcode_ret: cl_int ): cl_mem;

(* VERSION_1_0 *)
TclGetGLObjectInfo =  PROCEDURE {C} (memobj: cl_mem;
                  VAR gl_object_type: cl_gl_object_type;
                  VAR gl_object_name: cl_GLuint): cl_int;

(* VERSION_1_0 *)
TclGetGLTextureInfo* =  PROCEDURE {C} (memobj: cl_mem;
                   param_name: cl_gl_texture_info;
                   param_value_size: size_t;
                   param_value: ADDRESS;
                   param_value_size_ret: ADDRESS (* size_t *)): cl_int;

(* VERSION_1_0 *)
TclEnqueueAcquireGLObjects* = PROCEDURE {C} (command_queue: cl_command_queue;
                          num_objects: cl_uint;
                          mem_objects: ADDRESS (*cl_mem*);
                          num_events_in_wait_list: cl_uint;
                          event_wait_list:  ADDRESS (*cl_event *);
                          event: ADDRESS (*cl_event*)): cl_int;

(* VERSION_1_0 *)
TclEnqueueReleaseGLObjects* = PROCEDURE {C} (command_queue: cl_command_queue;
                          num_objects: cl_uint;
                          mem_objects: ADDRESS (*cl_mem*);
                          num_events_in_wait_list: cl_uint;
                          event_wait_list:  ADDRESS (*cl_event *);
                          event: ADDRESS (*cl_event*)): cl_int;


(*! warning CL_USE_DEPRECATED_OPENCL_1_1_APIS is defined. These APIs are unsupported and untested in OpenCL 1.2! *)
(* DEPRECATED_1_1 *)
TclCreateFromGLTexture2D* = PROCEDURE {C} (context: cl_context;
                            flags: cl_mem_flags;
                            target: cl_GLenum;
                            miplevel: cl_GLint;
                            texture: cl_GLuint;
                            VAR errcode_ret: cl_int):cl_mem;

(* DEPRECATED_1_1 *)
TclCreateFromGLTexture3D* =  PROCEDURE {C} (context: cl_context;
                            flags: cl_mem_flags;
                            target: cl_GLenum;
                            miplevel: cl_GLint;
                            texture: cl_GLuint;
                            VAR errcode_ret: cl_int):cl_mem;

(*!  CL_USE_DEPRECATED_OPENCL_1_1_APIS *)

CONST
	(* cl_khr_gl_sharing extension  *)
	cl_khr_gl_sharing* = 1;

TYPE
	cl_gl_context_info* = cl_uint;

CONST
	(* Additional Error Codes  *)
	CL_INVALID_GL_SHAREGROUP_REFERENCE_KHR* =  -1000;

	(* cl_gl_context_info  *)
	CL_CURRENT_DEVICE_FOR_GL_CONTEXT_KHR* =2006H;
	CL_DEVICES_FOR_GL_CONTEXT_KHR* =2007H;

	(* Additional cl_context_properties  *)
	CL_GL_CONTEXT_KHR* = 2008H;
	CL_EGL_DISPLAY_KHR* = 2009H;
	CL_GLX_DISPLAY_KHR* = 200AH;
	CL_WGL_HDC_KHR* = 200BH;
	CL_CGL_SHAREGROUP_KHR* =200CH;


TYPE
	TclGetGLContextInfoKHR* = PROCEDURE {C} (properties: ADDRESS (*cl_context_properties*);
                      param_name: cl_gl_context_info;
                      param_value_size: size_t;
                      param_value: ADDRESS;
                      VAR param_value_size_ret: size_t):cl_int;




(* **************************** *)
(*! cl_gl_ext.h *)

(*
 * For each extension, follow this template
 *  cl_VEN_extname extension  */
/* #define cl_VEN_extname 1
 * ... define new types, if any
 * ... define new tokens, if any
 * ... define new APIs, if any
 *
 *  If you need GLtypes here, mirror them with a cl_GLtype, rather than including a GL header
 *  This allows us to avoid having to decide whether to include GL headers or GLES here.
 *)

(*
 *  cl_khr_gl_event  extension
 *  See section 9.9 in the OpenCL 1.1 spec for more information
 *)
 CONST
	COMMAND_GL_FENCE_SYNC_OBJECT_KHR* =  200DH;

TYPE
(* VERSION_1_1; *)
	TclCreateEventFromGLsyncKHR* =  PROCEDURE { C } (context: cl_context;  clglsync: cl_GLsync;  VAR errcode_ret: cl_int): cl_event;

(* **************************** *)

VAR
	(* cl_gl *)
	clCreateFromGLBuffer- : TclCreateFromGLBuffer;
	clCreateFromGLTexture- : TclCreateFromGLTexture;
	clCreateFromGLTexture2D- : TclCreateFromGLTexture2D;
	clCreateFromGLTexture3D- : TclCreateFromGLTexture3D;
	clCreateFromGLRenderbuffer- : TclCreateFromGLRenderbuffer;
	clGetGLObjectInfo- : TclGetGLObjectInfo;
	clGetGLTextureInfo- : TclGetGLTextureInfo;
	clEnqueueAcquireGLObjects- : TclEnqueueAcquireGLObjects;
	clEnqueueReleaseGLObjects-: TclEnqueueReleaseGLObjects;

	clGetGLContextInfoKHR-: TclGetGLContextInfoKHR;
	(* cl_gl_ext *)
	clCreateEventFromGLsyncKHR-: TclCreateEventFromGLsyncKHR;

PROCEDURE Init;
VAR lib: LONGINT;	
BEGIN
	lib := CL.lib;
	(* cl_gl *)
	Unix.Dlsym(lib, 'clCreateFromGLBuffer', ADDRESSOF(clCreateFromGLBuffer));
	IF CL.VERSION_1_2 THEN
		Unix.Dlsym(lib, 'clCreateFromGLTexture', ADDRESSOF(clCreateFromGLTexture));
	END;

	IF CL.DEPRECEATED_1_1 THEN
		Unix.Dlsym(lib, 'clCreateFromGLTexture2D', ADDRESSOF(clCreateFromGLTexture2D));
		Unix.Dlsym(lib, 'clCreateFromGLTexture3D ', ADDRESSOF(clCreateFromGLTexture3D));
	END;
	Unix.Dlsym(lib, 'clCreateFromGLRenderbuffer', ADDRESSOF(clCreateFromGLRenderbuffer));
	Unix.Dlsym(lib, 'clGetGLObjectInfo', ADDRESSOF(clGetGLObjectInfo));
	Unix.Dlsym(lib, 'clGetGLTextureInfo', ADDRESSOF(clGetGLTextureInfo));
	Unix.Dlsym(lib, 'clEnqueueAcquireGLObjects', ADDRESSOF(clEnqueueAcquireGLObjects));
	Unix.Dlsym(lib, 'clEnqueueReleaseGLObjects', ADDRESSOF(clEnqueueReleaseGLObjects));


	Unix.Dlsym(lib, 'clGetGLContextInfoKHR', ADDRESSOF(clGetGLContextInfoKHR));
(*	KernelLog.String("clGetGLContextInfoKHR=NIL:  "); KernelLog.Boolean(clGetGLContextInfoKHR=NIL); KernelLog.Ln; *)

	(* cl_gl_ext *)
	IF CL.VERSION_1_1 THEN
		Unix.Dlsym(lib, 'clCreateEventFromGLsyncKHR', ADDRESSOF(clCreateEventFromGLsyncKHR));
	END;


END Init;

BEGIN
	Init;
END OpenCLGL.

