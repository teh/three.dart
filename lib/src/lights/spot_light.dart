part of three;

class SpotLight extends Light with ShadowCaster implements LightWithDistance {
  Vector3 position = new Vector3.up();
  Object3D target = new Object3D();

  double intensity;
  double distance;
  double angle;
  int exponent;

  SpotLight(int hex, [this.intensity = 1.0, this.distance = 0.0, this.angle = Math.PI / 2, this.exponent = 10]) 
      : super(hex) {
    shadowCameraFov = 50.0;
  }
}