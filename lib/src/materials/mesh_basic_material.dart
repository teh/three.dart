/*
 * @author mr.doob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 *
 * parameters = {
 *  color: <hex>,
 *  opacity: <float>,
 *  map: new THREE.Texture( <Image> ),
 *
 *  lightMap: new THREE.Texture( <Image> ),
 *
 *  envMap: new THREE.TextureCube( [posx, negx, posy, negy, posz, negz] ),
 *  combine: THREE.Multiply,
 *  reflectivity: <float>,
 *  refractionRatio: <float>,
 *
 *  shading: THREE.SmoothShading,
 *  blending: THREE.NormalBlending,
 *  depthTest: <bool>,
 *
 *  wireframe: <boolean>,
 *  wireframeLinewidth: <float>,
 *
 *  vertexColors: false / THREE.NoColors / THREE.VertexColors / THREE.FaceColors,
 *  skinning: <bool>,
 *
 *  fog: <bool>
 * }
 */

part of three;

class MeshBasicMaterial extends Material implements ITextureMaterial {
  /// Sets the color of the geometry. Default is 0xffffff.
  Color color;

  Texture map;
  
  /// Set light map. Default is null.
  Texture lightMap;
  
  /// Set specular map. Default is null.
  Texture specularMap;
  
  /// Set environmental map. Default is null.
  Texture envMap;
  
  int combine; 
  
  double reflectivity;
  
  double refractionRatio;

  /// Define shading type. Default is SMOOTH_SHADING.
  int shading;
  
  /// Render geometry as wireframe. Default is false (i.e. render as flat polygons).
  bool wireframe;
  
  /// Controls wireframe thickness. Default is 1.
  /// Due to limitations in the ANGLE layer, on Windows platforms linewidth will 
  /// always be 1 regardless of the set value.
  double wireframeLinewidth;
  
  /// Define appearance of line ends. Possible values are "butt", "round" and "square". Default is 'round'.
  /// This setting might not have any effect when used with certain renderers. For example, it is ignored with the WebGL renderer, but does work with the Canvas renderer.
  String wireframeLinecap;
  
  /// Define appearance of line joints. Possible values are "round", "bevel" and "miter". 
  /// Default is 'round'. This setting might not have any effect when used with 
  /// certain renderers. For example, it is ignored with the WebGL renderer, 
  /// but does work with the Canvas renderer.
  String wireframeLinejoin;

  /// Define whether the material uses skinning. Default is false.
  bool skinning;
  
  /// Define whether the material uses morphTargets. Default is false.
  bool morphTargets;

  /// Define whether the material uses vertex colors, or not. Default is NO_COLORS.
  /// This setting might not have any effect when used with certain renderers. 
  /// For example, it is ignored with the Canvas renderer, but does work 
  /// with the WebGL renderer.
  int vertexColors;
  
  /// Define whether the material color is affected by global fog settings. Default is true.
  /// This setting might not have any effect when used with certain renderers. 
  /// For example, it is ignored with the Canvas renderer, but does work with the WebGL renderer.
  bool fog;

  /// A material for drawing geometries in a simple shaded (flat or wireframe) way.
  /// The default will render as flat polygons. To draw the mesh as wireframe, 
  /// simply set the 'wireframe' property to true.
  MeshBasicMaterial({// MeshBasicMaterial
                     int color: 0xffffff, //emissive
                     
                     this.map,

                     this.lightMap,
                     this.specularMap,

                     this.envMap,
                     this.combine: MULTIPLY_OPERATION,
                     this.reflectivity: 1.0,
                     this.refractionRatio: 0.98,

                     this.shading: SMOOTH_SHADING,
                     
                     this.vertexColors: NO_COLORS,

                     this.fog: true,

                     this.wireframe: false,
                     this.wireframeLinewidth: 1.0,
                     this.wireframeLinecap: 'round',
                     this.wireframeLinejoin: 'round',

                     this.skinning: false,
                     this.morphTargets: false,

                     // Material
                     String name: '',
                     int side: FRONT_SIDE,
                     
                     double opacity: 1.0,
                     bool transparent: false,

                     int blending: NORMAL_BLENDING,
                     int blendSrc: SRC_ALPHA_FACTOR,
                     int blendDst: ONE_MINUS_SRC_ALPHA_FACTOR,
                     int blendEquation: ADD_EQUATION,

                     bool depthTest: true,
                     bool depthWrite: true,
                     
                     bool polygonOffset: false,
                     int polygonOffsetFactor: 0,
                     int polygonOffsetUnits: 0,

                     int alphaTest: 0,

                     int overdraw: 0,
                     
                     visible: true})
      : this.color = new Color(color),
        super(name: name,
              side: side,
              opacity: opacity,
              transparent: transparent,
              blending: blending,
              blendSrc: blendSrc,
              blendDst: blendDst,
              blendEquation: blendEquation,
              depthTest: depthTest,
              depthWrite: depthWrite,
              polygonOffset: polygonOffset,
              polygonOffsetFactor: polygonOffsetFactor,
              polygonOffsetUnits: polygonOffsetUnits,
              alphaTest: alphaTest,
              overdraw: overdraw,
              visible: visible);
  
  //TODO Add clone.
}
