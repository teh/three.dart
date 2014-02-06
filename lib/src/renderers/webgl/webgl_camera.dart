part of three;

class WebGLCamera { // implements Camera {
  Camera _camera;
  Float32List _viewMatrixArray = new Float32List(16);
  Float32List _projectionMatrixArray = new Float32List(16);

  WebGLCamera._internal(Camera camera) : _camera = camera;


  factory WebGLCamera(Camera camera) {
    if (camera["__webglCamera"] == null) {
      camera["__webglCamera"] = new WebGLCamera._internal(camera);
    }

    return camera["__webglCamera"];
  }

  double get near => _camera.near;
  double get far => _camera.far;
  Object3D get parent => _camera.parent;
  Matrix4 get matrixWorld => _camera.matrixWorld;
  Matrix4 get matrixWorldInverse => _camera.matrixWorldInverse;
  set matrixWorldInverse(Matrix4 m) => _camera.matrixWorldInverse = m;
  Matrix4 get projectionMatrix => _camera.projectionMatrix;

  void updateMatrixWorld( {bool force: false} ) => _camera.updateMatrixWorld();
}