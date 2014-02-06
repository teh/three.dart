/*
 * @author jonobr1 / http://jonobr1.com
 * 
 * based on r63
 */

part of three;

/// Creates a one-sided polygonal geometry from a path shape. Similar to ExtrudeGeometry.
class ShapeGeometry extends Geometry {
  List<Shape> shapes;

  Map shapebb;

  /// ## Parameters
  /// * curveSegments([int]): Number of points on the curves.
  /// * material([int]): material index for front and back faces
  /// * uvGenerator([WorldUVGenerator]): Object that provides UV generator functions
  ShapeGeometry(this.shapes,
               {int curveSegments: 12,
                int material,
                WorldUVGenerator uvGenerator}) : super() {
    if (shapes == null) {
      shapes = [];
      return;
    }

    shapebb = shapes.last.getBoundingBox();

    shapes.forEach((shape) => addShape(shape, curveSegments, material, uvGenerator));

    computeCentroids();
    computeFaceNormals();
  }

  void addShape(Shape shape, int curveSegments, int material, [WorldUVGenerator uvGenerator]) {
    var uvgen = uvGenerator != null ? uvGenerator : new ExtrudeGeometryWorldUVGenerator();

    var shapesOffset = this.vertices.length;
    var shapePoints = shape.extractPoints(curveSegments);

    List _vertices = shapePoints["shape"];
    List<List> holes = shapePoints["holes"];

    var reverse = !ShapeUtils.isClockWise(_vertices);

    if (reverse) {
      _vertices = _vertices.reversed.toList();

      holes.forEach((hole) {
        if (ShapeUtils.isClockWise(hole)) {
          hole = hole.reversed.toList();
        }
      });
      
      reverse = false;
    }

    var _faces = ShapeUtils.triangulateShape(_vertices, holes);

    // Vertices
    var contour = _vertices;
    
    holes.forEach((hole) => _vertices.addAll(hole));
    
    _vertices.forEach((vert) => vertices.add(new Vector3(vert.x, vert.y, 0.0)));
    
    _faces.forEach((face) {
      var a = face[0] + shapesOffset;
      var b = face[1] + shapesOffset;
      var c = face[2] + shapesOffset;

      faces.add(new Face3(a, b, c, null, null, material));
      faceVertexUvs[0].add(uvgen.generateBottomUV(this, a, b, c));
    });
  }
}