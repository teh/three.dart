/**
 * @author supereggbert / http://www.paulbrunt.co.uk/
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 * @author szimek / https://github.com/szimek/
 * 
 * based on r62
 */

part of three;

class WebGLRenderer implements Renderer {
  static const String PRECISION_HIGH = 'highp';

  CanvasElement canvas;
  gl.RenderingContext _gl;

  String precision;

  /// Returns a [Color] instance with the current clear color.
  Color get clearColor => _clearColor;
  Color _clearColor = new Color(0x000000);
  
  /// Returns a float with the current clear alpha. Ranges from 0 to 1.
  int get clearAlpha => _clearAlpha;
  int _clearAlpha = 0;
  
  double devicePixelRatio;

  bool alpha,
       premultipliedAlpha,
       antialias,
       stencil,
       preserveDrawingBuffer;

  /// Defines whether the renderer should automatically clear its output before rendering.
  /// Default is true.
  bool autoClear = true;
  
  /// If autoClear is true, defines whether the renderer should clear the color buffer. 
  /// Default is true.
  bool autoClearColor = true;
  
  /// If autoClear is true, defines whether the renderer should clear the depth buffer. 
  /// Default is true.
  bool autoClearDepth = true;
  
  /// If autoClear is true, defines whether the renderer should clear the stencil buffer. 
  /// Default is true.
  bool autoClearStencil = true;

  /// Defines whether the renderer should sort objects. Default is true.
  /// 
  /// Note: Sorting is used to attempt to properly render objects that have some 
  /// degree of transparency. By definition, sorting objects may not work in all 
  /// cases. Depending on the needs of application, it may be neccessary to turn 
  /// off sorting and use other methods to deal with transparency rendering e.g.
  /// manually determining the object rendering order.
  bool sortObjects = true;
  
  /// Defines whether the renderer should auto update objects. Default is true.
  bool autoUpdateObjects = true;

  /// Default is false.
  bool gammaInput = false;
  
  /// Default is false.
  bool gammaOutput = false;
  
  /// Default is false.
  bool physicallyBasedShading = false;

  /// Default is false.
  bool shadowMapEnabled = false;
  
  /// Default is true.
  bool shadowMapAutoUpdate = true;
  
  /// Default is false.
  bool shadowMapDebug = false;
  
  /// Default is false.
  bool shadowMapCascade = false;
  
  /// Defines shadow map type (unfiltered, percentage close filtering, percentage 
  /// close filtering with bilinear filtering in shader)
  /// 
  /// Options are BASIC_SHADOW_MAP, PCF_SHADOW_MAP, PCF_SOFT_SHADOW_MAP. 
  /// Default is PCF_SHADOW_MAP.
  int shadowMapType = PCF_SHADOW_MAP,
      shadowMapCullFace = CULL_FACE_FRONT;

  /// Default is 8.
  int maxMorphTargets = 8;
  
  /// Default is 4.
  int maxMorphNormals = 4;

  /// Default is true.
  bool autoScaleCubemaps = true;

  /// An array with render plugins to be applied before rendering.
  List renderPluginsPre = [];
  
  /// An array with render plugins to be applied after rendering.
  List renderPluginsPost = [];

  /// An object with a series of statistical information about the graphics board 
  /// memory and the rendering process. Useful for debugging or just for the sake 
  /// of curiosity. The object contains the following fields:
  /// 
  /// memory:
  /// * programs
  /// * geometries
  /// * textures
  /// 
  /// render:
  /// * calls
  /// * vertices
  /// * faces
  /// * points
  WebGLRendererInfo info = new WebGLRendererInfo();

  /*
   * Internal properties 
   */

  List<WebGLRendererProgram> _programs = [];
  int _programs_counter = 0;

  // internal state cache
  var _currentProgram,
      _currentFramebuffer;
  
  int _currentMaterialId = -1;
  
  var _currentGeometryGroupHash,
      _currentCamera;
  int _geometryGroupCounter = 0,
      _usedTextureUnits = 0;

  Map<int, bool> _enabledAttributes = {};

  // GL state cache
  bool _oldDoubleSided = false,
       _oldFlipSided = false;

  int _oldBlending = -1,
      _oldBlendEquation = -1,
      _oldBlendSrc = -1,
      _oldBlendDst = -1;

  bool _oldDepthTest = false,
       _oldDepthWrite = false;
       
  bool _oldPolygonOffset;
  int _oldPolygonOffsetFactor,
      _oldPolygonOffsetUnits;

  double _oldLineWidth;

  int _viewportX = 0,
      _viewportY = 0,
      _viewportWidth,
      _viewportHeight,
      _currentWidth = 0,
      _currentHeight = 0;

   // frustum
  Frustum _frustum = new Frustum();

   // camera matrices cache
  Matrix4 _projScreenMatrix = new Matrix4.identity(),
          _projScreenMatrixPS = new Matrix4.identity();

  Vector3 _vector3 = new Vector3.zero();

  // light arrays cache
  Vector3 _direction = new Vector3.zero();

  WebGLRendererLights _lights = new WebGLRendererLights();
  
  bool _lightsNeedUpdate = true;
  
  // GL Extensions
  gl.OesTextureFloat _glExtensionTextureFloat;
  gl.OesTextureFloatLinear _glExtensionTextureFloatLinear;
  gl.OesStandardDerivatives _glExtensionStandardDerivatives;
  gl.ExtTextureFilterAnisotropic _glExtensionTextureFilterAnisotropic;
  gl.CompressedTextureS3TC _glExtensionCompressedTextureS3TC;

  int maxAnisotropy;

  /// Wether the the context supports vertex textures
  bool supportsVertexTextures,
       supportsFloatTextures,
       supportsStandardDerivatives,
       supportsCompressedTextureS3TC,
       supportsBoneTextures;

  ShadowMapPlugin shadowMapPlugin;

  num maxTextures, 
      maxVertexTextures, 
      maxTextureSize, 
      maxCubemapSize;
  
  /// A Canvas where the renderer draws its output.
  /// This is automatically created by the renderer in the constructor 
  /// (if not provided already); you just need to add it to your page.
  Element get domElement => canvas;
  
  /// The HTML5 Canvas's 'webgl' context obtained from the canvas where the renderer will draw.
  gl.RenderingContext get context => _gl;

