part of three;

class GeometryAttribute<T> {
  static const String POSITION = "position";
  static const String NORMAL = "normal";
  static const String INDEX = "index";
  static const String UV = "uv";
  static const String TANGENT = "tangent";
  static const String COLOR = "color";
  int numItems, itemSize;
  T array;

  WebGLRendererBuffer buffer;
  
  bool needsUpdate = false,
       dynamic = false;

  GeometryAttribute._internal(this.numItems, this.itemSize, this.array);

  factory GeometryAttribute.float32(int numItems, [int itemSize = 1]) =>
      new GeometryAttribute<Float32List>._internal(numItems, itemSize, new Float32List(numItems * itemSize));

  factory GeometryAttribute.int16(int numItems, [int itemSize = 1]) =>
      new GeometryAttribute<Int16List>._internal(numItems, itemSize, new Int16List(numItems * itemSize));
}