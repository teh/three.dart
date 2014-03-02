part of three;

class WireframeHelper extends Line {
  factory WireframeHelper(Mesh object, [int hex = 0xffffff]) {
    var edge = [0, 0], hash = {};

    var geometry = new BufferGeometry();

    if (object.geometry is Geometry) {
      var vertices = object.geometry.vertices;
      var numEdges = 0;

      // allocate maximal size
      var edges = new Uint32List(6 * object.geometry.faces.length);

      object.geometry.faces.forEach((face) {
        for (var j = 0; j < 3; j++) {
          edge[0] = face.indices[j];
          edge[1] = face.indices[(j + 1) % 3];
          edge.sort((a, b) => b.compareTo(a));

          var key = edge.toString();
          if (!hash.containsKey(key)) {
            edges[2 * numEdges] = edge[0];
            edges[2 * numEdges + 1] = edge[1];
            hash[key] = true;
            numEdges++;
          }
        }
      });

      geometry.aPosition = new GeometryAttribute.float32(2 * numEdges, 3);

      var coords = geometry.aPosition.array;

      for (var i = 0; i < numEdges; i++) {
        for (var j = 0; j < 2; j++) {
          var vertex = vertices[edges[2 * i + j]];

          var index = 6 * i + 3 * j;
          coords[index + 0] = vertex.x;
          coords[index + 1] = vertex.y;
          coords[index + 2] = vertex.z;
        }
      }
    } else if (object.geometry is BufferGeometry && (object.geometry as
        BufferGeometry).attributes.containsKey("index")) {
      var vertices = (object.geometry as BufferGeometry).aPosition.array;
      var indices = (object.geometry as BufferGeometry).aIndex.array;
      var offsets = (object.geometry as BufferGeometry).offsets;
      var numEdges = 0;

      // allocate maximal size
      var edges = new Uint32List(2 * indices.length);

      for (var o = 0, ol = offsets.length; o < ol; ++o) {
        var start = offsets[o].start;
        var count = offsets[o].count;
        var index = offsets[o].index;

        for (var i = start; i < start + count; i += 3) {
          for (var j = 0; j < 3; j++) {
            edge[0] = index + indices[i + j];
            edge[1] = index + indices[i + (j + 1) % 3];
            edge.sort((a, b) => b.compareTo(a));

            var key = edge.toString();

            if (!hash.containsKey(key)) {
              edges[2 * numEdges] = edge[0];
              edges[2 * numEdges + 1] = edge[1];
              hash[key] = true;
              numEdges++;
            }
          }
        }
      }

      geometry.aPosition = new GeometryAttribute.float32(2 * numEdges, 3);

      var coords = geometry.aPosition.array;

      for (var i = 0; i < numEdges; i++) {
        for (var j = 0; j < 2; j++) {
          var index = 6 * i + 3 * j;
          var index2 = 3 * edges[2 * i + j];

          coords[index + 0] = vertices[index2];
          coords[index + 1] = vertices[index2 + 1];
          coords[index + 2] = vertices[index2 + 2];
        }
      }
    } else if (object.geometry is BufferGeometry) {
      var vertices = (object.geometry as BufferGeometry).aPosition.array;
      var numEdges = vertices.length / 3;
      var numTris = numEdges / 3;

      geometry.aPosition = new GeometryAttribute.float32(2 * numEdges, 3);
      var coords = geometry.aPosition.array;

      for (var i = 0, l = numTris; i < l; i++) {
        for (var j = 0; j < 3; j++) {
          var index = 18 * i + 6 * j;

          var index1 = 9 * i + 3 * j;
          coords[index + 0] = vertices[index1];
          coords[index + 1] = vertices[index1 + 1];
          coords[index + 2] = vertices[index1 + 2];

          var index2 = 9 * i + 3 * ((j + 1) % 3);
          coords[index + 3] = vertices[index2];
          coords[index + 4] = vertices[index2 + 1];
          coords[index + 5] = vertices[index2 + 2];
        }
      }
    }

    var line = new WireframeHelper._internal(geometry, new LineBasicMaterial(color:
        hex), LINE_PIECES);

    line.matrixAutoUpdate = false;
    line.matrixWorld = object.matrixWorld;
    //line.autoUpdateObjects = false;
    return line;
  }
  WireframeHelper._internal(geometry, material, x) : super(geometry, material, x);
}
