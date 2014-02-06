/*
 * @author mr.doob / http://mrdoob.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 */

part of three;

class RenderableObject implements IRenderable {
  int id = 0;
  
  Object3D object;
  double z = 0.0;
}
