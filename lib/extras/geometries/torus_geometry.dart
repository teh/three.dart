/*
 * @author oosmoxiecode
 * @author mrdoob / http://mrdoob.com/
 * based on http://code.google.com/p/away3d/source/browse/trunk/fp10/Away3DLite/src/away3dlite/primitives/Torus.as?r=2888
 * 
 * based on r65
 */

part of three;

class TorusGeometry extends Geometry {
  /// Radius of the doughnut. Default is 100.
  final double radius;
  
  /// Diameter of the tube. Default is 40. 
  final double tube;
  
  /// Default is 8
  final int radialSegments;
  
  /// Default is 6. 
  final int tubularSegments;
  
  /// Central angle. Default is Math.PI * 2.
  final double arc;

  TorusGeometry ([this.radius = 100.0, 
                  this.tube = 40.0, 
                  this.radialSegments = 8, 
                  this.tubularSegments = 6, 
                  this.arc = Math.PI * 2]) : super() {

    List<Vector2> uvs = [];
    List<Vector3> normals = [];

    for (var j = 0; j <= radialSegments; j++) {
      for (var i = 0; i <= tubularSegments; i++) {
        var u = i / tubularSegments * arc;
        var v = j / radialSegments * Math.PI * 2;

        var center = new Vector3.zero();
        center.x = radius * Math.cos(u);
        center.y = radius * Math.sin(u);

        var vertex = new Vector3.zero()
        ..x = (radius + tube * Math.cos(v)) * Math.cos(u)
        ..y = (radius + tube * Math.cos(v)) * Math.sin(u)
        ..z = tube * Math.sin(v);

        vertices.add(vertex);

        uvs.add(new Vector2(i / tubularSegments, j / radialSegments));
        normals.add((vertex - center).normalize());
      }
    }

    for (var j = 1; j <= radialSegments; j++) {
      for (var i = 1; i <= tubularSegments; i++) {
        var a = (tubularSegments + 1) * j + i - 1;
        var b = (tubularSegments + 1) * (j - 1) + i - 1;
        var c = (tubularSegments + 1) * (j - 1) + i;
        var d = (tubularSegments + 1) * j + i;

        var face = new Face3(a, b, d, [normals[a].clone(), normals[b].clone(), normals[d].clone()]);
        faces.add(face);
        faceVertexUvs[0].add([uvs[a].clone(), uvs[b].clone(), uvs[d].clone()]);

        face = new Face3(b, c, d, [normals[b].clone(), normals[c].clone(), normals[d].clone()]);
        faces.add( face );
        faceVertexUvs[0].add([uvs[b].clone(), uvs[c].clone(), uvs[d].clone()]);
      }
    }

    computeCentroids();
    computeFaceNormals();
  }
}
