/*
 * @author mr.doob / http://mrdoob.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 */

part of three;

class RenderableFace3 implements IRenderable {
  int id = 0;
  
  RenderableVertex v1 = new RenderableVertex();
  RenderableVertex v2 = new RenderableVertex();
  RenderableVertex v3 = new RenderableVertex();
  
  Vector3 centroidModel = new Vector3.zero();
  
  Vector3 normalModel = new Vector3.zero();
  Vector3 normalModelView = new Vector3.zero();

  int vertexNormalsLength = 0;
  List<Vector3> vertexNormalsModel = new List.filled(3, new Vector3.zero());
  List<Vector3> vertexNormalsModelView = new List.filled(3, new Vector3.zero());

  Color color;
  Material material;
  List<Vector2> uvs = [[]];
  
  double z = 0.0;
}
