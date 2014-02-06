/*
 * @author mr.doob / http://mrdoob.com/
 * @author mikael emtinger / http://gomo.se
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 * 
 * based on r63
 */

part of three;

class Camera extends Object3D {
  Matrix4 matrixWorldInverse = new Matrix4.identity();
  Matrix4 projectionMatrix = new Matrix4.identity();
  Matrix4 projectionMatrixInverse = new Matrix4.identity();
  
  double near;
  double far;
  
  Camera([this.near, this.far]) : super();
  
  void lookAt(Vector3 vector) {
    quaternion = new Quaternion.fromRotation(new Matrix3.lookAt(position, vector, up));
  }
  
  Camera clone([Camera camera, bool recursive = false]) {
    if (camera == null) camera = new Camera();
    
    super.clone(camera, recursive);
    
    camera.matrixWorldInverse.setFrom(matrixWorldInverse);
    camera.projectionMatrix.setFrom(projectionMatrix);
    camera.projectionMatrixInverse.setFrom(projectionMatrixInverse);
    
    return camera;
  }
}
