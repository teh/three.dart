/*
 * @author mr.doob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 * @author Nelson Silva
 *
 * based on r63
 */

part of three;

class DirectionalLight extends Light with ShadowCaster {
  Vector3 position = new Vector3.up();
  Object3D target = new Object3D();
  
  double intensity;

  bool shadowCascade = false;

  Vector3 shadowCascadeOffset = new Vector3(0.0, 0.0, -1000.0);
  int shadowCascadeCount = 2;

  List<double> shadowCascadeBias = [0.0, 0.0, 0.0];
  List<double> shadowCascadeWidth = [512.0, 512.0, 512.0];
  List<double> shadowCascadeHeight = [512.0, 512.0, 512.0];
  
  List<double> shadowCascadeNearZ = [-1.000, 0.990, 0.998];
  List<double> shadowCascadeFarZ = [0.990, 0.998, 1.000];
  List<VirtualLight> shadowCascadeArray = [];

  DirectionalLight(int hex, [this.intensity = 1.0]) : super(hex) {
    shadowCameraLeft = -500.0;
    shadowCameraRight = 500.0;
    shadowCameraTop = 500.0;
    shadowCameraBottom = -500.0;
  }
}
