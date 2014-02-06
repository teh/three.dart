/*
 * @author timothypratley / https://github.com/timothypratley
 * 
 * based on r63
 */

part of three;

class OctahedronGeometry extends PolyhedronGeometry {
  /// Generates a octahedron geometry with specified [radius] and [detail].
  /// Setting [detail] to a value greater than zero adds vertices making it no longer an octahedron.
  factory OctahedronGeometry(double radius, int detail) {
    var vertices = [[1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1]];

    var faces = [[0, 2, 4], [0, 4, 3], [0, 3, 5], [0, 5, 2], [1, 2, 5], [1, 5, 3], [1, 3, 4], [1, 4, 2]];

    for (int i = 0; i < vertices.length; i++) {
      for (int j = 0; j < vertices[i].length; j++) {
        vertices[i][j] = vertices[i][j].toDouble();
      }
    }
    
    return new OctahedronGeometry._internal(vertices, faces, radius, detail);
  }
  
  OctahedronGeometry._internal(List<List<double>> vertices, List<List<int>> faces, double radius, int detail) 
       : super(vertices, faces, radius, detail);
}