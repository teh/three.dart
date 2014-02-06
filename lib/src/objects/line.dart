/*
 * @author mr.doob / http://mrdoob.com/
 *
 * Ported to Dart from JS by:
 * @author adam smith / http://financecoding.wordpress.com/
 */

part of three;

class Line extends Object3D {
  var geometry; // EdgesHelper use BufferGeometry
  Material material;
  int type;

  Line(this.geometry, [this.material, this.type = LINE_STRIP]) : super() {
    if (material == null) { 
      material = new LineBasicMaterial(color: MathUtils.randHex()); 
    }

    if (geometry != null) {
      // calc bound radius
      if(geometry.boundingSphere == null) {
        geometry.computeBoundingSphere();
      }
    }
  }
}

const int LINE_STRIP = 0;
const int LINE_PIECES = 1;