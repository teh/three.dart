part of three;

class WebGLRenderTarget extends Texture {
	int width, height;

	Vector2 offset = new Vector2.zero();
	Vector2 repeat = new Vector2.one();

	bool depthBuffer,
		   stencilBuffer;

	bool generateMipmaps = true;

	var shareDepthFrom;

	var __webglFramebuffer; // List<WebGLFramebuffer> or WebGLFramebuffer
	var __webglRenderbuffer; // List<WebGLRenderbuffer> or WebGLRenderbuffer

	WebGLRenderTarget(this.width, this.height, 
	                 {int wrapS: CLAMP_TO_EDGE_WRAPPING,
                	  int wrapT: CLAMP_TO_EDGE_WRAPPING,
                	  int magFilter: LINEAR_FILTER,
                	  int minFilter: LINEAR_MIPMAP_LINEAR_FILTER,
                	  int anisotropy: 1,
                	  int format: RGBA_FORMAT,
                	  int type: UNSIGNED_BYTE_TYPE,
                	  this.depthBuffer: true,
                	  this.stencilBuffer: true,
	                  this.shareDepthFrom}) 
      : super(null, null, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);

	gl.Texture get __webglTexture => this["__webglTexture"];
  set __webglTexture(gl.Texture tex) { this["__webglTexture"] = tex; }

  WebGLRenderTarget clone([Texture texture]) {
    return new WebGLRenderTarget(width, height)
    ..wrapS = wrapS
    ..wrapT = wrapT
    
    ..magFilter = magFilter
    ..minFilter = minFilter

    ..anisotropy = anisotropy

    ..offset.setFrom(offset)
    ..repeat.setFrom(repeat)

    ..format = format
    ..type = type

    ..depthBuffer = depthBuffer
    ..stencilBuffer = stencilBuffer

    ..generateMipmaps = generateMipmaps

    ..shareDepthFrom = shareDepthFrom;
  }
}