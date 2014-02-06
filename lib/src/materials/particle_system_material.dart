/*
 * @author mr.doob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 *
 * parameters = {
 *  color: <hex>,
 *  opacity: <float>,
 *  map: new THREE.Texture( <Image> ),
 *
 *  size: <float>,
 *
 *  blending: THREE.NormalBlending,
 *  depthTest: <bool>,
 *
 *  vertexColors: false / THREE.NoColors  / THREE.VertexColors / THREE.FaceColors,
 *
 *  fog: <bool>
 * }
 */

part of three;

class ParticleSystemMaterial extends Material {
  /// Sets the color of the particles. Default is 0xffffff.
  Color color;
  
  /// Sets the color of the particles using data from a texture (?).
  Texture map;
  
  /// Sets the size of the particles. Default is 1.0.
  double size;
  
  /// Specify whether particles' size will get smaller with the distance. 
  /// Default is true.
  bool sizeAttenuation;

  /// Define whether the material uses vertex colors, or not. Default is false.
  /// This setting might not have any effect when used with certain renderers. 
  /// For example, it is ignored with the Canvas renderer, but does work with the WebGL renderer.
  int vertexColors;
  
  /// Define whether the material color is affected by global fog settings.
  /// This setting might not have any effect when used with certain renderers. 
  /// For example, it is ignored with the Canvas renderer, 
  /// but does work with the WebGL renderer.
  bool fog;

  /// The default material used by particle systems.
  ParticleSystemMaterial({// ParticleSystemMaterial
                          this.map,
                          int color: 0xffffff,
                          this.size: 1.0,
                          this.sizeAttenuation: true,
                          this.vertexColors: NO_COLORS,

                          this.fog: true, 

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
      : this.color = new Color(color),
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





