/*
 * @author mr.doob / http://mrdoob.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 */

part of three;

class RenderableLine implements IRenderable {
  int id = 0;
  
  RenderableVertex v1 = new RenderableVertex();
  RenderableVertex v2 = new RenderableVertex();
  
  List<Color> vertexColors = new List.filled(2, new Color.white());
  Material material;
  
  double z = 0.0;
}
