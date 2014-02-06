/**
 * @author mr.doob / http://mrdoob.com/
 * @author kile / http://kile.stravaganza.org/
 * @author alteredq / http://alteredqualia.com/
 * @author mikael emtinger / http://gomo.se/
 * @author zz85 / http://www.lab4games.net/zz85/blog
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 * 
 * based on r63
 */

part of three;

/// Base class for geometries.
/// A geometry holds all data necessary to describe a 3D model.
class Geometry implements IGeometry {
  /// Unique number of this geometry instance.
  int id = GeometryIdCount++;
  
  String uuid = MathUtils.generateUUID();
  
  /// Name for this geometry. Default is an empty string.
  String name = '';
  
  /// Array of vertices.
  /// The array of vertices holds every position of points in the model.
  /// To signal an update in this array, [verticesNeedUpdate] needs to be set to true
  List<Vector3> vertices = [];
  
  /// Array of vertex colors, matching number and order of vertices.
  /// Used in ParticleSystem and Line.
  /// Meshes use per-face-use-of-vertex colors embedded directly in faces.
  /// To signal an update in this array, [colorsNeedUpdate] needs to be set to true.
  List<Color> colors = [];
  
  /// Array of triangles.
  /// The array of faces describe how each vertex in the model is connected with each other.
  /// To signal an update in this array, [elementsNeedUpdate] needs to be set to true.
  List<Face3> faces = [];
  
  /// Array of face UV layers.
  /// Each UV layer is an array of UVs matching the order and number of vertices in faces.
  /// To signal an update in this array, [uvsNeedUpdate] needs to be set to true.
  List<List<List<Vector2>>> faceVertexUvs = [[]];
  
  /// Array of morph targets. Morph vertices match number and order of primary vertices.
  List<MorphTarget> morphTargets = [];
  
  /// Array of morph normals.
  List<MorphNormal> morphNormals = [];
  
  /// Array of morph colors. 
  /// Morph colors can match either the number and order of faces (face colors) 
  /// or the number of vertices (vertex colors).
  List<MorphColor> morphColors = [];
  
  /// Array of skinning weights, matching number and order of vertices.
  List<Vector4> skinWeights = [];
  
  /// Array of skinning indices, matching number and order of vertices.
  List<Vector4> skinIndices = [];
  
  /// An array containing distances between vertices for Line geometries. 
  /// This is required for LinePieces/LineDashedMaterial to render correctly. 
  /// Line distances can also be generated with computeLineDistances.
  List<double> lineDistances = [];
  
  /// Bounding box.
  Box3 boundingBox;
  
  /// Bounding sphere.
  Sphere boundingSphere;
  
  /// True if geometry has tangents. Set in Geometry.computeTangents().
  bool hasTangents = false;
  
  /// Set to true if attribute buffers will need to change in runtime (using "dirty" flags).
  /// Unless set to true internal typed arrays corresponding to buffers will be deleted once sent to GPU.
  /// Defaults to true.
  bool dynamic = true;
  
  /// Set to true if [vertices] has been updated.
  set verticesNeedUpdate(bool flag) => __data["verticesNeedUpdate"] = flag;
  
  /// Set to true if [faces] has been updated.
  set elementsNeedUpdate(bool flag) => __data["elementsNeedUpdate"] = flag;
  
  /// Set to true if [faceVertexUvs] has been updated.
  set uvsNeedUpdate(bool flag) => __data["uvsNeedUpdate"] = flag;
  
  /// Set to true if the normals array has been updated.
  set normalsNeedUpdate(bool flag) => __data["normalsNeedUpdate"] = flag;
  
  /// Set to true if the tangents in [faces] has been updated.
  set tangentsNeedUpdate(bool flag) => __data["tangentsNeedUpdate"] = flag;
  
  /// Set to true if [colors] has been updated.
  set colorsNeedUpdate(bool flag) => __data["colorsNeedUpdate"] = flag;
  
  /// Set to true if [lineDistances] has been updated
  set lineDistancesNeedUpdate(bool flag) => __data["lineDistancesNeedUpdate"] = flag;
  
  /// Set to true if an array has changed in length.
  set buffersNeedUpdate(bool flag) => __data["buffersNeedUpdate"] = flag;
  
  /// Set to true if [morphTargets] has been updated.
  set morphTargetsNeedUpdate(bool flag) => __data["morphTargetsNeedUpdate"] = flag;
  
  //Used in JSONLoader
  var bones;
  Map animation, animations;
  String firstAnimation;
  
  /// The constructor takes no arguments.
  Geometry();
  
  /// Bakes matrix transform directly into vertex coordinates.
  void applyMatrix(Matrix4 matrix) {
    var normalMatrix = matrix.getNormalMatrix();
    
    vertices.forEach((vertex) => vertex.applyMatrix4(matrix));
 
    faces.forEach((face) {
      face.normal.applyMatrix3(normalMatrix).normalize();
      face.vertexNormals.where((e) => e != null).forEach((vertexNormal) => vertexNormal.applyMatrix3(normalMatrix).normalize());
      face.centroid.applyMatrix4(matrix);
    });

    if (boundingBox is Box3) computeBoundingBox();
    if (boundingSphere is Sphere) computeBoundingSphere();
  }
  
