library GeometryUtils;

import "package:three/three.dart";
import 'package:three/extras/utils/math_utils.dart' as MathUtils;

/// Merge two geometries or geometry and geometry from object (using object's transform)
void merge(Geometry geometry, mesh_OR_geometry, [int materialIndexOffset = 0]) {
  Matrix4 matrix;
  Matrix3 normalMatrix;
  int vertexOffset = geometry.vertices.length;
  Geometry geometry2 = mesh_OR_geometry is Mesh ? mesh_OR_geometry.geometry : mesh_OR_geometry;

  if (mesh_OR_geometry is Mesh) {
    if (mesh_OR_geometry.matrixAutoUpdate) mesh_OR_geometry.updateMatrix();
    matrix = mesh_OR_geometry.matrix;
    normalMatrix = matrix.getNormalMatrix();
  }

  // Vertices
  geometry2.vertices.forEach((vertex) {
    var vertexCopy = vertex.clone();
    
    if (matrix != null) {
      matrix.transform3(vertexCopy);
      geometry.vertices.add(vertexCopy);
    }
  });
  
  // Faces
  geometry2.faces.forEach((face) {
    var faceCopy = new Face3(face.a + vertexOffset, face.b + vertexOffset, face.c + vertexOffset)
    ..normal.setFrom(face.normal);

    if (normalMatrix != null) {
      normalMatrix.transform(faceCopy.normal.normalize());
    }
    
    face.vertexNormals.forEach((vertexNormal) {
      var normal = vertexNormal.clone();
      
      if (normalMatrix != null) {
        normalMatrix.transform(normal.normalize());
      }
      
      faceCopy.vertexNormals.add(normal);
    });

    faceCopy.color.setFrom(face.color);
    
    face.vertexColors.forEach((vertexColor) => faceCopy.vertexColors.add(vertexColor));

    faceCopy.materialIndex = face.materialIndex + materialIndexOffset;
    faceCopy.centroid.setFrom(face.centroid);

    if (matrix != null) {
      matrix.transform3(faceCopy.centroid);
    }

    geometry.faces.add(faceCopy);
  });

  // Uvs
  geometry2.faceVertexUvs[0].forEach((List uv) => geometry.faceVertexUvs[0].add(uv.toList()));
}


/// Get random point in face (triangle / quad) (uniform distribution)
Vector3 randomPointInFace(Face3 face, Geometry geometry) =>
    new Triangle(geometry.vertices[face.a], 
                 geometry.vertices[face.b], 
                 geometry.vertices[face.c]).randomPoint();

// binary search cumulative areas array
int _binarySearch(double value, List<double> cumulativeAreas, int start, int end) {
  // return closest larger index
  // if exact number is not found
  if (end < start) return start;

  var mid = start + ((end - start) / 2).floor().toInt();

  if (cumulativeAreas[mid] > value) {
    return _binarySearch(value, cumulativeAreas, start, mid - 1);
  } else if (cumulativeAreas[mid] < value) {
    return _binarySearch(value, cumulativeAreas, mid + 1, end);
  } else {
    return mid;
  }
}

/// Get list of [n] random points in [geometry]
List<Vector3> randomPointsInGeometry(Geometry geometry, int n) {
  var totalArea = 0,
      cumulativeAreas = [];

  // precompute face areas
  var i = 0;
  geometry.faces.forEach((face) {
    var faceArea = triangleArea(geometry.vertices[face.a], 
                                geometry.vertices[face.b], 
                                geometry.vertices[face.c]);
    totalArea += faceArea;
    cumulativeAreas[i++] = totalArea;
  });

  var result = [];

  // pick random face weighted by face area
  for (var i = 0; i < n; i++) {
    var r = MathUtils.random16() * totalArea;
    var index = _binarySearch(r, cumulativeAreas, 0, cumulativeAreas.length - 1);
    result.add(randomPointInFace(geometry.faces[index], geometry));
  }

  return result;
}

/// Get area of triangle [A] [B] [C]
double triangleArea (Vector3 A, Vector3 B, Vector3 C) =>
    0.5 * (B - A).cross(C - A).length;

/// Center [geometry] so that 0,0,0 is in center of bounding box
double center(Geometry geometry) {
  geometry.computeBoundingBox();
  
  var bb = geometry.boundingBox;
  
  var offset = (bb.min + bb.max) * -0.5;
  
  geometry.applyMatrix(new Matrix4.translation(offset));
  geometry.computeBoundingBox();
  
  return offset;
}

void triangulateQuads(Geometry geometry) {
  var faces = [];
  var faceVertexUvs = new List(geometry.faceVertexUvs.length).map((_) => []);
  
  geometry.faces.forEach((face) {
    faces.add(face);
    
    var i = 0;
    geometry.faceVertexUvs.forEach((uv) => faceVertexUvs[i].add(uv[i++]));
  });

  geometry
  ..faces = faces
  ..faceVertexUvs = faceVertexUvs
  ..computeCentroids()
  ..computeFaceNormals()
  ..computeVertexNormals();

  if (geometry.hasTangents) {
    geometry.computeTangents();
  }
}

