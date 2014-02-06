/*
 * @author timothypratley / https://github.com/timothypratley
 * 
 * based on r63
 */

part of three;

/// A class for generating a tetrahedron geometries.
class TetrahedronGeometry extends PolyhedronGeometry {
  /// Generates tetrahedron geometry with specified [radius] and [detail].
  /// Setting [detail] to a value greater than 0 adds vertices making it no longer a tetrahedron.
  factory TetrahedronGeometry(double radius, int detail) {
    var vertices = [[1,  1,  1], [-1, -1, 1], [-1, 1, -1], [1, -1, -1]];

    var faces = [[2, 1, 0], [0, 3, 2], [1, 3, 0], [2, 3, 1]];
    
    for (int i = 0; i < vertices.length; i++) {
      for (int j = 0; j < vertices[i].length; j++) {
        vertices[i][j] = vertices[i][j].toDouble();
      }
    }

    return new TetrahedronGeometry._internal(vertices, faces, radius, detail);
  }
  
  TetrahedronGeometry._internal(List<List<double>> vertices, List<List<int>> faces, double radius, int detail) 
       : super(vertices, faces, radius, detail);
}