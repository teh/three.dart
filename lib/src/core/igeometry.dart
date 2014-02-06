part of three;

abstract class IGeometry {
  int id;
  bool dynamic;
  List<MorphTarget> morphTargets;
  bool hasTangents;
  Map __data;
  IGeometry clone();
  operator [](String k);
  operator []=(String k, v);
}