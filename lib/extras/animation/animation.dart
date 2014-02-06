/*
 * @author mikael emtinger / http://gomo.se/
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 * 
 * based on r62
 */

part of three;

class Animation implements IAnimation {
  Mesh root;
  Map data;
  List hierarchy;
  
  int currentTime = 0;
  double timeScale = 1.0;
  
  bool isPlaying = false;
  bool isPaused = true;
  bool loop = true;
  
  int interpolationType;
  
  List points = [];
  Vector3 target = new Vector3.zero();
  
  Animation(Mesh root, String name, {this.interpolationType: AnimationHandler.LINEAR})
      : data = AnimationHandler.get(name),
        hierarchy = AnimationHandler.parse(root);
    
  void play([loop = true, int startTimeMS = 0]) {
    if (!isPlaying) {
      isPlaying = true;
      this.loop = loop;
      currentTime = startTimeMS;
      
      // reset key cache
      for (var h = 0; h < hierarchy.length; h++) {
        var object = hierarchy[h];
        object.matrixAutoUpdate = true;

        if (object.animationCache == null) {
          object.animationCache = {};
          object.animationCache["prevKey"] = {"pos": 0, "rot": 0, "scl": 0};
          object.animationCache["nextKey"] = {"pos": 0, "rot": 0, "scl": 0};
          object.animationCache["originalMatrix"] = object is Bone ? object.skinMatrix : object.matrix;
        }

        var prevKey = object.animationCache["prevKey"];
        var nextKey = object.animationCache["nextKey"];

        prevKey["pos"] = data["hierarchy"][h]["keys"][0];
        prevKey["rot"] = data["hierarchy"][h]["keys"][0];
        prevKey["scl"] = data["hierarchy"][h]["keys"][0];

        nextKey["pos"] = getNextKeyWith("pos", h, 1);
        nextKey["rot"] = getNextKeyWith("rot", h, 1);
        nextKey["scl"] = getNextKeyWith("scl", h, 1);
      }
      update(0);
    }

    isPaused = false;
    AnimationHandler.addToUpdate(this); 
  }
  
  ///Pause the animation
  void pause() {
    if(isPaused) {
      AnimationHandler.addToUpdate(this);
    } else {
      AnimationHandler.removeFromUpdate(this);
    }
    isPaused = !isPaused;
  }
  
  void stop() {
    isPlaying = false;
    isPaused = false;
 
    AnimationHandler.removeFromUpdate(this);
  }
  
  void update(int deltaTimeMS) { 
    // early out
    if (!isPlaying) return;

    // vars
    var types = ["pos", "rot", "scl"];
    var type;
    var scale;
    var vector;
    var prevXYZ, nextXYZ;
    var prevKey, nextKey;
    var object;
    var animationCache;
    var frame;
    var JIThierarchy = data["JIT"]["hierarchy"];
    var currentTime, unloopedCurrentTime;
    var currentPoint, forwardPoint, angle;

    this.currentTime += deltaTimeMS * timeScale;

    unloopedCurrentTime = this.currentTime;
    currentTime         = this.currentTime = this.currentTime % data.length;
    
    frame = Math.min(currentTime * data["fps"], data.length * data["fps"]).toInt();

    var hl = hierarchy.length;
    for (var h = 0; h < hl; h ++) {

      object = hierarchy[h];
      animationCache = object.animationCache;

      // loop through pos/rot/scl

      for (var t = 0; t < 3; t ++) {

        // get keys

        type    = types[t];
        prevKey = animationCache["prevKey"][type];
        nextKey = animationCache["nextKey"][type];

        // switch keys?
        if (nextKey["time"] <= unloopedCurrentTime) {

          // did we loop?
          if (currentTime < unloopedCurrentTime) {
            if (loop) {
              prevKey = data["hierarchy"][h]["keys"][0];
              nextKey = getNextKeyWith(type, h, 1);

              while(nextKey.time < currentTime) {
                prevKey = nextKey;
                nextKey = getNextKeyWith(type, h, nextKey["index"] + 1);
              }
            } else {
              stop();
              return;
            }
          } else {
            do {
              prevKey = nextKey;
              nextKey = getNextKeyWith(type, h, nextKey["index"] + 1);

            } while(nextKey.time < currentTime);
          }
          animationCache["prevKey"][type] = prevKey;
          animationCache["nextKey"][type] = nextKey;
        }

        object.matrixAutoUpdate = true;
        object.matrixWorldNeedsUpdate = true;

        scale = (currentTime - prevKey["time"]) / (nextKey["time"] - prevKey["time"]);
        prevXYZ = prevKey[type];
        nextXYZ = nextKey[type];

        // check scale error
        if (scale < 0 || scale > 1) {
          print("Animation.update: Warning! Scale out of bounds: [$scale] on bone [$h]");
          scale = scale < 0 ? 0 : 1;
        }

        // interpolate
        if (type == "pos") {
          vector = object.position;
          
          if (interpolationType == AnimationHandler.LINEAR) {
            vector.x = prevXYZ[0] + (nextXYZ[0] - prevXYZ[0]) * scale;
            vector.y = prevXYZ[1] + (nextXYZ[1] - prevXYZ[1]) * scale;
            vector.z = prevXYZ[2] + (nextXYZ[2] - prevXYZ[2]) * scale;

          } else if (interpolationType == AnimationHandler.CATMULLROM ||
              interpolationType == AnimationHandler.CATMULLROM_FORWARD) {
            points[0] = getPrevKeyWith("pos", h, prevKey["index"] - 1)["pos"];
            points[1] = prevXYZ;
            points[2] = nextXYZ;
            points[3] = getNextKeyWith("pos", h, nextKey["index"] + 1)["pos"];

            scale = scale * 0.33 + 0.33;

            currentPoint = interpolateCatmullRom(points, scale);

            vector.x = currentPoint[0];
            vector.y = currentPoint[1];
            vector.z = currentPoint[2];

            if (interpolationType == AnimationHandler.CATMULLROM_FORWARD) {
              forwardPoint = interpolateCatmullRom(points, scale * 1.01);

              target.setValues(forwardPoint[0], forwardPoint[1], forwardPoint[2]);
              target -= vector;
              target.y = 0.0;
              target.normalize();

              angle = Math.atan2(target.x, target.z);
              object.rotation.setValues(0.0, angle, 0.0);
            }
          }
        } else if (type == "rot") {
          object.quaternion = Quaternion.slerp(new Quaternion.array(prevXYZ), new Quaternion.array(nextXYZ), scale);

        } else if (type == "scl") {
          vector = object.scale;

          vector.x = prevXYZ[0] + (nextXYZ[0] - prevXYZ[0]) * scale;
          vector.y = prevXYZ[1] + (nextXYZ[1] - prevXYZ[1]) * scale;
          vector.z = prevXYZ[2] + (nextXYZ[2] - prevXYZ[2]) * scale;
        }
      }
    }
  }
  
