/*
 * @author mr.doob / http://mrdoob.com/
 * based on http://papervision3d.googlecode.com/svn/trunk/as3/trunk/src/org/papervision3d/objects/primitives/Plane.as
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 * 
 * based on r63
 */

part of three;

class PlaneGeometry extends Geometry {
  final double width;
  final double height;
  final int widthSegments;
  final int heightSegments;
  
  PlaneGeometry(this.width, this.height, [this.widthSegments = 1, this.heightSegments = 1]) : super() {
    var width_half = width / 2;
    var height_half = height / 2;

    var gridX = widthSegments;
    var gridZ = heightSegments;

    var gridX1 = gridX + 1;
    var gridZ1 = gridZ + 1;

    var segment_width = width / gridX;
    var segment_height = height / gridZ;

    var normal = new Vector3.backward();

    for (var iz = 0; iz < gridZ1; iz++) {
      for (var ix = 0; ix < gridX1; ix++) {
        var x = ix * segment_width - width_half;
        var y = iz * segment_height - height_half;

        vertices.add(new Vector3(x, -y, 0.0));
      }
    }

    for (var iz = 0; iz < gridZ; iz++) {
      for (var ix = 0; ix < gridX; ix++) {
        var a = ix + gridX1 * iz;
        var b = ix + gridX1 * (iz + 1);
        var c = (ix + 1) + gridX1 * (iz + 1);
        var d = (ix + 1) + gridX1 * iz;

        var uva = new Vector2(ix / gridX, 1 - iz / gridZ);
        var uvb = new Vector2(ix / gridX, 1 - (iz + 1) / gridZ);
        var uvc = new Vector2((ix + 1) / gridX, 1 - (iz + 1) / gridZ);
        var uvd = new Vector2((ix + 1) / gridX, 1 - iz / gridZ);

        var face = new Face3(a, b, d);
        face.normal.setFrom(normal);
        face.vertexNormals.map((_) => normal.clone());

        this.faces.add(face);
        this.faceVertexUvs[0].add([uva, uvb, uvd]);

        face = new Face3(b, c, d);
        face.normal.setFrom(normal);
        face.vertexNormals.map((_) => normal.clone());

        faces.add(face);
        faceVertexUvs[0].add([uvb.clone(), uvc, uvd.clone()]);
      }
    }
    
    computeCentroids();
  }
}
