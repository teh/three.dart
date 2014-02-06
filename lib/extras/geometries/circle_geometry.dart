/*
 * @author hughes
 * 
 * based on r63
 */

part of three;

/// CircleGeometry is a simple shape of Euclidean geometry. It is contructed 
/// from a number of triangular segments that are oriented around a central 
/// point and extend as far out as a given radius. It is built counter-clockwise 
/// from a start angle and a given central angle. It can also be used to create 
/// regular polygons, where the number of segments determines the number of sides.
class CircleGeometry extends Geometry {
  final double radius;
  final double thetaStart;
  final double thetaLength;
  final int segments;

  /// ##Parameters
  /// * [radius]: Radius of the circle, default = 50.
  /// * [segments]: Number of segments (triangles), minimum = 3, default = 8.
  /// * [thetaStart]: Start angle for first segment, default = 0 (three o'clock position).
  /// * [thetaLength]: The central angle, often called theta, of the circular sector. 
  /// The default is 2*Pi, which makes for a complete circle.
  CircleGeometry([this.radius = 50.0, 
                  int segments, 
                  this.thetaStart = 0.0, 
                  this.thetaLength =  Math.PI * 2]) 
      : this.segments = segments != null ? Math.max(3, segments) : 8,
        super() {

    List<Vector2> uvs = [];
    var center = new Vector3.zero();
    var centerUV = new Vector2(0.5, 0.5);

    vertices.add(center);
    uvs.add(centerUV);

    for (var i = 0; i <= segments; i++) {
      var vertex = new Vector3.zero();
      vertex.x = radius * Math.cos(thetaStart + i / segments * thetaLength);
      vertex.y = radius * Math.sin(thetaStart + i / segments * thetaLength);
      
      vertices.add(vertex);
      uvs.add(new Vector2((vertex.x / radius + 1) / 2, -(vertex.y / radius + 1) / 2 + 1));
    }

    var n = new Vector3.forward();

    for (var i = 1; i <= segments; i++) {
      var v1 = i;
      var v2 = i + 1 ;
      var v3 = 0;

      faces.add(new Face3(v1, v2, v3, [n.clone(), n.clone(), n.clone()]));
      faceVertexUvs[0].add([uvs[i].clone(), uvs[i + 1].clone(), centerUV.clone()]);
    }

    computeCentroids();
    computeFaceNormals();

    boundingSphere = new Sphere(new Vector3.zero(), radius);
  }
}
