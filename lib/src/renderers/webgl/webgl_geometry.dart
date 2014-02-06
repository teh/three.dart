part of three;

class WebGLGeometry {
  int id;

  List<Face3> faces3;
  
  int _vertices;
  
  int materialIndex = 0; 
  int numMorphTargets = 0;
  int numMorphNormals = 0;

  var geometryGroups, geometryGroupsList;

  bool __webglInit;

  bool __inittedArrays;
  
  Float32List __vertexArray,
              __normalArray,
              __tangentArray,
              __colorArray,
              __lineDistanceArray,
              __uvArray,
              __uv2Array,
              __skinVertexAArray,
              __skinVertexBArray,
              __skinIndexArray,
              __skinWeightArray;
  
  Uint16List __faceArray, __lineArray;
  List<Float32List> __morphTargetsArrays, __morphNormalsArrays;
  int __webglFaceCount, __webglLineCount, __webglParticleCount, __webglVertexCount;

  List __sortArray;

  List<Attribute> __webglCustomAttributesList;

  gl.Buffer __webglVertexBuffer,
            __webglNormalBuffer,
            __webglTangentBuffer,
            __webglColorBuffer,
            __webglLineDistanceBuffer,
            __webglUVBuffer,
            __webglUV2Buffer,

            __webglSkinVertexABuffer,
            __webglSkinVertexBBuffer,
            __webglSkinIndicesBuffer,
            __webglSkinWeightsBuffer,

            __webglFaceBuffer,
            __webglLineBuffer;

  List<gl.Buffer> __webglMorphTargetsBuffers, __webglMorphNormalsBuffers;

  IGeometry _geometry;

  WebGLGeometry({this.faces3,
                 this.materialIndex: 0,
                 int vertices: null,
                 this.numMorphTargets: 0,
                 this.numMorphNormals: 0}) : _vertices = vertices;

  WebGLGeometry._internal(IGeometry geometry) 
      : _geometry = geometry,
        id = geometry.id;

  factory WebGLGeometry.from(IGeometry geometry) {
    if (geometry["__webglBuffer"] == null) {
      geometry["__webglBuffer"] = new WebGLGeometry._internal(geometry);
    }

    return geometry["__webglBuffer"];
  }

  // This is weird since vertices can be a List from geometry or a number
  set vertices(int n) => _vertices = n;
  get vertices {
    if (_vertices == null && _geometry != null) {
      return (_geometry as Geometry).vertices;
    }
    return _vertices;
  }

  List<Chunk> get offsets => (_geometry as BufferGeometry).offsets;
  Map<String, GeometryAttribute> get attributes => (_geometry as BufferGeometry).attributes;
  
  get lineDistances => (_geometry as Geometry).lineDistances;
  
  bool getBoolData(String key) => _geometry.__data.containsKey(key) ? _geometry[key] : false;

  bool get verticesNeedUpdate => getBoolData("verticesNeedUpdate");
       set verticesNeedUpdate(bool flag) => _geometry["verticesNeedUpdate"] = flag;

  bool get morphTargetsNeedUpdate => getBoolData("morphTargetsNeedUpdate");
       set morphTargetsNeedUpdate(bool flag) => _geometry["morphTargetsNeedUpdate"] = flag;

  bool get elementsNeedUpdate => getBoolData("elementsNeedUpdate");
       set elementsNeedUpdate(bool flag) => _geometry["elementsNeedUpdate"] = flag;

  bool get uvsNeedUpdate => getBoolData("uvsNeedUpdate");
       set uvsNeedUpdate(bool flag) => _geometry["uvsNeedUpdate"] = flag;

  bool get normalsNeedUpdate => getBoolData("normalsNeedUpdate");
       set normalsNeedUpdate(bool flag) => _geometry["normalsNeedUpdate"] = flag;

  bool get tangentsNeedUpdate => getBoolData("tangentsNeedUpdate");
       set tangentsNeedUpdate(bool flag) => _geometry["tangentsNeedUpdate"] = flag;

  bool get colorsNeedUpdate => getBoolData("colorsNeedUpdate");
       set colorsNeedUpdate(bool flag) => _geometry["colorsNeedUpdate"] = flag;

  bool get lineDistancesNeedUpdate => getBoolData("lineDistancesNeedUpdate");
       set lineDistancesNeedUpdate(bool flag) => _geometry["lineDistancesNeedUpdate"] = flag;

  bool get buffersNeedUpdate => getBoolData("buffersNeedUpdate");
       set buffersNeedUpdate(bool flag) => _geometry["buffersNeedUpdate"] = flag;

  List<MorphTarget> get morphTargets => _geometry.morphTargets;
  List<MorphNormal> get morphNormals => (_geometry as Geometry).morphNormals;

  List<Face3> get faces => (_geometry as Geometry).faces;

  bool get dynamic => _geometry.dynamic;

  List<List<List<Vector2>>> get faceVertexUvs => (_geometry as Geometry).faceVertexUvs;
  List<Color> get colors => (_geometry as Geometry).colors;
  List<Vector4> get skinIndices => (_geometry as Geometry).skinIndices;
  List<Vector4> get skinWeights => (_geometry as Geometry).skinWeights;


  bool get hasTangents => _geometry.hasTangents;

  bool get isBufferGeometry => _geometry is BufferGeometry;
}