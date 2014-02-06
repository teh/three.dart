/*
 * @author alteredq / http://alteredqualia.com/
 *
 * parameters = {
 *  fragmentShader: <string>,
 *  vertexShader: <string>,
 *
 *  uniforms: { "parameter1": { type: "f", value: 1.0 }, "parameter2": { type: "i" value2: 2 } },
 *
 *  defines: { "label" : "value" },
 *
 *  shading: THREE.SmoothShading,
 *  blending: THREE.NormalBlending,
 *  depthTest: <bool>,
 *  depthWrite: <bool>,
 *
 *  wireframe: <boolean>,
 *  wireframeLinewidth: <float>,
 *
 *  lights: <bool>,
 *
 *  vertexColors: THREE.NoColors / THREE.VertexColors / THREE.FaceColors,
 *
 *  skinning: <bool>,
 *  morphTargets: <bool>,
 *  morphNormals: <bool>,
 *
 *        fog: <bool>
 * }
 */

part of three;

/// Material rendered with custom shaders
class ShaderMaterial extends Material {
  String fragmentShader;
  String vertexShader;
  Map<String, Uniform> uniforms;
  Map<String, num> defines;
  Map<String, Attribute> attributes;

  int shading;
  
  double lineWidth;

  bool wireframe;
  double wireframeLinewidth;
  
  bool fog;

  bool lights; // set to use scene lights
  
  int vertexColors;

  bool skinning; // set to use skinning attribute streams

  bool morphTargets; // set to use morph targets
  bool morphNormals; // set to use morph normals
  
  ShaderMaterial({// ShaderMaterial
                  this.attributes,
                  this.fragmentShader: "void main() {}",
                  this.vertexShader: "void main() {}",
                  Map<String, Uniform> uniforms,
                  Map<String, num> defines,

                  this.shading: SMOOTH_SHADING,

                  this.vertexColors: NO_COLORS,

                  this.fog: true,

                  this.wireframe: false,
                  this.wireframeLinewidth: 1.0,

                  this.skinning: false,
                  this.morphTargets: false,
                  this.morphNormals: false,

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
                  int polygonOffsetUnits:  0,

                  int alphaTest: 0,

                  int overdraw: 0,

                  bool visible: true,
                  this.lights: false})
      : this.uniforms = uniforms != null ? uniforms : {},
        this.defines = defines != null ? defines : {},
        super(name: name,
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
