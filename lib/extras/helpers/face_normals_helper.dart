/*
 * @author mrdoob / http://mrdoob.com/
 * @author WestLangley / http://github.com/WestLangley
*/

part of three;

class FaceNormalsHelper extends Line {
  Mesh object;
  double size;
  Matrix3 normalMatrix = new Matrix3.identity();
  
  FaceNormalsHelper(this.object, {this.size: 1.0, int hex: 0xffff00, double linewidth: 1.0}) 
      : super(new Geometry(), new LineBasicMaterial(color: hex, linewidth: linewidth), LINE_PIECES) {

    object.geometry.faces.forEach((_) {
      geometry.vertices.add(new Vector3.zero());
      geometry.vertices.add(new Vector3.zero());
    });

    matrixAutoUpdate = false;

    update();
  }
  
  update() {
    object.updateMatrixWorld(true);
  
    normalMatrix = object.matrixWorld.getNormalMatrix();
  
    var vertices = geometry.vertices;
  
    var worldMatrix = object.matrixWorld;
    
    var i = 0;
    object.geometry.faces.forEach((face) {
      var v1 = face.normal
      ..applyMatrix3(normalMatrix)
      ..normalized()
      ..scale(size);
      
      var idx = 2 * i++;
  
      vertices[idx].setFrom(face.centroid).applyMatrix4(worldMatrix);
      vertices[idx + 1] = vertices[idx] + v1;
    });
  
    geometry.verticesNeedUpdate = true;
    return this;
  }
}