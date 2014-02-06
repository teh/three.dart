part of three;

class EdgesHelper extends Line {
  factory EdgesHelper(Mesh object, [int hex = 0xffffff]) {
    var edge = [0, 0], hash = {};
    var sortFunction = (a, b) => b.compareTo(b);

    var keys = ['a', 'b', 'c'];
    var geometry = new BufferGeometry();

    var geometry2 = object.geometry.clone();

    geometry2.mergeVertices();
    geometry2.computeFaceNormals();

    var vertices = geometry2.vertices;
    var faces = geometry2.faces;
    var numEdges = 0;

    for (var i = 0; i < faces.length; i++) {
      var face = faces[i];

      for (var j = 0; j < 3; j++) {
        edge[0] = face[keys[j]];
        edge[1] = face[keys[(j + 1) % 3]];
        edge.sort(sortFunction);

        var key = edge.toString();

        if (hash[key] == null) {
          hash[key] = {"vert1": edge[0], "vert2": edge[1], "face1": i, "face2": null};
          numEdges ++;
        } else {
          hash[key].face2 = i;
        }
      }
    }

    geometry.aPosition = new GeometryAttribute.float32(2 * numEdges, 3);

    var coords = geometry.aPosition.array;
    
    var index = 0;
    
    hash.forEach((key, h) {
      if (h["face2"] == null || faces[h["face1"]].normal.dot(faces[h["face2"]].normal) < 0.9999) { // hardwired const OK
        var vertex = vertices[h["vert1"]];
        coords[index++] = vertex.x;
        coords[index++] = vertex.y;
        coords[index++] = vertex.z;

        vertex = vertices[h["vert2"]];
        coords[index++] = vertex.x;
        coords[index++] = vertex.y;
        coords[index++] = vertex.z;
      }
    });
    
    matrixAutoUpdate = false;
    matrixWorld = object.matrixWorld;

    return new EdgesHelper._internal(geometry, new LineBasicMaterial(color: hex), LINE_PIECES);
  }
  
  EdgesHelper._internal(BufferGeometry geometry, LineBasicMaterial material, int type) : super(geometry, material, type);
}