/**
 * @author mikael emtinger / http://gomo.se/
 * 
 * based on r62
 */

part of three;

class AnimationMorphTarget implements IAnimation {
  Mesh root;
  Map data;
  List hierarchy;
  int currentTime = 0;
  double timeScale = 1.0;
  bool isPlaying = false;
  bool isPaused = true;
  bool loop = true;
  int influence = 1;
  
  AnimationMorphTarget(Mesh root, String name)
      : this.data = AnimationHandler.get(name),
        this.hierarchy = AnimationHandler.parse(root);
  
  /// Plays animation
  play({bool loop: true, int startTimeMS: 0}) {
    if (!isPlaying) {
      isPlaying = true;
      this.loop = loop;
      currentTime = startTimeMS;
      
      // reset key cache
      for (var h = 0; h < hierarchy.length; h++) {
        if (hierarchy[h].animationCache == null) {

          hierarchy[h].animationCache = {};
          hierarchy[h].animationCache["prevKey"] = 0;
          hierarchy[h].animationCache["nextKey"] = 0;
        }

        hierarchy[h].animationCache.prevKey = data["hierarchy"][h]["keys"][0];
        hierarchy[h].animationCache.nextKey = data["hierarchy"][h]["keys"][1];
      }

      update(0);
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
  
  ///Stop animation
  stop() {
    isPlaying = false;
    isPaused  = false;
    
    AnimationHandler.removeFromUpdate(this);
    
    // reset JIT matrix and remove cache
    for (var h = 0; h < hierarchy.length; h++) {
      if (hierarchy[h].animationCache.isNotEmpty) {
        hierarchy[h].animationCache.clear();
      }
    }
  }

  ///Update animation
  update(int deltaTimeMS) {
    // early out
    if(!isPlaying) return;

    // vars
    var scale,
        vector,
        prevXYZ, nextXYZ,
        prevKey, nextKey,
        object,
        animationCache,
        currentTime, unloopedCurrentTime;
    
    // update time
    this.currentTime += deltaTimeMS * timeScale;

    unloopedCurrentTime = this.currentTime;
    currentTime         = this.currentTime = this.currentTime % data.length;

    // update
    var hl = hierarchy.length;
    for (var h = 0; h < hl; h++) {
      object = hierarchy[h];
      animationCache = object.animationCache;

      // get keys
      prevKey = animationCache["prevKey"];
      nextKey = animationCache["nextKey"];

      // switch keys?
      if (nextKey.time <= unloopedCurrentTime) {

        // did we loop?
        if (currentTime < unloopedCurrentTime) {
          if (loop) {
            prevKey = data["hierarchy"][h]["keys"][0];
            nextKey = data["hierarchy"][h]["keys"][1];
            
            while(nextKey["time"] < currentTime) {
              prevKey = nextKey;
              nextKey = data["hierarchy"][h]["keys"][nextKey["index"] + 1];
            }
          } else {
            stop();
            return;
          }
        } else {
          do {
            prevKey = nextKey;
            nextKey = data["hierarchy"][h]["keys"][nextKey["index"] + 1];
          } while(nextKey["time"] < currentTime);
        }

        animationCache["prevKey"] = prevKey;
        animationCache["nextKey"] = nextKey;
      }


      // calc scale and check for error
      scale = (currentTime - prevKey["time"]) / (nextKey["time"] - prevKey["time"]);

      if (scale < 0 || scale > 1) {
        print("AnimationMorphTarget.update: Warning! Scale out of bounds: [$scale]"); 
        scale = scale < 0 ? 0 : 1;
      }

      // interpolate
      var pi, pmti = prevKey["morphTargetsInfluences"];
      var ni, nmti = nextKey["morphTargetsInfluences"];
      var mt, i;
      
      for(mt in pmti) {
        pi = pmti[mt];
        ni = nmti[mt];
        i = root.getMorphTargetIndexByName(mt);
        
        root.morphTargetInfluences[i] = (pi + (ni - pi) * scale) * influence;
      }
    }
  }
}