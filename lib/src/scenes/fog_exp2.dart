/**
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 */

part of three;

class FogExp2 implements Fog {
  String name = '';
  Color color;
  double density;
  
  FogExp2(int hex, [this.density = 0.00025]) : color = new Color(hex);
  
  Fog clone() => new FogExp2(color.getHex(), density);
}
