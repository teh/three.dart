/*
 * @author mr.doob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 *
 */

part of three;

/// A material for non-shiny (Lambertian) surfaces, evaluated per vertex.
class MeshLambertMaterial extends Material implements ITextureMaterial {
  /// Diffuse color of the material. Default is white.
  Color color;
  
  /// Ambient color of the material, multiplied by the color of the AmbientLight. 
  /// Default is white.
  Color ambient;
  
  /// Emissive (light) color of the material, essentially a solid color unaffected 
  /// by other lighting. Default is black.
  Color emissive;

  bool wrapAround;
  Vector3 wrapRGB;
  
  /// Set color texture map. Default is null.
  Texture map;
  
  /// Set light map. Default is null.
  Texture lightMap;
  
  /// Since this material does not have a specular component, the specular 
  /// value affects only how much of the environment map affects the surface. 
  /// Default is null.
  Texture specularMap;
  
  /// Set environmental map. Default is null.
  Texture envMap;
  
  /// How to combine the result of the surface's color with the environment map, if any.
  /// Options are MULTIPLY (default), MIX_OPERATION, ADD_OPERATION. 
  /// If mix is chosen, the reflectivity is used to blend between the two colors.
  int combine;
  
  /// How much the environment map affects the surface; also see "combine".
  double reflectivity;
  
  /// The index of refraction for an environment map using CubeRefractionMapping. 
  /// Default is 0.98.
  double refractionRatio;

  /// Define whether the material color is affected by global fog settings. 
  /// Default is true. This setting might not have any effect when used 
  /// with certain renderers. For example, it is ignored with the Canvas renderer, 
  /// but does work with the WebGL renderer.
  bool fog;
  
  /// How the triangles of a curved surface are rendered: as a 
  /// smooth surface, as flat separate facets, or no shading at all.
  /// Options are SMOOTH_SHADING (default), FLAT_SHADING, NO_SHADING.
  int shading;
  
  /// Whether the triangles' edges are displayed instead of surfaces. 
  /// Default is false.
  bool wireframe;
  
  /// Line thickness for wireframe mode. Default is 1.0.
  /// Due to limitations in the ANGLE layer, on Windows platforms 
  /// linewidth will always be 1 regardless of the set value.
  double wireframeLinewidth;
  
  /// Define appearance of line ends. Possible values are "butt", "round" 
  /// and "square". Default is 'round'. This setting might not have any 
  /// effect when used with certain renderers. For example, it is ignored 
  /// with the WebGL renderer, but does work with the Canvas renderer.
  String wireframeLinecap;
  
  /// Define appearance of line joints. Possible values are "round", "bevel" and "miter". 
  /// Default is 'round'. This setting might not have any effect when used with 
  /// certain renderers. For example, it is ignored with the WebGL renderer, 
  /// but does work with the Canvas renderer.
  String wireframeLinejoin;
  
  /// Define whether the material uses vertex colors, or not. 
  /// Default is false. This setting might not have any effect when used 
  /// with certain renderers. For example, it is ignored with the Canvas 
  /// renderer, but does work with the WebGL renderer.
  int vertexColors;

  /// Define whether the material uses skinning. Default is false.
  bool skinning;
  
  /// Define whether the material uses morphTargets. Default is false.
  bool morphTargets;
  
  /// Define whether the material uses morphNormals. Default is false.
  bool morphNormals;

  /**
   * #parameters
   ** color: <hex>,
 *  ambient: <hex>,
 *  opacity: <float>,
 *
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
 *  vertexColors: false / THREE.NoColors  / THREE.VertexColors / THREE.FaceColors,
 *  skinning: <bool>,
 *
 *  fog: <bool>
   */
  MeshLambertMaterial({// MeshLambertMaterial
                       this.map,

                       int color: 0xffffff, // diffuse
                       int ambient: 0xffffff,
                       int emissive: 0x000000,

                       this.wrapAround: false,
                       Vector3 wrapRGB,

                       this.lightMap,
                       this.specularMap,
                       this.envMap,

                       this.combine: MULTIPLY_OPERATION,
                       this.reflectivity: 1.0,
                       this.refractionRatio: 0.98,
                       
                       this.fog: true,

                       this.shading: SMOOTH_SHADING,

                       this.wireframe: false,
                       this.wireframeLinewidth: 1.0,
                       this.wireframeLinecap: 'round',
                       this.wireframeLinejoin: 'round',
                       
                       this.vertexColors: NO_COLORS,

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
                       int polygonOffsetUnits: 0,

                       int alphaTest: 0,

                       int overdraw: 0,

                       visible: true})
      : this.color = new Color(color),
        this.ambient = new Color(ambient),
        this.emissive = new Color(emissive),
        
        this.wrapRGB = wrapRGB == null ? new Vector3.one() : wrapRGB,
            
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
