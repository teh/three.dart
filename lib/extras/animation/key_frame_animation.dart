/*
 * @author mikael emtinger / http://gomo.se/
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 * @author khang duong
 * @author erik kitson
 * 
 * based on r62
 */

part of three;

class KeyFrameAnimation implements IAnimation {
  Mesh root;
  Map data;
  List<Bone> hierarchy;
  int currentTime = 0;
  double timeScale = 0.001;
  bool isPlaying = false;
  bool isPaused = true;
  bool loop = true;
  
  bool JITCompile;
  
  int startTime;
  int startTimeMs;
  int endTime;
  
  KeyFrameAnimation(Mesh root, String name, {this.JITCompile: true}) {
    // initialize to first keyframee
    for (var h = 0; h < hierarchy.length; h++) {
      var keys = data["hierarchy"][h]["keys"],
          sids = data["hierarchy"][h]["sids"],
          obj = hierarchy[h];

      if (keys.length && sids) {
        for (var s = 0; s < sids.length; s++) {
          var sid = sids[s],
              next = _getNextKeyWith(sid, h, 0);
          
          if (next) {
            next.apply(sid);
          }
        }
        
        obj.matrixAutoUpdate = false;
        data["hierarchy"][h]["node"].updateMatrix();
        obj.matrixWorldNeedsUpdate = true;
      }
    }
  }
  
  ///Play the animation
  play({loop: false, startTimeMS: 0}) {
    if(!isPlaying) {
      isPlaying = true;
      currentTime = startTimeMS;
      startTimeMs = startTimeMS;
      startTime = 10000000;
      endTime = -startTime;

      // reset key cache
      var h, hl = hierarchy.length,
          object,
          node;
      
      for (h = 0; h < hl; h++) {
        object = hierarchy[h];
        node = data["hierarchy"][h];

        if (node.animationCache == null) {
          node.animationCache = {};
          node.animationCache["prevKey"] = null;
          node.animationCache["nextKey"] = null;
          node.animationCache["originalMatrix"] = object is Bone ? object.skinMatrix : object.matrix;

        }

        var keys = data["hierarchy"][h]["keys"];

        if (keys.length) {
          node.animationCache["prevKey"] = keys[ 0 ];
          node.animationCache["nextKey"] = keys[ 1 ];

          startTime = Math.min(keys[0]["time"], startTime);
          endTime = Math.max(keys[keys.length - 1]["time"], endTime);
        }
      }
      
      update( 0 );
    }
    
    isPaused = false;
    AnimationHandler.addToUpdate(this);
  }
  
  /// Pauses the animation
  void pause() {
    if(isPaused) {
      AnimationHandler.addToUpdate(this);
    } else {
      AnimationHandler.removeFromUpdate(this);
    }

    isPaused = !isPaused;
  }
  
  /// Stops the animation
  stop() {
    isPlaying = false;
    isPaused  = false;
    AnimationHandler.removeFromUpdate( this );

    // reset JIT matrix and remove cache
    for (var h = 0; h < data["hierarchy"].length; h++) {  
      var obj = hierarchy[h];
      var node = data["hierarchy"][ h ];

      if (node.animationCache.isNotEmpty) {
        var original = node.animationCache[ "originalMatrix" ];
        
        if(obj is Bone) {
          original.copy(obj.skinMatrix);
          obj.skinMatrix = original;
        } else {
          original.copy(obj.matrix);
          obj.matrix = original;
        }
        
        node.animationCache.clear();
      }
    }
  }
  
