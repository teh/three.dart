/*
 * @author alteredq / http://alteredqualia.com/
 *
 * parameters = {
 *  color: <hex>,
 *  opacity: <float>,
 *
 *  blending: THREE.NormalBlending,
 *  depthTest: <bool>,
 *  depthWrite: <bool>,
 *
 *  linewidth: <float>,
 *
 *  scale: <float>,
 *  dashSize: <float>,
 *  gapSize: <float>,
 *
 *  vertexColors: <bool>
 *
 *  fog: <bool>
 * }
 */

part of three;

class LineDashedMaterial extends Material {
  Color color;
  
  double lineWidth;
  
  double scale;
  double dashSize;
  double gapSize;
  
  int vertexColors;
  
  bool fog;
  
  LineDashedMaterial({// LineDashedMaterial
                      int color: 0xffffff,
                      this.lineWidth: 1.0,
                      this.scale: 1.0,
                      this.dashSize: 3.0,
                      this.gapSize: 1.0,
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