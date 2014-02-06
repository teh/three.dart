part of three;

class ShadowCaster {
  bool castShadow = false;
  bool onlyShadow = false;

  double shadowCameraNear = 50.0;
  double shadowCameraFar = 5000.0;
  double shadowCameraFov;
  
  double shadowCameraLeft;
  double shadowCameraRight;
  double shadowCameraTop;
  double shadowCameraBottom;
  
  bool shadowCameraVisible = false;

  double shadowBias = 0.0;
  double shadowDarkness = 0.5;

  int shadowMapWidth = 512;
  int shadowMapHeight = 512;
  
  WebGLRenderTarget shadowMap;
  Vector2 shadowMapSize;
  Camera shadowCamera;
  Matrix4 shadowMatrix;

  CameraHelper cameraHelper;
}

