/**
 * @author mr.doob / http://mrdoob.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 */

part of three;

class Scene extends Object3D {
  Fog fog;
  Material overrideMaterial;
  
  bool autoUpdate = true;
  
  List<Light> __lights = [];
  
  List<Object3D> __objectsAdded = [];
  List<Object3D> __objectsRemoved = [];

  Scene() {
    matrixAutoUpdate = false;
  }

  void __addObject(Object3D object) {
    if (object is Light) {
      if (!__lights.contains(object)) {
        __lights.add(object);
      }
      
      if (object is DirectionalLight || object is SpotLight) {
        if ((object as dynamic).target != null && (object as dynamic).target.parent == null) {
          add((object as dynamic).target);
        }
      }
    } else if (!(object is Camera || object is Bone)) {
      __objectsAdded.add(object);
      
      // check if previously removed
      if (__objectsRemoved.contains(object)) {
        __objectsRemoved.remove(object);
      }
    }
    
    object.children.forEach((children) => __addObject(children));
  }
  
  void __removeObject(Object3D object) {
    if (object is Light) {
      if (__lights.contains(object)) {
        __lights.remove(object);
      }

      if (object is DirectionalLight) {
        object.shadowCascadeArray.forEach((o) => __removeObject(o));
      }
    } else if (object is! Camera) {
      __objectsRemoved.add(object);

      // check if previously added
      if (__objectsAdded.contains(object)) {
        __objectsAdded.remove(object);
      }
    }
 
    object.children.forEach((o) => __removeObject(o));
  } 
}
