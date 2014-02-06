part of three;

class MorphAnimMesh extends Mesh {
  // API
  int duration = 1000; // milliseconds
  bool mirroredLoop = false;
  int time = 0;

  // internals
  int _lastKeyframe = 0;
  int _currentKeyframe = 0;

  int _direction = 1;
  bool _directionBackwards = false;
  int _startKeyframe, _endKeyframe, _length;

  MorphAnimMesh(Geometry geometry, Material material) : super(geometry, material) {
    setFrameRange(0, geometry.morphTargets.length - 1);
  }

  void setFrameRange(int start, int end) {
    _startKeyframe = start;
    _endKeyframe = end;

    _length = _endKeyframe - _startKeyframe + 1;
  }

  void setDirectionForward() {
    _direction = 1;
    _directionBackwards = false;
  }

  void setDirectionBackward() {
    _direction = -1;
    _directionBackwards = true;
  }

  void parseAnimations() {
    if (geometry.animations == null) geometry.animations = {};

    var firstAnimation, animations = geometry.animations;

    RegExp pattern = new RegExp(r'([a-z]+)(\d+)');

    for (var i = 0; i < geometry.morphTargets.length; i++) {
      var morph = geometry.morphTargets[i];
      var parts = pattern.allMatches(morph.name);

      if (parts.length > 1) {
        var label = parts[1];
        var num = parts[2];

        if (!animations.containsKey(label)) { 
          animations[label] = {"start": double.INFINITY, "end": double.NEGATIVE_INFINITY};
        }

        var animation = animations[label];

        if (i < animation["start"]) animation["start"] = i;
        if (i > animation["end"]) animation["end"] = i;

        if (geometry.firstAnimation == null) firstAnimation = label;
      }
    }

    geometry.firstAnimation = firstAnimation;
  }

  void setAnimationLabel(String label, int start, int end) {
    if (geometry.animations == null) geometry.animations = {};
    geometry.animations[label] = {"start": start, "end": end};
  }

  void playAnimation(String label, int fps) {
    var animation = geometry.animations[label];

    if (animation != null) {
      setFrameRange(animation["start"], animation["end"]);
      duration = 1000 * ((animation["end"] - animation["start"]) / fps);
      time = 0;
    } else {
      print("animation[$label] undefined");
    }
  }

  void updateAnimation(int delta) {
    var frameTime = duration / _length;

    time += _direction * delta;

    if (mirroredLoop) {
      if (time > duration || time < 0) {
        _direction *= -1;

        if (time > duration) {
          time = duration;
          _directionBackwards = true;
        }

        if (time < 0) {
          time = 0;
          _directionBackwards = false;
        }
      }
    } else {
      time = time % duration;
      if (time < 0) time += duration;
    }

    var keyframe = _startKeyframe + MathUtils.clamp((time / frameTime).floor(), 0, _length - 1);

    if (keyframe != _currentKeyframe) {
      morphTargetInfluences[_lastKeyframe] = 0;
      morphTargetInfluences[_currentKeyframe] = 1;

      morphTargetInfluences[keyframe] = 0;

      _lastKeyframe = _currentKeyframe;
      _currentKeyframe = keyframe;
    }

    var mix = (time % frameTime) / frameTime;

    if (_directionBackwards) {
      mix = 1 - mix;
    }

    morphTargetInfluences[_currentKeyframe] = mix;
    morphTargetInfluences[_lastKeyframe] = 1 - mix;
  }
}
