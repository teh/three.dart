/*
 * @author mr.doob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 */

part of three;

class LineBasicMaterial extends Material {
  /// Sets the color of the line. Default is 0xffffff.
  Color color;
  
  /// Controls line thickness. Default is 1.
  /// Due to limitations in the ANGLE layer, 
  /// on Windows platforms linewidth will always be 1 regardless of the set value.
  double linewidth;
  
  /// Define appearance of line ends. Possible values are "butt", "round" and "square". 
  /// Default is 'round'. This setting might not have any effect when used with certain renderers. 
  /// For example, it is ignored with the WebGL renderer, but does work with the Canvas renderer.
  String linecap;
  
  /// Define appearance of line joints. Possible values are "round", "bevel" and "miter". 
  /// Default is 'round'.This setting might not have any effect when used with certain renderers. 
  /// For example, it is ignored with the WebGL renderer, but does work with the Canvas renderer.
  String linejoin;

  /// Define whether the material color is affected by global fog settings.
  /// This setting might not have any effect when used with certain renderers. 
  /// For example, it is ignored with the Canvas renderer, but does work with the WebGL renderer.
  bool fog;
  
  /// Define whether the material uses vertex colors, or not. Default is NO_COLORS.
  /// This setting might not have any effect when used with certain renderers. 
  /// For example, it is ignored with the Canvas renderer, but does work with the WebGL renderer.
  int vertexColors;

  /**
   * A material for drawing wireframe-style geometries 
   * 
   * ## Parameters
   * * color[int]
   * * opacity[double]
   * * blending[int] (default: NORMAL_BLENDING)
   * * depthTest[bool]
   * * linewidth[double]
   * * linecap[String] (default: "round")
   * * linejoin[String] (default: "round")
   * * vertexColors[int]
   * * fog[bool]
 */
  LineBasicMaterial({// LineBasicMaterial
                      int color: 0xffffff,
                      this.linewidth: 1.0,
                      this.linecap: 'round',
                      this.linejoin: 'round',
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
            visible: visible );
  
  //TODO Add clone.
}
