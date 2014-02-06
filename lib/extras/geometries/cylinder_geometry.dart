/*
 * @author mrdoob / http://mrdoob.com/
 * 
 * based on r63
 */

part of three;

class CylinderGeometry extends Geometry {
  final double radiusTop;
  final double radiusBottom;
  final double height;
  final int radialSegments;
  final int heightSegments;
  final bool openEnded;

  /// ##Parameters
  /// * [radiusTop]: Radius of the cylinder at the top. Default is 20.
  /// * [radiusBottom]: Radius of the cylinder at the bottom. Default is 20.
  /// * [height]: Height of the cylinder. Default is 100.
  /// * [radialSegments]: Number of segmented faces around the circumference of the cylinder. Default is 8
  /// * [heightSegments]: Number of rows of faces along the height of the cylinder. Default is 1.
  /// * [openEnded]: A Boolean indicating whether the ends of the cylinder are open or capped. Default is false, meaning capped.
  CylinderGeometry([this.radiusTop = 20.0,
                    this.radiusBottom = 20.0,
                    this.height = 100.0,
                    this.radialSegments = 8,
                    this.heightSegments = 1,
                    this.openEnded = false]) : super() {

    double heightHalf = height / 2;
    
    List<List<int>> vertices = [];
    List<List<Vector2>> uvs = [];

    for (var y = 0; y <= heightSegments; y++) {
      var verticesRow = [];
      var uvsRow = [];

      double v = y / heightSegments;
      var radius = v * (radiusBottom - radiusTop) + radiusTop;

      for (var x = 0; x <= radialSegments; x++) {
        double u = x / radialSegments;
        
        var vertex = new Vector3.zero()
            ..x = radius * Math.sin(u * Math.PI * 2)
            ..y = -v * height + heightHalf
            ..z = radius * Math.cos(u * Math.PI * 2);
        
        this.vertices.add(vertex);

        verticesRow.add(this.vertices.length - 1);
        uvsRow.add(new Vector2(u, 1 - v));
      }

      vertices.add(verticesRow);
      uvs.add(uvsRow);
    }

    var tanTheta = (radiusBottom - radiusTop) / height;
    var na, nb;

    for (var x = 0; x < radialSegments; x++) {
      if (radiusTop != 0) {
        na = this.vertices[vertices[0][x]].clone();
        nb = this.vertices[vertices[0][x + 1]].clone();
      } else {
        na = this.vertices[vertices[1][x]].clone();
        nb = this.vertices[vertices[1][x + 1]].clone();
      }

      na.y = Math.sqrt(na.x * na.x + na.z * na.z) * tanTheta;
      na.normalize();
      nb.y = Math.sqrt(nb.x * nb.x + nb.z * nb.z) * tanTheta;
      na.normalize();

      for (var y = 0; y < heightSegments; y++) {
        var v1 = vertices[y][x];
        var v2 = vertices[y + 1][x];
        var v3 = vertices[y + 1][x + 1];
        var v4 = vertices[y][x + 1];

        var n1 = na.clone();
        var n2 = na.clone();
        var n3 = nb.clone();
        var n4 = nb.clone();

        var uv1 = uvs[y][x].clone();
        var uv2 = uvs[y + 1][x].clone();
        var uv3 = uvs[y + 1][x + 1].clone();
        var uv4 = uvs[y][x + 1].clone();

        faces.add(new Face3(v1, v2, v4, [n1, n2, n4]));
        faceVertexUvs[0].add([uv1, uv2, uv4]);

        faces.add(new Face3(v2, v3, v4, [n2.clone(), n3, n4.clone()]));
        faceVertexUvs[0].add([uv2.clone(), uv3, uv4.clone()]);
      }
    }

    // top cap
    if (!openEnded && radiusTop > 0) {
      this.vertices.add(new Vector3(0.0, heightHalf, 0.0));
      
      for (var x = 0; x < radialSegments; x++) {
        var v1 = vertices[0][x];
        var v2 = vertices[0][x + 1];
        var v3 = this.vertices.length - 1;

        var n1 = new Vector3.up();
        var n2 = new Vector3.up();
        var n3 = new Vector3.up();

        var uv1 = uvs[0][x].clone();
        var uv2 = uvs[0][x + 1].clone();
        var uv3 = new Vector2(uv2.x, 0.0);

        faces.add(new Face3(v1, v2, v3, [n1, n2, n3]));
        faceVertexUvs[0].add([uv1, uv2, uv3]);
      }
    }

    // bottom cap
    if (!openEnded && radiusBottom > 0) {
      this.vertices.add(new Vector3(0.0, - heightHalf, 0.0));
      
      var y = heightSegments;

      for (var x = 0; x < radialSegments; x++) {
        var v1 = vertices[y][x + 1];
        var v2 = vertices[y][x];
        var v3 = this.vertices.length - 1;

        var n1 = new Vector3(0.0, -1.0, 0.0);
        var n2 = new Vector3(0.0, -1.0, 0.0);
        var n3 = new Vector3(0.0, -1.0, 0.0);

        var uv1 = uvs[y][x + 1].clone();
        var uv2 = uvs[y][x].clone();
        var uv3 = new Vector2(uv2.x, 1.0);

        faces.add(new Face3(v1, v2, v3, [n1, n2, n3]));
        faceVertexUvs[0].add([uv1, uv2, uv3]);
      }
    }

    computeCentroids();
    computeFaceNormals();
  }
}
