/*
 * @author mrdoob / http://mrdoob.com/
 * 
 * based on r63
 */

part of three;

/// A class for generating sphere geometries.
class SphereGeometry extends Geometry {
  /// Sphere radius. Default is 50.
  final double radius;
  
  /// Number of horizontal segments. Minimum value is 3, and the default is 8.
  final int widthSegments;
  
  /// Number of vertical segments. Minimum value is 2, and the default is 6.
  final int heightSegments;
  
  /// Horizontal starting angle. Default is 0.
  final double phiStart;
  
  /// Horizontal sweep angle size. Default is Math.PI * 2.
  final double phiLength;
  
  /// Vertical starting angle. Default is 0.
  final double thetaStart;
  
  /// Vertical sweep angle size. Default is Math.PI.
  final double thetaLength;

  /// ##Parameters
  /// * [radius]: Sphere radius. Default is 50.0.
  /// * [widthSegments]: Number of horizontal segments. Minimum value is 3, and the default is 8.
  /// * [heightSegments]: Number of vertical segments. Minimum value is 2, and the default is 6.
  /// * [phiStart]: Horizontal starting angle. Default is 0.0.
  /// * [phiLength]: Horizontal sweep angle size. Default is Math.PI * 2.
  /// * [thetaStart]: Vertical starting angle. Default is 0.0.
  /// * [thetaLength]: Vertical sweep angle size. Default is Math.PI.
  SphereGeometry([this.radius = 50.0,
                  int widthSegments,
                  int heightSegments,
                  this.phiStart = 0.0,
                  this.phiLength = Math.PI * 2.0,
                  this.thetaStart = 0.0,
                  this.thetaLength = Math.PI]) 
      : this.widthSegments = widthSegments != null ? Math.max(3, widthSegments) : 8, 
        this.heightSegments = heightSegments != null ? Math.max(2, heightSegments) : 6,
        super() {
    List<List<int>> vertices = [];
    List<List<Vector2>> uvs = [];

    for (var y = 0; y <= heightSegments; y++) {
      List<int> verticesRow = [];
      List<Vector2> uvsRow = [];

      for (var x = 0; x <= widthSegments; x++) {
        var u = x / widthSegments;
        var v = y / heightSegments;

        var vertex = new Vector3.zero()
            ..x = -radius * Math.cos(phiStart + u * phiLength) * Math.sin(thetaStart + v * thetaLength)
            ..y = radius * Math.cos(thetaStart + v * thetaLength)
            ..z = radius * Math.sin(phiStart + u * phiLength) * Math.sin(thetaStart + v * thetaLength);

        this.vertices.add(vertex);

        verticesRow.add(this.vertices.length - 1);
        uvsRow.add(new Vector2(u, 1 - v));
      }

      vertices.add(verticesRow);
      uvs.add(uvsRow);
    }

    for (var y = 0; y < this.heightSegments; y++) {
      for (var x = 0; x < this.widthSegments; x++) {
        var v1 = vertices[y][x + 1];
        var v2 = vertices[y][x];
        var v3 = vertices[y + 1][x];
        var v4 = vertices[y + 1][x + 1];

        var n1 = this.vertices[v1].clone().normalize();
        var n2 = this.vertices[v2].clone().normalize();
        var n3 = this.vertices[v3].clone().normalize();
        var n4 = this.vertices[v4].clone().normalize();

        var uv1 = uvs[y    ][x + 1].clone();
        var uv2 = uvs[y    ][x    ].clone();
        var uv3 = uvs[y + 1][x    ].clone();
        var uv4 = uvs[y + 1][x + 1].clone();

        if ((this.vertices[v1].y).abs() == radius) {
          uv1.x = (uv1.x + uv2.x) / 2;
          faces.add(new Face3(v1, v3, v4, [n1, n3, n4]));
          faceVertexUvs[0].add([uv1, uv3, uv4]);
        } else if ((this.vertices[v3].y).abs() == radius) {
          uv3.x = (uv3.x + uv4.x) / 2;
          faces.add(new Face3(v1, v2, v3, [n1, n2, n3]));
          faceVertexUvs[0].add([uv1, uv2, uv3]);
        } else {
          faces.add(new Face3(v1, v2, v4, [n1, n2, n4]));
          faceVertexUvs[0].add([uv1, uv2, uv4]);

          faces.add(new Face3(v2, v3, v4, [n2.clone(), n3, n4.clone()]));
          faceVertexUvs[0].add([uv2.clone(), uv3, uv4.clone()]);
        }
      }
    }

    computeCentroids();
    computeFaceNormals();

    boundingSphere = new Sphere(new Vector3.zero(), radius);
  }
}
