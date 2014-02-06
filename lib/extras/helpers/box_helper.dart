part of three;

class BoxHelper extends Line {
  List<Vector3> vertices = [new Vector3( 1.0,  1.0,  1.0),
                            new Vector3(-1.0,  1.0,  1.0),
                            new Vector3(-1.0, -1.0,  1.0),
                            new Vector3( 1.0, -1.0,  1.0),
 
                            new Vector3( 1.0,  1.0, -1.0),
                            new Vector3(-1.0,  1.0, -1.0),
                            new Vector3(-1.0, -1.0, -1.0),
                            new Vector3( 1.0, -1.0, -1.0)];
  
  factory BoxHelper(Mesh object) {
    var geometry = new Geometry()
    ..vertices.addAll([vertices[0], vertices[1],
                       vertices[1], vertices[2],
                       vertices[2], vertices[3],
                       vertices[3], vertices[0],
               
                       vertices[4], vertices[5],
                       vertices[5], vertices[6],
                       vertices[6], vertices[7],
                       vertices[7], vertices[4],
              
                       vertices[0], vertices[4],
                       vertices[1], vertices[5],
                       vertices[2], vertices[6],
                       vertices[3], vertices[7]]);
    
    if (object != null) update(object);
    return new BoxHelper._internal(geometry, new LineBasicMaterial(color: 0xffff00), LINE_PIECES);
  }
  
  BoxHelper._internal(Geometry geometry, Material material, int type) : super(geometry, material, type);
  
  update(Mesh object) {
    var geometry = object.geometry;

    if (geometry.boundingBox == null) {
      geometry.computeBoundingBox();
    }

    var min = geometry.boundingBox.min;
    var max = geometry.boundingBox.max;

    vertices[0].setValues(max.x, max.y, max.z);
    vertices[1].setValues(min.x, max.y, max.z);
    vertices[2].setValues(min.x, min.y, max.z);
    vertices[3].setValues(max.x, min.y, max.z);
    vertices[4].setValues(max.x, max.y, min.z);
    vertices[5].setValues(min.x, max.y, min.z);
    vertices[6].setValues(min.x, min.y, min.z);
    vertices[7].setValues(max.x, min.y, min.z);

    geometry.computeBoundingSphere();
    geometry.verticesNeedUpdate = true;

    matrixAutoUpdate = false;
    matrixWorld = object.matrixWorld;
  }
}