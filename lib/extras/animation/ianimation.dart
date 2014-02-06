part of three;

abstract class IAnimation {
  Mesh root;
  
  Map data;
  List<Bone> hierarchy;
  
  int currentTime;
  double timeScale;
  
  bool isPlaying;
  bool isPaused;
  bool loop;
  
  play();
  pause();
  stop();
  update(int deltaTimeMS);
}