  /// Computes centroids for all faces.
  void computeCentroids() {
    faces.forEach((face) {
      face.centroid.setZero();
      face.centroid.add(vertices[face.a] + vertices[face.b] + vertices[face.c]);
      face.centroid.scale(1 / 3);
    });
  }
  
  /// Computes face normals.
  void computeFaceNormals() {
    faces.forEach((face) {
      var vA = vertices[face.a];
      var vB = vertices[face.b];
      var vC = vertices[face.c];
      
      face.normal.setFrom((vC - vB).cross(vA - vB).normalize());
    });
  }
  
  /// Computes vertex normals by averaging face normals.
  /// Face normals must be existing/computed beforehand.
  void computeVertexNormals({bool areaWeighted: false}) {
    var _vertices = new List.filled(vertices.length, new Vector3.zero());
    
    if (areaWeighted) {
      faces.forEach((face) {
        var vA = vertices[face.a];
        var vB = vertices[face.b];
        var vC = vertices[face.c];

        var cb = (vC - vB).cross(vA - vB);

        _vertices[face.a].add(cb);
        _vertices[face.b].add(cb);
        _vertices[face.c].add(cb);
      });
    } else {
      faces.forEach((face) {
        _vertices[face.a].add(face.normal);
        _vertices[face.b].add(face.normal);
        _vertices[face.c].add(face.normal);
      });
    }
    
    _vertices.forEach((vertex) => vertex.normalize());
    
    faces.forEach((face) {
      face.vertexNormals[0] = _vertices[face.a].clone();
      face.vertexNormals[1] = _vertices[face.b].clone();
      face.vertexNormals[2] = _vertices[face.c].clone();
    });
  }
  
  /// Computes morph normals.
  void computeMorphNormals() {
    // save original normals
    faces.forEach((face) {
      face.__originalFaceNormal = face.normal.clone();
      face.__originalVertexNormals = face.vertexNormals.toList();
    });
  
    // use temp geometry to compute face and vertex normals for each morph
    var tmpGeo = new Geometry()
        ..faces = faces;

    morphNormals = new List(morphTargets.length);
    
    for (var i = 0; i < morphTargets.length; i++) {
      // create on first access
      this.morphNormals[i] = new MorphNormal();

      var dstNormalsFace = this.morphNormals[i].faceNormals;
      var dstNormalsVertex = this.morphNormals[i].vertexNormals;
      
      faces.forEach((_) {
        var faceNormal = new Vector3.zero();
        var vertexNormals = {"a": new Vector3.zero(), "b": new Vector3.zero(), "c": new Vector3.zero()};

        dstNormalsFace.add(faceNormal);
        dstNormalsVertex.add(vertexNormals);
      });

      var morphNormals = this.morphNormals[i];

      // set vertices to morph target
      tmpGeo.vertices = this.morphTargets[i].vertices;

      // compute morph normals
      tmpGeo.computeFaceNormals();
      tmpGeo.computeVertexNormals();

      // store morph normals
      var f = 0;
      faces.forEach((face) {
        var faceNormal = morphNormals.faceNormals[f];
        var vertexNormals = morphNormals.vertexNormals[f];

        faceNormal.copy(face.normal);

        vertexNormals["a"].setFrom(face.vertexNormals[0]);
        vertexNormals["b"].setFrom(face.vertexNormals[1]);
        vertexNormals["c"].setFrom(face.vertexNormals[2]);
        
        f++;
      });
    }
    
    // restore original normals
    faces.forEach((face) {
      face.normal = face.__originalFaceNormal;
      face.vertexNormals = face.__originalVertexNormals;
    });
  }
  