  // Catmull-Rom spline
  interpolateCatmullRom(points, scale) {
    var c = [], v3 = [],
    point, intPoint, weight, w2, w3,
    pa, pb, pc, pd;

    point = (points.length - 1) * scale;
    intPoint = point.floor();
    weight = point - intPoint;

    c[0] = intPoint == 0 ? intPoint : intPoint - 1;
    c[1] = intPoint;
    c[2] = intPoint > points.length - 2 ? intPoint : intPoint + 1;
    c[3] = intPoint > points.length - 3 ? intPoint : intPoint + 2;

    pa = points[c[0]];
    pb = points[c[1]];
    pc = points[c[2]];
    pd = points[c[3]];

    w2 = weight * weight;
    w3 = weight * w2;

    v3[0] = interpolate(pa[0], pb[0], pc[0], pd[0], weight, w2, w3);
    v3[1] = interpolate(pa[1], pb[1], pc[1], pd[1], weight, w2, w3);
    v3[2] = interpolate(pa[2], pb[2], pc[2], pd[2], weight, w2, w3);

    return v3; 
  }

  interpolate(p0, p1, p2, p3, t, t2, t3) {
    var v0 = (p2 - p0) * 0.5,
        v1 = (p3 - p1) * 0.5;

    return (2 * (p1 - p2) + v0 + v1) * t3 + (-3 * (p1 - p2) - 2 * v0 - v1) * t2 + v0 * t + p1;
  }

  // Get next key with
  getNextKeyWith(String type, int h, int key) {
    var keys = data["hierarchy"][h]["keys"];
  
    if (interpolationType == AnimationHandler.CATMULLROM ||
             interpolationType == AnimationHandler.CATMULLROM_FORWARD) {
      key = key < keys.length - 1 ? key : keys.length - 1;
    } else {
      key = key % keys.length;
    }
    
    for (; key < keys.length; key++) {
      if (keys[key].containsKey(type)) {
        return keys[key];
      }
    }
    return data["hierarchy"][h]["keys"][0];
  }

  // Get previous key with
  getPrevKeyWith(String type, int h, int key) {
    var keys = data["hierarchy"][h]["keys"];

    if (interpolationType == AnimationHandler.CATMULLROM ||
         interpolationType == AnimationHandler.CATMULLROM_FORWARD) {
      key = key > 0 ? key : 0;
    } else {
      key = key >= 0 ? key : key + keys.length;
    }
    
    for (; key >= 0; key--) {
      if (keys[key].containsKey(type)) {
        return keys[key];
      }
    }
    return data["hierarchy"][h]["keys"][keys.length - 1];
  } 
}