  ///Update the animation
  update(int deltaTimeMS) {
    // early out
    if(!isPlaying) return;

    // vars
    var prevKey, nextKey;
    var object;
    var node;
    var frame;
    var JIThierarchy = data["JIT"]["hierarchy"];
    var currentTime, unloopedCurrentTime;
    var looped;

    // update
    this.currentTime += deltaTimeMS * this.timeScale;

    unloopedCurrentTime = this.currentTime;
    currentTime         = this.currentTime = this.currentTime % data.length;

    // if looped around, the current time should be based on the startTime
    if (currentTime < startTimeMs) {
      currentTime = this.currentTime = this.startTimeMs + currentTime;
    }

    frame = Math.min(currentTime * data["fps"], data.length * data["fps"]).toInt();
    looped = currentTime < unloopedCurrentTime;

    if (looped && !loop) {

      // Set the animation to the last keyframes and stop
      for (var h = 0, hl = this.hierarchy.length; h < hl; h++) {
        var keys = data["hierarchy"][h].keys,
            sids = data["hierarchy"][h].sids,
            end = keys.length-1,
            obj = hierarchy[h];

        if (keys.length) {
          for (var s = 0; s < sids.length; s++) {
            var sid = sids[s],
                prev = _getPrevKeyWith(sid, h, end);

            if (prev) {
              prev.apply(sid);
            }
          }

          data["hierarchy"][h].node.updateMatrix();
          obj.matrixWorldNeedsUpdate = true;
        }
      }

      stop();
      return;
    }

    // check pre-infinity
    if ( currentTime < startTime ) {
      return;
    }

    // update
    var hl = hierarchy.length;
    for (var h = 0; h < hl; h++) {

      object = hierarchy[h];
      node = data["hierarchy"][h];

      var keys = node.keys,
          animationCache = node.animationCache;

      // use JIT?
      if (JITCompile && JIThierarchy[h][frame] != null) {
        if(object is Bone) {
          object.skinMatrix = JIThierarchy[h][frame];
          object.matrixWorldNeedsUpdate = false;
        } else {
          object.matrix = JIThierarchy[h][frame];
          object.matrixWorldNeedsUpdate = true;
        }
        // use interpolation
      } else if (keys.length) {
        // make sure so original matrix and not JIT matrix is set
        if (JITCompile && animationCache) {
          if(object is Bone) {
            object.skinMatrix = animationCache ["originalMatrix"];
          } else {
            object.matrix = animationCache["originalMatrix"];
          }
        }
      
        prevKey = animationCache["prevKey"];
        nextKey = animationCache["nextKey"];
        
        if (prevKey.isNotEmpty && nextKey.isNotEmpty) {
          // switch keys?
          if (nextKey["time"] <= unloopedCurrentTime) {
            // did we loop?
            if (looped && loop) {
              prevKey = keys[0];
              nextKey = keys[1];

              while (nextKey["time"] < currentTime) {
                prevKey = nextKey;
                nextKey = keys[prevKey["index"] + 1];
              }
            } else if (!looped) {
              var lastIndex = keys.length - 1;

              while (nextKey["time"] < currentTime && nextKey["index"] != lastIndex) {
                prevKey = nextKey;
                nextKey = keys[ prevKey.index + 1 ];
              }
            }
            
            animationCache["prevKey"] = prevKey;
            animationCache["nextKey"] = nextKey;
          }
          
          if(nextKey["time"] >= currentTime) {
            prevKey.interpolate(nextKey, currentTime);
          }
          else {
            prevKey.interpolate(nextKey, nextKey.time);
          }
        }

        data["hierarchy"][h].node.updateMatrix();
        object.matrixWorldNeedsUpdate = true;
      }
    }

    // update JIT?
    if (JITCompile) {
      if (JIThierarchy[0][frame] == null) {
        hierarchy[0].updateMatrixWorld(true);
        
        for (var h = 0; h < hierarchy.length; h++) {
          if(hierarchy[h] is Bone) {
            JIThierarchy[h][frame] = hierarchy[h].skinMatrix.clone();
          } else {
            JIThierarchy[h][frame] = hierarchy[h].matrix.clone();
          }
        }
      }
    }
  }
  
  
  // Get next key with
  _getNextKeyWith( sid, h, key ) {

    var keys = data["hierarchy"][ h ][ "keys" ];
    key = key % keys.length;

    for ( ; key < keys.length; key++ ) {

      if ( keys[ key ].hasTarget( sid ) ) {

        return keys[ key ];

      }

    }

    return keys[ 0 ];

  }
  
  
  // Get previous key with
  
  _getPrevKeyWith( sid, h, key ) {

    var keys = data["hierarchy"][ h ].keys;
    key = key >= 0 ? key : key + keys.length;

    for ( ; key >= 0; key-- ) {

      if ( keys[ key ].hasTarget( sid ) ) {

        return keys[ key ];

      }

    }

    return keys[ keys.length - 1 ];

  }
  
}