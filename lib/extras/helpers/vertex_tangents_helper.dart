part of three;

class VertexTangentsHelper extends Line {
  Mesh object;
  double size;
  
  VertexTangentsHelper(Mesh object, this.size, {int hex: 0x0000ff, double linewidth: 1.0})
      : this.object = object,
        super(new Geometry()..vertices = new List.filled(object.geometry.faces.length * 3 * 2, new Vector3.zero()),
              new LineBasicMaterial(color: hex, linewidth: linewidth), 
              LINE_PIECES) {
    matrixAutoUpdate = false;
    update();
  }
  
  Line update() {
    final keys = ['a', 'b', 'c', 'd'];

    object.updateMatrixWorld(true);

    var idx = 0;
    object.geometry.faces.forEach((face) {
      for (var j = 0; j < face.vertexTangents.length; j++) {
        var vertexId = face[keys[j]];
        var vertex = object.geometry.vertices[vertexId];

        geometry.vertices[idx]
        ..setFrom(vertex)
        ..applyMatrix4(object.matrixWorld);
        
        var vertexTangent = face.vertexTangents[j];

        var v1 = new Vector3(vertexTangent.x, vertexTangent.y, vertexTangent.z)
        ..transformDirection(object.matrixWorld)
        ..scale(size);

        v1.add(geometry.vertices[idx]);
        idx = idx + 1;

        geometry.vertices[idx].setFrom(v1);
        idx = idx + 1;
      }
    });

    geometry.verticesNeedUpdate = true;
    return this;
  }
}