  WebGLRenderer({this.canvas,
                 this.precision: PRECISION_HIGH,
                 this.alpha: true,
                 this.premultipliedAlpha: true,
                 this.antialias: true,
                 this.stencil: true,
                 this.preserveDrawingBuffer: false,
                 double devicePixelRatio}) {
    this.devicePixelRatio = devicePixelRatio != null ? devicePixelRatio : (window.devicePixelRatio != null ? window.devicePixelRatio : 1.0);

    if (canvas == null) canvas = new CanvasElement();
    _viewportWidth = canvas.width;
    _viewportHeight = canvas.height;

    // initialize
    initGL();
    setDefaultGLState();

    // GPU capabilities
    maxTextures = _gl.getParameter(gl.MAX_TEXTURE_IMAGE_UNITS);
    maxVertexTextures = _gl.getParameter(gl.MAX_VERTEX_TEXTURE_IMAGE_UNITS);
    maxTextureSize = _gl.getParameter(gl.MAX_TEXTURE_SIZE);
    maxCubemapSize = _gl.getParameter(gl.MAX_CUBE_MAP_TEXTURE_SIZE);

    maxAnisotropy = (_glExtensionTextureFilterAnisotropic != null) ? _gl.getParameter(gl.ExtTextureFilterAnisotropic.MAX_TEXTURE_MAX_ANISOTROPY_EXT) : 0;

    supportsVertexTextures = maxVertexTextures > 0;
    supportsBoneTextures = supportsVertexTextures && (_glExtensionTextureFloat != null);

    var _compressedTextureFormats = (_glExtensionCompressedTextureS3TC != null) ? _gl.getParameter(gl.COMPRESSED_TEXTURE_FORMATS) : [];

    //

    var _vertexShaderPrecisionHighpFloat = _gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.HIGH_FLOAT);
    var _vertexShaderPrecisionMediumpFloat = _gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.MEDIUM_FLOAT);
    var _vertexShaderPrecisionLowpFloat = _gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.LOW_FLOAT);

    var _fragmentShaderPrecisionHighpFloat = _gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.HIGH_FLOAT);
    var _fragmentShaderPrecisionMediumpFloat = _gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.MEDIUM_FLOAT);
    var _fragmentShaderPrecisionLowpFloat = _gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.LOW_FLOAT);

    var _vertexShaderPrecisionHighpInt = _gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.HIGH_INT);
    var _vertexShaderPrecisionMediumpInt = _gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.MEDIUM_INT);
    var _vertexShaderPrecisionLowpInt = _gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.LOW_INT);

    var _fragmentShaderPrecisionHighpInt = _gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.HIGH_INT);
    var _fragmentShaderPrecisionMediumpInt = _gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.MEDIUM_INT);
    var _fragmentShaderPrecisionLowpInt = _gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.LOW_INT);

    // clamp precision to maximum available

    var highpAvailable = _vertexShaderPrecisionHighpFloat.precision > 0 && _fragmentShaderPrecisionHighpFloat.precision > 0;
    var mediumpAvailable = _vertexShaderPrecisionMediumpFloat.precision > 0 && _fragmentShaderPrecisionMediumpFloat.precision > 0;

    if (precision == "highp" && !highpAvailable) {
      if (mediumpAvailable) {
        precision = "mediump";
        print("WebGLRenderer: highp not supported, using mediump");
      } else {
        precision = "lowp";
        print("WebGLRenderer: highp and mediump not supported, using lowp");
      }
    }
    if (precision == "mediump" && !mediumpAvailable) {
      precision = "lowp";
      print("WebGLRenderer: mediump not supported, using lowp");
    }

    
    // default plugins (order is important)
    shadowMapPlugin = new ShadowMapPlugin();
    addPrePlugin(shadowMapPlugin);

    // addPostPlugin(new SpritePlugin());
    // addPostPlugin(new LensFlarePlugin());
  }

  /// Resizes the output canvas to (width, height), and also sets the viewport to 
  /// fit that size, starting in (0, 0).
  void setSize(int width, int height, {bool updateStyle: false}) {
    canvas.width = (width * devicePixelRatio).toInt();
    canvas.height = (height * devicePixelRatio).toInt();

    if (devicePixelRatio != 1 && updateStyle != false) {
      canvas.style.width = "$width px";
      canvas.style.height = "$height px";
    }
    
    setViewport(0, 0, canvas.width, canvas.height);
  }

  /// Sets the viewport to render from (x, y) to (x + width, y + height).
  void setViewport([int x = 0, int y = 0, int width, int height]) {
    _viewportX = x;
    _viewportY = y;

    _viewportWidth = width != null ? width : canvas.width;
    _viewportHeight = height != null ? height : canvas.height;

    _gl.viewport(_viewportX, _viewportY, _viewportWidth, _viewportHeight);
  }

  /// Sets the scissor area from (x, y) to (x + width, y + height).
  void setScissor(int x, int y, int width, int height) {
    _gl.scissor(x, y, width, height);
  }

  /// Enable the scissor test. When this is enabled, only the pixels within the defined 
  /// scissor area will be affected by further renderer actions.
  void enableScissorTest(bool enable) {
    enable ? _gl.enable(gl.SCISSOR_TEST) : _gl.disable(gl.SCISSOR_TEST);
  }

  /// Sets the clear color and opacity.
  /// 
  ///     // Creates a renderer with red background
  ///     var renderer = new WebGLRenderer()
  ///         ..setSize(200, 100)
  ///         ..setClearColor(0xff0000, 1);
  void setClearColor(color, [int alpha = 1]) {
    _clearColor.setFrom(color);
    _clearAlpha = alpha;

    _gl.clearColor(_clearColor.r, _clearColor.g, _clearColor.b, _clearAlpha);
  }

  /// Tells the renderer to clear its color, depth or stencil drawing buffer(s).
  /// If no parameters are passed, no buffer will be cleared.
  void clear([bool color = true, bool depth = true, bool stencil = true]) {
    var bits = 0;

    if (color) bits |= gl.COLOR_BUFFER_BIT;
    if (depth) bits |= gl.DEPTH_BUFFER_BIT;
    if (stencil) bits |= gl.STENCIL_BUFFER_BIT;

    _gl.clear(bits);
  }

  void clearTarget(WebGLRenderTarget renderTarget, bool color, bool depth, bool stencil) {
    setRenderTarget(renderTarget);
    clear(color, depth, stencil);
  }

  /// Initialises the postprocessing plugin, and adds it to the renderPluginsPost array.
  void addPostPlugin(plugin) {
    plugin.init(this);
    renderPluginsPost.add(plugin);
  }

  /// Initialises the preprocessing plugin, and adds it to the renderPluginsPre array.
  void addPrePlugin(plugin) {
    plugin.init(this);
    renderPluginsPre.add(plugin);
  }

  /// Tells the shadow map plugin to update using the passed scene and camera parameters.
  void updateShadowMap(Scene scene, Camera camera) {
    _currentProgram = null;
    _oldBlending = -1;
    _oldDepthTest = false;
    _oldDepthWrite = false;
    _currentGeometryGroupHash = -1;
    _currentMaterialId = -1;
    _lightsNeedUpdate = true;
    _oldDoubleSided = false;
    _oldFlipSided = false;

    shadowMapPlugin.update(scene, camera);
  }

  /* 
   * Internal functions
   */

  // Buffer allocation
  void createParticleBuffers(WebGLGeometry geometry) {
    geometry.__webglVertexBuffer = _gl.createBuffer();
    geometry.__webglColorBuffer = _gl.createBuffer();

    info.memory.geometries++;
  }

  void createLineBuffers(WebGLGeometry geometry) {
    geometry.__webglVertexBuffer = _gl.createBuffer();
    geometry.__webglColorBuffer = _gl.createBuffer();
    geometry.__webglLineDistanceBuffer = _gl.createBuffer();

    info.memory.geometries++;
  }

  void createRibbonBuffers(WebGLGeometry geometry) {
    geometry.__webglVertexBuffer = _gl.createBuffer();
    geometry.__webglColorBuffer = _gl.createBuffer();
    geometry.__webglNormalBuffer = _gl.createBuffer();

    info.memory.geometries++;
  }

  void createMeshBuffers(WebGLGeometry geometryGroup) {
    geometryGroup.__webglVertexBuffer = _gl.createBuffer();
    geometryGroup.__webglNormalBuffer = _gl.createBuffer();
    geometryGroup.__webglTangentBuffer = _gl.createBuffer();
    geometryGroup.__webglColorBuffer = _gl.createBuffer();
    geometryGroup.__webglUVBuffer = _gl.createBuffer();
    geometryGroup.__webglUV2Buffer = _gl.createBuffer();

    geometryGroup.__webglSkinIndicesBuffer = _gl.createBuffer();
    geometryGroup.__webglSkinWeightsBuffer = _gl.createBuffer();

    geometryGroup.__webglFaceBuffer = _gl.createBuffer();
    geometryGroup.__webglLineBuffer = _gl.createBuffer();
    
    if (geometryGroup.numMorphTargets != null) {
      geometryGroup.__webglMorphTargetsBuffers = [];

      for (var m = 0; m < geometryGroup.numMorphTargets; m++) {
        geometryGroup.__webglMorphTargetsBuffers.add(_gl.createBuffer());
      }
    }

    if (geometryGroup.numMorphNormals != null) {
      geometryGroup.__webglMorphNormalsBuffers = [];

      for (var m = 0; m < geometryGroup.numMorphNormals; m++) {
        geometryGroup.__webglMorphNormalsBuffers.add(_gl.createBuffer());
      }
    }

    info.memory.geometries++;
  }

  // Events

  void onGeometryDispose(Event event) {
    var geometry = event.target;

    geometry.removeEventListener('dispose', onGeometryDispose);
    deallocateGeometry(geometry);
  }

  void onTextureDispose(Event event) {
    var texture = event.target;

    texture.removeEventListener('dispose', onTextureDispose);
    deallocateTexture(texture);
    info.memory.textures--;
  }

  void onRenderTargetDispose(Event event) {
    var renderTarget = event.target;

    renderTarget.removeEventListener('dispose', onRenderTargetDispose);
    deallocateRenderTarget(renderTarget);
    info.memory.textures--;
  }

  void onMaterialDispose(Event event) {
    var material = event.target;

    material.removeEventListener('dispose', onMaterialDispose);
    deallocateMaterial(material);
  }

  // Buffer deallocation
  void deleteBuffers(Geometry geometry) {
    var glGeometry = new WebGLGeometry.from(geometry);
    
    glGeometry.__webglInit = null;

    if (glGeometry.__webglVertexBuffer != null) _gl.deleteBuffer(glGeometry.__webglVertexBuffer);
    if (glGeometry.__webglNormalBuffer != null) _gl.deleteBuffer(glGeometry.__webglNormalBuffer);
    if (glGeometry.__webglTangentBuffer != null) _gl.deleteBuffer(glGeometry.__webglTangentBuffer);
    if (glGeometry.__webglColorBuffer != null) _gl.deleteBuffer(glGeometry.__webglColorBuffer);
    if (glGeometry.__webglUVBuffer != null) _gl.deleteBuffer(glGeometry.__webglUVBuffer);
    if (glGeometry.__webglUV2Buffer != null) _gl.deleteBuffer(glGeometry.__webglUV2Buffer);

    if (glGeometry.__webglSkinIndicesBuffer != null) _gl.deleteBuffer(glGeometry.__webglSkinIndicesBuffer);
    if (glGeometry.__webglSkinWeightsBuffer != null) _gl.deleteBuffer(glGeometry.__webglSkinWeightsBuffer);

    if (glGeometry.__webglFaceBuffer != null) _gl.deleteBuffer(glGeometry.__webglFaceBuffer);
    if (glGeometry.__webglLineBuffer != null) _gl.deleteBuffer(glGeometry.__webglLineBuffer);

    if (glGeometry.__webglLineDistanceBuffer != null) _gl.deleteBuffer(glGeometry.__webglLineDistanceBuffer);
    
    //custom attributes
    if (glGeometry.__webglCustomAttributesList != null) {
      glGeometry.__webglCustomAttributesList.forEach((cal) => _gl.deleteBuffer(cal.buffer));
    }
    
    info.memory.geometries--;
  }
  
  void deallocateGeometry(IGeometry geometry) {
    var glGeometry = new WebGLGeometry.from(geometry);
    
    glGeometry.__webglInit = null;
    
    if (glGeometry.isBufferGeometry) {
      glGeometry.attributes.forEach((_, attribute) {
        if (attribute.buffer != null) {
          _gl.deleteBuffer(attribute.buffer);
        }
      });
      
      info.memory.geometries--;
    } else {
      if (glGeometry.geometryGroups != null) {
        for (var g in glGeometry.geometryGroups) {
          var geometryGroup = glGeometry.geometryGroups[g];
          
          if (geometryGroup.numMorphTargest != null) {
            for (var m = 0; m < geometryGroup.numMorphNormals; m++) {
              _gl.deleteBuffer(geometryGroup.__webglMorphNormalsBuffers[m]);
            }
          }
          
          deleteBuffers(geometryGroup);
        }
      } else {
        deleteBuffers(geometry);
      }
    }
  }

  void deallocateTexture(Texture texture) {
    if (texture.image && texture.image.__webglTextureCube) {
      // cube texture
      _gl.deleteTexture(texture.image.__webglTextureCube);
    } else {
      // 2D texture
      if (!texture["__webglInit"]) return;

      texture["__webglInit"] = false;
      _gl.deleteTexture(texture["__webglTexture"]);
    }
  }

  void deallocateRenderTarget(WebGLRenderTarget renderTarget) {
    if (renderTarget == null || renderTarget.__webglTexture == null) return;

    _gl.deleteTexture(renderTarget.__webglTexture);

    if (renderTarget is WebGLRenderTargetCube) {
      for (var i = 0; i < 6; i++) {
        _gl.deleteFramebuffer(renderTarget.__webglFramebuffer[i]);
        _gl.deleteRenderbuffer(renderTarget.__webglRenderbuffer[i]);
      }
    } else {
      _gl.deleteFramebuffer(renderTarget.__webglFramebuffer);
      _gl.deleteRenderbuffer(renderTarget.__webglRenderbuffer);
    }
  }

  void deallocateMaterial(WebGLMaterial material) {
    var program = material.program;

    if (program == null) return;

    material.program = null;

    // only deallocate GL program if this was the last use of shared program
    // assumed there is only single copy of any program in the _programs list
    // (that's how it's constructed)

    var programInfo;
    var deleteProgram = false;
    
    for (var i = 0; i < _programs.length; i++) {
      programInfo = _programs[i];

      if (programInfo.glProgram == program) {
        programInfo.usedTimes--;

        if (programInfo.usedTimes == 0) {
          deleteProgram = true;
        }
        
        break;
      }
    }

    if (deleteProgram == true) {
      // avoid using array.splice, this is costlier than creating new array from scratch
      var newPrograms = [];

      for (var i = 0; i < _programs.length; i++) {
        programInfo = _programs[i];

        if (programInfo.glProgram != program) {
            newPrograms.add(programInfo);
        }
      }
      
      _programs = newPrograms;
      _gl.deleteProgram(program);
      info.memory.programs--;
    }
  }

  // Buffer initialization
  void initCustomAttributes(WebGLGeometry geometry, WebGLObject object) {
    var nvertices = geometry.vertices.length;
    var material = object.webglmaterial;

    if (material.attributes != null) {
      if (geometry.__webglCustomAttributesList == null) {
        geometry.__webglCustomAttributesList = [];
      }

      material.attributes.forEach((attributeName, attribute) {
        if(!attribute.__webglInitialized || attribute.createUniqueBuffers) {
          attribute.__webglInitialized = true;

          attribute.array = new Float32List(nvertices * attribute.size);

          attribute.buffer = new WebGLRendererBuffer(_gl);
          attribute.buffer.belongsToAttribute = attributeName;

          attribute.needsUpdate = true;
        }
        
        geometry.__webglCustomAttributesList.add(attribute);
      });
    }
  }

  void initParticleBuffers(WebGLGeometry geometry, WebGLObject object) {
    var nvertices = geometry.vertices.length;

    geometry.__vertexArray = new Float32List(nvertices * 3);
    geometry.__colorArray = new Float32List(nvertices * 3);
    geometry.__sortArray = [];
    geometry.__webglParticleCount = nvertices;

    initCustomAttributes (geometry, object);
  }

  void initLineBuffers(WebGLGeometry geometry, WebGLObject object) {
    var nvertices = geometry.vertices.length;
  
    geometry.__vertexArray = new Float32List(nvertices * 3);
    geometry.__colorArray = new Float32List(nvertices * 3);
    geometry.__lineDistanceArray = new Float32List(nvertices * 1);
    geometry.__webglLineCount = nvertices;
  
    initCustomAttributes (geometry, object);
  }

  void initMeshBuffers(WebGLGeometry geometryGroup, WebGLObject object) {
    var geometry = object.geometry,
        faces3 = geometryGroup.faces3,

        nvertices = faces3.length * 3,
        ntris     = faces3.length * 1,
        nlines    = faces3.length * 3;

    WebGLMaterial material = getBufferMaterial(object, geometryGroup);

    var uvType = bufferGuessUVType(material),
        normalType = bufferGuessNormalType(material);
    
    geometryGroup.__vertexArray = new Float32List(nvertices * 3);

    if (normalType != NO_SHADING) {
      geometryGroup.__normalArray = new Float32List(nvertices * 3);
    }

    if (geometry.hasTangents) {
      geometryGroup.__tangentArray = new Float32List(nvertices * 4);
    }

    if (material.vertexColors != NO_COLORS) {
      geometryGroup.__colorArray = new Float32List(nvertices * 3);
    }

    if (uvType) {
      if (geometry.faceVertexUvs.length > 0) {
        geometryGroup.__uvArray = new Float32List(nvertices * 2);
      }

      if (geometry.faceVertexUvs.length > 1) {
        geometryGroup.__uv2Array = new Float32List(nvertices * 2);
      }
    }

    if (!object.geometry.skinWeights.isEmpty && !object.geometry.skinIndices.isEmpty) {
      geometryGroup.__skinIndexArray = new Float32List(nvertices * 4);
      geometryGroup.__skinWeightArray = new Float32List(nvertices * 4);
    }

    geometryGroup.__faceArray = new Uint16List(ntris * 3);
    geometryGroup.__lineArray = new Uint16List(nlines * 2);

    if (geometryGroup.numMorphTargets != null) {
      geometryGroup.__morphTargetsArrays = [];
      
      for (var m = 0; m < geometryGroup.numMorphTargets; m++) {
        geometryGroup.__morphTargetsArrays.add(new Float32List(nvertices * 3));
      }
    }

    if (geometryGroup.numMorphNormals != null) {
      geometryGroup.__morphNormalsArrays = [];
      
      for (var m = 0; m < geometryGroup.numMorphNormals; m++) {
        geometryGroup.__morphNormalsArrays.add(new Float32List(nvertices * 3));
      }
    }

    geometryGroup.__webglFaceCount = ntris * 3;
    geometryGroup.__webglLineCount = nlines * 2;

    // custom attributes
    if (material.attributes != null) {
      if (geometryGroup.__webglCustomAttributesList == null) {
        geometryGroup.__webglCustomAttributesList = [];
      }

    
      material.attributes.forEach((attributeName, attribute) {
        if(!attribute.__webglInitialized || attribute.createUniqueBuffers) {
          attribute.__webglInitialized = true;
          attribute.array = new Float32List(nvertices * attribute.size);
    
          var buffer = new WebGLRendererBuffer(_gl);
          buffer.belongsToAttribute = attributeName;
          attribute.buffer = buffer;
  
          // Do a shallow copy of the attribute object so different geometryGroup chunks use different
          // attribute buffers which are correctly indexed in the setMeshBuffers function
        
          var originalAttribute = attribute.clone();
              originalAttribute.needsUpdate = true;
              attribute.__original = originalAttribute;
        }
        
        geometryGroup.__webglCustomAttributesList.add(attribute);
      });
    }
    
    geometryGroup.__inittedArrays = true;
  }

  WebGLMaterial getBufferMaterial(WebGLObject object, WebGLGeometry geometryGroup) {
    Material material = (object.material is MeshFaceMaterial) 
        ? (object.material as MeshFaceMaterial).materials[geometryGroup.materialIndex]
        : object.material;

      return new WebGLMaterial.from(material);
  }
  
  int bufferGuessNormalType(WebGLMaterial material) {
    // only MeshBasicMaterial and MeshDepthMaterial don't need normals
    if ((material is MeshBasicMaterial && material.envMap == null) || material is MeshDepthMaterial) {
      return NO_SHADING;
    }

    if (material.needsSmoothNormals) return SMOOTH_SHADING;
    
    return FLAT_SHADING;
  }

  bool bufferGuessUVType(WebGLMaterial material) {
    // material must use some texture to require uvs
    if (material.map != null ||     
        material.lightMap != null ||
        material.bumpMap != null ||
        material.normalMap != null ||
        material.specularMap != null ||
        material is ShaderMaterial) {
      return true;
    }

    return false;
  }

  void initDirectBuffers(BufferGeometry geometry) {
    var type;

    geometry.attributes.forEach((attributeName, attribute) {
      if (attributeName == "index") {
        type = gl.ELEMENT_ARRAY_BUFFER;
      } else {
        type = gl.ARRAY_BUFFER;
      }

      if (attribute.numItems == null) {
        attribute.numItems = attribute.array.length;
      }

      attribute.buffer = new WebGLRendererBuffer(_gl);
      attribute.buffer.bind(type);
      _gl.bufferDataTyped(type, attribute.array, gl.STATIC_DRAW);
    });
  }

  // Buffer setting

  void setParticleBuffers(WebGLGeometry geometry, int hint, ParticleSystem object) {
    var vertexArray = geometry.__vertexArray,
        colorArray = geometry.__colorArray,
        sortArray = geometry.__sortArray,
        customAttributes = geometry.__webglCustomAttributesList;

    if (object.sortParticles) {
      _projScreenMatrixPS.setFrom(_projScreenMatrix)..multiply(object.matrixWorld);
  
      for (var v = 0; v < geometry.vertices.length; v++) {
        var vertex = geometry.vertices[v];

        _vector3.setFrom(vertex)..applyProjection(_projScreenMatrixPS);

        sortArray[v] = [_vector3.z, v];
      }
  
      sortArray.sort(numericalSort);
  
      for (var v = 0; v < geometry.vertices.length; v++) {
        var vertex = geometry.vertices[sortArray[v][1]];
  
        var offset = v * 3;
  
        vertexArray[offset]     = vertex.x;
        vertexArray[offset + 1] = vertex.y;
        vertexArray[offset + 2] = vertex.z;
      }
  
      for (var c = 0; c < geometry.colors.length; c++) {
        var offset = c * 3;
  
        var color = geometry.colors[sortArray[c][1]];
  
        colorArray[offset]     = color.r;
        colorArray[offset + 1] = color.g;
        colorArray[offset + 2] = color.b;
      }

      if (customAttributes != null) {
        for (var i = 0; i < customAttributes.length; i++) {
          var customAttribute = customAttributes[i];
          
          if (!(customAttribute.boundTo == null || customAttribute.boundTo == "vertices")) { 
            continue;
          }

          var offset = 0;
          var cal = customAttribute.value.length;

          if (customAttribute.size == 1) {
            for (var ca = 0; ca < cal; ca++) {
              var index = sortArray[ca][1];
              customAttribute.array[ca] = customAttribute.value[index];
            }
          } else if (customAttribute.size == 2) {
            for (var ca = 0; ca < cal; ca++) {
              var index = sortArray[ca][1];

              var value = customAttribute.value[index];

              customAttribute.array[offset]   = value.x;
              customAttribute.array[offset + 1] = value.y;

              offset += 2;
            }
          } else if (customAttribute.size == 3) {
            if (customAttribute.type == "c") {
              for (var ca = 0; ca < cal; ca++) {
                var index = sortArray[ca][1];

                var value = customAttribute.value[index];

                customAttribute.array[offset]     = value.r;
                customAttribute.array[offset + 1] = value.g;
                customAttribute.array[offset + 2] = value.b;

                offset += 3;
              }
            } else {
              for (var ca = 0; ca < cal; ca++) {
                var index = sortArray[ca][1];

                var value = customAttribute.value[index];

                customAttribute.array[offset]   = value.x;
                customAttribute.array[offset + 1] = value.y;
                customAttribute.array[offset + 2] = value.z;

                offset += 3;
              }
            }
          } else if (customAttribute.size == 4) {
            for (var ca = 0; ca < cal; ca++) {
              var index = sortArray[ca][1];

              var value = customAttribute.value[index];

              customAttribute.array[offset]     = value.x;
              customAttribute.array[offset + 1] = value.y;
              customAttribute.array[offset + 2] = value.z;
              customAttribute.array[offset + 3] = value.w;

              offset += 4;
            }
          }
        }
      }
    } else {
      if (geometry.verticesNeedUpdate) {
        for (var v = 0; v < geometry.vertices.length; v++) {
          var vertex = geometry.vertices[v];

          var offset = v * 3;

          vertexArray[offset]     = vertex.x;
          vertexArray[offset + 1] = vertex.y;
          vertexArray[offset + 2] = vertex.z;
        }
      }

      if (geometry.colorsNeedUpdate) {
          for (var c = 0; c < geometry.colors.length; c++) {
              var color = geometry.colors[c];

              var offset = c * 3;

              colorArray[offset]     = color.r;
              colorArray[offset + 1] = color.g;
              colorArray[offset + 2] = color.b;
          }
      }
        
      if (customAttributes != null) {
        for (var i = 0; i < customAttributes.length; i++) {
          var customAttribute = customAttributes[i];

          if (customAttribute.needsUpdate &&
              (customAttribute.boundTo == null || customAttribute.boundTo == "vertices")) {
            var offset = 0;
            var cal = customAttribute.value.length;

            if (customAttribute.size == 1) {
              for (var ca = 0; ca < cal; ca++) {
                customAttribute.array[ca] = customAttribute.value[ca];
              }
            } else if (customAttribute.size == 2) {
              for (var ca = 0; ca < cal; ca++) {
                var value = customAttribute.value[ca];

                customAttribute.array[offset]     = value.x;
                customAttribute.array[offset + 1] = value.y;

                offset += 2;
              }
            } else if (customAttribute.size == 3) {
              if (customAttribute.type == "c") {
                for (var ca = 0; ca < cal; ca++) {
                  var value = customAttribute.value[ca];

                  customAttribute.array[offset]     = value.r;
                  customAttribute.array[offset + 1] = value.g;
                  customAttribute.array[offset + 2] = value.b;

                  offset += 3;
                }
              } else {
                for (var ca = 0; ca < cal; ca++) {
                  var value = customAttribute.value[ca];

                  customAttribute.array[offset]     = value.x;
                  customAttribute.array[offset + 1] = value.y;
                  customAttribute.array[offset + 2] = value.z;

                  offset += 3;
                }
              }
            } else if (customAttribute.size == 4) {
              for (var ca = 0; ca < cal; ca++) {
                var value = customAttribute.value[ca];

                customAttribute.array[offset]      = value.x;
                customAttribute.array[offset + 1] = value.y;
                customAttribute.array[offset + 2] = value.z;
                customAttribute.array[offset + 3] = value.w;

                offset += 4;
              }
            }
          }
        }
      }
    }

    if (geometry.verticesNeedUpdate || object.sortParticles) {
      _gl.bindBuffer(gl.ARRAY_BUFFER, geometry.__webglVertexBuffer);
      _gl.bufferDataTyped(gl.ARRAY_BUFFER, vertexArray, hint);
    }

    if (geometry.colorsNeedUpdate || object.sortParticles) {
      _gl.bindBuffer(gl.ARRAY_BUFFER, geometry.__webglColorBuffer);
      _gl.bufferDataTyped(gl.ARRAY_BUFFER, colorArray, hint);
    }

    if (customAttributes != null) {
      for (var i = 0; i < customAttributes.length; i++) {
        var customAttribute = customAttributes[i];

        if (customAttribute.needsUpdate || object.sortParticles) {
          customAttribute.buffer.bind(gl.ARRAY_BUFFER);
          _gl.bufferDataTyped(gl.ARRAY_BUFFER, customAttribute.array, hint);
        }
      }
    }
  }

  void setLineBuffers(WebGLGeometry geometry, int hint) {
    var vertexArray = geometry.__vertexArray,
        colorArray = geometry.__colorArray,
        lineDistanceArray = geometry.__lineDistanceArray,

        customAttributes = geometry.__webglCustomAttributesList;

    if (geometry.verticesNeedUpdate) {
      for (var v = 0; v < geometry.vertices.length; v++) {
        var vertex = geometry.vertices[v];
  
        var offset = v * 3;
  
        vertexArray[offset]     = vertex.x;
        vertexArray[offset + 1] = vertex.y;
        vertexArray[offset + 2] = vertex.z;
      }

      _gl.bindBuffer(gl.ARRAY_BUFFER, geometry.__webglVertexBuffer);
      _gl.bufferDataTyped(gl.ARRAY_BUFFER, vertexArray, hint);
    }

    if (geometry.colorsNeedUpdate) {
      for (var c = 0; c < geometry.colors.length; c++) {
        var color = geometry.colors[c];

        var offset = c * 3;

        colorArray[offset]     = color.r;
        colorArray[offset + 1] = color.g;
        colorArray[offset + 2] = color.b;
      }
  
      _gl.bindBuffer(gl.ARRAY_BUFFER, geometry.__webglColorBuffer);
      _gl.bufferDataTyped(gl.ARRAY_BUFFER, colorArray, hint);  
    }

    if (geometry.lineDistancesNeedUpdate) {
      lineDistanceArray = new Float32List.fromList(geometry.lineDistances);

      _gl.bindBuffer(gl.ARRAY_BUFFER, geometry.__webglLineDistanceBuffer);
      _gl.bufferDataTyped(gl.ARRAY_BUFFER, lineDistanceArray, hint);
    }

    if (geometry.__webglCustomAttributesList != null) {
      geometry.__webglCustomAttributesList.forEach((customAttribute) {
        if (customAttribute.needsUpdate && 
            (customAttribute.boundTo == null || customAttribute.boundTo == "vertices")) {
          var offset = 0;

          if (customAttribute.size == 1) {
            customAttribute.array = new List.from(customAttribute.value);
          } else if (customAttribute.size == 2) {
            customAttribute.value.forEach((value) {
              customAttribute.array[offset]     = value.x;
              customAttribute.array[offset + 1] = value.y;

              offset += 2;
            });
          } else if (customAttribute.size == 3) {
            if (customAttribute.type == "c") {
              customAttribute.value.forEach((value) {
                customAttribute.array[offset]     = value.r;
                customAttribute.array[offset + 1] = value.g;
                customAttribute.array[offset + 2] = value.b;
  
                offset += 3;
              });
            } else {
              customAttribute.value.forEach((value) {
                customAttribute.array[offset]     = value.x;
                customAttribute.array[offset + 1] = value.y;
                customAttribute.array[offset + 2] = value.z;

                offset += 3;
              });
            }
          } else if (customAttribute.size == 4) {
            customAttribute.value.forEach((value) {
              customAttribute.array[offset]      = value.x;
              customAttribute.array[offset + 1] = value.y;
              customAttribute.array[offset + 2] = value.z;
              customAttribute.array[offset + 3] = value.w;

              offset += 4;
            });
          }

          customAttribute.buffer.bind(gl.ARRAY_BUFFER);
          _gl.bufferDataTyped(gl.ARRAY_BUFFER, customAttribute.array, hint);
        }
      });
    }
  }

  void setMeshBuffers(WebGLGeometry geometryGroup, WebGLObject object, int hint, bool dispose, WebGLMaterial material) {
    if (!geometryGroup.__inittedArrays) return;

    var normalType = bufferGuessNormalType(material),
        uvType = bufferGuessUVType(material),

        needsSmoothNormals = normalType == SMOOTH_SHADING;

    var vertexIndex = 0,

        offset = 0,
        offset_uv = 0,
        offset_uv2 = 0,
        offset_face = 0,
        offset_normal = 0,
        offset_tangent = 0,
        offset_line = 0,
        offset_color = 0,
        offset_skin = 0,
        offset_morphTarget = 0,
        offset_custom = 0,
        offset_customSrc = 0,
  
        vertexArray = geometryGroup.__vertexArray,
        uvArray = geometryGroup.__uvArray,
        uv2Array = geometryGroup.__uv2Array,
        normalArray = geometryGroup.__normalArray,
        tangentArray = geometryGroup.__tangentArray,
        colorArray = geometryGroup.__colorArray,

        skinIndexArray = geometryGroup.__skinIndexArray,
        skinWeightArray = geometryGroup.__skinWeightArray,

        morphTargetsArrays = geometryGroup.__morphTargetsArrays,
        morphNormalsArrays = geometryGroup.__morphNormalsArrays,

        customAttributes = geometryGroup.__webglCustomAttributesList,

        faceArray = geometryGroup.__faceArray,
        lineArray = geometryGroup.__lineArray,

        geometry = object.webglgeometry, // this is shared for all chunks

        dirtyVertices = geometry.verticesNeedUpdate,
        dirtyElements = geometry.elementsNeedUpdate,
        dirtyUvs = geometry.uvsNeedUpdate,
        dirtyNormals = geometry.normalsNeedUpdate,
        dirtyTangents = geometry.tangentsNeedUpdate,
        dirtyColors = geometry.colorsNeedUpdate,
        dirtyMorphTargets = geometry.morphTargetsNeedUpdate,

        vertices = geometry.vertices,
        chunk_faces3 = geometryGroup.faces3,
        obj_faces = geometry.faces,

        obj_uvs  = geometry.faceVertexUvs.length == 0 ? [] : geometry.faceVertexUvs[0],
        obj_uvs2 = geometry.faceVertexUvs.length > 1 ? geometry.faceVertexUvs[1] : null,

        obj_colors = geometry.colors,

        obj_skinIndices = geometry.skinIndices,
        obj_skinWeights = geometry.skinWeights,

        morphTargets = geometry.morphTargets,
        morphNormals = geometry.morphNormals;
     
    if (dirtyVertices) {
      chunk_faces3.forEach((f) {
        var face = obj_faces[f];

        var v1 = vertices[face.a],
            v2 = vertices[face.b],
            v3 = vertices[face.c];

        vertexArray[offset]     = v1.x;
        vertexArray[offset + 1] = v1.y;
        vertexArray[offset + 2] = v1.z;

        vertexArray[offset + 3] = v2.x;
        vertexArray[offset + 4] = v2.y;
        vertexArray[offset + 5] = v2.z;

        vertexArray[offset + 6] = v3.x;
        vertexArray[offset + 7] = v3.y;
        vertexArray[offset + 8] = v3.z;

        offset += 9;
      });
       
      _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglVertexBuffer);
      _gl.bufferDataTyped(gl.ARRAY_BUFFER, vertexArray, hint); 
    }

    if (dirtyMorphTargets) {
      for (var vk = 0; vk < morphTargets.length; vk++) {
        offset_morphTarget = 0;

        chunk_faces3.forEach((chf) {
          var face = obj_faces[chf];

          // morph positions
          var v1 = morphTargets[vk].vertices[face.a],
              v2 = morphTargets[vk].vertices[face.b],
              v3 = morphTargets[vk].vertices[face.c];

          var vka = morphTargetsArrays[vk];

          vka[offset_morphTarget]     = v1.x;
          vka[offset_morphTarget + 1] = v1.y;
          vka[offset_morphTarget + 2] = v1.z;

          vka[offset_morphTarget + 3] = v2.x;
          vka[offset_morphTarget + 4] = v2.y;
          vka[offset_morphTarget + 5] = v2.z;

          vka[offset_morphTarget + 6] = v3.x;
          vka[offset_morphTarget + 7] = v3.y;
          vka[offset_morphTarget + 8] = v3.z;

          // morph normals
          if (material.morphNormals) {
            var n1, n2, n3;
            
            if (needsSmoothNormals) {
              var faceVertexNormals = morphNormals[vk].vertexNormals[chf];

              n1 = faceVertexNormals.a;
              n2 = faceVertexNormals.b;
              n3 = faceVertexNormals.c;
            } else {
              n1 = morphNormals[vk].faceNormals[chf];
              n2 = n1;
              n3 = n1;
            }

            var nka = morphNormalsArrays[vk];

            nka[offset_morphTarget]     = n1.x;
            nka[offset_morphTarget + 1] = n1.y;
            nka[offset_morphTarget + 2] = n1.z;

            nka[offset_morphTarget + 3] = n2.x;
            nka[offset_morphTarget + 4] = n2.y;
            nka[offset_morphTarget + 5] = n2.z;

            nka[offset_morphTarget + 6] = n3.x;
            nka[offset_morphTarget + 7] = n3.y;
            nka[offset_morphTarget + 8] = n3.z;
          }

          //

          offset_morphTarget += 9;
        });

        _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglMorphTargetsBuffers[vk]);
        _gl.bufferDataTyped(gl.ARRAY_BUFFER, morphTargetsArrays[vk], hint);

        if (material.morphNormals) {
          _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglMorphNormalsBuffers[vk]);
          _gl.bufferDataTyped(gl.ARRAY_BUFFER, morphNormalsArrays[vk], hint);
        }
      }
    }
    
    if (!obj_skinWeights.isEmpty) {
      chunk_faces3.forEach((chf) {
        var face = obj_faces[chf];
        
        // weights
        var sw1 = obj_skinWeights[face.a],
            sw2 = obj_skinWeights[face.b],
            sw3 = obj_skinWeights[face.c];

        skinWeightArray[offset_skin]      = sw1.x;
        skinWeightArray[offset_skin + 1]  = sw1.y;
        skinWeightArray[offset_skin + 2]  = sw1.z;
        skinWeightArray[offset_skin + 3]  = sw1.w;

        skinWeightArray[offset_skin + 4]  = sw2.x;
        skinWeightArray[offset_skin + 5]  = sw2.y;
        skinWeightArray[offset_skin + 6]  = sw2.z;
        skinWeightArray[offset_skin + 7]  = sw2.w;

        skinWeightArray[offset_skin + 8]  = sw3.x;
        skinWeightArray[offset_skin + 9]  = sw3.y;
        skinWeightArray[offset_skin + 10] = sw3.z;
        skinWeightArray[offset_skin + 11] = sw3.w;

        // indices
        var si1 = obj_skinIndices[face.a],
            si2 = obj_skinIndices[face.b],
            si3 = obj_skinIndices[face.c];

        skinIndexArray[offset_skin]      = si1.x;
        skinIndexArray[offset_skin + 1]  = si1.y;
        skinIndexArray[offset_skin + 2]  = si1.z;
        skinIndexArray[offset_skin + 3]  = si1.w; 

        skinIndexArray[offset_skin + 4]  = si2.x;
        skinIndexArray[offset_skin + 5]  = si2.y;
        skinIndexArray[offset_skin + 6]  = si2.z;
        skinIndexArray[offset_skin + 7]  = si2.w;

        skinIndexArray[offset_skin + 8]  = si3.x;
        skinIndexArray[offset_skin + 9]  = si3.y;
        skinIndexArray[offset_skin + 10] = si3.z;
        skinIndexArray[offset_skin + 11] = si3.w;

        offset_skin += 12;
      });

      if (offset_skin > 0) {
        _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglSkinIndicesBuffer);
        _gl.bufferDataTyped(gl.ARRAY_BUFFER, skinIndexArray, hint);

        _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglSkinWeightsBuffer);
        _gl.bufferDataTyped(gl.ARRAY_BUFFER, skinWeightArray, hint);
      }
    }

    if (dirtyColors && material.vertexColors != NO_COLORS) {
      chunk_faces3.forEach((chf) {
        var face = obj_faces[chf];

        var vertexColors = face.vertexColors,
            faceColor = face.color;
        
        var c1, c2, c3;
        
        if (vertexColors.length == 3 && material.vertexColors == VERTEX_COLORS) {
          c1 = vertexColors[0];
          c2 = vertexColors[1];
          c3 = vertexColors[2];
        } else {
          c1 = faceColor;
          c2 = faceColor;
          c3 = faceColor;
        }

        colorArray[offset_color]     = c1.r;
        colorArray[offset_color + 1] = c1.g;
        colorArray[offset_color + 2] = c1.b;

        colorArray[offset_color + 3] = c2.r;
        colorArray[offset_color + 4] = c2.g;
        colorArray[offset_color + 5] = c2.b;

        colorArray[offset_color + 6] = c3.r;
        colorArray[offset_color + 7] = c3.g;
        colorArray[offset_color + 8] = c3.b;

        offset_color += 9;
      });

      if (offset_color > 0) {
        _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglColorBuffer);
        _gl.bufferDataTyped(gl.ARRAY_BUFFER, colorArray, hint);
      }
    }

    if (dirtyTangents && geometry.hasTangents) {
      chunk_faces3.forEach((chf) {
        var face = obj_faces[chf];

        var vertexTangents = face.vertexTangents;

        var t1 = vertexTangents[0],
            t2 = vertexTangents[1],
            t3 = vertexTangents[2];

        tangentArray[offset_tangent]     = t1.x;
        tangentArray[offset_tangent + 1] = t1.y;
        tangentArray[offset_tangent + 2] = t1.z;
        tangentArray[offset_tangent + 3] = t1.w;

        tangentArray[offset_tangent + 4] = t2.x;
        tangentArray[offset_tangent + 5] = t2.y;
        tangentArray[offset_tangent + 6] = t2.z;
        tangentArray[offset_tangent + 7] = t2.w;

        tangentArray[offset_tangent + 8]  = t3.x;
        tangentArray[offset_tangent + 9]  = t3.y;
        tangentArray[offset_tangent + 10] = t3.z;
        tangentArray[offset_tangent + 11] = t3.w;

        offset_tangent += 12;
      });
      
      _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglTangentBuffer);
      _gl.bufferDataTyped(gl.ARRAY_BUFFER, tangentArray, hint);
    }

    if (dirtyNormals && normalType != NO_SHADING) {
      chunk_faces3.forEach((chf) {
        var face = obj_faces[chf];
        
        var vertexNormals = face.vertexNormals,
            faceNormal = face.normal;

        if (!vertexNormals.contains(null) && needsSmoothNormals) { 
          for (var i = 0; i < 3; i++) {
            var vn = vertexNormals[i];

            normalArray[offset_normal]     = vn.x;
            normalArray[offset_normal + 1] = vn.y;
            normalArray[offset_normal + 2] = vn.z;

            offset_normal += 3;
          }
        } else {
          for (var i = 0; i < 3; i++) {
            normalArray[offset_normal]     = faceNormal.x;
            normalArray[offset_normal + 1] = faceNormal.y;
            normalArray[offset_normal + 2] = faceNormal.z;

            offset_normal += 3;
          }
        }
      });
      
      _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglNormalBuffer);
      _gl.bufferDataTyped(gl.ARRAY_BUFFER, normalArray, hint);
    }

    if (dirtyUvs && !obj_uvs.isEmpty && uvType) {
      chunk_faces3.where((e) => obj_uvs[e] != null).forEach((chf) {
        var uv = obj_uvs[chf];

        for (var i = 0; i < 3; i++) {
          var uvi = uv[i];

          uvArray[offset_uv]     = uvi.x;
          uvArray[offset_uv + 1] = uvi.y;

          offset_uv += 2;
        }
      });   

      if (offset_uv > 0) {
        _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglUVBuffer);
        _gl.bufferDataTyped(gl.ARRAY_BUFFER, uvArray, hint);
      }
    }

    if (dirtyUvs && obj_uvs2 != null && uvType) {
      chunk_faces3.where((e) => obj_uvs2[e] != null).forEach((chf) {
        var uv2 = obj_uvs2[chf];
        
        for (var i = 0; i < 3; i++) {
          var uv2i = uv2[i];

          uv2Array[offset_uv2]     = uv2i.x;
          uv2Array[offset_uv2 + 1] = uv2i.y;

          offset_uv2 += 2;
        }
      });
      
      if (offset_uv2 > 0) {
        _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglUV2Buffer);
        _gl.bufferDataTyped(gl.ARRAY_BUFFER, uv2Array, hint);
      }
    }

    if (dirtyElements) {
      chunk_faces3.forEach((chf) {
        faceArray[offset_face]     = vertexIndex;
        faceArray[offset_face + 1] = vertexIndex + 1;
        faceArray[offset_face + 2] = vertexIndex + 2;

        offset_face += 3;

        lineArray[offset_line]     = vertexIndex;
        lineArray[offset_line + 1] = vertexIndex + 1;

        lineArray[offset_line + 2] = vertexIndex;
        lineArray[offset_line + 3] = vertexIndex + 2;

        lineArray[offset_line + 4] = vertexIndex + 1;
        lineArray[offset_line + 5] = vertexIndex + 2;

        offset_line += 6;

        vertexIndex += 3;
      });

      _gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, geometryGroup.__webglFaceBuffer);
      _gl.bufferDataTyped(gl.ELEMENT_ARRAY_BUFFER, faceArray, hint);

      _gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, geometryGroup.__webglLineBuffer);
      _gl.bufferDataTyped(gl.ELEMENT_ARRAY_BUFFER, lineArray, hint);
    }

    if (customAttributes != null) {
      customAttributes.where((e) => e.__original.needsUpdate).forEach((customAttribute) {
        offset_custom = 0;
        offset_customSrc = 0;

        if (customAttribute.size == 1) {
          if (customAttribute.boundTo == null || customAttribute.boundTo == "vertices") {
            for (var f = 0; f < chunk_faces3.length; f++) {
              var face = obj_faces[chunk_faces3[f]];

              customAttribute.array[offset_custom]       = customAttribute.value[face.a];
              customAttribute.array[offset_custom + 1] = customAttribute.value[face.b];
              customAttribute.array[offset_custom + 2] = customAttribute.value[face.c];

              offset_custom += 3;
            }
          } else if (customAttribute.boundTo == "faces") {
            for (var f = 0; f < chunk_faces3.length; f++) {
              var value = customAttribute.value[chunk_faces3[f]];

              customAttribute.array[offset_custom]       = value;
              customAttribute.array[offset_custom + 1] = value;
              customAttribute.array[offset_custom + 2] = value;

              offset_custom += 3;
            }
          }
        } else if (customAttribute.size == 2) {
          if (customAttribute.boundTo == null || customAttribute.boundTo == "vertices") {
            for (var f = 0; f < chunk_faces3.length; f++) {
              var face = obj_faces[chunk_faces3[f]];

              var v1 = customAttribute.value[face.a],
                  v2 = customAttribute.value[face.b],
                  v3 = customAttribute.value[face.c];

              customAttribute.array[offset_custom]       = v1.x;
              customAttribute.array[offset_custom + 1] = v1.y;

              customAttribute.array[offset_custom + 2] = v2.x;
              customAttribute.array[offset_custom + 3] = v2.y;

              customAttribute.array[offset_custom + 4] = v3.x;
              customAttribute.array[offset_custom + 5] = v3.y;

              offset_custom += 6;
            }
          } else if (customAttribute.boundTo == "faces") {
            for (var f = 0; f < chunk_faces3.length; f++) {

              var value = customAttribute.value[chunk_faces3[f]];

              var v1 = value,
                  v2 = value,
                  v3 = value;

              customAttribute.array[offset_custom]       = v1.x;
              customAttribute.array[offset_custom + 1] = v1.y;

              customAttribute.array[offset_custom + 2] = v2.x;
              customAttribute.array[offset_custom + 3] = v2.y;

              customAttribute.array[offset_custom + 4] = v3.x;
              customAttribute.array[offset_custom + 5] = v3.y;

              offset_custom += 6;

            }
          }
        } else if (customAttribute.size == 3) {
          var pp;

          if (customAttribute.type == "c") {
            pp = ["r", "g", "b"];
          } else {
            pp = ["x", "y", "z"];
          }

          if (customAttribute.boundTo == null || customAttribute.boundTo == "vertices") {
            for (var f = 0; f < chunk_faces3.length; f++) {
              var face = obj_faces[chunk_faces3[f]];

              var v1 = customAttribute.value[face.a],
                  v2 = customAttribute.value[face.b],
                  v3 = customAttribute.value[face.c];

              customAttribute.array[offset_custom]       = v1[pp[0]];
              customAttribute.array[offset_custom + 1] = v1[pp[1]];
              customAttribute.array[offset_custom + 2] = v1[pp[2]];

              customAttribute.array[offset_custom + 3] = v2[pp[0]];
              customAttribute.array[offset_custom + 4] = v2[pp[1]];
              customAttribute.array[offset_custom + 5] = v2[pp[2]];

              customAttribute.array[offset_custom + 6] = v3[pp[0]];
              customAttribute.array[offset_custom + 7] = v3[pp[1]];
              customAttribute.array[offset_custom + 8] = v3[pp[2]];

              offset_custom += 9;

            }
          } else if (customAttribute.boundTo == "faces") {
            for (var f = 0; f < chunk_faces3.length; f++) {
              var value = customAttribute.value[chunk_faces3[f]];

              var v1 = value,
                  v2 = value,
                  v3 = value;

              customAttribute.array[offset_custom]       = v1[pp[0]];
              customAttribute.array[offset_custom + 1] = v1[pp[1]];
              customAttribute.array[offset_custom + 2] = v1[pp[2]];

              customAttribute.array[offset_custom + 3] = v2[pp[0]];
              customAttribute.array[offset_custom + 4] = v2[pp[1]];
              customAttribute.array[offset_custom + 5] = v2[pp[2]];

              customAttribute.array[offset_custom + 6] = v3[pp[0]];
              customAttribute.array[offset_custom + 7] = v3[pp[1]];
              customAttribute.array[offset_custom + 8] = v3[pp[2]];

              offset_custom += 9;

            }
          } else if (customAttribute.boundTo == "faceVertices") {
            chunk_faces3.forEach((chunk_face) {
              var value = customAttribute.value[chunk_face];

              var v1 = value[0],
                  v2 = value[1],
                  v3 = value[2];

              customAttribute.array[offset_custom]     = v1[pp[0]];
              customAttribute.array[offset_custom + 1] = v1[pp[1]];
              customAttribute.array[offset_custom + 2] = v1[pp[2]];

              customAttribute.array[offset_custom + 3] = v2[pp[0]];
              customAttribute.array[offset_custom + 4] = v2[pp[1]];
              customAttribute.array[offset_custom + 5] = v2[pp[2]];

              customAttribute.array[offset_custom + 6] = v3[pp[0]];
              customAttribute.array[offset_custom + 7] = v3[pp[1]];
              customAttribute.array[offset_custom + 8] = v3[pp[2]];

              offset_custom += 9;
            });
          }
        } else if (customAttribute.size == 4) {
          if (customAttribute.boundTo == null || customAttribute.boundTo == "vertices") {
            chunk_faces3.forEach((chunk_face) {
              var face = obj_faces[chunk_face];

              var v1 = customAttribute.value[face.a],
                  v2 = customAttribute.value[face.b],
                  v3 = customAttribute.value[face.c];

              customAttribute.array[offset_custom]      = v1.x;
              customAttribute.array[offset_custom + 1]  = v1.y;
              customAttribute.array[offset_custom + 2]  = v1.z;
              customAttribute.array[offset_custom + 3]  = v1.w;

              customAttribute.array[offset_custom + 4]  = v2.x;
              customAttribute.array[offset_custom + 5]  = v2.y;
              customAttribute.array[offset_custom + 6]  = v2.z;
              customAttribute.array[offset_custom + 7]  = v2.w;

              customAttribute.array[offset_custom + 8]  = v3.x;
              customAttribute.array[offset_custom + 9]  = v3.y;
              customAttribute.array[offset_custom + 10] = v3.z;
              customAttribute.array[offset_custom + 11] = v3.w;

              offset_custom += 12;
            }); 
          } else if (customAttribute.boundTo == "faces") {
            chunk_faces3.forEach((chunk_face) {
              var value = customAttribute.value[chunk_face];

              var v1 = value,
                  v2 = value,
                  v3 = value;

              customAttribute.array[offset_custom]      = v1.x;
              customAttribute.array[offset_custom + 1]  = v1.y;
              customAttribute.array[offset_custom + 2]  = v1.z;
              customAttribute.array[offset_custom + 3]  = v1.w;

              customAttribute.array[offset_custom + 4]  = v2.x;
              customAttribute.array[offset_custom + 5]  = v2.y;
              customAttribute.array[offset_custom + 6]  = v2.z;
              customAttribute.array[offset_custom + 7]  = v2.w;

              customAttribute.array[offset_custom + 8]  = v3.x;
              customAttribute.array[offset_custom + 9]  = v3.y;
              customAttribute.array[offset_custom + 10] = v3.z;
              customAttribute.array[offset_custom + 11] = v3.w;

              offset_custom += 12;
            });
          } else if (customAttribute.boundTo == "faceVertices") {
            chunk_faces3.forEach((chunk_face) {
              var value = customAttribute.value[chunk_face];
              
              var v1 = value[0],
                  v2 = value[1],
                  v3 = value[2];

              customAttribute.array[offset_custom]      = v1.x;
              customAttribute.array[offset_custom + 1]  = v1.y;
              customAttribute.array[offset_custom + 2]  = v1.z;
              customAttribute.array[offset_custom + 3]  = v1.w;

              customAttribute.array[offset_custom + 4]  = v2.x;
              customAttribute.array[offset_custom + 5]  = v2.y;
              customAttribute.array[offset_custom + 6]  = v2.z;
              customAttribute.array[offset_custom + 7]  = v2.w;

              customAttribute.array[offset_custom + 8]  = v3.x;
              customAttribute.array[offset_custom + 9]  = v3.y;
              customAttribute.array[offset_custom + 10] = v3.z;
              customAttribute.array[offset_custom + 11] = v3.w;

              offset_custom += 12;
            });
          }
        }
        
        customAttribute.buffer.bind(gl.ARRAY_BUFFER);
        
        _gl.bufferDataTyped(gl.ARRAY_BUFFER, customAttribute.array, hint);
      });
    }

    if (dispose) {
      geometryGroup.__inittedArrays = false;  //delete geometryGroup.__inittedArrays"];
      geometryGroup.__colorArray = null;      //delete geometryGroup.__colorArray"];
      geometryGroup.__normalArray = null;     //delete geometryGroup.__normalArray"];
      geometryGroup.__tangentArray = null;    //delete geometryGroup.__tangentArray"];
      geometryGroup.__uvArray = null;         //delete geometryGroup.__uvArray"];
      geometryGroup.__uv2Array = null;        //delete geometryGroup.__uv2Array"];
      geometryGroup.__faceArray = null;       //delete geometryGroup.__faceArray"];
      geometryGroup.__vertexArray = null;     //delete geometryGroup.__vertexArray"];
      geometryGroup.__lineArray = null;       //delete geometryGroup.__lineArray"];
      geometryGroup.__skinIndexArray = null;  //delete geometryGroup.__skinIndexArray"];
      geometryGroup.__skinWeightArray = null; //delete geometryGroup.__skinWeightArray"];
    }
  }

  // Reviewed.
  void setDirectBuffers(WebGLGeometry geometry, int hint, bool dispose) {
    geometry.attributes.forEach((attributeName, attribute) {
      if (attribute.needsUpdate) {
        if (attributeName == 'index') {
          _gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, attribute.buffer);
          _gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, attribute.array, hint);
        } else {
          _gl.bindBuffer(gl.ARRAY_BUFFER, attribute.buffer);
          _gl.bufferData(gl.ARRAY_BUFFER, attribute.array, hint);
        }
        
        attribute.needsUpdate = false;
      }
      
      if (dispose && !attribute.dynamic) attribute.array = null;
    });
  }

  // Buffer rendering
  void renderBufferImmediate(object, WebGLRendererProgram program, material) {
    if (object.hasPositions && !object["__webglVertexBuffer"]) object["__webglVertexBuffer"] = _gl.createBuffer();
    if (object.hasNormals && !object["__webglNormalBuffer"]) object["__webglNormalBuffer"] = _gl.createBuffer();
    if (object.hasUvs && !object["__webglUVBuffer"]) object["__webglUVBuffer"] = _gl.createBuffer();
    if (object.hasColors && !object["__webglColorBuffer"]) object["__webglColorBuffer"] = _gl.createBuffer();

    if (object.hasPositions) {
      _gl.bindBuffer(gl.ARRAY_BUFFER, object["__webglVertexBuffer"]);
      _gl.bufferDataTyped(gl.ARRAY_BUFFER, object.positionArray, gl.DYNAMIC_DRAW);
      _gl.enableVertexAttribArray(program.attributes["position"]);
      _gl.vertexAttribPointer(program.attributes["position"], 3, gl.FLOAT, false, 0, 0);
    }

    if (object.hasNormals) {
        _gl.bindBuffer(gl.ARRAY_BUFFER, object["__webglNormalBuffer"]);

        if (material.shading == FLAT_SHADING) {
            var normalArray;
            
            for(var i = 0; i < object.count * 3; i += 9) {
                normalArray = object.normalArray;

                var nax  = normalArray[i],
                    nay  = normalArray[i + 1],
                    naz  = normalArray[i + 2],

                    nbx  = normalArray[i + 3],
                    nby  = normalArray[i + 4],
                    nbz  = normalArray[i + 5],

                    ncx  = normalArray[i + 6],
                    ncy  = normalArray[i + 7],
                    ncz  = normalArray[i + 8],

                    nx = (nax + nbx + ncx) / 3,
                    ny = (nay + nby + ncy) / 3,
                    nz = (naz + nbz + ncz) / 3;

                normalArray[i]     = nx;
                normalArray[i + 1] = ny;
                normalArray[i + 2] = nz;

                normalArray[i + 3] = nx;
                normalArray[i + 4] = ny;
                normalArray[i + 5] = nz;

                normalArray[i + 6] = nx;
                normalArray[i + 7] = ny;
                normalArray[i + 8] = nz;
            }
        }

        _gl.bufferDataTyped(gl.ARRAY_BUFFER, object.normalArray, gl.DYNAMIC_DRAW);
        _gl.enableVertexAttribArray(program.attributes["normal"]);
        _gl.vertexAttribPointer(program.attributes["normal"], 3, gl.FLOAT, false, 0, 0);
    }

    if (object.hasUvs && material.map) {
        _gl.bindBuffer(gl.ARRAY_BUFFER, object["__webglUVBuffer"]);
        _gl.bufferDataTyped(gl.ARRAY_BUFFER, object.uvArray, gl.DYNAMIC_DRAW);
        _gl.enableVertexAttribArray(program.attributes["uv"]);
        _gl.vertexAttribPointer(program.attributes["uv"], 2, gl.FLOAT, false, 0, 0);
    }

    if (object.hasColors && material.vertexColors != NO_COLORS) {
        _gl.bindBuffer(gl.ARRAY_BUFFER, object["__webglColorBuffer"]);
        _gl.bufferDataTyped(gl.ARRAY_BUFFER, object.colorArray, gl.DYNAMIC_DRAW);
        _gl.enableVertexAttribArray(program.attributes["color"]);
        _gl.vertexAttribPointer(program.attributes["color"], 3, gl.FLOAT, false, 0, 0);
    }
    
    _gl.drawArrays(gl.TRIANGLES, 0, object.count);

    object.count = 0;
  }

  //TODO
  void renderBufferDirect(WebGLCamera camera, List lights, Fog fog, WebGLMaterial material, WebGLGeometry webglgeometry, WebGLObject webglobject) {
    if (!material.visible) return;

    BufferGeometry geometry = webglgeometry._geometry as BufferGeometry;
    
    var program = setProgram(camera, lights, fog, material, webglobject);

    var programAttributes = program.attributes;
    var geometryAttributes = geometry.attributes;

    var updateBuffers = false,
        wireframeBit = material.wireframe ? 1 : 0,
        geometryHash = (webglgeometry.id * 0xffffff) + (program.id * 2) + wireframeBit;

    if (geometryHash != _currentGeometryGroupHash) {
      _currentGeometryGroupHash = geometryHash;
      updateBuffers = true;
    }

    if (updateBuffers) disableAttributes();

    // render mesh

    var object = webglobject.object;

    if (object is Mesh) {
      var index = geometry.aIndex;

      // indexed triangles
      if (index != null) { 
        var offsets = geometry.offsets;
        
        if (offsets.length > 1) updateBuffers = true;

        for (var i = 0; i < offsets.length; i++) {
          var startIndex = offsets[i].index;

          if (updateBuffers) {
            programAttributes.forEach((attributeName, value) {
              var attributePointer = value;
              var attributeItem = geometryAttributes[attributeName];
              
              if (attributePointer >= 0) {
                if (attributeItem != null) {
                  var attributeSize = attributeItem.itemSize;
                  
                  attributeItem.buffer.bind(gl.ARRAY_BUFFER);
                  enableAttribute(attributePointer);
                  _gl.vertexAttribPointer(attributePointer, attributeSize, gl.FLOAT, false, 0, startIndex * attributeSize * 4); // 4 bytes per Float32
                } else if (material.defaultAttributeValues != null) {
                  if (material.defaultAttributeValues[attributeName].length == 2) {
                    _gl.vertexAttrib2fv(attributePointer, material.defaultAttributeValues[attributeName]);
                  } else if (material.defaultAttributeValues[attributeName].length == 3) {
                    _gl.vertexAttrib3fv(attributePointer, material.defaultAttributeValues[attributeName]);
                  }
                }
              }
            });
            
            index.buffer.bind(gl.ELEMENT_ARRAY_BUFFER);
          }
          
          // render indexed triangles
          _gl.drawElements(gl.TRIANGLES, offsets[i].count, gl.UNSIGNED_SHORT, offsets[i].start * 2); // 2 bytes per Uint16

          info.render.calls++;
          info.render.vertices += offsets[i].count; // not really true, here vertices can be shared
          info.render.faces += offsets[i].count ~/ 3;
        }
        // non-indexed triangles
      } else {
        if (updateBuffers) {
          programAttributes.forEach((attributeName, value) {
            if (attributeName != "index") {
              var attributePointer = value;
              var attributeItem = geometryAttributes[attributeName];
              
              if (attributePointer >= 0) {
                if (attributeItem != null) {
                  var attributeSize = attributeItem.itemSize;
                  
                  attributeItem.buffer.bind(gl.ARRAY_BUFFER);
                  enableAttribute(attributePointer);
                  _gl.vertexAttribPointer(attributePointer, attributeSize, gl.FLOAT, false, 0, 0);
                }  else if (material.defaultAttributeValues.containsKey(attributeName)) {  
                  if (material.defaultAttributeValues[attributeName].length == 2) {
                    _gl.vertexAttrib2fv(attributePointer, material.defaultAttributeValues[attributeName]);
                  } else if (material.defaultAttributeValues[attributeName].length == 3) {
                    _gl.vertexAttrib3fv(attributePointer, material.defaultAttributeValues[attributeName]);
                  }
                }
              }
            }
          });
        }
            
        var position = geometry.aPosition;
          
        //render non-indexed triangles
        _gl.drawArrays(gl.TRIANGLES, 0, position.numItems ~/ 3);
        
        info.render.calls++;
        info.render.vertices += position.numItems ~/ 3;
        info.render.faces += position.numItems ~/ 3 ~/ 3;
      }
    } else if (object is ParticleSystem) {
      if (updateBuffers) {
        programAttributes.forEach((attributeName, value) {
          var attributePointer = value;
          var attributeItem = geometryAttributes[attributeName];
          
          if (attributePointer >= 0) {
            if (attributeItem != null) {
              var attributeSize = attributeItem.itemSize;
              attributeItem.buffer.bind(gl.ARRAY_BUFFER);
              enableAttribute(attributePointer);
              _gl.vertexAttribPointer(attributePointer, attributeSize, gl.FLOAT, false, 0, 0);
            } else if (material.defaultAttributeValues.containsKey(attributeName)) {
              if (material.defaultAttributeValues[attributeName].length == 2) { 
                _gl.vertexAttrib2fv(attributePointer, material.defaultAttributeValues[attributeName]);
              } else if (material.defaultAttributeValues[attributeName].length == 3) {
                _gl.vertexAttrib3fv(attributePointer, material.defaultAttributeValues[attributeName]);
              }  
            }
          }
        });
      }
      
      var position = geometry.aPosition;
      
      //render particles
      _gl.drawArrays(gl.POINTS, 0, position.numItems ~/ 3);

      info.render.calls++;
      info.render.points += position.numItems ~/ 3;
    } else if (object is Line) {
      if (updateBuffers) {
        programAttributes.forEach((attributeName, value) {
          var attributePointer = programAttributes[attributeName];
          var attributeItem = geometryAttributes[attributeName];

          if (attributePointer >= 0) {
            if (attributeItem != null) {
              var attributeSize = attributeItem.itemSize;
              _gl.bindBuffer(gl.ARRAY_BUFFER, attributeItem.buffer);
              enableAttribute(attributePointer);
              _gl.vertexAttribPointer(attributePointer, attributeSize, gl.FLOAT, false, 0, 0);

            } else if (material.defaultAttributeValues.containsKey(attributeName)) {
              if (material.defaultAttributeValues[attributeName].length == 2) {
                _gl.vertexAttrib2fv(attributePointer, material.defaultAttributeValues[attributeName]);
              } else if (material.defaultAttributeValues[attributeName].length == 3) {
                _gl.vertexAttrib3fv(attributePointer, material.defaultAttributeValues[attributeName]);
              }
            }
          }
        });
      }

      // render lines

      var primitives = (object.type == LINE_STRIP) ? gl.LINE_STRIP : gl.LINES;

      setLineWidth(material.linewidth);

      var position = geometryAttributes["position"];

      _gl.drawArrays(primitives, 0, position.numItems ~/ 3);

      info.render.calls++;
      info.render.points += position.numItems;
    }
  }

  void renderBuffer(camera, List<Light> lights, Fog fog, WebGLMaterial material, WebGLGeometry geometryGroup, object) {
    // Wrap these into proper WebGL objects since this method is called from plugins
    WebGLObject webglobject = object is WebGLObject ? object : new WebGLObject(object);
    object = webglobject.object;

    WebGLCamera webglcamera = camera is WebGLCamera ? camera : new WebGLCamera(camera);
    camera = webglcamera._camera;

    if (!material.visible) return;

    var program = setProgram(webglcamera, lights, fog, material, webglobject);

    var attributes = program.attributes;

    var updateBuffers = false,
        wireframeBit = material.wireframe ? 1 : 0,
        geometryGroupHash = (geometryGroup.id * 0xffffff) + (program.id * 2) + wireframeBit;

    if (geometryGroupHash != _currentGeometryGroupHash) {
      _currentGeometryGroupHash = geometryGroupHash;
      updateBuffers = true;
    }
    
    if (updateBuffers) disableAttributes();
    
    // vertices
    if (!material.morphTargets && attributes["position"] >= 0) {
      if (updateBuffers) {
        _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglVertexBuffer);
        enableAttribute(attributes["position"]);
        _gl.vertexAttribPointer(attributes["position"], 3, gl.FLOAT, false, 0, 0);
      }
    } else {
      if (webglobject.morphTargetBase != 0) {
        setupMorphTargets(material, geometryGroup, webglobject);
      }
    }

    if (updateBuffers) {
      // custom attributes

      // Use the per-geometryGroup custom attribute arrays which are setup in initMeshBuffers
      if (geometryGroup.__webglCustomAttributesList != null) {
        var il = geometryGroup.__webglCustomAttributesList.length;
        
        for (var i = 0; i < il; i++) {
          var attribute = geometryGroup.__webglCustomAttributesList[i];

          if(attributes[attribute.buffer.belongsToAttribute] >= 0) {
            attribute.buffer.bind(gl.ARRAY_BUFFER);
            enableAttribute(attributes[attribute.buffer.belongsToAttribute]);
            _gl.vertexAttribPointer(attributes[attribute.buffer.belongsToAttribute], attribute.size, gl.FLOAT, false, 0, 0);
          }
        }
      }

      // colors
      if (attributes["color"] >= 0) {
        if (object.geometry.colors.length > 0 || object.geometry.faces.length > 0) {
          _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglColorBuffer);
          
          enableAttribute(attributes["color"]);
          _gl.vertexAttribPointer(attributes["color"], 3, gl.FLOAT, false, 0, 0);
          
        }
        else if (material.defaultAttributeValues != null) {
          _gl.vertexAttrib3fv(attributes["color"], material.defaultAttributeValues["color"]); 
        }
      }

      // normals
      if (attributes["normal"] >= 0) {
        _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglNormalBuffer);
        enableAttribute(attributes["normal"]);
        _gl.vertexAttribPointer(attributes["normal"], 3, gl.FLOAT, false, 0, 0);

      }

      // tangents
      if (attributes["tangent"] >= 0) {
        _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglTangentBuffer);
        enableAttribute(attributes["tangent"]);
        _gl.vertexAttribPointer(attributes["tangent"], 4, gl.FLOAT, false, 0, 0);

      }

      // uvs
      if (attributes["uv"] >= 0) {
        if (object.geometry.faceVertexUvs[0] != null) {
          _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglUVBuffer);
          enableAttribute(attributes["uv"]);
          _gl.vertexAttribPointer(attributes["uv"], 2, gl.FLOAT, false, 0, 0);
          
        } 
        else if (material.defaultAttributeValues != null) {
          _gl.vertexAttrib2fv(attributes["uv"], material.defaultAttributeValues["uv"]);
        }
      }

      if (attributes["uv2"] >= 0) {
        if (object.geometry.faceVertexUvs[1] != null) {
          _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglUV2Buffer);
          enableAttribute(attributes["uv2"]);
          _gl.vertexAttribPointer(attributes["uv2"], 2, gl.FLOAT, false, 0, 0);
        }
      
      } else if (material.defaultAttributeValues != null){
        _gl.vertexAttrib2fv(attributes["uv2"], material.defaultAttributeValues["uv2"]);
      }
    }

    if (material.skinning &&
       attributes["skinIndex"] >= 0 && attributes["skinWeight"] >= 0) {

      _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglSkinIndicesBuffer);
      enableAttribute(attributes["skinIndex"]);
      _gl.vertexAttribPointer(attributes["skinIndex"], 4, gl.FLOAT, false, 0, 0);

      _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglSkinWeightsBuffer);
      enableAttribute(attributes["skinWeight"]);
      _gl.vertexAttribPointer(attributes["skinWeight"], 4, gl.FLOAT, false, 0, 0);
    }

    // line distances
    if (attributes["lineDistance"] >= 0) {
      _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglLineDistanceBuffer);
      enableAttribute(attributes["lineDistance"]);
      _gl.vertexAttribPointer(attributes["lineDistance"], 1, gl.FLOAT, false, 0, 0);
    }
    
    // render mesh
    if (object is Mesh) {
      // wireframe
      if (material.wireframe) {
        setLineWidth(material.wireframeLinewidth);

        if (updateBuffers) _gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, geometryGroup.__webglLineBuffer);
        _gl.drawElements(gl.LINES, geometryGroup.__webglLineCount, gl.UNSIGNED_SHORT, 0);

      // triangles
      } else {
        if (updateBuffers) _gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, geometryGroup.__webglFaceBuffer);
        _gl.drawElements(gl.TRIANGLES, geometryGroup.__webglFaceCount, gl.UNSIGNED_SHORT, 0);
      }

      info.render.calls++;
      info.render.vertices += geometryGroup.__webglFaceCount;
      info.render.faces += geometryGroup.__webglFaceCount ~/ 3;

    // render lines
    } else if (object is Line) {
      var primitives = ((object as Line).type == LINE_STRIP) ? gl.LINE_STRIP : gl.LINES;

      setLineWidth(material.linewidth);

      _gl.drawArrays(primitives, 0, geometryGroup.__webglLineCount);

      info.render.calls++;

    // render particles
    } else if (object is ParticleSystem) {
      _gl.drawArrays(gl.POINTS, 0, geometryGroup.__webglParticleCount);

      info.render.calls++;
      info.render.points += geometryGroup.__webglParticleCount;
    }
  }

  void enableAttribute(int attribute) {
    if (_enabledAttributes[attribute] == null || !_enabledAttributes[attribute]) {
      _gl.enableVertexAttribArray(attribute);
      _enabledAttributes[attribute] = true;
    }
  }

  void disableAttributes() {
    _enabledAttributes.forEach((key, enabled) {
      if (enabled) {
        _gl.disableVertexAttribArray(key);
        _enabledAttributes[key] = false;
      }
    });
  }

  void setupMorphTargets(WebGLMaterial material, WebGLGeometry geometryGroup, WebGLObject object) {
    // set base
    var attributes = material.program.attributes;

    if (object.morphTargetBase != -1 && attributes["position"] >= 0) {
      _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglMorphTargetsBuffers[object.morphTargetBase]);
      enableAttribute(attributes["position"]);
      _gl.vertexAttribPointer(attributes["position"], 3, gl.FLOAT, false, 0, 0);
    } else if (attributes["position"] >= 0) {
      _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglVertexBuffer);
      enableAttribute(attributes["position"]);
      _gl.vertexAttribPointer(attributes["position"], 3, gl.FLOAT, false, 0, 0);
    }

    if (object.morphTargetForcedOrder.length > 0) {
      // set forced order
      var m = 0;
      var order = object.morphTargetForcedOrder;
      var influences = object.morphTargetInfluences;

      while (m < material.numSupportedMorphTargets && m < order.length) {
        if (attributes["morphTarget${m.toString()}"] >= 0) {
          _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglMorphTargetsBuffers[order[m]]);
          enableAttribute(attributes["morphTarget${m.toString()}"]);
          _gl.vertexAttribPointer(attributes["morphTarget${m.toString()}"], 3, gl.FLOAT, false, 0, 0);
        }

        if (attributes["morphNormal${m.toString()}"] >= 0 && material.morphNormals) {
          _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglMorphNormalsBuffers[order[m]]);
          enableAttribute(attributes["morphNormal${m.toString()}"]);
          _gl.vertexAttribPointer(attributes["morphNormal${m.toString()}"], 3, gl.FLOAT, false, 0, 0);
        }

        object.__webglMorphTargetInfluences[m] = influences[order[m]].toDouble();
        m++;
      }
    } else {
      // find the most influencing
      var activeInfluenceIndices = [];
      var influences = object.morphTargetInfluences;

      for (var i = 0; i < influences.length; i++) {
        var influence = influences[i];

        if (influence > 0) {
          activeInfluenceIndices.add([i, influence]);
        }
      }

      if (activeInfluenceIndices.length > material.numSupportedMorphTargets) {
        activeInfluenceIndices.sort(numericalSort);
        activeInfluenceIndices.length = material.numSupportedMorphTargets;
      } else if (activeInfluenceIndices.length > material.numSupportedMorphNormals) {
        activeInfluenceIndices.sort(numericalSort);
      } else if (activeInfluenceIndices.length == 0) {
        activeInfluenceIndices.add([0, 0]);
      }

      var influenceIndex, m = 0;

      while (m < material.numSupportedMorphTargets) {
        if (m < activeInfluenceIndices.length && activeInfluenceIndices[m] != null && !activeInfluenceIndices[m].isEmpty) {
          influenceIndex = activeInfluenceIndices[m][0];

          _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglMorphTargetsBuffers[influenceIndex]);
          enableAttribute(attributes["morphNormal${m.toString()}"]);
          _gl.vertexAttribPointer(attributes["morphTarget$m"], 3, gl.FLOAT, false, 0, 0);

          if (material.morphNormals) {
            _gl.bindBuffer(gl.ARRAY_BUFFER, geometryGroup.__webglMorphNormalsBuffers[influenceIndex]);
            enableAttribute(attributes["morphNormal${m.toString()}"]);
            _gl.vertexAttribPointer(attributes["morphNormal${m.toString()}"], 3, gl.FLOAT, false, 0, 0);
          }
          object.__webglMorphTargetInfluences[m] = influences[influenceIndex].toDouble();
        } else {
          object.__webglMorphTargetInfluences[m] = 0.0;
        }
        
        m++;
      }
    }

    // load updated influences uniform
    if (material.program.uniforms["morphTargetInfluences"] != null) {
      _gl.uniform1fv(material.program.uniforms["morphTargetInfluences"], object.__webglMorphTargetInfluences);
    }
  }

  // Sorting

  int painterSort(a, b) => (a.z.isNaN || b.z.isNaN || a.z.isInfinite || b.z.isInfinite) ? 0 : (b.z - a.z).toInt();

  int numericalSort(a, b) => (b[0] - a[0]).toInt();


  // Rendering
  void render(Scene scene, Camera camera_, {WebGLRenderTarget renderTarget, bool forceClear: false}) {
    WebGLObject webglObject;
    Object3D object;
    List renderList;

    List lights = scene.__lights;
    Fog fog = scene.fog;

    // reset caching for this frame
    _currentMaterialId = -1;
    _lightsNeedUpdate = true;

    // update scene graph

    if (scene.autoUpdate) scene.updateMatrixWorld();

    var camera = new WebGLCamera(camera_);

    // update camera matrices and frustum

    if (camera.parent == null) camera.updateMatrixWorld();

    camera.matrixWorldInverse.copyInverse(camera.matrixWorld);

    _projScreenMatrix.setFrom(camera.projectionMatrix * camera.matrixWorldInverse);
    _frustum.setFromMatrix(_projScreenMatrix);

    // update WebGL objects

    if (autoUpdateObjects) initWebGLObjects(scene);

    // custom render plugins (pre pass)
     
    renderPlugins(renderPluginsPre, scene, camera);

    //
    
    info.render.calls = 0;
    info.render.vertices = 0;
    info.render.faces = 0;
    info.render.points = 0;

    setRenderTarget(renderTarget);

    if (autoClear || forceClear) {
      clear(autoClearColor, autoClearDepth, autoClearStencil);
    }

    // set matrices for regular objects (frustum culled)

    renderList = scene["__webglObjects"];
    
    renderList.forEach((webglObject) {
      object = webglObject.object;

      webglObject.render = false;

      if (object.visible) {
        if (!(object is Mesh || object is ParticleSystem) || !object.frustumCulled || _frustum.intersectsObject(object)) {
          setupMatrices(webglObject, camera);
      
          unrollBufferMaterial(webglObject);

          webglObject.render = true;

          if (sortObjects) {
            if (object.renderDepth != null) {
              webglObject.z = object.renderDepth;
            } else {
              _vector3 = object.matrixWorld.getTranslation();
              _vector3.applyProjection(_projScreenMatrix);

              webglObject.z = _vector3.z;
            }
          }
        }
      }
    });

    if (sortObjects) renderList.sort(painterSort);

    // set matrices for immediate objects
    renderList = scene["__webglObjectsImmediate"];

    renderList.forEach((webglObject) {
      object = webglObject.object;

      if (object.visible) {
        setupMatrices(webglObject, camera);

        unrollImmediateBufferMaterial(webglObject);
      }
    });

    if (scene.overrideMaterial != null) {
      var material = scene.overrideMaterial;

      setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst);
      setDepthTest(material.depthTest);
      setDepthWrite(material.depthWrite);
      setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);

      renderObjects(scene["__webglObjects"], false, "", camera, lights, fog, true, material);
      renderObjectsImmediate(scene["__webglObjectsImmediate"], "", camera, lights, fog, false, material);

    } else {
      // opaque pass (front-to-back order)
      setBlending(NO_BLENDING);
  
      renderObjects(scene["__webglObjects"], true, "opaque", camera, lights, fog, false);
      renderObjectsImmediate(scene["__webglObjectsImmediate"], "opaque", camera, lights, fog, false);
  
      // transparent pass (back-to-front order)
      renderObjects(scene["__webglObjects"], false, "transparent", camera, lights, fog, true);
      renderObjectsImmediate(scene["__webglObjectsImmediate"], "transparent", camera, lights, fog, true);
    }

    // custom render plugins (post pass)
    renderPlugins(renderPluginsPost, scene, camera);


    // Generate mipmap if we're using any kind of mipmap filtering
    if ((renderTarget != null) && renderTarget.generateMipmaps && renderTarget.minFilter != NEAREST_FILTER && renderTarget.minFilter != LINEAR_FILTER) {
        updateRenderTargetMipmap(renderTarget);
    }

    // Ensure depth buffer writing is enabled so it can be cleared on next render
    setDepthTest(true);
    setDepthWrite(true);
  }

  void renderPlugins(List plugins, Scene scene, WebGLCamera camera) {
    plugins.forEach((plugin) {
      // reset state for plugin (to start from clean slate)

      _currentProgram = null;
      _currentCamera = null;

      _oldBlending = -1;
      _oldDepthTest = false;
      _oldDepthWrite = false;
      _oldDoubleSided = false;
      _oldFlipSided = false;
      _currentGeometryGroupHash = -1;
      _currentMaterialId = -1;

      _lightsNeedUpdate = true;

      plugin.render(scene, camera._camera, _currentWidth, _currentHeight);

      // reset state after plugin (anything could have changed)

      _currentProgram = null;
      _currentCamera = null;

      _oldBlending = -1;
      _oldDepthTest = false;
      _oldDepthWrite = false;
      _oldDoubleSided = false;
      _oldFlipSided = false;
      _currentGeometryGroupHash = -1;
      _currentMaterialId = -1;

      _lightsNeedUpdate = true;
    });
  }

  // Reviewed.
  void renderObjects(List<WebGLObject> renderList,
                     bool reverse, 
                     String materialType,
                     WebGLCamera camera,
                     List<Light> lights,
                     Fog fog,
                     bool useBlending,
                    [WebGLMaterial overrideMaterial]) {
    int start, end, delta;

    if (reverse) {
      start = renderList.length - 1;
      end = -1;
      delta = -1;
    } else {
      start = 0;
      end = renderList.length;
      delta = 1;
    }

    for (var i = start; i != end; i += delta) {
      var webglObject = renderList[i];
      
      if (webglObject.render) {
        var material;

        if (overrideMaterial != null) {
          material = overrideMaterial;
        } else {
          material = materialType == "opaque" ? webglObject.opaque : webglObject.transparent;

          if (material == null) continue;

          if (useBlending) setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst);

          setDepthTest(material.depthTest);
          setDepthWrite(material.depthWrite);
          setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
        }
        
        setMaterialFaces(material);
        
        if (webglObject.buffer.isBufferGeometry) {
          renderBufferDirect(camera, lights, fog, material, webglObject.buffer, webglObject);
        } else {
          renderBuffer(camera, lights, fog, material, webglObject.buffer, webglObject);
        }
      }
    }
  } 

  void renderObjectsImmediate(List renderList, String materialType, WebGLCamera camera, List<Light> lights, 
                              Fog fog, bool useBlending, [Material overrideMaterial]) {
    var material;

    for (var i = 0; i < renderList.length; i++) {
      var webglObject = renderList[i];
      var object = webglObject.object;

      if (object.visible) {
        if (overrideMaterial != null) {
          material = overrideMaterial;
        } else {
          material = webglObject[materialType];
          
          if (material == null) continue;
          
          if (useBlending) setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst);

          setDepthTest(material.depthTest);
          setDepthWrite(material.depthWrite);
          setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);
        }

        renderImmediateObject(camera, lights, fog, material, object);
      }
    }
  }

  // TODO
  void renderImmediateObject(WebGLCamera camera, List lights, Fog fog, WebGLMaterial material, object) {
    var program = setProgram(camera, lights, fog, material, object);

    _currentGeometryGroupHash = -1;

    setMaterialFaces(material);

    if (object.immediateRenderCallback) {
      object.immediateRenderCallback(program, _gl, _frustum);
    } else {
      object.render((object) => renderBufferImmediate(object, program, material));
    }
  }

  void unrollImmediateBufferMaterial(WebGLObject webglobject) {
    var material = webglobject.webglmaterial;

    if (material.transparent) {
      webglobject.transparent = material;
      webglobject.opaque = null;
    } else {
      webglobject.opaque = material;
      webglobject.transparent = null;
    }
  }

  void unrollBufferMaterial(WebGLObject object) {
    WebGLGeometry buffer = object.buffer;
    WebGLMaterial meshMaterial = object.webglmaterial;
    int materialIndex;
    WebGLMaterial material;
  
    if (object.material is MeshFaceMaterial) {
      materialIndex = buffer.materialIndex;
  
      if (materialIndex >= 0) {
        material = new WebGLMaterial.from((object.material as MeshFaceMaterial).materials[materialIndex]);
  
        if (material.transparent) {
          object.transparent = material;
          object.opaque = null;
        } else {
  
          object.opaque = material;
          object.transparent = null;
        }
      }
  
    } else {
      material = meshMaterial;
      
      if (material != null) {
        if (material.transparent != null) {
          object.transparent = material;
          object.opaque = null;
  
        } else {
          object.opaque = material;
          object.transparent = null;
        }
      }
    }
  }

  // Geometry splitting

  void sortFacesByMaterial(WebGLGeometry geometry, Material material) {
    Map<String, Map> hash_map = {};

    var numMorphTargets = geometry.morphTargets.length;
    var numMorphNormals = geometry.morphNormals.length;

    var usesFaceMaterial = material is MeshFaceMaterial;

    geometry.geometryGroups = {};

    for (var f = 0; f < geometry.faces.length; f++) {
      var face = geometry.faces[f];
      var materialIndex = usesFaceMaterial ? face.materialIndex.toString() : "0";

      if (hash_map[materialIndex] == null) {
        hash_map[materialIndex] = {'hash': materialIndex, 'counter': 0};
      }

      var groupHash = "${hash_map[materialIndex]["hash"]}_${hash_map[materialIndex]["counter"]}";

      if (geometry.geometryGroups[groupHash] == null) {
          geometry.geometryGroups[groupHash] = new WebGLGeometry(faces3: [], 
                                                                 materialIndex: int.parse(materialIndex), 
                                                                 vertices: 0, numMorphTargets: numMorphTargets, 
                                                                 numMorphNormals: numMorphNormals);
      }

      var vertices = 3;
      
      if (geometry.geometryGroups[groupHash].vertices + vertices > 65535) {
        hash_map[materialIndex]["counter"] += 1;
        groupHash = "${hash_map[materialIndex]["hash"]}_${hash_map[materialIndex]["counter"]}";

        if (geometry.geometryGroups[groupHash] == null) {
          geometry.geometryGroups[groupHash] = new WebGLGeometry(faces3: [], 
                                                                 materialIndex: int.parse(materialIndex), 
                                                                 vertices: 0, numMorphTargets: numMorphTargets, 
                                                                 numMorphNormals: numMorphNormals);
        }
      }
      
      geometry.geometryGroups[groupHash].faces3.add(f);
      geometry.geometryGroups[groupHash].vertices += vertices;
    }

    geometry.geometryGroupsList = [];
    
    
    geometry.geometryGroups.forEach((_, group) {
      group.id = _geometryGroupCounter++;
      geometry.geometryGroupsList.add(group);
    });
  }

  // Objects refresh
  void initWebGLObjects(Scene scene) {
    if (scene["__webglObjects"] == null) {
      scene["__webglObjects"] = [];
      scene["__webglObjectsImmediate"] = [];
      scene["__webglSprites"] = [];
      scene["__webglFlares"] = [];
    }

    while (scene.__objectsAdded.length > 0) {
      addObject(scene.__objectsAdded[0], scene);
      scene.__objectsAdded.removeAt(0);
    }

    while (scene.__objectsRemoved.length > 0) {
      removeObject(scene.__objectsRemoved[0], scene);
      scene.__objectsRemoved.removeAt(0);
    }

    // update must be called after objects adding / removal
    for (var o = 0; o < scene["__webglObjects"].length; o++) {
      WebGLObject webglObject = scene["__webglObjects"][o];

      if (!webglObject.__webglInit) {
        if (webglObject.__webglActive) {
          removeObject(webglObject.object, scene);
        }
     
        addObject(webglObject.object, scene);
      }
    
      updateObject(webglObject);
    }
  }

  // Objects adding
  void addObject(Object3D object, Scene scene) {
      // nelsonsilva - wrapping in our own decorator
    WebGLObject webglobject = new WebGLObject(object);
  
    // ATTENTION - All type checks must be done with object and object.geometry
    WebGLGeometry geometry = webglobject.webglgeometry;
  
    var material;

    if (!webglobject.__webglInit) {
      webglobject.__webglInit = true;

      webglobject._modelViewMatrix = new Matrix4.identity();
      webglobject._normalMatrix = new Matrix3.zero();

      if (geometry != null && geometry.__webglInit == null) {
        geometry.__webglInit = true;
        //geometry.addEventListener('dispose', onGeometryDispose);
      }
      
      if (geometry == null) {
        //fail silently for now
      } else if ((object as dynamic).geometry is BufferGeometry) {
        initDirectBuffers((object as dynamic).geometry);
      } else if (object is Mesh) {
        material = object.material;

        if ((object.geometry is Geometry)  && (object.geometry is! BufferGeometry)) {
          if (geometry.geometryGroups == null) {
            sortFacesByMaterial(geometry, material);
          }
          
          // create separate VBOs per geometry chunk
          geometry.geometryGroups.forEach((_, geometryGroup) {
            // initialise VBO on the first access
            if (geometryGroup.__webglVertexBuffer == null) {
              createMeshBuffers(geometryGroup);
              initMeshBuffers(geometryGroup, webglobject);

              geometry.verticesNeedUpdate = true;
              geometry.morphTargetsNeedUpdate = true;
              geometry.elementsNeedUpdate = true;
              geometry.uvsNeedUpdate = true;
              geometry.normalsNeedUpdate = true;
              geometry.tangentsNeedUpdate = true;
              geometry.colorsNeedUpdate = true;
            }
          });
        }
      } else if (object is Line) {
        if(geometry.__webglVertexBuffer == null) {
          createLineBuffers(geometry);
          initLineBuffers(geometry, webglobject);

          geometry.verticesNeedUpdate = true;
          geometry.colorsNeedUpdate = true;
          geometry.lineDistancesNeedUpdate = true;
        }
      } else if (object is ParticleSystem) {
        if (geometry.__webglVertexBuffer == null) {
          createParticleBuffers(geometry);
          initParticleBuffers(geometry, webglobject);
          
          geometry.verticesNeedUpdate = true;
          geometry.colorsNeedUpdate = true;
        }
      }
    }

    if (!webglobject.__webglActive) {
      if (object is Mesh) {
        if (object.geometry is BufferGeometry) {
            addBuffer(scene["__webglObjects"], geometry, webglobject);
        } else if (object.geometry is Geometry) {
          geometry.geometryGroups.forEach((_, geometryGroup) =>
              addBuffer(scene["__webglObjects"], geometryGroup, webglobject));
        }
      } else if (object is Line || object is ParticleSystem) {
        addBuffer(scene["__webglObjects"],  geometry, webglobject);
      } else if (object is ImmediateRenderObject || (object["immediateRenderCallback"] != null)) {
        addBufferImmediate(scene["__webglObjectsImmediate"], webglobject);
      } else if (object is Sprite) {
        scene["__webglSprites"].add(object);
      } else if (object is LensFlare) {
        scene["__webglFlares"].add(object);
      }
      
      webglobject.__webglActive = true;
    }
  }

  void addBuffer(List<WebGLObject> objlist, WebGLGeometry buffer, WebGLObject object) {
    objlist.add(new WebGLObject._internal(object.object, null, null, buffer, object.render, 0));
  }

  void addBufferImmediate(List<WebGLObject> objlist, WebGLObject object) {
    objlist.add(new WebGLObject._internal(object.object, null, null, null, object.render, 0));
  }

  // Objects updates
  void updateObject(WebGLObject webglobject) {
    Object3D object = webglobject.object;
    WebGLGeometry geometry = webglobject.webglgeometry, geometryGroup;

    WebGLMaterial material;
    
    if ((object as dynamic).geometry is BufferGeometry) {
      setDirectBuffers(geometry, gl.DYNAMIC_DRAW, !(object as dynamic).geometry.isDynamic);
    } else if (object is Mesh) {
      // check all geometry groups
    
      for(var i = 0; i < geometry.geometryGroupsList.length; i++) {
        geometryGroup = geometry.geometryGroupsList[i];
        material = getBufferMaterial(webglobject, geometryGroup);

        if (geometry.buffersNeedUpdate) {
          initMeshBuffers(geometryGroup, webglobject);
        }

        var customAttributesDirty = material.attributes != null && areCustomAttributesDirty(material);
  
        if (geometry.verticesNeedUpdate || 
            geometry.morphTargetsNeedUpdate || 
            geometry.elementsNeedUpdate ||
            geometry.uvsNeedUpdate || 
            geometry.normalsNeedUpdate ||
            geometry.colorsNeedUpdate || 
            geometry.tangentsNeedUpdate || 
            customAttributesDirty) {
          setMeshBuffers(geometryGroup, webglobject, gl.DYNAMIC_DRAW, !geometry.dynamic, material);
        }
      }

      geometry.verticesNeedUpdate = false;
      geometry.morphTargetsNeedUpdate = false;
      geometry.elementsNeedUpdate = false;
      geometry.uvsNeedUpdate = false;
      geometry.normalsNeedUpdate = false;
      geometry.colorsNeedUpdate = false;
      geometry.tangentsNeedUpdate = false;
  
      geometry.buffersNeedUpdate = false;

      if (material.attributes != null) {
        clearCustomAttributes(material);
      }
    } else if (object is Line) {
      material = getBufferMaterial(webglobject, geometry);
      
      var customAttributesDirty = material.attributes != null && areCustomAttributesDirty(material);

      if (geometry.verticesNeedUpdate ||  geometry.colorsNeedUpdate || geometry.lineDistancesNeedUpdate || customAttributesDirty) {
        setLineBuffers(geometry, gl.DYNAMIC_DRAW);
      }

      geometry.verticesNeedUpdate = false;
      geometry.colorsNeedUpdate = false;
      geometry.lineDistancesNeedUpdate = false;

      if (material.attributes != null) { 
        clearCustomAttributes(material);
      }
    } else if (object is ParticleSystem) {
      material = getBufferMaterial(webglobject, geometryGroup);

      var customAttributesDirty = material.attributes != null && areCustomAttributesDirty(material);

      if (geometry.verticesNeedUpdate || geometry.colorsNeedUpdate || object.sortParticles || customAttributesDirty) {
        setParticleBuffers(geometry, gl.DYNAMIC_DRAW, object);
      }

      geometry.verticesNeedUpdate = false;
      geometry.colorsNeedUpdate = false;

      if (material.attributes != null) {
        clearCustomAttributes(material);
      }       
    }
  }

  // Objects updates - custom attributes check
  bool areCustomAttributesDirty(WebGLMaterial material) => 
      material.attributes.values.any((attribute) => attribute.needsUpdate);

  void clearCustomAttributes(WebGLMaterial material) {
    material.attributes.forEach((_, attribute) => attribute.needsUpdate = false);
  }

  // Objects removal
  void removeObject(Object3D object, Scene scene) {
    WebGLObject webglobject = new WebGLObject(object);

    if (object is Mesh  ||
        object is ParticleSystem ||
        object is Line) {
      removeInstances(scene["__webglObjects"], object);
    } else if (object is Sprite) {
      removeInstancesDirect(scene["__webglSprites"], object);
    } else if (object is LensFlare) {
      removeInstancesDirect(scene["__webglFlares"], object);
    } else if (object is ImmediateRenderObject || (object["immediateRenderCallback"] != null)) {
      removeInstances(scene["__webglObjectsImmediate"], object);
    }

    webglobject.__webglActive = false;
  }

  void removeInstances(List<WebGLObject> objlist, Object3D object) {
    for (var o = objlist.length - 1; o >= 0; o--) {
      if (objlist[o].object == object) objlist.removeAt(o);
    }
  }

  void removeInstancesDirect(List<Object3D> objlist, Object3D object) {
    for (var o = objlist.length - 1; o >= 0; o--) {
      if (objlist[o] == object) objlist.removeAt(o);
    }
  }

  // Materials
  void initMaterial(WebGLMaterial material, List<Light> lights, Fog fog, WebGLObject webglobject) {
    //material.addEventListener('dispose', onMaterialDispose);

    var object = webglobject.object;
    
    var shaderID;
      
    if      (material.isMeshDepthMaterial)      { shaderID = 'depth'; }
    else if (material.isMeshNormalMaterial)     { shaderID = 'normal'; }
    else if (material.isMeshBasicMaterial)      { shaderID = 'basic'; }
    else if (material.isMeshLambertMaterial)    { shaderID = 'lambert'; }
    else if (material.isMeshPhongMaterial)      { shaderID = 'phong'; }
    else if (material.isLineBasicMaterial)      { shaderID = 'basic'; }
    else if (material.isParticleSystemMaterial) { shaderID = 'particle_basic'; }
      
    //TODO else if (material.isLineDashedMaterial)  shaderID = 'dashed';
      
    if (shaderID != null) {
      setMaterialShaders(material, ShaderLib[shaderID]);
    }

    // heuristics to create shader parameters according to lights in the scene
    // (not to blow over maxLights budget)

    var maxLightCount = allocateLights(lights),
        maxShadows = allocateShadows(lights),
        maxBones = allocateBones(object);

    material.program = buildProgram(
        shaderID,
        material.fragmentShader,
        material.vertexShader,
        material.uniforms,
        material.attributes,
        material.defines,
        material.index0AttributeName,
        map: material.map,
        envMap: material.envMap,
        lightMap: material.lightMap,
        bumpMap: material.bumpMap,
        normalMap: material.normalMap,
        specularMap: material.specularMap,

        vertexColors: material.vertexColors,

        fog: fog,
        useFog: material.fog,
        fogExp: fog is FogExp2,

        sizeAttenuation: material.sizeAttenuation,

        skinning: material.skinning,
        maxBones: maxBones,
        useVertexTexture: supportsBoneTextures && object != null && object is SkinnedMesh && object.useVertexTexture,

        morphTargets: material.morphTargets,
        morphNormals: material.morphNormals,
        maxMorphTargets: maxMorphTargets,
        maxMorphNormals: maxMorphNormals,

        maxDirLights: maxLightCount['directional'],
        maxPointLights: maxLightCount['point'],
        maxSpotLights: maxLightCount['spot'],
        maxHemiLights: maxLightCount['hemi'],

        maxShadows: maxShadows,
        shadowMapEnabled: shadowMapEnabled && object.receiveShadow,
        shadowMapType: shadowMapType,
        shadowMapDebug: shadowMapDebug,
        shadowMapCascade: shadowMapCascade,

        alphaTest: material.alphaTest,
        metal: material.metal,
        perPixel: material.perPixel,
        wrapAround: material.wrapAround,
        doubleSided: material.side == DOUBLE_SIDE,
        flipSided: material.side == BACK_SIDE);

    var attributes = material.program.attributes;

    if (material.morphTargets) {
      material.numSupportedMorphTargets = 0;
      var base = "morphTarget";
      
      for (var i = 0; i < maxMorphTargets; i++) {
        var id = "$base$i";

        if (attributes[id] >= 0) {
          material.numSupportedMorphTargets++;
        }
      }
    }

    if (material.morphNormals) {
      material.numSupportedMorphNormals = 0;

      var base = "morphNormal";

      for (var i = 0; i < maxMorphNormals; i++) {
        var id = "$base$i";
        if (attributes[id] >= 0) {
            material.numSupportedMorphNormals++;
        }
      }
    }
    
    material.uniformsList = [];
    material.uniforms.forEach((k, u) => material.uniformsList.add([u, k]));
  }

  void setMaterialShaders(WebGLMaterial material, Map shaders) {
    material.uniforms = UniformsUtils.clone(shaders["uniforms"]);
    material.vertexShader = shaders["vertexShader"];
    material.fragmentShader = shaders["fragmentShader"];
  }

  WebGLRendererProgram setProgram(WebGLCamera camera, List lights, Fog fog, WebGLMaterial material, WebGLObject object) {
    _usedTextureUnits = 0;

    if (material.needsUpdate) {
      if (material.program != null) { 
        deallocateMaterial(material); 
      }
        
      initMaterial(material, lights, fog, object);
      material.needsUpdate = false;
    }

    if (material.morphTargets) {
      if (object.__webglMorphTargetInfluences == null) {
        object.__webglMorphTargetInfluences = new Float32List(maxMorphTargets);
      }
    }

    var refreshMaterial = false;

    var program = material.program,
        p_uniforms = program.uniforms,
        m_uniforms = material.uniforms;

    if (!identical(program, _currentProgram)) {
      _gl.useProgram(program.glProgram);
      _currentProgram = program;
      refreshMaterial = true;
    }

    if (material.id != _currentMaterialId) {
      _currentMaterialId = material.id;
      refreshMaterial = true;
    }

    if (refreshMaterial || !identical(camera, _currentCamera)) {
      _gl.uniformMatrix4fv(p_uniforms["projectionMatrix"], false, camera.projectionMatrix.storage);

      if (!identical(camera, _currentCamera)) { 
        _currentCamera = camera; 
      }
    }

    // skinning uniforms must be set even if material didn't change
    // auto-setting of texture unit for bone texture must go before other textures
    // not sure why, but otherwise weird things happen

    if (material.skinning) {
      if (supportsBoneTextures && object.useVertexTexture) {
        if (p_uniforms.boneTexture != null) {
          var textureUnit = getTextureUnit();

          _gl.uniform1i(p_uniforms.boneTexture, textureUnit);
          setTexture(object.boneTexture, textureUnit);
        }
        
        if (p_uniforms.boneTextureWidth != null) {
          _gl.uniform1i(p_uniforms.boneTextureWidth, object.boneTextureWidth);
        }
        
        if (p_uniforms.boneTextureHeight != null) {
          _gl.uniform1i(p_uniforms.boneTextureWidth, object.boneTextureHeight);
        }
      } else {
        if (p_uniforms.boneGlobalMatrices != null) {
          _gl.uniformMatrix4fv(p_uniforms.boneGlobalMatrices, false, object.boneMatrices);
        }
      }
    }

    if (refreshMaterial) {
      // refresh uniforms common to several materials
      if ((fog != null) && material.fog) {
        refreshUniformsFog(m_uniforms, fog);
      }

      if (material.isMeshPhongMaterial ||
          material.isMeshLambertMaterial ||
          material.lights) {
        if (_lightsNeedUpdate) {
          setupLights(program, lights);
          _lightsNeedUpdate = false;
        }
        
        refreshUniformsLights(m_uniforms, _lights);
      }

      if (material.isMeshBasicMaterial ||
          material.isMeshLambertMaterial ||
          material.isMeshPhongMaterial) {
        refreshUniformsCommon(m_uniforms, material);
      }

      // refresh single material specific uniforms
      if (material.isLineBasicMaterial) {
        refreshUniformsLine(m_uniforms, material);

      // TODO - Implement LineDashedMaterial
      //} else if (material instanceof THREE.LineDashedMaterial) {

      //  refreshUniformsLine(m_uniforms, material);
      //  refreshUniformsDash(m_uniforms, material);

      } else if (material.isParticleSystemMaterial) {
        refreshUniformsParticle(m_uniforms, material);
      } else if (material.isMeshPhongMaterial) {
        refreshUniformsPhong(m_uniforms, material);
      } else if (material.isMeshLambertMaterial) {
        refreshUniformsLambert(m_uniforms, material);
      } else if (material.isMeshDepthMaterial) {
        m_uniforms["mNear"].value = camera.near;
        m_uniforms["mFar"].value = camera.far;
        m_uniforms["opacity"].value = material.opacity;
      } else if (material.isMeshNormalMaterial) {
        m_uniforms["opacity"].value = material.opacity;
      }

      if (object.receiveShadow && !material.shadowPass) {
        refreshUniformsShadow(m_uniforms, lights);
      }

      // load common uniforms
      loadUniformsGeneric(program, material.uniformsList);

      // load material specific uniforms
      // (shader material also gets them for the sake of genericity)
      if (material.isShaderMaterial ||
          material.isMeshPhongMaterial ||
          material.envMap != null) {
        if (p_uniforms["cameraPosition"] != null) {
          _vector3 = camera.matrixWorld.getTranslation();
          _gl.uniform3f(p_uniforms["cameraPosition"], _vector3.x, _vector3.y, _vector3.z);
        }
      }
        
      if (material.isMeshPhongMaterial ||
          material.isMeshLambertMaterial ||
          material.isShaderMaterial ||
          material.skinning) {
        if (p_uniforms["viewMatrix"] != null) {
          _gl.uniformMatrix4fv(p_uniforms["viewMatrix"], false, camera.matrixWorldInverse.storage);
        }
      }
    }

    loadUniformsMatrices(p_uniforms, object);

    if (p_uniforms.containsKey("modelMatrix")) {
      _gl.uniformMatrix4fv(p_uniforms["modelMatrix"], false, object.matrixWorld.storage);
    }

    return program;
  }

  // Uniforms (refresh uniforms objects)

  void refreshUniformsCommon(Map<String, Uniform> uniforms, WebGLMaterial material) {
    uniforms["opacity"].value = material.opacity;

    if (gammaInput) {
      uniforms["diffuse"].value.copyGammaToLinear(material.color);
    } else {
      uniforms["diffuse"].value = material.color;
    }

    uniforms["map"].value = material.map;
    uniforms["lightMap"].value = material.lightMap;
    uniforms["specularMap"].value = material.specularMap;

    if (material.bumpMap != null) {
      uniforms["bumpMap"].value = material.bumpMap;
      uniforms["bumpScale"].value = material.bumpScale;
    }

    if (material.normalMap != null) {
      uniforms["normalMap"].value = material.normalMap;
      uniforms["normalScale"].value.copy(material.normalScale);
    }

    // uv repeat and offset setting priorities
    //  1. color map
    //  2. specular map
    //  3. normal map
    //  4. bump map

    var uvScaleMap;

    if (material.map != null) {
      uvScaleMap = material.map;
    } else if (material.specularMap != null) {
      uvScaleMap = material.specularMap;
    } else if (material.normalMap != null) {
      uvScaleMap = material.normalMap;
    } else if (material.bumpMap != null) {
      uvScaleMap = material.bumpMap;
    }

    if (uvScaleMap != null) {
      Vector2 offset = uvScaleMap.offset;
      Vector2 repeat = uvScaleMap.repeat;

      uniforms["offsetRepeat"].value.setValues(offset.x, offset.y, repeat.x, repeat.y);
    }

    uniforms["envMap"].value = material.envMap;
    uniforms["flipEnvMap"].value = material.envMap is WebGLRenderTargetCube ? 1 : -1;

    if (gammaInput) {
      uniforms["reflectivity"].value = material.reflectivity;
    } else {
      uniforms["reflectivity"].value = material.reflectivity;
    }

    uniforms["refractionRatio"].value = material.refractionRatio;
    uniforms["combine"].value = material.combine;
    uniforms["useRefract"].value = material.envMap != null && material.envMap.mapping is CubeRefractionMapping ? 1:0;
  }

  void refreshUniformsLine(Map<String, Uniform> uniforms, WebGLMaterial material) {
    uniforms["diffuse"].value = material.color;
    uniforms["opacity"].value = material.opacity;
  }

  void refreshUniformsDash(Map<String, Uniform> uniforms, WebGLMaterial material) {
    uniforms["dashSize"].value = material.dashSize;
    uniforms["totalSize"].value = material.dashSize + material.gapSize;
    uniforms["scale"].value = material.scale;
  }

  void refreshUniformsParticle(Map<String, Uniform> uniforms, WebGLMaterial material) {
    uniforms["psColor"].value = material.color;
    uniforms["opacity"].value = material.opacity;
    uniforms["size"].value = material.size;
    uniforms["scale"].value = canvas.height / 2.0;

    uniforms["map"].value = material.map;
  }

  void refreshUniformsFog(Map<String, Uniform> uniforms, Fog fog) {
    uniforms["fogColor"].value = fog.color;

    if (fog is FogLinear) {
      uniforms["fogNear"].value = fog.near;
      uniforms["fogFar"].value = fog.far;
    } else if (fog is FogExp2) {
      uniforms["fogDensity"].value = fog.density;
    }
  }

  void refreshUniformsPhong(Map<String, Uniform> uniforms, WebGLMaterial material) {
    uniforms["shininess"].value = material.shininess;

    if (gammaInput) {
      uniforms["ambient"].value.copyGammaToLinear(material.ambient);
      uniforms["emissive"].value.copyGammaToLinear(material.emissive);
      uniforms["specular"].value.copyGammaToLinear(material.specular);
    } else {
      uniforms["ambient"].value = material.ambient;
      uniforms["emissive"].value = material.emissive;
      uniforms["specular"].value = material.specular;
    }

    if (material.wrapAround) {
      uniforms["wrapRGB"].value.copy(material.wrapRGB);
    }
  }

  void refreshUniformsLambert(Map<String, Uniform> uniforms, WebGLMaterial material) {
    if (gammaInput) {
      uniforms["ambient"].value.copyGammaToLinear(material.ambient);
      uniforms["emissive"].value.copyGammaToLinear(material.emissive);
    } else {
      uniforms["ambient"].value = material.ambient;
      uniforms["emissive"].value = material.emissive;
    }

    if (material.wrapAround) {
      uniforms["wrapRGB"].value.copy(material.wrapRGB);
    }
  }

  void refreshUniformsLights(Map<String, Uniform> uniforms, WebGLRendererLights lights) {
    uniforms["ambientLightColor"].value = lights.ambient;

    uniforms["directionalLightColor"].value = lights.directional.colors;
    uniforms["directionalLightDirection"].value = lights.directional.positions;

    uniforms["pointLightColor"].value = lights.point.colors;
    uniforms["pointLightPosition"].value = lights.point.positions;
    uniforms["pointLightDistance"].value = lights.point.distances;

    uniforms["spotLightColor"].value = lights.spot.colors;
    uniforms["spotLightPosition"].value = lights.spot.positions;
    uniforms["spotLightDistance"].value = lights.spot.distances;
    uniforms["spotLightDirection"].value = lights.spot.directions;
    uniforms["spotLightAngleCos"].value = lights.spot.anglesCos;
    uniforms["spotLightExponent"].value = lights.spot.exponents;

    uniforms["hemisphereLightSkyColor"].value = lights.hemi.skyColors;
    uniforms["hemisphereLightGroundColor"].value = lights.hemi.groundColors;
    uniforms["hemisphereLightDirection"].value = lights.hemi.positions;
  }

  void refreshUniformsShadow(Map<String, Uniform> uniforms, List<ShadowCaster> lights) {
    if (uniforms.containsKey("shadowMatrix")) {
      var j = 0;
      
      lights.where((e) => e.castShadow).forEach((light) {
        if (light is SpotLight || (light is DirectionalLight && !light.shadowCascade)) {
          // Grow the arrays
          if (uniforms["shadowMap"].value.length < j + 1) {
            uniforms["shadowMap"].value.length = j + 1;
            uniforms["shadowMapSize"].value.length = j + 1;
            uniforms["shadowMatrix"].value.length = j + 1;
            uniforms["shadowDarkness"].value.length = j + 1;
            uniforms["shadowBias"].value.length = j + 1;
          }

          uniforms["shadowMap"].value[j] = light.shadowMap;
          uniforms["shadowMapSize"].value[j] = light.shadowMapSize;

          uniforms["shadowMatrix"].value[j] = light.shadowMatrix;

          uniforms["shadowDarkness"].value[j] = light.shadowDarkness;
          uniforms["shadowBias"].value[j] = light.shadowBias;

          j++;
        }
      });
    }
  }

  // Uniforms (load to GPU)

  void loadUniformsMatrices(Map<String, gl.UniformLocation> uniforms, WebGLObject object) {
    _gl.uniformMatrix4fv(uniforms["modelViewMatrix"], false, object._modelViewMatrix.storage);

    if (uniforms["normalMatrix"] != null) {
      _gl.uniformMatrix3fv(uniforms["normalMatrix"], false, object._normalMatrix.storage);
    }
  }

  int getTextureUnit() {
    var unit = _usedTextureUnits;

    if (unit >= maxTextures) {
      print("WebGLRenderer: trying to use $unit texture units while this GPU supports only $maxTextures");
    }

    _usedTextureUnits += 1;
    return unit;
  }

  void loadUniformsGeneric(WebGLRendererProgram program, List<List> uniforms) {
    for (var j = 0; j < uniforms.length; j++) {
      var location = program.uniforms[uniforms[j][1]];
      if (location == null) continue;

      var uniform = uniforms[j][0];

      var type = uniform.type;
      var value = uniform.typedValue; // Get the value properly typed
      
      switch(type) {
        case 'i':  // single integer
          _gl.uniform1i(location, value);  
          break;
        case 'f':  // single float
          _gl.uniform1f(location, value); 
          break;
        case 'v2':  // single Vector2
          _gl.uniform2f(location, value.x, value.y);  
          break;
        case 'v3':  // single Vector3
          _gl.uniform3f(location, value.x, value.y, value.z); 
          break;
        case 'v4':  // single Vector4
          _gl.uniform4f(location, value.x, value.y, value.z, value.w); 
          break;
        case 'c':   // single Color
          _gl.uniform3f(location, value.r, value.g, value.b);
          break;
        case 'iv1': // flat array of integers (JS or typed array)
          _gl.uniform1iv(location, value);
          break;
        case 'iv':  // flat array of integers with 3 x N size (JS or typed array)
          _gl.uniform3iv(location, value);
          break;
        case 'fv1': // flat array of floats (JS or typed array)
          _gl.uniform1fv(location, value);
          break;
        case 'fv':  // flat array of floats with 3 x N size (JS or typed array)
          _gl.uniform3fv(location, value);
          break;
        case 'v2v': // array of Vector2
          _gl.uniform2fv(location, value);
          break;
        case 'v3v': // array of Vector3
          _gl.uniform3fv(location, value);
          break;
        case 'v4v': // array of Vector4
          _gl.uniform4fv(location, value);
          break;
        case 'm2':  // single Matrix2
          _gl.uniformMatrix2fv(location, false, value);
          break; 
        case 'm3':  // single Matrix3
          _gl.uniformMatrix3fv(location, false, value);
          break;
        case 'm4':  // single Matrix4
          _gl.uniformMatrix4fv(location, false, value);
          break; 
        case 'm4v': // array of Matrix4
          _gl.uniformMatrix4fv(location, false, value);
          break;
        case 't':   // single Texture (2d or cube)
          var texture = uniform.value;
          var textureUnit = getTextureUnit();

          _gl.uniform1i(location, textureUnit);

          if (texture == null) continue;

          if ((texture.image is ImageList || texture.image is WebGLImageList) && texture.image.length == 6) {
            setCubeTexture(texture, textureUnit);
          } else if (texture is WebGLRenderTargetCube) {
            setCubeTextureDynamic(texture, textureUnit);
          } else {
            setTexture(texture, textureUnit);
          }
          break; 
        case 'tv':   // array of THREE.Texture (2d)
          List<Texture> textures = uniform.value;
          
          uniform._array = new Int32List.fromList(textures.map((_) => getTextureUnit()).toList());
          _gl.uniform1iv(location, uniform._array);
          
          for(var i = 0; i < textures.length; i++) {
            var texture = uniform.value[i];
            var textureUnit = uniform._array[i];

            if (texture == null) continue;

            setTexture(texture, textureUnit);
          }
        break;
      }
    }
  }

  void setColorGamma(List<double> array, int offset, Color color, double intensitySq) {
    array[offset]     = color.r * color.r * intensitySq;
    array[offset + 1] = color.g * color.g * intensitySq;
    array[offset + 2] = color.b * color.b * intensitySq;
  }

  void setColorLinear(List<double> array, int offset, Color color, double intensity) {
    array[offset]     = color.r * intensity;
    array[offset + 1] = color.g * intensity;
    array[offset + 2] = color.b * intensity;
  }

  
  void setupMatrices(WebGLObject object, WebGLCamera camera) {
    object._modelViewMatrix = camera.matrixWorldInverse * object.matrixWorld;
    object._normalMatrix = object._modelViewMatrix.getNormalMatrix();
  }

  void setupLights(WebGLRendererProgram program, List<Light> lights) {
    var r = 0.0, g = 0.0, b = 0.0,
    zlights = _lights;

    var dirColors    = zlights.directional.colors,
        dirPositions = zlights.directional.positions,

        pointColors    = zlights.point.colors,
        pointPositions = zlights.point.positions,
        pointDistances = zlights.point.distances,
  
        spotColors     = zlights.spot.colors,
        spotPositions  = zlights.spot.positions,
        spotDistances  = zlights.spot.distances,
        spotDirections = zlights.spot.directions,
        spotAnglesCos  = zlights.spot.anglesCos,
        spotExponents  = zlights.spot.exponents,
  
        hemiSkyColors    = zlights.hemi.skyColors,
        hemiGroundColors = zlights.hemi.groundColors,
        hemiPositions    = zlights.hemi.positions;

    var dirLength = 0,
        pointLength = 0,
        spotLength = 0,
        hemiLength = 0,

        dirCount = 0,
        pointCount = 0,
        spotCount = 0,
        hemiCount = 0,

        dirOffset = 0,
        pointOffset = 0,
        spotOffset = 0,
        hemiOffset = 0;

    for (var l = 0; l < lights.length; l++) {
      var light = lights[l];
      
      if (light is ShadowCaster && light.onlyShadow) continue;

      var color = light.color,
          intensity,
          distance;

      if (light is LightWithDistance) {
        distance = light.distance;
      }
      
      if (light is! AmbientLight) {
        intensity = (light as dynamic).intensity;
      }

      if (light is AmbientLight) {
        if (!light.visible) continue;
          
        if (gammaInput) {
          r += color.r * color.r;
          g += color.g * color.g;
          b += color.b * color.b;
        } else {
          r += color.r;
          g += color.g;
          b += color.b;
        }
      } else if (light is DirectionalLight) {
        dirCount += 1;

        if (!light.visible) continue;

        _direction = light.matrixWorld.getTranslation();
        _vector3 = light.target.matrixWorld.getTranslation();
        _direction.sub(_vector3);
        _direction.normalize();

        // skip lights with undefined direction
        // these create troubles in OpenGL (making pixel black)
        if (_direction.isZero) continue;

        dirOffset = dirLength * 3;
  
        // Grow the lists
        dirColors.length = dirOffset + 3;
        dirPositions.length = dirOffset + 3;

        dirPositions[dirOffset]     = _direction.x;
        dirPositions[dirOffset + 1] = _direction.y;
        dirPositions[dirOffset + 2] = _direction.z;

        if (gammaInput) {
          setColorGamma(dirColors, dirOffset, color, intensity * intensity);
        } else {
          setColorLinear(dirColors, dirOffset, color, intensity);
        }

        dirLength += 1;
      } else if (light is PointLight) {
        pointCount += 1;

        if (!light.visible) continue;

        pointOffset = pointLength * 3;

        // Grow the lists
        pointColors.length = pointOffset + 3;
        pointPositions.length = pointOffset + 3;
        pointDistances.length = pointLength + lights.length - 1;

        if (gammaInput) {
          setColorGamma(pointColors, pointOffset, color, intensity * intensity);
        } else {
          setColorLinear(pointColors, pointOffset, color, intensity);
        }

        var position = light.matrixWorld.getTranslation();

        pointPositions[pointOffset]     = position.x;
        pointPositions[pointOffset + 1] = position.y;
        pointPositions[pointOffset + 2] = position.z;
        
        pointDistances[pointLength] = distance;

        pointLength += 1;
      } else if (light is SpotLight) {
        spotCount += 1;

        spotOffset = spotLength * 3;

        if (!light.visible) continue;

        // Grow the lists
        spotColors.length = spotOffset + 3;
        spotPositions.length = spotOffset + 3;
        spotDirections.length = spotOffset + 3;
        spotDistances.length = spotLength + 1;

        if (gammaInput) {
          setColorGamma(spotColors, spotOffset, color, intensity * intensity);
        } else {
          setColorLinear(spotColors, spotOffset, color, intensity);
        }

        var position = light.matrixWorld.getTranslation();

        spotPositions[spotOffset]     = position.x;
        spotPositions[spotOffset + 1] = position.y;
        spotPositions[spotOffset + 2] = position.z;

        spotDistances[spotLength] = distance;

        _direction.setFrom(position);
        _direction.sub(light.target.matrixWorld.getTranslation());
        _direction.normalize();

        spotDirections[spotOffset]     = _direction.x;
        spotDirections[spotOffset + 1] = _direction.y;
        spotDirections[spotOffset + 2] = _direction.z;

        // grow the arrays
        spotAnglesCos.length = spotLength + 1;
        spotExponents.length = spotLength + 1;

        spotAnglesCos[spotLength] = Math.cos(light.angle);
        spotExponents[spotLength] = light.exponent;

        spotLength += 1;
      } else if (light is HemisphereLight) {
        hemiCount += 1;

        if (!light.visible) continue;

        var position = light.matrixWorld.getTranslation();
        _direction.setFrom(position);
        _direction.normalize();

        // skip lights with undefined direction
        // these create troubles in OpenGL (making pixel black)
        if (_direction.isZero) continue;
        
        hemiOffset = hemiLength * 3;

        // Grow the lists
        hemiSkyColors.length = hemiOffset + 3;
        hemiGroundColors.length = hemiOffset + 3;
        hemiPositions.length = hemiOffset + 3;

        hemiPositions[hemiOffset]     = _direction.x;
        hemiPositions[hemiOffset + 1] = _direction.y;
        hemiPositions[hemiOffset + 2] = _direction.z;

        var skyColor = light.color;
        var groundColor = light.groundColor;

        if (gammaInput) {
          var intensitySq = intensity * intensity;

          setColorGamma(hemiSkyColors, hemiOffset, skyColor, intensitySq);
          setColorGamma(hemiGroundColors, hemiOffset, groundColor, intensitySq);
        } else {
          setColorLinear(hemiSkyColors, hemiOffset, skyColor, intensity);
          setColorLinear(hemiGroundColors, hemiOffset, groundColor, intensity);
        }

        hemiLength += 1;
      }
    }

    // null eventual remains from removed lights
    // (this is to avoid if in shader)
    
    _nullColors(length, colors, count) {
      for (var l = length * 3; l < Math.max(colors.length, count * 3); l++) {
        colors[l] = 0.0;
      }
    }
      
    _nullColors(dirLength, dirColors, dirCount);
    _nullColors(pointLength, pointColors, pointCount);
    _nullColors(spotLength, spotColors, spotCount);
    _nullColors(hemiLength, hemiSkyColors, hemiCount);
    _nullColors(hemiLength, hemiGroundColors, hemiCount);

    zlights.directional.length = dirLength;
    zlights.point.length = pointLength;
    zlights.spot.length = spotLength;
    zlights.hemi.length = hemiLength;

    zlights.ambient[0] = r;
    zlights.ambient[1] = g;
    zlights.ambient[2] = b;
  }

  // GL state setting
  void setFaceCulling(int cullFace, int frontFaceDirection) {
    if (cullFace == CULL_FACE_NONE) {
      _gl.disable(gl.CULL_FACE);
    } else {
      if (frontFaceDirection == FRONT_FACE_DIRECTION_CW) {
        _gl.frontFace(gl.CW);
      } else {
        _gl.frontFace(gl.CCW);
      }

      if (cullFace == CULL_FACE_BACK) {
        _gl.cullFace(gl.BACK);
      } else if (cullFace == CULL_FACE_FRONT) {
        _gl.cullFace(gl.FRONT);
      } else {
        _gl.cullFace(gl.FRONT_AND_BACK);
      }
      
      _gl.enable(gl.CULL_FACE);
    }
  }

  void setMaterialFaces(WebGLMaterial material) {
    var doubleSided = material.side == DOUBLE_SIDE;
    var flipSided = material.side == BACK_SIDE;
  
    if (_oldDoubleSided != doubleSided) {
      if (doubleSided) {
        _gl.disable(gl.CULL_FACE);
      } else {
        _gl.enable(gl.CULL_FACE);
      }
      
      _oldDoubleSided = doubleSided;
    }
  
    if (_oldFlipSided != flipSided) {
      if (flipSided) {
        _gl.frontFace(gl.CW);
      } else {
        _gl.frontFace(gl.CCW);
      }
  
      _oldFlipSided = flipSided;
    }
  }
  
  void setDepthTest(bool depthTest) {
    if (_oldDepthTest != depthTest) {
      if (depthTest) {
        _gl.enable(gl.DEPTH_TEST);
      } else {
        _gl.disable(gl.DEPTH_TEST);
      }
      
      _oldDepthTest = depthTest;
    }
  }

  void setDepthWrite(bool depthWrite) {
    if (_oldDepthWrite != depthWrite) {
      _gl.depthMask(depthWrite);
      _oldDepthWrite = depthWrite;
    }
  }

  void setLineWidth(double width) {
    if (width != _oldLineWidth) {
      _gl.lineWidth(width);
      _oldLineWidth = width;
    }
  }

  void setPolygonOffset(bool polygonoffset, int factor, int units) {
    if (_oldPolygonOffset != polygonoffset) {
      if (polygonoffset) {
        _gl.enable(gl.POLYGON_OFFSET_FILL);
      } else {
        _gl.disable(gl.POLYGON_OFFSET_FILL);
      }
      
      _oldPolygonOffset = polygonoffset;
    }

    if (polygonoffset && (_oldPolygonOffsetFactor != factor || _oldPolygonOffsetUnits != units)) {
      _gl.polygonOffset(factor, units);

      _oldPolygonOffsetFactor = factor;
      _oldPolygonOffsetUnits = units;
    }
  }

  void setBlending(int blending, [int blendEquation, int blendSrc, int blendDst]) {
    if (blending != _oldBlending) {
      if (blending == NO_BLENDING) {
        _gl.disable(gl.BLEND);
      } else if (blending == ADDITIVE_BLENDING) {
        _gl.enable(gl.BLEND);
        _gl.blendEquation(gl.FUNC_ADD);
        _gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
      } else if (blending == SUBTRACTIVE_BLENDING) {
        _gl.enable(gl.BLEND);
        _gl.blendEquation(gl.FUNC_ADD);
        _gl.blendFunc(gl.ZERO, gl.ONE_MINUS_SRC_COLOR);
      } else if (blending == MULTIPLY_BLENDING) {
        _gl.enable(gl.BLEND);
        _gl.blendEquation(gl.FUNC_ADD);
        _gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
      } else if (blending == CUSTOM_BLENDING) {
        _gl.enable(gl.BLEND);
      } else {
        _gl.enable(gl.BLEND);
        _gl.blendEquationSeparate(gl.FUNC_ADD, gl.FUNC_ADD);
        _gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
      }

      _oldBlending = blending;
    }

    if (blending == CUSTOM_BLENDING) {
      if (blendEquation != _oldBlendEquation) {
        _gl.blendEquation(paramThreeToGL(blendEquation));
        blendEquation = blendEquation;
      }

      if (blendSrc != _oldBlendSrc || blendDst != _oldBlendDst) {
        _gl.blendFunc(paramThreeToGL(blendSrc), paramThreeToGL(blendDst));

        _oldBlendSrc = blendSrc;
        _oldBlendDst = blendDst;
      }
        
    } else {
      _oldBlendEquation = null;
      _oldBlendSrc = null;
      _oldBlendDst = null;
    }
  }

  // Defines

  String generateDefines(Map<String, bool> defines) {
    var chunks = [];

    defines.forEach((d, value) {
      if (value != false) {
        chunks.add("#define $d $value");
      }
    });
    
    return chunks.join("\n");
  }

  // Shaders

  WebGLRendererProgram buildProgram(String shaderID, 
                                    String fragmentShader, 
                                    String vertexShader, 
                                    Map<String, Uniform> uniforms, 
                                    Map<String, Attribute> attributes, 
                                    Map<String, bool> defines, 
                                    String index0AttributeName,
                                   {int maxDirLights: 0,
                                    int maxPointLights: 0,
                                    int maxSpotLights: 0,
                                    int maxHemiLights: 0,
                                    int maxShadows: 0,
                                    int maxBones: 0,
                                    Texture map,
                                    Texture envMap,
                                    Texture lightMap,
                                    Texture bumpMap,
                                    Texture normalMap,
                                    Texture specularMap,
                                    int vertexColors: NO_COLORS,
                                    bool skinning: false,
                                    bool useVertexTexture: false,
                                    int boneTextureWidth,
                                    int boneTextureHeight,
                                    bool morphTargets: false,
                                    bool morphNormals: false,
                                    bool perPixel: false,
                                    bool wrapAround: false,
                                    bool doubleSided: false,
                                    bool flipSided: false,
                                    bool shadowMapEnabled: false,
                                    int shadowMapType,
                                    bool shadowMapDebug: false,
                                    bool shadowMapCascade: false,
                                    bool sizeAttenuation: false,
                                    Fog fog,
                                    bool useFog: false,
                                    bool fogExp: false,
                                    int maxMorphTargets: 8,
                                    int maxMorphNormals: 4,
                                    int alphaTest: 0,
                                    bool metal: false}) {
      var chunks = [];

      // Generate code

      if (shaderID != null) {
        chunks.add(shaderID);
      } else {
        chunks.add(fragmentShader);
        chunks.add(vertexShader);
      }

      defines.forEach((d, define) {
        chunks.add(d);
        chunks.add(define);
      });
      
      var code = """${chunks.join()}
                    maxDirLights$maxDirLights
                    maxPointLights$maxPointLights
                    maxSpotLights$maxSpotLights
                    maxHemiLights$maxHemiLights
                    maxShadows$maxShadows
                    maxBones$maxBones
                    map$map
                    envMap$envMap
                    lightMap$lightMap
                    bumpMap$bumpMap
                    normalMap$normalMap
                    specularMap$specularMap
                    vertexColors$vertexColors
                    fog$fog
                    useFog$useFog
                    fogExp$fogExp
                    skinning$skinning
                    useVertexTexture$useVertexTexture
                    boneTextureWidth$boneTextureWidth
                    boneTextureHeight$boneTextureHeight
                    morphTargets$morphTargets
                    morphNormals$morphNormals
                    perPixel$perPixel
                    wrapAround$wrapAround
                    doubleSided$doubleSided
                    flipSided$flipSided
                    shadowMapEnabled$shadowMapEnabled
                    shadowMapType$shadowMapType
                    shadowMapDebug$shadowMapDebug
                    shadowMapCascade$shadowMapCascade
                    sizeAttenuation$sizeAttenuation""";

      // Check if code has been already compiled
      for (var p = 0; p < _programs.length; p++) {
         var program = _programs[p];
         
         if (program.code == code) {
           program.usedTimes++;
           return program;
         }
      }

      var shadowMapTypeDefine = "SHADOWMAP_TYPE_BASIC";

      if (shadowMapType == PCF_SHADOW_MAP) {
        shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF";
      } else if (shadowMapType == PCF_SOFT_SHADOW_MAP) {
        shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF_SOFT";
      }

      //

      var customDefines = generateDefines(defines);

      var glprogram = _gl.createProgram();
      
      var prefix_vertex = """
        precision $precision float;
        precision $precision int;
        
        $customDefines
        
        ${supportsVertexTextures ? "#define VERTEX_TEXTURES" : ""}
              
        ${gammaInput ? "#define GAMMA_INPUT" : ""}
        ${gammaOutput ? "#define GAMMA_OUTPUT" : ""}
        ${physicallyBasedShading ? "#define PHYSICALLY_BASED_SHADING" : ""}
        
        #define MAX_DIR_LIGHTS $maxDirLights
        #define MAX_POINT_LIGHTS $maxPointLights
        #define MAX_SPOT_LIGHTS $maxSpotLights
        #define MAX_HEMI_LIGHTS $maxHemiLights
        
        #define MAX_SHADOWS $maxShadows
        
        #define MAX_BONES $maxBones
        
        ${map != null ? "#define USE_MAP" : ""}
        ${envMap != null ? "#define USE_ENVMAP" : ""}
        ${lightMap != null ? "#define USE_LIGHTMAP" : ""}
        ${bumpMap != null ? "#define USE_BUMPMAP" : ""}
        ${normalMap != null ? "#define USE_NORMALMAP" : ""}
        ${specularMap != null ? "#define USE_SPECULARMAP" : ""}
        ${vertexColors != NO_COLORS ? "#define USE_COLOR" : ""}
        
        ${skinning ? "#define USE_SKINNING" : ""}
        ${useVertexTexture ? "#define BONE_TEXTURE" : ""}
        
        ${morphTargets ? "#define USE_MORPHTARGETS" : ""}
        ${morphNormals ? "#define USE_MORPHNORMALS" : ""}
        ${perPixel ? "#define PHONG_PER_PIXEL" : ""}
        ${wrapAround ? "#define WRAP_AROUND" : ""}
        ${doubleSided ? "#define DOUBLE_SIDED" : ""}
        ${flipSided ? "#define FLIP_SIDED" : ""}
        
        ${shadowMapEnabled ? "#define USE_SHADOWMAP" : ""}
        ${shadowMapEnabled ? "#define $shadowMapTypeDefine" : ""}
        ${shadowMapDebug ? "#define SHADOWMAP_DEBUG" : ""}
        ${shadowMapCascade ? "#define SHADOWMAP_CASCADE" : ""}
        
        ${sizeAttenuation ? "#define USE_SIZEATTENUATION" : ""}
        
        uniform mat4 modelMatrix;
        uniform mat4 modelViewMatrix;
        uniform mat4 projectionMatrix;
        uniform mat4 viewMatrix;
        uniform mat3 normalMatrix;
        uniform vec3 cameraPosition;
        
        attribute vec3 position;
        attribute vec3 normal;
        attribute vec2 uv;
        attribute vec2 uv2;
        
        #ifdef USE_COLOR
          attribute vec3 color;
        #endif
        
        #ifdef USE_MORPHTARGETS
          attribute vec3 morphTarget0;
          attribute vec3 morphTarget1;
          attribute vec3 morphTarget2;
          attribute vec3 morphTarget3;
          #ifdef USE_MORPHNORMALS
            attribute vec3 morphNormal0;
            attribute vec3 morphNormal1;
            attribute vec3 morphNormal2;
            attribute vec3 morphNormal3;
          #else
            attribute vec3 morphTarget4;
            attribute vec3 morphTarget5;
            attribute vec3 morphTarget6;
            attribute vec3 morphTarget7;
          #endif
        #endif
        #ifdef USE_SKINNING
          attribute vec4 skinIndex;
          attribute vec4 skinWeight;
        #endif
""";
        
        var prefix_fragment = """
          precision $precision float;
          precision $precision int;

          ${bumpMap != null || normalMap != null ? "#extension GL_OES_standard_derivatives : enable" : ""}

          $customDefines

          ${bumpMap != null ? "#extension GL_OES_standard_derivatives : enable" : ""}

          #define MAX_DIR_LIGHTS $maxDirLights
          #define MAX_POINT_LIGHTS $maxPointLights
          #define MAX_SPOT_LIGHTS $maxSpotLights
          #define MAX_HEMI_LIGHTS $maxHemiLights

          #define MAX_SHADOWS $maxShadows

          ${alphaTest != 0 ? "#define ALPHATEST $alphaTest": ""}

          ${gammaInput ? "#define GAMMA_INPUT" : ""}
          ${gammaOutput ? "#define GAMMA_OUTPUT" : ""}
          ${physicallyBasedShading ? "#define PHYSICALLY_BASED_SHADING" : ""}

          ${useFog && fog != null ? "#define USE_FOG" : ""}
          ${useFog && fog is FogExp2 ? "#define FOG_EXP2" : ""}

          ${map != null ? "#define USE_MAP" : ""}
          ${envMap != null ? "#define USE_ENVMAP" : ""}
          ${lightMap != null ? "#define USE_LIGHTMAP" : ""}
          ${bumpMap != null ? "#define USE_BUMPMAP" : ""}
          ${normalMap != null ? "#define USE_NORMALMAP" : ""}
          ${specularMap != null ? "#define USE_SPECULARMAP" : ""}
          ${vertexColors != NO_COLORS ? "#define USE_COLOR" : ""}

          ${metal ? "#define METAL" : ""}
          ${perPixel ? "#define PHONG_PER_PIXEL" : ""}
          ${wrapAround ? "#define WRAP_AROUND" : ""}
          ${doubleSided ? "#define DOUBLE_SIDED" : ""}
          ${flipSided ? "#define FLIP_SIDED" : ""}

          ${shadowMapEnabled ? "#define USE_SHADOWMAP" : ""}
          ${shadowMapEnabled ? "#define $shadowMapTypeDefine" : ""}
          ${shadowMapDebug ? "#define SHADOWMAP_DEBUG" : ""}
          ${shadowMapCascade ? "#define SHADOWMAP_CASCADE" : ""}

          uniform mat4 viewMatrix;
          uniform vec3 cameraPosition;
""";
     
      var glFragmentShader = getShader("fragment", "$prefix_fragment$fragmentShader");
      var glVertexShader = getShader("vertex", "$prefix_vertex$vertexShader");

      _gl.attachShader(glprogram, glVertexShader);
      _gl.attachShader(glprogram, glFragmentShader);
      
    //Force a particular attribute to index 0.
    //because potentially expensive emulation is done by browser if attribute 0 is disabled.
    //And, color, for example is often automatically bound to index 0 so disabling it
    if (index0AttributeName != null) {
      _gl.bindAttribLocation(glprogram, 0, index0AttributeName);
    }
  
    _gl.linkProgram(glprogram);
  
    if (!_gl.getProgramParameter(glprogram, gl.LINK_STATUS)) {
      var status = _gl.getProgramParameter(glprogram, gl.VALIDATE_STATUS);
      var error = _gl.getError();
      print("Could not initialise shader\nVALIDATE_STATUS: $status, gl error [$error]");
      print("Program Info Log: ${_gl.getProgramInfoLog(glprogram)}");
    }

    // clean up
    _gl.deleteShader(glFragmentShader);
    _gl.deleteShader(glVertexShader);

    var program = new WebGLRendererProgram(_programs_counter++, glprogram, code, usedTimes: 1);

    // cache uniform locations
    var identifiers = 
        ['viewMatrix', 'modelViewMatrix', 'projectionMatrix', 'normalMatrix', 'modelMatrix', 'cameraPosition',
         'morphTargetInfluences'];

    if (useVertexTexture) {
      identifiers.add('boneTexture');
      identifiers.add('boneTextureWidth');
      identifiers.add('boneTextureHeight');
    } else {
      identifiers.add('boneGlobalMatrices');
    }

    uniforms.forEach((u, _) => identifiers.add(u));

    cacheUniformLocations(program, identifiers);

    // cache attributes locations

    identifiers = 
        ["position", "normal", "uv", "uv2", "tangent", "color",
         "skinIndex", "skinWeight", "lineDistance"];

    for (var i = 0; i < maxMorphTargets; i++) {
      identifiers.add("morphTarget$i");
    }

    for (var i = 0; i < maxMorphNormals; i++) {
      identifiers.add("morphNormal$i");
    }

    if (attributes != null) {
      attributes.forEach((a, _) => identifiers.add(a));
    }

    cacheAttributeLocations(program, identifiers);
    
    _programs.add(program);
    
    info.memory.programs = _programs.length;
    
    return program;
  }

  // Shader parameters cache

  void cacheUniformLocations(WebGLRendererProgram program, List<String> identifiers) {
    identifiers.forEach((id) => program.uniforms[id] = _gl.getUniformLocation(program.glProgram, id));
  }

  void cacheAttributeLocations(WebGLRendererProgram program, List<String> identifiers) {
    identifiers.forEach((id) => program.attributes[id] = _gl.getAttribLocation(program.glProgram, id));
  }

  String addLineNumbers(String string) {
    var chunks = string.split("\n");
    
    for (var i = 0; i < chunks.length; i++) {
      // Chrome reports shader errors on lines
      // starting counting from 1
      chunks[i] = "${i + 1}:${chunks[i]}";
    }

    return chunks.join("\n");
  }

  gl.Shader getShader(String type, String string) {
    var shader;

    if (type == "fragment") {
      shader = _gl.createShader(gl.FRAGMENT_SHADER);
    } else if (type == "vertex") {
      shader = _gl.createShader(gl.VERTEX_SHADER);
    }

    _gl.shaderSource(shader, string);
    _gl.compileShader(shader);

    if (!_gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      print(_gl.getShaderInfoLog(shader));
      print(addLineNumbers(string));
      return null;
    }

    return shader;
  }

  // Textures
  void setTextureParameters(int textureType, Texture texture, bool isImagePowerOfTwo) {
    if (isImagePowerOfTwo) {
      _gl.texParameteri(textureType, gl.TEXTURE_WRAP_S, paramThreeToGL(texture.wrapS));
      _gl.texParameteri(textureType, gl.TEXTURE_WRAP_T, paramThreeToGL(texture.wrapT));

      _gl.texParameteri(textureType, gl.TEXTURE_MAG_FILTER, paramThreeToGL(texture.magFilter));
      _gl.texParameteri(textureType, gl.TEXTURE_MIN_FILTER, paramThreeToGL(texture.minFilter));
    } else {
      _gl.texParameteri(textureType, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      _gl.texParameteri(textureType, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

      _gl.texParameteri(textureType, gl.TEXTURE_MAG_FILTER, filterFallback(texture.magFilter));
      _gl.texParameteri(textureType, gl.TEXTURE_MIN_FILTER, filterFallback(texture.minFilter));
    }

    if ((_glExtensionTextureFilterAnisotropic != null) && texture.type != FLOAT_TYPE) {
      if (texture.anisotropy > 1 || texture["__oldAnisotropy"] != null) {
        _gl.texParameterf(textureType, gl.ExtTextureFilterAnisotropic.TEXTURE_MAX_ANISOTROPY_EXT, Math.min(texture.anisotropy, maxAnisotropy));
        texture["__oldAnisotropy"] = texture.anisotropy;
      }
    }
  }

  void _checkGLError() {
    int error = _gl.getError();
    if (error != 0) print("gl error [$error]");
  }

  void setTexture(Texture texture, int slot) {
    if (texture.needsUpdate) {
      if (texture["__webglInit"] == null) {
        texture["__webglInit"] = true;
  
        //texture.addEventListener('dispose', onTextureDispose);
        texture["__webglTexture"] = _gl.createTexture();
  
        info.memory.textures++;
      }
        
      _gl.activeTexture(gl.TEXTURE0 + slot);
      _gl.bindTexture(gl.TEXTURE_2D, texture["__webglTexture"]);
    
      _gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, (texture.flipY) ? 1 : 0);
      _gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, (texture.premultiplyAlpha) ? 1 : 0);
      _gl.pixelStorei(gl.UNPACK_ALIGNMENT, texture.unpackAlignment);
    
      var image = texture.image,
          isImagePowerOfTwo = MathUtils.isPowerOfTwo(image.width) && MathUtils.isPowerOfTwo(image.height),
          glFormat = paramThreeToGL(texture.format),
          glType = paramThreeToGL(texture.type);
    
      setTextureParameters(gl.TEXTURE_2D, texture, isImagePowerOfTwo);
    
      var mipmap, mipmaps = texture.mipmaps;
    
      if (texture is DataTexture) {
        // use manually created mipmaps if available
        // if there are no manual mipmaps
        // set 0 level mipmap and then use GL to generate other mipmap levels
        if (mipmaps.length > 0 && isImagePowerOfTwo) {
          for (var i = 0; i < mipmaps.length; i++) {
            mipmap = mipmaps[i];
            _gl.texImage2DTyped(gl.TEXTURE_2D, i, glFormat, mipmap.width, mipmap.height, 0, glFormat, glType, mipmap.data);
          }
    
          texture.generateMipmaps = false;
        } else {
          _gl.texImage2DTyped(gl.TEXTURE_2D, 0, glFormat, image.width, image.height, 0, glFormat, glType, image.data);
        }
      } else if (texture is CompressedTexture) {
        for (var i = 0; i < mipmaps.length; i++) {
          mipmap = mipmaps[i];
          
          if (texture.format != RGBA_FORMAT) {
            _gl.compressedTexImage2D(gl.TEXTURE_2D, i, glFormat, mipmap.width, mipmap.height, 0, mipmap.data);
          } else {
            _gl.texImage2D(gl.TEXTURE_2D, i, glFormat, mipmap.width, mipmap.height, 0, glFormat, glType, mipmap.data);
          }
        }
      } else { // regular Texture (image, video, canvas)
    
        // use manually created mipmaps if availabl 
        // if there are no manual mipmaps
        // set 0 level mipmap and then use GL to generate other mipmap levels
    
        if (mipmaps.length > 0 && isImagePowerOfTwo) {
          for (var i = 0; i < mipmaps.length; i++) {
            mipmap = mipmaps[i];
            _gl.texImage2D(gl.TEXTURE_2D, i, glFormat, glFormat, glType, mipmap);
          }
    
          texture.generateMipmaps = false;
    
        } else if (texture.image is ImageElement) {
          _gl.texImage2DImage(gl.TEXTURE_2D, 0, glFormat, glFormat, glType, texture.image);
        } else if (texture.image is CanvasElement) {
          _gl.texImage2DCanvas(gl.TEXTURE_2D, 0, glFormat, glFormat, glType, texture.image);
        } else if (texture.image is VideoElement) {
          _gl.texImage2DVideo(gl.TEXTURE_2D, 0, glFormat, glFormat, glType, texture.image);
        }
      }
    
      if (texture.generateMipmaps && isImagePowerOfTwo) {
        _gl.generateMipmap(gl.TEXTURE_2D);
      }
      
      texture.needsUpdate = false;
          
      if (texture.onUpdate != null) texture.onUpdate();
    } else {
      _gl.activeTexture(gl.TEXTURE0 + slot);
      _gl.bindTexture(gl.TEXTURE_2D, texture["__webglTexture"]);
    }
  }

  void clampToMaxSize(image, maxSize) {
    if (image.width <= maxSize && image.height <= maxSize) {
      return image;
    }

    // Warning: Scaling through the canvas will only work with images that use
    // premultiplied alpha.

    var maxDimension = Math.max(image.width, image.height);
    var newWidth = (image.width * maxSize / maxDimension).floor();
    var newHeight = (image.height * maxSize / maxDimension).floor();

    var canvas = new CanvasElement()
    ..width = newWidth
    ..height = newHeight;

    var ctx = canvas.context2D;
    ctx.drawImageScaledFromSource(image, 0, 0, image.width, image.height, 0, 0, newWidth, newHeight);

    return canvas;
  }

  void setCubeTexture(Texture texture, int slot) {
    if (texture.image.length == 6) {
      if(texture.image is ImageList){
        texture.image = new WebGLImageList(texture.image);
      }
        
      if (texture.needsUpdate) {
        if (texture.image.webglTextureCube == null) {
          //TODO texture.addEventListener('dispose', onTextureDispose);
          texture.image.webglTextureCube = _gl.createTexture();
          info.memory.textures++;
        }

        _gl.activeTexture(gl.TEXTURE0 + slot);
        _gl.bindTexture(gl.TEXTURE_CUBE_MAP, texture.image.webglTextureCube);

        _gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, texture.flipY ? 1 : 0);

        var isCompressed = texture is CompressedTexture;
        
        var cubeImage = new List(6);

        for (var i = 0; i < 6; i++) {
          if (autoScaleCubemaps && !isCompressed) {
            cubeImage[i] = clampToMaxSize(texture.image[i], maxCubemapSize);
          } else {
            cubeImage[i] = texture.image[i];
          }
        }

        var image = cubeImage[0],
        isImagePowerOfTwo = MathUtils.isPowerOfTwo((image as dynamic).width) && MathUtils.isPowerOfTwo((image as dynamic).height),
        glFormat = paramThreeToGL(texture.format),
        glType = paramThreeToGL(texture.type);

        setTextureParameters(gl.TEXTURE_CUBE_MAP, texture, isImagePowerOfTwo);

        for (var i = 0; i < 6; i++) {
          if (!isCompressed) {
            _gl.texImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, glFormat, glFormat, glType, cubeImage[i]);
          } else {
            var mipmap, mipmaps = cubeImage[i].mipmaps;
      
            for(var j = 0; j < mipmaps.length; j++) {
              var mipmap = mipmaps[j];
              if (texture.format != RGBA_FORMAT) {
                _gl.compressedTexImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j, glFormat, mipmap.width, mipmap.height, 0, mipmap.data);
              } else {
                _gl.texImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j, glFormat, mipmap.width, mipmap.height, 0, glFormat, glType, mipmap.data);
              }
            }
          }
        }

        if (texture.generateMipmaps && isImagePowerOfTwo) {
          _gl.generateMipmap(gl.TEXTURE_CUBE_MAP);
        }

        texture.needsUpdate = false;

        if (texture.onUpdate != null) texture.onUpdate();
      } else {
        _gl.activeTexture(gl.TEXTURE0 + slot);
        _gl.bindTexture(gl.TEXTURE_CUBE_MAP, texture.image.webglTextureCube);
      }
    }
  }

  void setCubeTextureDynamic(Texture texture, int slot) {
    _gl.activeTexture(gl.TEXTURE0 + slot);
    _gl.bindTexture(gl.TEXTURE_CUBE_MAP, texture["__webglTexture"]);
  }

  // Render targets
  void setupFrameBuffer(gl.Framebuffer framebuffer, WebGLRenderTarget renderTarget, int textureTarget) {
    _gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
    _gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, textureTarget, renderTarget.__webglTexture, 0);
  }

  void setupRenderBuffer(gl.Renderbuffer renderbuffer, WebGLRenderTarget renderTarget) {
    _gl.bindRenderbuffer(gl.RENDERBUFFER, renderbuffer);

    if (renderTarget.depthBuffer && !renderTarget.stencilBuffer) {
      _gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, renderTarget.width, renderTarget.height);
      _gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, renderbuffer);
    } else if(renderTarget.depthBuffer && renderTarget.stencilBuffer) {
      _gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_STENCIL, renderTarget.width, renderTarget.height);
      _gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, renderbuffer);
    } else {
      _gl.renderbufferStorage(gl.RENDERBUFFER, gl.RGBA4, renderTarget.width, renderTarget.height);
    }
  }

  void setRenderTarget(WebGLRenderTarget renderTarget) {
    var isCube = (renderTarget is WebGLRenderTargetCube);

    if ((renderTarget != null) && (renderTarget.__webglFramebuffer == null)) {
      if (renderTarget.depthBuffer == null) renderTarget.depthBuffer = true;
      if (renderTarget.stencilBuffer == null) renderTarget.stencilBuffer = true;

      //renderTarget.addEventListener('dispose', onRenderTargetDispose);

      renderTarget.__webglTexture = _gl.createTexture();
      info.memory.textures++;

      // Setup texture, create render and frame buffers
      var isTargetPowerOfTwo = MathUtils.isPowerOfTwo(renderTarget.width) && MathUtils.isPowerOfTwo(renderTarget.height),
          glFormat = paramThreeToGL(renderTarget.format),
          glType = paramThreeToGL(renderTarget.type);

      if (isCube) {
        renderTarget.__webglFramebuffer = [];
        renderTarget.__webglRenderbuffer = [];

        _gl.bindTexture(gl.TEXTURE_CUBE_MAP, renderTarget.__webglTexture);
        setTextureParameters(gl.TEXTURE_CUBE_MAP, renderTarget, isTargetPowerOfTwo);

        for (var i = 0; i < 6; i++) {
          renderTarget.__webglFramebuffer[i] = _gl.createFramebuffer();
          renderTarget.__webglRenderbuffer[i] = _gl.createRenderbuffer();

          _gl.texImage2DTyped(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, glFormat, renderTarget.width, renderTarget.height, 0, glFormat, glType, null);

          setupFrameBuffer(renderTarget.__webglFramebuffer[i], renderTarget, gl.TEXTURE_CUBE_MAP_POSITIVE_X + i);
          setupRenderBuffer(renderTarget.__webglRenderbuffer[i], renderTarget);
        }

        if (isTargetPowerOfTwo) { 
          _gl.generateMipmap(gl.TEXTURE_CUBE_MAP); 
        }
      } else {
        renderTarget.__webglFramebuffer = _gl.createFramebuffer();
      
        if (renderTarget.shareDepthFrom != null) {
          renderTarget.__webglRenderbuffer = renderTarget.shareDepthFrom.__webglRenderbuffer;
        } else {
          renderTarget.__webglRenderbuffer = _gl.createRenderbuffer();
        }

        _gl.bindTexture(gl.TEXTURE_2D, renderTarget.__webglTexture);
        setTextureParameters(gl.TEXTURE_2D, renderTarget, isTargetPowerOfTwo);
        
        _gl.texImage2DTyped(gl.TEXTURE_2D, 0, glFormat, renderTarget.width, renderTarget.height, 0, glFormat, glType, null);

        setupFrameBuffer(renderTarget.__webglFramebuffer, renderTarget, gl.TEXTURE_2D);

        if (renderTarget.shareDepthFrom != null) {
          if (renderTarget.depthBuffer && !renderTarget.stencilBuffer) {
            _gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, renderTarget.__webglRenderbuffer);
              
          } else if (renderTarget.depthBuffer && renderTarget.stencilBuffer) {
            _gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, renderTarget.__webglRenderbuffer);
          }
        } else {
          setupRenderBuffer(renderTarget.__webglRenderbuffer, renderTarget);
        }
        
        if (isTargetPowerOfTwo) _gl.generateMipmap(gl.TEXTURE_2D);
      }

      // Release everything
      if (isCube) {
        _gl.bindTexture(gl.TEXTURE_CUBE_MAP, null);
      } else {
        _gl.bindTexture(gl.TEXTURE_2D, null);
      }
      
      _gl.bindRenderbuffer(gl.RENDERBUFFER, null);
      _gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    }

    var framebuffer, width, height, vx, vy;

    if (renderTarget != null) {
      if (isCube) {
        framebuffer = renderTarget.__webglFramebuffer[(renderTarget as WebGLRenderTargetCube).activeCubeFace];
      } else {
        framebuffer = renderTarget.__webglFramebuffer;
      }

      width = renderTarget.width;
      height = renderTarget.height;

      vx = 0;
      vy = 0;
    } else {
      framebuffer = null;

      width = _viewportWidth;
      height = _viewportHeight;

      vx = _viewportX;
      vy = _viewportY;
    }

    if (!identical(framebuffer, _currentFramebuffer)) {
      _gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
      _gl.viewport(vx, vy, width, height);

      _currentFramebuffer = framebuffer;
    }

    _currentWidth = width;
    _currentHeight = height;
  }

  void updateRenderTargetMipmap(WebGLRenderTarget renderTarget) {
    if (renderTarget is WebGLRenderTargetCube) {
      _gl.bindTexture(gl.TEXTURE_CUBE_MAP, renderTarget.__webglTexture);
      _gl.generateMipmap(gl.TEXTURE_CUBE_MAP);
      _gl.bindTexture(gl.TEXTURE_CUBE_MAP, null);
    } else {
      _gl.bindTexture(gl.TEXTURE_2D, renderTarget.__webglTexture);
      _gl.generateMipmap(gl.TEXTURE_2D);
      _gl.bindTexture(gl.TEXTURE_2D, null);
    }
  }

  // Fallback filters for non-power-of-2 textures

  int filterFallback(int f) {
    if (f == NEAREST_FILTER || 
        f == NEAREST_MIPMAP_NEAREST_FILTER || 
        f == NEAREST_MIPMAP_LINEAR_FILTER) {
      return gl.NEAREST;
    }
      
    return gl.LINEAR;
  }

  // Map three.js constants to WebGL constants
  int paramThreeToGL(int p) {
    if (p == REPEAT_WRAPPING) return gl.REPEAT;
    if (p == CLAMP_TO_EDGE_WRAPPING) return gl.CLAMP_TO_EDGE;
    if (p == MIRRORED_REPEAT_WRAPPING) return gl.MIRRORED_REPEAT;

    if (p == NEAREST_FILTER) return gl.NEAREST;
    if (p == NEAREST_MIPMAP_NEAREST_FILTER) return gl.NEAREST_MIPMAP_NEAREST;
    if (p == NEAREST_MIPMAP_LINEAR_FILTER) return gl.NEAREST_MIPMAP_LINEAR;

    if (p == LINEAR_FILTER) return gl.LINEAR;
    if (p == LINEAR_MIPMAP_NEAREST_FILTER) return gl.LINEAR_MIPMAP_NEAREST;
    if (p == LINEAR_MIPMAP_LINEAR_FILTER) return gl.LINEAR_MIPMAP_LINEAR;

    if (p == UNSIGNED_BYTE_TYPE) return gl.UNSIGNED_BYTE;
    if (p == UNSIGNED_SHORT_4444_TYPE) return gl.UNSIGNED_SHORT_4_4_4_4;
    if (p == UNSIGNED_SHORT_5551_TYPE) return gl.UNSIGNED_SHORT_5_5_5_1;
    if (p == UNSIGNED_SHORT_565_TYPE) return gl.UNSIGNED_SHORT_5_6_5;

    if (p == BYTE_TYPE) return gl.BYTE;
    if (p == SHORT_TYPE) return gl.SHORT;
    if (p == UNSIGNED_SHORT_TYPE) return gl.UNSIGNED_SHORT;
    if (p == INT_TYPE) return gl.INT;
    if (p == UNSIGNED_INT_TYPE) return gl.UNSIGNED_INT;
    if (p == FLOAT_TYPE) return gl.FLOAT;

    if (p == ALPHA_FORMAT) return gl.ALPHA;
    if (p == RGB_FORMAT) return gl.RGB;
    if (p == RGBA_FORMAT) return gl.RGBA;
    if (p == LUMINANCE_FORMAT) return gl.LUMINANCE;
    if (p == LUMINANCE_ALPHA_FORMAT) return gl.LUMINANCE_ALPHA;

    if (p == ADD_EQUATION) return gl.FUNC_ADD;
    if (p == SUBTRACT_EQUATION) return gl.FUNC_SUBTRACT;
    if (p == REVERSE_SUBTRACT_EQUATION) return gl.FUNC_REVERSE_SUBTRACT;

    if (p == ZERO_FACTOR) return gl.ZERO;
    if (p == ONE_FACTOR) return gl.ONE;
    if (p == SRC_COLOR_FACTOR) return gl.SRC_COLOR;
    if (p == ONE_MINUS_SRC_COLOR_FACTOR) return gl.ONE_MINUS_SRC_COLOR;
    if (p == SRC_ALPHA_FACTOR) return gl.SRC_ALPHA;
    if (p == ONE_MINUS_SRC_ALPHA_FACTOR) return gl.ONE_MINUS_SRC_ALPHA;
    if (p == DST_ALPHA_FACTOR) return gl.DST_ALPHA;
    if (p == ONE_MINUS_DST_ALPHA_FACTOR) return gl.ONE_MINUS_DST_ALPHA;

    if (p == DST_COLOR_FACTOR) return gl.DST_COLOR;
    if (p == ONE_MINUS_DST_COLOR_FACTOR) return gl.ONE_MINUS_DST_COLOR;
    if (p == SRC_ALPHA_SATURATE_FACTOR) return gl.SRC_ALPHA_SATURATE;

    if (_glExtensionCompressedTextureS3TC != null) {
      if (p == RGB_S3TC_DXT1_FORMAT) return gl.CompressedTextureS3TC.COMPRESSED_RGB_S3TC_DXT1_EXT;
      if (p == RGBA_S3TC_DXT1_FORMAT) return gl.CompressedTextureS3TC.COMPRESSED_RGBA_S3TC_DXT1_EXT;
      if (p == RGBA_S3TC_DXT3_FORMAT) return gl.CompressedTextureS3TC.COMPRESSED_RGBA_S3TC_DXT3_EXT;
      if (p == RGBA_S3TC_DXT5_FORMAT) return gl.CompressedTextureS3TC.COMPRESSED_RGBA_S3TC_DXT5_EXT;
    }
    
    return 0;
  }

  // Allocations
  int allocateBones(Object3D object) {
    if (supportsBoneTextures && 
        object != null && 
        object is SkinnedMesh && 
        object.useVertexTexture) {
      return 1024;
    } else {
      // default for when object is not specified
      // (for example when prebuilding shader
      //   to be used with multiple objects)
      //
      //  - leave some extra space for other uniforms
      //  - limit here is ANGLE's 254 max uniform vectors
      //    (up to 54 should be safe)

      int nVertexUniforms = _gl.getParameter(gl.MAX_VERTEX_UNIFORM_VECTORS);
      int nVertexMatrices = ((nVertexUniforms - 20) / 4).floor().toInt();

      var maxBones = nVertexMatrices;

      if (object != null && object is SkinnedMesh) {
        maxBones = Math.min(object.bones.length, maxBones);

        if (maxBones < object.bones.length) {
          print("WebGLRenderer: too many bones - ${object.bones.length}, "
                "this GPU supports just $maxBones (try OpenGL instead of ANGLE)");
        }
      }

      return maxBones;
    }
  }

  Map<String, int> allocateLights(List<Light> lights) {
    var dirLights = 0,
        pointLights = 0,
        spotLights = 0,
        hemiLights = 0;
    
    for (var l = 0; l < lights.length; l++) {
      var light = lights[l];

      if (light is ShadowCaster && light.onlyShadow) continue;

      if (light is DirectionalLight) dirLights++;
      if (light is PointLight) pointLights++;
      if (light is SpotLight) spotLights++;
      if (light is HemisphereLight) hemiLights++;
    }

    return {'directional': dirLights, 'point': pointLights, 'spot': spotLights, 'hemi': hemiLights};
  }

  int allocateShadows(List<Light> lights) {
    var maxShadows = 0;
    
    lights.where((e) => e.castShadow).forEach((light) {
      if (light is SpotLight) maxShadows++;
      if (light is DirectionalLight && !light.shadowCascade) maxShadows++;
    });
    
    return maxShadows;
  }

  // Initialization
  void initGL() { 
    try {
      _gl = canvas.getContext3d(
          alpha: alpha, 
          premultipliedAlpha: premultipliedAlpha, 
          antialias: antialias, 
          stencil: stencil, 
          preserveDrawingBuffer: preserveDrawingBuffer);
          
      if (_gl == null) throw 'Error creating WebGL context.';        
    } catch (error) {
      print(error);
    }
      
    _glExtensionTextureFloat = _gl.getExtension('OES_texture_float');
    // _glExtensionTextureFloatLinear = _gl.getExtension('OES_texture_float_linear');
    _glExtensionStandardDerivatives = _gl.getExtension('OES_standard_derivatives');
    
    _glExtensionTextureFilterAnisotropic = 
        [_gl.getExtension('EXT_texture_filter_anisotropic'),
         _gl.getExtension('MOZ_EXT_texture_filter_anisotropic'),
         _gl.getExtension('WEBKIT_EXT_texture_filter_anisotropic')].firstWhere((e) => e != null);
    
    _glExtensionCompressedTextureS3TC = 
        [_gl.getExtension('WEBGL_compressed_texture_s3tc'),
         _gl.getExtension('MOZ_WEBGL_compressed_texture_s3tc'),
         _gl.getExtension('WEBKIT_WEBGL_compressed_texture_s3tc')].firstWhere((e) => e != null);

    if (_glExtensionTextureFloat == null) {
      print('WebGLRenderer: Float textures not supported.');
    }

    if (_glExtensionStandardDerivatives == null) {
      print('WebGLRenderer: Standard derivatives not supported.');
    }

    if (_glExtensionTextureFilterAnisotropic == null) {
      print('WebGLRenderer: Anisotropic texture filtering not supported.');
    }

    if (_glExtensionCompressedTextureS3TC == null) {
      print('WebGLRenderer: S3TC compressed textures not supported.');
    }
  }

  void setDefaultGLState() {
    _gl.clearColor(0, 0, 0, 1);
    _gl.clearDepth(1);
    _gl.clearStencil(0);

    _gl.enable(gl.DEPTH_TEST);
    _gl.depthFunc(gl.LEQUAL);

    _gl.frontFace(gl.CCW);
    _gl.cullFace(gl.BACK);
    _gl.enable(gl.CULL_FACE);

    _gl.enable(gl.BLEND);
    _gl.blendEquation(gl.FUNC_ADD);
    _gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    
    _gl.viewport(_viewportX, _viewportY, _viewportWidth, _viewportHeight);

    _gl.clearColor(_clearColor.r, _clearColor.g, _clearColor.b, _clearAlpha);
  }
}

