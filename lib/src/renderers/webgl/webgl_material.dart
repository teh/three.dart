part of three;

class WebGLMaterial { // implements Material {
  Material _material;

  var program;
  var _fragmentShader;
  var _vertexShader;
  var _uniforms;
  var uniformsList;

  num numSupportedMorphTargets = 0, numSupportedMorphNormals = 0;

  // Used by ShadowMapPlugin
  bool shadowPass = false;
  
  // When rendered geometry doesn't include these attributes but the material does,
  // use these default values in WebGL. This avoids errors when buffer data is missing.
  Map<String, List<double>> get defaultAttributeValues => isShaderMaterial ?  
      {"color": new Float32List.fromList([1.0, 1.0, 1.0]),
       "uv": new Float32List.fromList([0.0, 0.0]),
       "uv2": new Float32List.fromList([0.0, 0.0])} : null;
  
  // By default, bind position to attribute index 0. In WebGL, attribute 0
  // should always be used to avoid potentially expensive emulation.
  String get index0AttributeName => isShaderMaterial ? "position" : null;

  WebGLMaterial._internal(Material material) : _material = material;

  factory WebGLMaterial.from(Material material) {
    if (material["__webglMaterial"] == null) {
      material["__webglMaterial"] = new WebGLMaterial._internal(material);
    }

    return material["__webglMaterial"];
  }

  Map<String, Attribute> get attributes => isShaderMaterial ? (_material as ShaderMaterial).attributes : null;
  get defines => isShaderMaterial ? (_material as ShaderMaterial).defines : {};
  get fragmentShader => isShaderMaterial ? (_material as ShaderMaterial).fragmentShader : _fragmentShader;
  get vertexShader => isShaderMaterial ? (_material as ShaderMaterial).vertexShader : _vertexShader;
  get uniforms => isShaderMaterial ? (_material as ShaderMaterial).uniforms : _uniforms;
  set fragmentShader(v) => isShaderMaterial ? (_material as ShaderMaterial).fragmentShader = v : _fragmentShader = v;
  set vertexShader(v) =>  isShaderMaterial ? (_material as ShaderMaterial).vertexShader = v: _vertexShader = v;
  set uniforms(v) => isShaderMaterial ? (_material as ShaderMaterial).uniforms = v : _uniforms = v;

  bool get needsSmoothNormals => 
      _material != null && shading != null && shading == SMOOTH_SHADING;

  // only MeshBasicMaterial and MeshDepthMaterial don't need normals
  bool get needsNormals => 
      !((_material is MeshBasicMaterial && envMap == null) || _material is MeshDepthMaterial);

  String get name => _material.name;
  int get id => _material.id;
  int get side => _material.side;
  num get opacity => _material.opacity;
  int get blending => _material.blending;
  int get blendSrc => _material.blendSrc;
  int get blendDst => _material.blendDst;
  int get blendEquation => _material.blendEquation;
  num get alphaTest => _material.alphaTest;
  int get polygonOffsetFactor => _material.polygonOffsetFactor;
  int get polygonOffsetUnits => _material.polygonOffsetUnits;
  bool get transparent => _material.transparent;
  bool get depthTest => _material.depthTest;
  bool get depthWrite => _material.depthWrite;
  bool get polygonOffset => _material.polygonOffset;
  int get overdraw => _material.overdraw;
  bool get visible => _material.visible;
  bool get needsUpdate => _material.needsUpdate;
  set needsUpdate(bool flag) => _material.needsUpdate = flag;


  // TODO - Define proper interfaces to remove use of Dynamic
  get vertexColors => _hasVertexColors ? (_material as dynamic).vertexColors : NO_COLORS;
  get color => (_material as dynamic).color;
  get ambient => (_material as dynamic).ambient;
  get emissive => (_material as dynamic).emissive;

  get shininess => isMeshPhongMaterial ? (_material as dynamic).shininess : null;
  get specular => isMeshPhongMaterial ? (_material as dynamic).specular : null;

  bool get lights => isShaderMaterial ? (_material as ShaderMaterial).lights : false;

  get morphTargets => _hasMorhTargets ?  (_material as dynamic).morphTargets : false;
  get morphNormals => _hasMorphNormals ?  (_material as dynamic).morphNormals : false;

  bool get metal => isMeshPhongMaterial ? (_material as MeshPhongMaterial).metal : false; 
  bool get perPixel => isMeshPhongMaterial ? (_material as MeshPhongMaterial).perPixel : false;

  get wrapAround => _hasWrapAround ?  (_material as dynamic).wrapAround : false;
  
