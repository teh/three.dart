/*
 * @author WestLangley / http://github.com/WestLangley
 * 
 * based on r63
 */

part of three;

/// A helper to show the world-axis-aligned bounding box for an object.
class BoundingBoxHelper extends Mesh {
  Object3D object;
  Box3 box = new Box3();
  
  BoundingBoxHelper(this.object, [int hex = 0x888888]) 
      : super(new CubeGeometry(1.0, 1.0, 1.0), 
              new MeshBasicMaterial(color: hex, wireframe: true));
  
  void update() {
    box.setFromObject(object);
    scale = box.size;
    position = box.center;
  }
}