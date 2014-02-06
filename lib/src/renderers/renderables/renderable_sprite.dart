/*
 * @author mrdoob / http://mrdoob.com/
 */

part of three; 

class RenderableSprite implements IRenderable {
  int id = 0;
  
  Object3D object;
  
  double x = 0.0;
  double y = 0.0;
  double z = 0.0;
  
  double rotation = 0.0;
  Vector2 scale = new Vector2.zero();
  
  Material material;
}