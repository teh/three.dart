/*
 * @author mr.doob / http://mrdoob.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 */

part of three;

class Material {
  /// Unique number of this material instance.
  int id = MaterialIdCount++;
  
  String uuid = MathUtils.generateUUID();
  
  /// Material name. Default is an empty string.
  String name;
  
  /// Defines which of the face sides will be rendered - front, back or both.
  /// Default is FRONT_SIDE. Other options are BACK_SIDE and DOUBLE_SIDE.
  int side;

  /// Float in the range of 0.0 - 1.0 indicating how see through the material is. 
  /// A value of 0.0 indicates fully transparent, 1.0 is fully opaque. 
  /// If transparent is not set to true for the material, the material will remain 
  /// fully opaque and this value will only affect its color.
  /// Default is 1.0.
  double opacity;
  
  /// Defines whether this material is transparent. 
  /// This has an effect on rendering, as transparent objects need an special treatment, 
  /// and are rendered after the non transparent objects. For a working example of 
  /// this behaviour, check the WebGLRenderer code. When set to true, the extent to 
  /// which the material is transparent is controlled by setting opacity.
  ///  Default is false.
  bool transparent;
  
  /// Which blending to use when displaying objects with this material. 
  /// Default is NormalBlending
  int blending;
  
  /// Blending source. It's one of the blending mode constants defined in three.dart. 
  /// Default is SrcAlphaFactor
  int blendSrc;
  
  /// Blending destination. It's one of the blending mode constants defined in three.dart. 
  /// Default is OneMinusSrcAlphaFactor.
  int blendDst;
  
  /// Blending equation to use when applying blending. It's one of the constants defined in three.dart.
  /// Default is AddEquation.
  int blendEquation;
  
  /// Whether to have depth test enabled when rendering this material. Default is true.
  bool depthTest;
  
  /// Whether rendering this material has any effect on the depth buffer. Default is true.
  /// When drawing 2D overlays it can be useful to disable the depth writing in order to layer several things together without creating z-index artifacts.
  bool depthWrite;
  
  /// Whether to use polygon offset. Default is false. This corresponds to the POLYGON_OFFSET_FILL WebGL feature.
  bool polygonOffset;
  
  /// Sets the polygon offset factor. Default is 0.
  int polygonOffsetFactor;
  
  /// Sets the polygon offset units. Default is 0.
  int polygonOffsetUnits;
  
  /// Sets the alpha value to be used when running an alpha test. Default is 0.
  int alphaTest;
  
  /// Enables/disables overdraw. If enabled, polygons are drawn slightly bigger in order 
  /// to fix antialiasing gaps when using the CanvasRenderer. Default is false.
  int overdraw;// Overdrawn pixels (typically between 0 and 1) for fixing antialiasing gaps in CanvasRenderer
  
  /// Defines whether this material is visible. Default is true.
  bool visible;
  
  /// Specifies that the material needs to be updated, WebGL wise. Set it to true if you made changes that need to be reflected in WebGL.
  /// This property is automatically set to true when instancing a new material.
  bool needsUpdate = true;

  /// A generic material.
  Material({this.name: '', 
            
            this.side: FRONT_SIDE,
            
            this.opacity: 1.0,
            this.transparent: false,
            
            this.blending: NORMAL_BLENDING,
            this.blendSrc: SRC_ALPHA_FACTOR,
            this.blendDst: ONE_MINUS_SRC_ALPHA_FACTOR,
            this.blendEquation: ADD_EQUATION,
            
            this.depthTest: true,
            this.depthWrite: true,

            this.polygonOffset: false,
            this.polygonOffsetFactor: 0,
            this.polygonOffsetUnits: 0,

            this.alphaTest: 0,
              
            this.overdraw: 0, // Overdrawn pixels (typically between 0 and 1) for fixing antialiasing gaps in CanvasRenderer

            this.visible: true});
 
  Material clone([Material material]) {
    if (material == null) material = new Material();
    
    return material
        ..name = name
        
        ..side = side
    
        ..opacity = opacity
        ..transparent = transparent
    
        ..blending = blending
    
        ..blendSrc = blendSrc
        ..blendDst = blendDst
        ..blendEquation = blendEquation
    
        ..depthTest = depthTest
        ..depthWrite = depthWrite
    
        ..polygonOffset = polygonOffset
        ..polygonOffsetFactor = polygonOffsetFactor
        ..polygonOffsetUnits = polygonOffsetUnits
    
        ..alphaTest = alphaTest
    
        ..overdraw = overdraw
    
        ..visible = visible;
  }

  // Quick hack to allow setting new properties (used by the renderer)
  Map __data = {};
  operator [](String key) => __data[key];
  operator []=(String key, value) => __data[key] = value;
}
