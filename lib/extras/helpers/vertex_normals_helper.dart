part of three; 

class VertexNormalsHelper extends Line {
  Mesh object;
  double size;
  Matrix3 normalMatrix = new Matrix3.identity();
  
  VertexNormalsHelper(this.object, {this.size: 1.0, int hex: 0xff0000, double linewidth: 1.0}) 
      : super(new Geometry(),
              new LineBasicMaterial(color: hex, linewidth: linewidth), 
              LINE_PIECES) {
    object.geometry.faces.forEach((face) =>
        face.vertexNormals.forEach((_) => geometry.vertices.addAll([new Vector3.zero(), new Vector3.zero()])));

    matrixAutoUpdate = false;
    update();
  }
  
  Line update() {
    final keys = ['a', 'b', 'c', 'd'];

    object.updateMatrixWorld(true);

    normalMatrix = object.matrixWorld.getNormalMatrix();

    var idx = 0;
    object.geometry.faces.forEach((face) {
      for (var j = 0; j < face.vertexNormals.length; j++) {
        var vertexId = face[keys[j]];
        var vertex = object.geometry.vertices[vertexId];

        geometry.vertices[idx]
        ..setFrom(vertex)
        ..applyMatrix4(object.matrixWorld);

        var v1 = new Vector3.copy(face.vertexNormals[j])
        ..applyMatrix3(normalMatrix)
        ..normalize()
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