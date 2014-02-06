/*
 * @author alteredq / http://alteredqualia.com/
 *
 * parameters = {
 *  color: <hex>,
 *  opacity: <float>,
 *  map: new THREE.Texture( <Image> ),
 *
 *  blending: THREE.NormalBlending,
 *  depthTest: <bool>,
 *  depthWrite: <bool>,
 *
 *  uvOffset: new THREE.Vector2(),
 *  uvScale: new THREE.Vector2(),
 *
 *  fog: <bool>
 * }
 */

part of three;

class SpriteMaterial extends Material {
  Color color;
  
  Texture map;
  
  double rotation;
  
  bool fog;
  
  Vector2 uvOffset;
  
  Vector2 uvScale;
  
  SpriteMaterial({// SpriteMaterial
                  int color: 0xffffff,
                  this.map,
                  this.rotation: 0.0,
                  this.fog: false,
                  Vector2 uvOffset,
                  Vector2 uvScale,
                  
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
                  visible: true})
      : this.uvOffset = uvOffset != null ? uvOffset : new Vector2.zero(),
        this.uvScale = uvScale !=  null ? uvScale : new Vector2.one(),
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