  /// Computes vertex tangents.
  /// Based on http://www.terathon.com/code/tangent.html
  /// Geometry must have vertex UVs (layer 0 will be used).
  void computeTangents() {
    List<Vector2> uv;
    var tan1 = new List.filled(vertices.length, new Vector3.zero()),
        tan2 = new List.filled(vertices.length, new Vector3.zero());

    var handleTriangle = (Geometry context, int a, int b, int c, int ua, int ub, int uc) {
      var vA = context.vertices[a],
          vB = context.vertices[b],
          vC = context.vertices[c];

      var r = 1.0 / ((uv[ub].x - uv[ua].x) * (uv[uc].y - uv[ua].y) - (uv[uc].x - uv[ua].x) * (uv[ub].y - uv[ua].y));
          
      var sdir = new Vector3.zero()
          ..x = ((uv[uc].y - uv[ua].y) * (vB.x - vA.x) - (uv[ub].y - uv[ua].y) * (vC.x - vA.x)) * r 
          ..y = ((uv[uc].y - uv[ua].y) * (vB.y - vA.y) - (uv[ub].y - uv[ua].y) * (vC.y - vA.y)) * r
          ..z = ((uv[uc].y - uv[ua].y) * (vB.z - vA.z) - (uv[ub].y - uv[ua].y) * (vC.z - vA.z)) * r;
                             
      var tdir = new Vector3.zero()
          ..x = ((uv[ub].x - uv[ua].x) * (vC.x - vA.x) - (uv[uc].x - uv[ua].x) * (vB.x - vA.x)) * r
          ..y = ((uv[ub].x - uv[ua].x) * (vC.y - vA.y) - (uv[uc].x - uv[ua].x) * (vB.y - vA.y)) * r
          ..z = ((uv[ub].x - uv[ua].x) * (vC.z - vA.z) - (uv[uc].x - uv[ua].x) * (vB.z - vA.z)) * r;

      tan1[a].add(sdir);
      tan1[b].add(sdir);
      tan1[c].add(sdir);

      tan2[a].add(tdir);
      tan2[b].add(tdir);
      tan2[c].add(tdir);
    };
    
    var f = 0;
    faces.forEach((face) {
      uv = faceVertexUvs[0][f++]; // use UV layer 0 for tangents
      handleTriangle(this, face.a, face.b, face.c, 0, 1, 2);
    });

    faces.forEach((face) {
      for (var i = 0; i < face.vertexNormals.length; i++) {
        var n = new Vector3.copy(face.vertexNormals[i]);

        var vertexIndex = face[i];

        var t = tan1[vertexIndex];

        // Gram-Schmidt orthogonalize
        var tmp = new Vector3.copy(t)
            ..sub(n.scale(n.dot(t))).normalize();

        // Calculate handedness
        var tmp2 = face.vertexNormals[i].cross(t);
        var test = tmp2.dot(tan2[vertexIndex]);
        var w = (test < 0.0) ? -1.0 : 1.0;

        face.vertexTangents[i] = new Vector4(tmp.x, tmp.y, tmp.z, w);
      }
    });

    hasTangents = true;
  }

  /// Compute distances between vertices for Line geometries.
  void computeLineDistances() {
    var d = 0;
    for (var i = 0; i < vertices.length; i++) {
      if (i > 0) d += vertices[i].distanceTo(vertices[i - 1]);
      lineDistances[i] = d;
    }
  }

  /// Computes bounding box of the geometry, updating [boundingBox].
  void computeBoundingBox() {
    boundingBox = new Box3.fromPoints(vertices);
  }
  
  /// Computes bounding sphere of the geometry, updating [boundingSphere].
  /// Neither bounding boxes or bounding spheres are computed by default. 
  /// They need to be explicitly computed, otherwise they are null.
  void computeBoundingSphere() {
    boundingSphere = new Sphere.fromPoints(vertices);
  }
  
  /// Checks for duplicate vertices.
  /// Duplicated vertices are removed and faces' vertices are updated.
  int mergeVertices() {
    var verticesMap = {}; // Map for looking up vertice by position coordinates (and making sure they are unique)
    var unique = [], 
        changes = new List(vertices.length);
    
    var precisionPoints = 4; // number of decimal points, eg. 4 for epsilon of 0.0001
    var precision = Math.pow(10, precisionPoints);

    for (var i = 0; i < vertices.length; i++) {
      var v = vertices[i];
      var key = "${(v.x * precision).round()}_${(v.y * precision).round()}_${(v.z * precision).round()}";

      if (!verticesMap.containsKey(key)) {
        verticesMap[key] = i;
        unique.add(vertices[i]);
        changes[i] = unique.length - 1;
      } else {
        changes[i] = changes[verticesMap[key]];
      }
    }

    // If faces are completely degenerate after merging vertices, we
    // have to remove them from the geometry.
    var faceIndicesToRemove = [];

    for(var i = 0; i < faces.length; i++) {
      var face = faces[i];

      face.a = changes[face.a];
      face.b = changes[face.b];
      face.c = changes[face.c];

      var indices = [face.a, face.b, face.c];

      var dupIndex = -1;

      // if any duplicate vertices are found in a Face3
      // we have to remove the face as nothing can be saved
      for (var n = 0; n < 3; n ++) {
        if (indices[n] == indices[(n + 1) % 3]) {
          dupIndex = n;
          faceIndicesToRemove.add(i);
          break;
        }
      }
    }

    for (var i = faceIndicesToRemove.length - 1; i >= 0; i--) {
      var idx = faceIndicesToRemove[i];
      
      faces.removeAt(idx);
      faceVertexUvs.forEach((uv) => uv.removeAt(idx));
    }

    // Use unique set of vertices
    var diff = vertices.length - unique.length;
    vertices = unique;
    
    return diff;
  }

  /// Creates a new clone of the Geometry.
  Geometry clone() =>
      new Geometry()
          ..vertices = vertices.toList()
          ..faces = faces.toList()
          ..faceVertexUvs[0].addAll(faceVertexUvs[0].toList());  
  
  // Quick hack to allow setting new properties (used by the renderer)
  Map __data = {};
  operator [](String k) => __data[k];
  operator []=(String k, v) => __data[k] = v;
}