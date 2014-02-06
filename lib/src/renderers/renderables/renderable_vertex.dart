/*
 * @author mr.doob / http://mrdoob.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 */

part of three;

class RenderableVertex {
  Vector3 position = new Vector3.zero();
  Vector3 positionWorld = new Vector3.zero();
  Vector4 positionScreen = new Vector4.identity();

  bool visible = true;

  void copy(RenderableVertex vertex) {
    positionWorld.setFrom(vertex.positionWorld);
    positionScreen.setFrom(vertex.positionScreen);
  }
}
