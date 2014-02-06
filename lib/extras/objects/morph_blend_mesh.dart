part of three;
/*
class MorphBlendMesh extends Mesh {
  Map<String, MorphBlendMeshAnimation> animationsMap = {};
  List animationsList = [];
  var firstAnimation;
  
  MorphBlendMesh(Geometry geometry, Material material) : super(geometry, material) {
    // prepare default animation
    // (all frames played together in 1 second)

    var numFrames = geometry.morphTargets.length;

    var name = "__default";

    var startFrame = 0;
    var endFrame = numFrames - 1;

    var fps = numFrames / 1;

    createAnimation(name, startFrame, endFrame, fps);
    setAnimationWeight(name, 1);
  }
  
  void createAnimation(String name, int start, int end, int fps) {
    var animation = new MorphBlendMeshAnimation(
        startFrame: start,
        endFrame: end,
        
        length: end - start + 1,
        
        fps: fps,
        duration: (end - start) ~/ fps,
        
        lastFrame: 0,
        currentFrame: 0,
        
        active: false,
        
        time: 0,
        direction: 1,
        weight: 1.0,
        
        directionBackwards: false,
        mirroredLoop: false);
    
    animationsMap[name] = animation;
    animationsList.add(animation);
  }
  
  void autoCreateAnimations(int fps) {
    var pattern = r"([a-z]+)(\d+)";

    var firstAnimation, frameRanges = {};
    
    var i = 0;
    geometry.morphTargets.forEach((morph) {
      var chunks = new RegExp(pattern).allMatches(morph.name);

      if (chunks.isNotEmpty && chunks.length > 1 ) {
        var name = chunks[1];
        var num = chunks[2];

        if (!frameRanges.containsKey(name)) { 
          frameRanges[name] = {"start": double.INFINITY, "end": -double.INFINITY};
        }

        var range = frameRanges[ name ];

        if (i < range.start ) range.start = i;
        if (i > range.end ) range.end = i;

        if (firstAnimation != null) firstAnimation = name;
        
      }
      i++;
    });
    
    frameRanges.forEach((name, range) => createAnimation(name, range["start"], range["end"], fps));

    this.firstAnimation = firstAnimation;
  }
  
  void setAnimationDirectionForward(String name) {
    var animation = animationsMap[name];

    if (animation != null) {
      animation.direction = 1;
      animation.directionBackwards = false;
    }
  }

  void setAnimationDirectionBackward(String name) {
    var animation = animationsMap[name];

    if (animation != null) {
      animation.direction = -1;
      animation.directionBackwards = true;
    }
  }

  void setAnimationFPS(String name, int fps) {
    var animation = animationsMap[name];

    if (animation != null) {
      animation.fps = fps;
      animation.duration = (animation.endFrame - animation.startFrame) / animation.fps;
    }
  }

  void setAnimationDuration(String name, double duration) {
    var animation = animationsMap[name];

    if (animation != null) {
      animation.duration = duration;
      animation.fps = ( animation.endFrame - animation.startFrame) / animation.duration;
    }
  }

  void setAnimationWeight(String name, double weight) {
    var animation = animationsMap[name];
    
    if (animation) {
      animation.weight = weight;
    }
  }

  void setAnimationTime(String name, int time) {
    var animation = animationsMap[name];

    if (animation) {
      animation.time = time;
    }
  }

  void getAnimationTime(String name) {
    var time = 0;

    var animation = animationsMap[name];

    if (animation) {
      time = animation.time;
    }

    return time;
  }

  double getAnimationDuration(String name) {
    var duration = -1;
    var animation = animationsMap[name];

    if (animation) {
      duration = animation.duration;
    }

    return duration;
  }

  void playAnimation(String name) {
    var animation = animationsMap[name];

    if (animation) {
      animation.time = 0;
      animation.active = true;
    } else {
      print("animation[$name] undefined");
    }
  }

  stopAnimation(String name) {
    var animation = animationsMap[name];
    
    if (animation) {
      animation.active = false;
    }
  }

  void update(double delta) {
    for ( var i = 0; i < animationsList.length; i++) {
      var animation = animationsList[ i ];

      if (!animation.active) continue;

      var frameTime = animation.duration / animation.length;

      animation.time += animation.direction * delta;

      if ( animation.mirroredLoop ) {

        if ( animation.time > animation.duration || animation.time < 0 ) {

          animation.direction *= -1;

          if ( animation.time > animation.duration ) {

            animation.time = animation.duration;
            animation.directionBackwards = true;

          }

          if ( animation.time < 0 ) {

            animation.time = 0;
            animation.directionBackwards = false;

          }

        }

      } else {

        animation.time = animation.time % animation.duration;

        if ( animation.time < 0 ) animation.time += animation.duration;

      }

      var keyframe = animation.startFrame + THREE.Math.clamp( Math.floor( animation.time / frameTime ), 0, animation.length - 1 );
      var weight = animation.weight;

      if ( keyframe != animation.currentFrame ) {

        this.morphTargetInfluences[ animation.lastFrame ] = 0;
        this.morphTargetInfluences[ animation.currentFrame ] = 1 * weight;

        this.morphTargetInfluences[ keyframe ] = 0;

        animation.lastFrame = animation.currentFrame;
        animation.currentFrame = keyframe;

      }

      var mix = ( animation.time % frameTime ) / frameTime;

      if ( animation.directionBackwards ) mix = 1 - mix;

      this.morphTargetInfluences[ animation.currentFrame ] = mix * weight;
      this.morphTargetInfluences[ animation.lastFrame ] = ( 1 - mix ) * weight;

    }

  }
}

class MorphBlendMeshAnimation {
  int startFrame,
      endFrame,
      length,
      fps;
  
  int duration;
  
  int lastFrame,
      currentFrame;
  
  bool active;
  
  int time,
      direction;
  
  double weight;
  
  bool directionBackwards,
       mirroredLoop;
  
  MorphBlendMeshAnimation({this.startFrame, 
                           this.endFrame, 
                           this.length, 
                           this.fps, 
                           this.duration, 
                           this.lastFrame, 
                           this.currentFrame,
                           this.active,
                           this.time,
                           this.direction,
                           this.weight,
                           this.directionBackwards,
                           this.mirroredLoop});  

}

*/