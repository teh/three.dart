/*
 * @author alteredq / http://alteredqualia.com/
 * 
 * based on r63
 */

part of three;

class Gyroscope extends Object3D {
  Vector3 translationWorld = new Vector3.zero();
  Vector3 translationObject  = new Vector3.zero();
  Quaternion rotationWorld = new Quaternion.identity();
  Quaternion rotationObject = new Quaternion.identity();
  Vector3 scaleWorld = new Vector3.zero();
  Vector3 scaleObject = new Vector3.zero();
  
  void updateMatrixWorld([bool force = false]) {
    if (matrixAutoUpdate) updateMatrix();

    // update matrixWorld
    if (matrixWorldNeedsUpdate || force) {
      if (parent != null) {
        matrixWorld = parent.matrixWorld * matrix;

        matrixWorld.decompose(translationWorld, rotationWorld, scaleWorld);
        matrix.decompose(translationObject, rotationObject, scaleObject);

        matrixWorld = new Matrix4.compose(translationWorld, rotationObject, scaleWorld);
      } else {
        matrixWorld.setFrom(matrix);
      }

      matrixWorldNeedsUpdate = false;

      force = true;
    }
    
    // update children
    children.forEach((child) => child.updateMatrixWorld(force));
  }
}