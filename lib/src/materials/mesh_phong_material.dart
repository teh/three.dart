/*
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 */

part of three;

/// A material for shiny surfaces, evaluated per pixel.
class MeshPhongMaterial extends Material implements ITextureMaterial {
  /// Diffuse color of the material. Default is white.
  Color color; 
  
  /// Ambient color of the material, multiplied by the color of the AmbientLight. 
  /// Default is white.
  Color ambient;
  
  /// Emissive (light) color of the material, essentially a solid color 
  /// unaffected by other lighting. Default is black.
  Color emissive;
  
  /// Specular color of the material, i.e., how shiny the material is and 
  /// the color of its shine. Setting this the same color as the diffuse 
  /// value (times some intensity) makes the material more 
  /// metallic-looking; setting this to some gray makes the material look 
  /// more plastic. Default is dark gray.
  Color specular;
  
  /// How shiny the specular highlight is; a higher value gives a sharper highlight. 
  /// Default is 30.
  double shininess;

  bool metal;
  bool perPixel;

  bool wrapAround;
  Vector3 wrapRGB;

  /// Set color texture map. Default is null.
  Texture map;

  /// Set light map. Default is null.
  Texture lightMap;

  Texture bumpMap;
  
  double bumpScale;

  Texture normalMap;
  
  Vector2 normalScale;

  /// The specular map value affects both how much the specular surface 
  /// highlight contributes and how much of the environment map 
  /// affects the surface. Default is null.
  Texture specularMap;

  /// Set environmental map. Default is null.
  Texture envMap;
  
  /// How to combine the result of the surface's color with the environment 
  /// map, if any. Options are MULTIPLY_OPERATION (default), MIX_OPERATION, ADD_OPERATION. 
  /// If mix is chosen, the reflectivity is used to blend between the two colors.
  int combine;
  
  /// How much the environment map affects the surface; also see "combine".
  double reflectivity;
  
  /// The index of refraction for an environment map using CubeRefractionMapping. 
  /// Default is 0.98.
  double refractionRatio;
  
  /// Define whether the material color is affected by global fog settings. Default is true.
  /// This setting might not have any effect when used with certain renderers. 
  /// For example, it is ignored with the Canvas renderer, 
  /// but does work with the WebGL renderer.
  bool fog;

  /// How the triangles of a curved surface are rendered: as a smooth surface, 
  /// as flat separate facets, or no shading at all. Options are 
  /// SMOOTH_SHADING (default), FLAT_SHADING, NO_SHADING.
  int shading;

  /// Whether the triangles' edges are displayed instead of surfaces. 
  /// Default is false.
  bool wireframe;
  
  /// Line thickness for wireframe mode. Default is 1.0.
  /// Due to limitations in the ANGLE layer, on Windows platforms 
  /// linewidth will always be 1 regardless of the set value.
  double wireframeLinewidth;
  
  /// Define appearance of line ends. Possible values are "butt", "round" and "square". 
  /// Default is 'round'. This setting might not have any effect when used 
  /// with certain renderers. For example, it is ignored with the WebGL renderer, 
  /// but does work with the Canvas renderer.
  String wireframeLinecap;
  
  /// Define appearance of line joints. Possible values are "round", "bevel" and "miter". 
  /// Default is 'round'. This setting might not have any effect when used with 
  /// certain renderers. For example, it is ignored with the WebGL renderer, 
  /// but does work with the Canvas renderer.
  String wireframeLinejoin;
  
  /// Define whether the material uses vertex colors, or not. Default is false.
  /// This setting might not have any effect when used with certain renderers. 
  /// For example, it is ignored with the Canvas renderer, 
  /// but does work with the WebGL renderer.
  int vertexColors;

  /// Define whether the material uses skinning. Default is false.
  bool skinning;
  
  /// Define whether the material uses morphTargets. Default is false.
  bool morphTargets;
  
  bool morphNormals;


  /**
   * ## Parameters 
   * * color: <hex>,
   * * ambient: <hex>,
   * * emissive: <hex>,
   * * specular: <hex>,
   * * shininess: <float>
   * * opacity: <float>,
   * * map: new THREE.Texture( <Image> ),
   * * lightMap: new THREE.Texture( <Image> ),
   * * bumpMap: new THREE.Texture( <Image> ),
   * * bumpScale: <float>,
   * * normalMap: new THREE.Texture( <Image> ),
   * * normalScale: <Vector2>,
   * * specularMap: new THREE.Texture( <Image> ),
   * * envMap: new THREE.TextureCube( [posx, negx, posy, negy, posz, negz] ),
   * * combine: THREE.Multiply,
   * * reflectivity: <float>,
   * * refractionRatio: <float>,
   * * shading: THREE.SmoothShading,
   * * blending: THREE.NormalBlending,
   * * depthTest: <bool>,
   * * depthWrite: <bool>,
   * * wireframe: <boolean>,
   * * wireframeLinewidth: <float>,
   * * vertexColors: THREE.NoColors / THREE.VertexColors / THREE.FaceColors,
   * * skinning: <bool>,
   * * morphTargets: <bool>,
   * * morphNormals: <bool>
   * * fog: <bool>
   */
  MeshPhongMaterial({// MeshLambertMaterial
                     int color: 0xffffff, // diffuse
                     num ambient: 0xffffff,
                     num emissive: 0x000000,
                     num specular: 0x111111,

                     this.map,

                     this.shininess: 30.0,

                     this.metal: false,
                     this.perPixel: false,

                     this.wrapAround: false,
                     Vector3 wrapRGB,

                     this.lightMap,
                     this.specularMap,
                     this.envMap,

                     this.bumpMap,
                     this.bumpScale: 1.0,

                     this.normalMap: null,
                     Vector2 normalScale,

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
                     this.morphNormals: false,

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
                     int polygonOffsetUnits:  0,

                     int alphaTest: 0,

                     int overdraw: 0,
                     
                     visible: true})
      : this.color = new Color(color),
        this.ambient = new Color(ambient),
        this.emissive = new Color(emissive),
        this.specular = new Color(specular),

        this.wrapRGB = wrapRGB == null ? new Vector3.one() : wrapRGB,
        this.normalScale = normalScale == null ? new Vector2(1.0, 1.0) : normalScale,

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