class WebGLRendererBuffer {
  gl.RenderingContext context;
  gl.Buffer _glbuffer;
  String belongsToAttribute;
  
  WebGLRendererBuffer(this.context) {
    _glbuffer = context.createBuffer();
  }
  
  void bind(int target) {
    context.bindBuffer(target, _glbuffer);
  }
}

class WebGLRendererProgram {
  int id;
  gl.Program glProgram;
  String code;
  int usedTimes;
  Map<String, int> attributes = {};
  Map<String, gl.UniformLocation> uniforms = {};

  WebGLRendererProgram(this.id, this.glProgram, this.code, {this.usedTimes: 0});
}

class WebGLRendererInfo {
  WebGLRendererMemoryInfo memory = new WebGLRendererMemoryInfo();
  WebGLRendererRenderInfo render = new WebGLRendererRenderInfo();
}

class WebGLRendererMemoryInfo {
  int programs = 0;
  int geometries = 0;
  int textures = 0;
}

class WebGLRendererRenderInfo {
  int calls = 0;
  int vertices = 0;
  int faces = 0;
  int points = 0;
}

class WebGLRendererLights {
  List<double> ambient = [0.0, 0.0, 0.0];
  WebGLRendererDirectionalLight directional = new WebGLRendererDirectionalLight();
  WebGLRendererPointLight point = new WebGLRendererPointLight();
  WebGLRendererSpotLight spot = new WebGLRendererSpotLight();
  WebGLRendererHemiLight hemi = new WebGLRendererHemiLight();
}

class WebGLRendererLight {
  int length = 0;
  List positions = [];
}

class WebGLRendererDirectionalLight extends WebGLRendererLight {
  List<double> colors = [];
}

class WebGLRendererPointLight extends WebGLRendererLight {
  List<double> colors = [];
  List<double> distances = [];
}

class WebGLRendererSpotLight extends WebGLRendererLight {
  List<double> colors = [];
  List<double> distances = [];
  List directions = [];
  List anglesCos = [];
  List exponents = [];
}

class WebGLRendererHemiLight extends WebGLRendererLight {
  List skyColors = [];
  List groundColors = [];
}