  Vector3 get wrapRGB => _hasWrapRGB ? (_material as dynamic).wrapRGB : null;

  get fog => _hasFog ? (_material as dynamic).fog : false;
  get shading => (_material as dynamic).shading;
  
  Texture get map => isITextureMaterial || isParticleSystemMaterial ? (_material as ITextureMaterial).map : null;
  Texture get envMap => isITextureMaterial ? (_material as ITextureMaterial).envMap : null;
  Texture get lightMap => isITextureMaterial ? (_material as ITextureMaterial).lightMap : null;
  Texture get specularMap => isITextureMaterial ? (_material as ITextureMaterial).specularMap : null;
  
  Texture get bumpMap => isMeshPhongMaterial ? (_material as MeshPhongMaterial).bumpMap : null;
  Texture get normalMap => isMeshPhongMaterial ? (_material as MeshPhongMaterial).normalMap : null;

  Vector2 get normalScale => isMeshPhongMaterial ? (_material as MeshPhongMaterial).normalScale : null;
  double get bumpScale => isMeshPhongMaterial ? (_material as MeshPhongMaterial).bumpScale : null;

  get wireframe => !isLineBasicMaterial && !isParticleSystemMaterial && (_material as dynamic).wireframe;
  get wireframeLinewidth => wireframe ? (_material as dynamic).wireframeLinewidth : null;
  get wireframeLinecap => wireframe ? (_material as dynamic).wireframeLinecap : null;
  get wireframeLinejoin => wireframe ? (_material as dynamic).wireframeLinejoin : null;

  get linewidth => (isLineBasicMaterial) ? (_material as dynamic).linewidth : null;
  double get reflectivity => isITextureMaterial ? (_material as ITextureMaterial).reflectivity : null;
  double get refractionRatio => isITextureMaterial ? (_material as ITextureMaterial).refractionRatio : null;
  int get combine => isITextureMaterial ? (_material as ITextureMaterial).combine : null;
  
  get skinning => _hasSkinning ? (_material as dynamic).skinning : false;
  
  bool get sizeAttenuation => isParticleSystemMaterial ? (_material as ParticleSystemMaterial).sizeAttenuation : false; //null;
  double get size => isParticleSystemMaterial ? (_material as ParticleSystemMaterial).size : null;

  double get dashSize => isLineDashedMaterial ? (_material as LineDashedMaterial).dashSize : null;
  double get scale => isLineDashedMaterial ? (_material as LineDashedMaterial).scale : null;
  double get gapSize => isLineDashedMaterial ? (_material as LineDashedMaterial).gapSize : null;
  
  bool get isShaderMaterial => _material is ShaderMaterial;
  bool get isMeshFaceMaterial => _material is MeshFaceMaterial;
  bool get isMeshDepthMaterial => _material is MeshDepthMaterial;
  bool get isMeshNormalMaterial => _material is MeshNormalMaterial;
  bool get isMeshBasicMaterial => _material is MeshBasicMaterial;
  bool get isMeshLambertMaterial => _material is MeshLambertMaterial;
  bool get isMeshPhongMaterial => _material is MeshPhongMaterial;
  bool get isLineBasicMaterial => _material is LineBasicMaterial;
  bool get isLineDashedMaterial => _material is LineDashedMaterial;
  bool get isParticleSystemMaterial => _material is ParticleSystemMaterial;
  
  bool get isITextureMaterial => _material is ITextureMaterial;
      
  // TODO - Use this to identify proper interfaces
  bool get _hasAmbient => isMeshLambertMaterial || isMeshPhongMaterial;
  bool get _hasEmissive => isMeshLambertMaterial || isMeshPhongMaterial;
  bool get _hasWrapAround => isMeshLambertMaterial || isMeshPhongMaterial;
  bool get _hasWrapRGB => isMeshLambertMaterial || isMeshPhongMaterial;

  bool get _hasSkinning => isMeshBasicMaterial || isMeshLambertMaterial || isMeshPhongMaterial || isShaderMaterial;

  bool get _hasMorhTargets => isMeshBasicMaterial || isMeshLambertMaterial || isMeshPhongMaterial || isShaderMaterial;

  bool get _hasMorphNormals => isMeshLambertMaterial || isMeshPhongMaterial || isShaderMaterial;

  bool get _hasVertexColors => isLineBasicMaterial || isMeshBasicMaterial || isMeshLambertMaterial || isMeshPhongMaterial || isParticleSystemMaterial || isShaderMaterial;
  bool get _hasFog => isLineBasicMaterial || isMeshBasicMaterial || isMeshLambertMaterial || isMeshPhongMaterial || isParticleSystemMaterial || isShaderMaterial;
}