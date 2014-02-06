/*
 * @author Kaleb Murphy
 * 
 * based on r63
 */

part of three;

class RingGeometry extends Geometry {
  RingGeometry([double innerRadius = 0.0, 
                double outerRadius = 50.0, 
                int thetaSegments, 
                int phiSegments, 
                double thetaStart = 0.0, 
                double thetaLength = Math.PI * 2]) : super() {
    thetaSegments = thetaSegments != null ? Math.max(3, thetaSegments) : 8;
    phiSegments = phiSegments != null ? Math.max(3, phiSegments) : 8;
    
    List<Vector2> uvs = [];
    double radius = innerRadius;
    double radiusStep = ((outerRadius - innerRadius) / phiSegments);

    for (var i = 0; i <= phiSegments; i++) { // concentric circles inside ring
      for (var o = 0; o <= thetaSegments; o ++) { // number of segments per circle
        var vertex = new Vector3.zero();
        var segment = thetaStart + o / thetaSegments * thetaLength;

        vertex.x = radius * Math.cos(segment);
        vertex.y = radius * Math.sin(segment);

        vertices.add(vertex);
        uvs.add(new Vector2((vertex.x / outerRadius + 1) / 2, (vertex.y / outerRadius + 1) / 2));
      }

      radius += radiusStep;
    }

    var n = new Vector3.backward();

    for (var i = 0; i < phiSegments; i++) { // concentric circles inside ring
      var thetaSegment = i * thetaSegments;

      for (var o = 0; o <= thetaSegments; o++) { // number of segments per circle
        var segment = o + thetaSegment;

        var v1 = segment + i;
        var v2 = segment + thetaSegments + i;
        var v3 = segment + thetaSegments + 1 + i;

        faces.add(new Face3(v1, v2, v3, [n.clone(), n.clone(), n.clone()]));
        faceVertexUvs[0].add([uvs[v1].clone(), uvs[v2].clone(), uvs[v3].clone()]);

        v1 = segment + i;
        v2 = segment + thetaSegments + 1 + i;
        v3 = segment + 1 + i;

        faces.add(new Face3(v1, v2, v3, [n.clone(), n.clone(), n.clone()]));
        faceVertexUvs[0].add([uvs[v1].clone(), uvs[v2].clone(), uvs[v3].clone()]);
      }
    }

    computeCentroids();
    computeFaceNormals();

    boundingSphere = new Sphere(new Vector3.zero(), radius);
  }
}