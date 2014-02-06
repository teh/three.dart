/**
 * @author mrdoob / http://mrdoob.com/
 *
 * parameters = {
 *  color: <hex>,
 *  program: <function>,
 *  opacity: <float>,
 *  blending: THREE.NormalBlending
 * }
 */

part of three;

typedef SpriteCanvasMaterialProgram(context, color);

class SpriteCanvasMaterial extends Material {
  Color color;
  SpriteCanvasMaterialProgram program;
  
  SpriteCanvasMaterial({// SpriteCanvasMaterial
                        int color: 0xffffff,
                        this.program,
    
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
                       
                        visible: true})
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