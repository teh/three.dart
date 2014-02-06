part of three;

class WebGLObject {
  bool __webglInit = false;
  bool __webglActive = false;

  Matrix4 _modelViewMatrix;
  Matrix3 _normalMatrix;

  var _normalMatrixArray;
  var _modelViewMatrixArray;
  var modelMatrixArray;

  WebGLGeometry buffer;
  Object3D object;
  WebGLMaterial opaque, transparent;
  bool render;
  var z;

  var __webglMorphTargetInfluences;

  WebGLObject._internal(this.object, this.opaque, this.transparent, this.buffer, this.render, this.z) ;

  factory WebGLObject(Object3D object, {WebGLMaterial opaque,
                                        WebGLMaterial transparent,
                                        WebGLGeometry buffer,
                                        bool render: true,
                                        num z: 0}) {
    if (object["__webglObject"] == null) {
      object["__webglObject"] = new WebGLObject._internal(object, opaque, transparent, buffer, render, z );
    }

    return object["__webglObject"];
  }

  Geometry get geometry => _hasGeometry ? (object as dynamic).geometry : null;
  WebGLGeometry get webglgeometry => geometry != null ? new WebGLGeometry.from(geometry) : null;

  Material get material => (object as dynamic).material;
  WebGLMaterial get webglmaterial => new WebGLMaterial.from(material);

  get matrixWorld => object.matrixWorld;

  get _hasGeometry => (object is Mesh) || (object is ParticleSystem) || (object is Line);

  get morphTargetBase => (object as dynamic).morphTargetBase;

  get receiveShadow => object.receiveShadow;

  get morphTargetForcedOrder => (object as Mesh).morphTargetForcedOrder;
  get morphTargetInfluences => (object as Mesh).morphTargetInfluences;

  // only SkinnedMesh
  get useVertexTexture => (object as dynamic).useVertexTexture;
  get boneMatrices => (object as dynamic).boneMatrices;
  get boneTexture => (object as dynamic).boneTexture;
  
  int get boneTextureWidth => (object as SkinnedMesh).boneTextureWidth;
  int get boneTextureHeight => (object as SkinnedMesh).boneTextureHeight;
}