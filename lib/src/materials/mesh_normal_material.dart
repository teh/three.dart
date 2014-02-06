/*
 * @author mr.doob / http://mrdoob.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 *
 * parameters = {
 *  opacity: <float>,

 *  shading: THREE.FlatShading,
 *  blending: THREE.NormalBlending,
 *  depthTest: <bool>,

 *  wireframe: <boolean>,
 *  wireframeLinewidth: <float>
 * }
 */

part of three;

class MeshNormalMaterial extends Material {
  /// How the triangles of a curved surface are rendered: as a smooth surface, as flat separate facets, or no shading at all.
  /// Options are SMOOTH_SHADING (default), FLAT_SHADING
  int shading;
  
  /// Render geometry as wireframe. Default is false (i.e. render as smooth shaded).
  bool wireframe;
  
  /// Controls wireframe thickness. Default is 1.

  /// Due to limitations in the ANGLE layer, on Windows platforms 
  /// linewidth will always be 1 regardless of the set value.
  double wireframeLinewidth;
  
  /// Define whether the material uses morphTargets. Default is false.
  bool morphTargets;

  /// A material that maps the normal vectors to RGB colors.
  MeshNormalMaterial({// MeshNormalMaterial
                      this.shading: FLAT_SHADING,
                      this.wireframe: false,
                      this.wireframeLinewidth: 1.0,

                      // Material
                      String name: '',
                      int side: FRONT_SIDE,

                      double opacity: 1.0,
                      bool transparent: false,

                      int blending: NORMAL_BLENDING,
                      int blendSrc: SRC_ALPHA_FACTOR,
                      int blendDst: ONE_MINUS_SRC_ALPHA_FACTOR,
                      int blendEquation: ADD_EQUATION,

                      bool depthTest: true,
                      bool depthWrite: true,

                      bool polygonOffset: false,
                      int polygonOffsetFactor: 0,
                      int polygonOffsetUnits: 0,

                      int alphaTest: 0,
                      
                      int overdraw: 0,

                      bool visible: true})
      : super(name: name,
              side: side,
              opacity: opacity,
              transparent: transparent,
              blending: blending,
              blendSrc: blendSrc,
              blendDst: blendDst,
              blendEquation: blendEquation,
              depthTest: depthTest,
              depthWrite: depthWrite,
              polygonOffset: polygonOffset,
              polygonOffsetFactor: polygonOffsetFactor,
              polygonOffsetUnits: polygonOffsetUnits,
              alphaTest: alphaTest,
              overdraw: overdraw,
              visible: visible);
  
  //TODO Add clone.
}
