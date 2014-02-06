/*
 * @author mikael emtinger / http://gomo.se/
 * @author alteredq / http://alteredqualia.com/
 * @author mrdoob / http://mrdoob.com/
 */

part of three;

class LOD extends Object3D {
  List<LODObject> objects = [];

  void addLevel(Object3D object, [double distance = 0.0]) {
    distance = distance.abs();
    
    var l;
    for (l = 0; l < objects.length; l++) {
      if (distance < objects[l].distance) break;
    }

    objects.insert(l, new LODObject(distance, object));
    add(object);
  }
  
  Object3D getObjectForDistance(double distance) {
    var i;
    for (i = 1; i < objects.length; i++) {
      if (distance < objects[i].distance) break;
    }

    return objects[i - 1].object;
  }

  void update(Camera camera) {
    if (objects.length > 1) {
      var v1 = camera.matrixWorld.getTranslation();
      var v2 = matrixWorld.getTranslation();
      
      var distance = v1.distanceTo(v2);
      objects[0].object.visible = true;

      var l;
      for (l = 1; l < objects.length; l++) {
        if (distance >= objects[l].distance) {
          objects[l - 1].object.visible = false;
          objects[l].object.visible = true;
        } else {
          break;
        }
      }

      for(; l < objects.length; l++) {
        objects[l].object.visible = false;
      }
    }
  }
}

class LODObject {
  double distance;
  Object3D object;
  
  LODObject(this.distance, this.object);
}
