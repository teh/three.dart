/*
 * @author mr.doob / http://mrdoob.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 */

part of three;

class PointLight extends Light implements LightWithDistance {
  Vector3 position = new Vector3.zero();
  double intensity;
  double distance;

  PointLight(int hex, [this.intensity = 1.0, this.distance = 0.0]) : super(hex);
}

