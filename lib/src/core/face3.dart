part of three;

class Face3 {
  /// Vertex A, B and C index.
  final List<int> indices;
  
  /// Face normal.
  final Vector3 normal;
  
  /// Array of 3 vertex normals.
  final List<Vector3> vertexNormals;
  
  /// Face color.
  final Color color;
  
  /// Array of 3 vertex colors.
  final List<Color> vertexColors;
  
  /// Array of 3 vertex tangents.
  final List<Vector4> vertexTangents = new List(3);
  
  /// Material index.
  int materialIndex;
  
  /// Face centroid.
  Vector3 centroid = new Vector3.zero();
  
  Vector3 __originalFaceNormal;
  List __originalVertexNormals;

  /// Constructs a new face with vertex indices [a], [b] and [c], initially set to zero, 
  /// and an optional normal, color and material index.
  /// 
  /// [normal] can be either a face normal or an array of vertex normals,
  /// and [color] can be either a face color or an array of vertex colors.
  Face3([int a = 0, int b = 0, int c = 0, normal, color, this.materialIndex]) 
      : indices = [a, b, c],
        normal = normal is Vector3 ? normal : new Vector3.zero(),
        vertexNormals = normal is List ? normal : new List(3),
        color = color is Color ? color : new Color.white(),
        vertexColors = color is List ? color : new List(3);

  /// Creates a new clone of the Face3 object.
  Face3 clone() {
    var face = new Face3(a, b, c, normal, color, materialIndex)
        ..centroid.setFrom(centroid);
    
    for (var i = 0; i < vertexNormals.length; i++) face.vertexNormals[i] = vertexNormals[i].clone();
    for (var i = 0; i < vertexColors.length; i++) face.vertexColors[i] = vertexColors[i].clone();
    for (var i = 0; i < vertexTangents.length; i++) face.vertexTangents[i] = vertexTangents[i].clone();

    return face;
  }
  
  /// Vertex A index
  int get a => indices[0];
      set a(int i) => indices[0] = i; 

  /// Vertex B index
  int get b => indices[1];
      set b(int i) => indices[1] = i; 
  
  /// Vertex C index
  int get c => indices[2];
      set c(int i) => indices[2] = i; 

  int operator [](int i) => indices[i];
  operator []=(int i, int v) => indices[i] = v;
}
