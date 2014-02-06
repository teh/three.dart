/*
 * @author mr.doob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 * @author mikael emtinger / http://gomo.se/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 * @author nelson silva / http://www.inevo.pt/
 */

part of three;

class Mesh extends Object3D {
  /// An instance of Geometry, defining the object's structure.
  Geometry geometry;
  
  /// An instance of Material, defining the object's appearance. 
  /// Default is a MeshBasicMaterial with wireframe mode enabled 
  /// and randomised colour.
  Material material;

  int morphTargetBase;
  List morphTargetForcedOrder;
  List morphTargetInfluences;
  Map morphTargetDictionary;

  Mesh([this.geometry, this.material]) : super() {
    geometry = geometry != null ? geometry : new Geometry();
    material = material != null ? material : new MeshBasicMaterial(color: MathUtils.randHex(), wireframe: true);
    
    updateMorphTargets();
  }
  
  void updateMorphTargets() {
    if (geometry.morphTargets.length > 0) {
      morphTargetBase = -1;
      morphTargetForcedOrder = [];
      morphTargetInfluences = [];
      morphTargetDictionary = {};
      
      for (var m = 0; m < geometry.morphTargets.length; m++) {
        morphTargetInfluences.add(0);
        morphTargetDictionary[geometry.morphTargets[m].name] = m;
      }
    }
  }

  /// Returns the index of a morph target defined by name.
  int getMorphTargetIndexByName(String name) {
    if (morphTargetDictionary.containsKey(name)) {
      return morphTargetDictionary[name];
    }

    print("Mesh.getMorphTargetIndexByName: morph target [$name] does not exist. Returning 0.");
    return 0;
  }
}
