/*
 * @author alteredq / http://alteredqualia.com
 */

part of three;

class WebGLRenderTargetCube extends WebGLRenderTarget {
	int activeCubeFace = 0; // PX 0, NX 1, PY 2, NY 3, PZ 4, NZ 5

	WebGLRenderTargetCube(int width, int height,
          	           {wrapS: CLAMP_TO_EDGE_WRAPPING,
          						  wrapT: CLAMP_TO_EDGE_WRAPPING,
          						  magFilter: LINEAR_FILTER,
          						  minFilter: LINEAR_MIPMAP_LINEAR_FILTER,
          						  anisotropy: 1,
          						  format: RGBA_FORMAT,
          						  type: UNSIGNED_BYTE_TYPE,
          						  depthBuffer: true,
          						  stencilBuffer: true}) :
      super(width, height,
            wrapS: wrapS,
    	      wrapT: wrapT,
    	      magFilter: magFilter,
    	      minFilter: minFilter,
    	      anisotropy: anisotropy,
    	      format: format,
    	      type: type,
    	      depthBuffer: depthBuffer,
    	      stencilBuffer: stencilBuffer);
}
