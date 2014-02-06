/**
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 */

part of three;

class FogLinear implements Fog {
  String name = '';
  Color color;
  double near, far;
  
  FogLinear(int hex, [this.near = 1.0, this.far = 1000.0]) : color = new Color(hex);
  
  Fog clone() => new FogLinear(color.getHex(), near, far);
}
