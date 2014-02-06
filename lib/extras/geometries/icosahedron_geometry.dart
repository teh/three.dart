/*
 * @author timothypratley / https://github.com/timothypratley
 * 
 * based on r63
 */

part of three;

/// A class for generating an icosahedron geometry.
class IcosahedronGeometry extends PolyhedronGeometry {
  /// Generates a icoshedron with specified [radius] and [detail].
  /// 
  /// Setting [detail] to a value greater than 0 adds more vertices making it no 
  /// longer an icosahedron. When detail is greater than 1, it's effectively a sphere.
  factory IcosahedronGeometry([double radius = 1.0, int detail = 0]) {
    var t = (1 + Math.sqrt(5)) / 2;

    var vertices = [[-1,  t,  0], [1,  t,  0], [-1,  -t,  0], [ 1,  -t,   0],
                    [ 0, -1,  t], [0,  1,  t], [ 0,  -1, -t], [ 0,   1,  -t],
                    [ t,  0, -1], [t,  0,  1], [-t,   0, -1], [-t,   0,   1]];

    var faces = [[0, 11,  5], [0,  5,  1], [ 0,  1,  7], [ 0, 7, 10], [0, 10, 11],
                 [1,  5,  9], [5, 11,  4], [11, 10,  2], [10, 7,  6], [7,  1,  8],
                 [3,  9,  4], [3,  4,  2], [ 3,  2,  6], [ 3, 6,  8], [3,  8,  9],
                 [4,  9,  5], [2,  4, 11], [ 6,  2, 10], [ 8, 6,  7], [9,  8,  1]];
    
    for (int i = 0; i < vertices.length; i++) {
      for (int j = 0; j < vertices[i].length; j++) {
        vertices[i][j] = vertices[i][j].toDouble();
      }
    }

    return new IcosahedronGeometry.internal(vertices, faces, radius, detail);
  }
  
  IcosahedronGeometry.internal(List<List<double>> vertices, List<List<int>> faces, double radius, int detail) 
       : super(vertices, faces, radius, detail);
}
