/**
 * @author mikael emtinger / http://gomo.se/
 * 
 * based on r63
 */

library AnimationHandler;

import 'package:three/three.dart';

var _playing = [];
var _library = {};

// interpolation types
const int LINEAR = 0;
const int CATMULLROM = 1;
const int CATMULLROM_FORWARD = 2;

///Update animations
void update(int deltaTimeMS) {
  for (var i = 0; i < _playing.length; i++)
    _playing[i].update (deltaTimeMS);
}

///Add [animation] to update
void addToUpdate(animation) {
  if (!_playing.contains(animation)) {
    _playing.add(animation);
  }
}

///Remove [animation] from update
void removeFromUpdate(animation) {
  if(_playing.contains(animation))
    _playing.remove( animation );
}

///Add animation
void add(Map data) {
  if (_library.containsKey(data["name"]))
    print("AnimationHandler.add: Warning! [${data["name"]}] already exists in library. Overwriting.");
  _library[data["name"]] = data;
  _initData(data); 
}

///Get animation [name]
Map get(String name) {
  if (_library.containsKey(name)) {
    return _library[name];
  } else {
    print("AnimationHandler.get: Couldn't find animation [$name]");
    return null;  
  } 
}

///Parse
List parse(root) {
  var hierarchy = [];
  if (root is SkinnedMesh) {
    for (var b = 0; b < root.bones.length; b++) {
      hierarchy.add(root.bones[b]);
    }
  } else {
    _parseRecurseHierarchy(root, hierarchy);
  }
  return hierarchy;
}

void _parseRecurseHierarchy(Mesh root, List hierarchy) {
  hierarchy.add(root);
  for (var c = 0; c < root.children.length; c++)
    _parseRecurseHierarchy(root.children[c], hierarchy);
}

void _initData(Map data) {
  if (data.containsKey("initialized") && data["initialized"])
    return;
  
  // loop through all keys
  for (var h = 0; h < data["hierarchy"].length; h++) {
    for (var k = 0; k < data["hierarchy"][h]["keys"].length; k++) {
      // remove minus times
      if (data["hierarchy"][h]["keys"][k]["time"] < 0) {
        data["hierarchy"][h]["keys"][k]["time"] = 0;
      }
      
      // create quaternions
      if (data["hierarchy"][h]["keys"][k].containsKey("rot") &&
          (data["hierarchy"][h]["keys"][k]["rot"] is! Quaternion)) {
        var quat = data["hierarchy"][h]["keys"][k]["rot"];
        data["hierarchy"][h]["keys"][k]["rot"] = new Quaternion(quat[0].toDouble(), quat[1].toDouble(), quat[2].toDouble(), quat[3].toDouble());
      }
    }
    
    // prepare morph target keys
    if (data["hierarchy"][h]["keys"].isNotEmpty && data["hierarchy"][h]["keys"][0].containsKey("morphTargets")) {
      // get all used
      var usedMorphTargets = {};

      for (var k = 0; k < data["hierarchy"][h]["keys"].length; k ++ ) {
        for (var m = 0; m < data["hierarchy"][h]["keys"][k]["morphTargets"].length; m++) {
          var morphTargetName = data["hierarchy"][h]["keys"][k]["morphTargets"][m];
          usedMorphTargets[ morphTargetName ] = -1;
        }
      }

      data["hierarchy"][h]["usedMorphTargets"] = usedMorphTargets;

      // set all used on all frames
      for (var k = 0; k < data["hierarchy"][h]["keys"].length; k++) {
        var influences = {};

        for (var morphTargetName in usedMorphTargets) {
          for (var m = 0; m < data["hierarchy"][h]["keys"][k]["morphTargets"].length; m++) {
            if (data["hierarchy"][h]["keys"][k]["morphTargets"][m] == morphTargetName) {
              influences[morphTargetName] = data["hierarchy"][h]["keys"][k]["morphTargetsInfluences"][m];
              break;

            }
            
            if (m == data["hierarchy"][h]["keys"][k]["morphTargets"].length) {
              influences[morphTargetName] = 0;
            }
          }
        }
        data["hierarchy"][h]["keys"][k]["morphTargetsInfluences"] = influences;
      }
    }

    // remove all keys that are on the same time
    for (var k = 1; k < data["hierarchy"][h]["keys"].length; k++) {
      if (data["hierarchy"][h]["keys"][k]["time"] == data["hierarchy"][h]["keys"][k - 1]["time"]) {
        data["hierarchy"][h]["keys"].removeAt(k);
        k--;
      }
    }

    // set index
    for (var k = 0; k < data["hierarchy"][h]["keys"].length; k++) {
      data["hierarchy"][h]["keys"][k]["index"] = k;
    }
  }

  // JIT
  int lengthInFrames = data.length * data["fps"];

  data["JIT"] = {};
  data["JIT"]["hierarchy"] = [];

  for( var h = 0; h < data["hierarchy"].length; h++) {
    data["JIT"]["hierarchy"].add(new List(lengthInFrames));
  }

  // done
  data["initialized"] = true;
}

