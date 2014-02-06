/*
 * @author mr.doob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 * 
 * based on r63
 */

part of three;

class Light extends Object3D {
  Color color;

  Light(int hex) : color = new Color(hex), super();
}

abstract class LightWithDistance {
  double distance;
}
