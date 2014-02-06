/**
 * @author zz85 / http://www.lab4games.net/zz85/blog
 * @author alteredq / http://alteredqualia.com/
 * 
 * based on r63
 */

part of three;

/// Class for creating 3D text geometry in three.dart.
class TextGeometry extends ExtrudeGeometry {
  /**
   * ## Parameters
   * * text([String]): 3D text.
   * * size([double]): Size of the text.
   * * height([double]): Thickness to extrude text.
   * * curveSegments([int]): Number of points on the curves.
   * * font([String]): Font name.
   * * weight([String]): Font weight (normal, bold).
   * * style([String]): Font style  (normal, italics).
   * * bevelEnabled([bool]): Turn on bevel.
   * * bevelThickness([double]): How deep into text bevel goes.
   * * bevelSize([double]): How far from text outline is bevel.
   */
  factory TextGeometry(String text,
                      {double size: 100.0,
                       double height: 50.0,
                       int curveSegments: 4,
                       String font: "helvetiker",
                       String weight: "normal",
                       String style: "normal",
                       
                       bool bevelEnabled: false,
                       double bevelThickness: 10.0,
                       double bevelSize: 8.0}) {
                       
    var textShapes = FontUtils.generateShapes(text, size, curveSegments, font, weight, style);
    
    return new TextGeometry._internal(textShapes,
                                      height,
                                      bevelThickness,
                                      bevelSize,
                                      bevelEnabled);
  }

  TextGeometry._internal(shapes,
                         amount,
                         bevelThickness,
                         bevelSize,
                         bevelEnabled)

      : super(shapes,
              amount: amount,
              bevelThickness: bevelThickness,
              bevelSize: bevelSize,
              bevelEnabled: bevelEnabled);
}
