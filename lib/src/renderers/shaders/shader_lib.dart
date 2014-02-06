part of three;

final Map ShaderLib = {            
/*
 * Basic
 */
"basic": {
  
  "uniforms": UniformsUtils.merge([UniformsLib["common"],
                                   UniformsLib["fog"],
                                   UniformsLib["shadowmap"]]),
  
  "vertexShader": """
    ${ShaderChunk["map_pars_vertex"]}
    ${ShaderChunk["lightmap_pars_vertex"]}
    ${ShaderChunk["envmap_pars_vertex"]}
    ${ShaderChunk["color_pars_vertex"]}
    ${ShaderChunk["morphtarget_pars_vertex"]}
    ${ShaderChunk["skinning_pars_vertex"]}
    ${ShaderChunk["shadowmap_pars_vertex"]}
    void main() {
      ${ShaderChunk["map_vertex"]}
      ${ShaderChunk["lightmap_vertex"]}
      ${ShaderChunk["color_vertex"]}
      ${ShaderChunk["skinbase_vertex"]}
      #ifdef USE_ENVMAP
      ${ShaderChunk["morphnormal_vertex"]}
      ${ShaderChunk["skinnormal_vertex"]}
      ${ShaderChunk["defaultnormal_vertex"]}
      #endif
      ${ShaderChunk["morphtarget_vertex"]}
      ${ShaderChunk["skinning_vertex"]}
      ${ShaderChunk["default_vertex"]}
      ${ShaderChunk["worldpos_vertex"]}
      ${ShaderChunk["envmap_vertex"]}
      ${ShaderChunk["shadowmap_vertex"]}
    }
    """,
    
    "fragmentShader": """
    uniform vec3 diffuse;
    uniform float opacity;
    ${ShaderChunk["color_pars_fragment"]}
    ${ShaderChunk["map_pars_fragment"]}
    ${ShaderChunk["lightmap_pars_fragment"]}
    ${ShaderChunk["envmap_pars_fragment"]}
    ${ShaderChunk["fog_pars_fragment"]}
    ${ShaderChunk["shadowmap_pars_fragment"]}
    ${ShaderChunk["specularmap_pars_fragment"]}
    void main() {
      gl_FragColor = vec4(diffuse, opacity);
      ${ShaderChunk["map_fragment"]}
      ${ShaderChunk["alphatest_fragment"]}
      ${ShaderChunk["specularmap_fragment"]}
      ${ShaderChunk["lightmap_fragment"]}
      ${ShaderChunk["color_fragment"]}
      ${ShaderChunk["envmap_fragment"]}
      ${ShaderChunk["shadowmap_fragment"]}
      ${ShaderChunk["linear_to_gamma_fragment"]}
      ${ShaderChunk["fog_fragment"]}
    }
  """},

/*
 * Lambert
 */
"lambert": {
  
  "uniforms": UniformsUtils.merge([UniformsLib["common"],
                                   UniformsLib["fog"],
                                   UniformsLib["lights"],
                                   UniformsLib["shadowmap"],
                                  {"ambient": new Uniform.color(0xffffff),
                                   "emissive": new Uniform.color(0x000000),
                                   "wrapRGB": new Uniform.vector3(1.0, 1.0, 1.0)}]),
  
  "vertexShader": """
    #define LAMBERT
    varying vec3 vLightFront;
    #ifdef DOUBLE_SIDED
      varying vec3 vLightBack;
    #endif
    ${ShaderChunk["map_pars_vertex"]}
    ${ShaderChunk["lightmap_pars_vertex"]}
    ${ShaderChunk["envmap_pars_vertex"]}
    ${ShaderChunk["lights_lambert_pars_vertex"]}
    ${ShaderChunk["color_pars_vertex"]}
    ${ShaderChunk["morphtarget_pars_vertex"]}
    ${ShaderChunk["skinning_pars_vertex"]}
    ${ShaderChunk["shadowmap_pars_vertex"]}
    void main() {
      ${ShaderChunk["map_vertex"]}
      ${ShaderChunk["lightmap_vertex"]}
      ${ShaderChunk["color_vertex"]}
      ${ShaderChunk["morphnormal_vertex"]}
      ${ShaderChunk["skinbase_vertex"]}
      ${ShaderChunk["skinnormal_vertex"]}
      ${ShaderChunk["defaultnormal_vertex"]}
      ${ShaderChunk["morphtarget_vertex"]}
      ${ShaderChunk["skinning_vertex"]}
      ${ShaderChunk["default_vertex"]}
      ${ShaderChunk["worldpos_vertex"]}
      ${ShaderChunk["envmap_vertex"]}
      ${ShaderChunk["lights_lambert_vertex"]}
      ${ShaderChunk["shadowmap_vertex"]}
    }
    """,
  
  "fragmentShader": """
    uniform float opacity;
    varying vec3 vLightFront;
    #ifdef DOUBLE_SIDED
      varying vec3 vLightBack;
    #endif
    ${ShaderChunk["color_pars_fragment"]}
    ${ShaderChunk["map_pars_fragment"]}
    ${ShaderChunk["lightmap_pars_fragment"]}
    ${ShaderChunk["envmap_pars_fragment"]}
    ${ShaderChunk["fog_pars_fragment"]}
    ${ShaderChunk["shadowmap_pars_fragment"]}
    ${ShaderChunk["specularmap_pars_fragment"]}
    void main() {
      gl_FragColor = vec4(vec3(1.0), opacity);
      ${ShaderChunk["map_fragment"]}
      ${ShaderChunk["alphatest_fragment"]}
      ${ShaderChunk["specularmap_fragment"]}
      #ifdef DOUBLE_SIDED
        if(gl_FrontFacing)
          gl_FragColor.xyz *= vLightFront;
        else
          gl_FragColor.xyz *= vLightBack;
      #else
        gl_FragColor.xyz *= vLightFront;
      #endif
      ${ShaderChunk["lightmap_fragment"]}
      ${ShaderChunk["color_fragment"]}
      ${ShaderChunk["envmap_fragment"]}
      ${ShaderChunk["shadowmap_fragment"]}
      ${ShaderChunk["linear_to_gamma_fragment"]}
      ${ShaderChunk["fog_fragment"]}
    }
  """},

/*
 * Phong
 */
"phong": {
  "uniforms": UniformsUtils.merge([UniformsLib["common"],
                                   UniformsLib["bump"],
                                   UniformsLib["normalmap"],
                                   UniformsLib["fog"],
                                   UniformsLib["lights"],
                                   UniformsLib["shadowmap"],
                                  {"ambient"  : new Uniform.color(0xffffff),
                                   "emissive" : new Uniform.color(0x000000),
                                   "specular" : new Uniform.color(0x111111),
                                   "shininess": new Uniform.float(30.0),
                                   "wrapRGB"  : new Uniform.vector3(1.0, 1.0, 1.0)}]),

  "vertexShader": """
    #define PHONG
    varying vec3 vViewPosition;
    varying vec3 vNormal;
    ${ShaderChunk["map_pars_vertex"]}
    ${ShaderChunk["lightmap_pars_vertex"]}
    ${ShaderChunk["envmap_pars_vertex"]}
    ${ShaderChunk["lights_phong_pars_vertex"]}
    ${ShaderChunk["color_pars_vertex"]}
    ${ShaderChunk["morphtarget_pars_vertex"]}
    ${ShaderChunk["skinning_pars_vertex"]}
    ${ShaderChunk["shadowmap_pars_vertex"]}
    void main() {
      ${ShaderChunk["map_vertex"]}
      ${ShaderChunk["lightmap_vertex"]}
      ${ShaderChunk["color_vertex"]}
      ${ShaderChunk["morphnormal_vertex"]}
      ${ShaderChunk["skinbase_vertex"]}
      ${ShaderChunk["skinnormal_vertex"]}
      ${ShaderChunk["defaultnormal_vertex"]}
      vNormal = normalize(transformedNormal);
      ${ShaderChunk["morphtarget_vertex"]}
      ${ShaderChunk["skinning_vertex"]}
      ${ShaderChunk["default_vertex"]}
      vViewPosition = -mvPosition.xyz;
      ${ShaderChunk["worldpos_vertex"]}
      ${ShaderChunk["envmap_vertex"]}
      ${ShaderChunk["lights_phong_vertex"]}
      ${ShaderChunk["shadowmap_vertex"]}
    }
    """,
  
  "fragmentShader": """
    uniform vec3 diffuse;
    uniform float opacity;
    uniform vec3 ambient;
    uniform vec3 emissive;
    uniform vec3 specular;
    uniform float shininess;
    ${ShaderChunk["color_pars_fragment"]}
    ${ShaderChunk["map_pars_fragment"]}
    ${ShaderChunk["lightmap_pars_fragment"]}
    ${ShaderChunk["envmap_pars_fragment"]}
    ${ShaderChunk["fog_pars_fragment"]}
    ${ShaderChunk["lights_phong_pars_fragment"]}
    ${ShaderChunk["shadowmap_pars_fragment"]}
    ${ShaderChunk["bumpmap_pars_fragment"]}
    ${ShaderChunk["normalmap_pars_fragment"]}
    ${ShaderChunk["specularmap_pars_fragment"]}
    void main() {
      gl_FragColor = vec4(vec3 (1.0), opacity);
      ${ShaderChunk["map_fragment"]}
      ${ShaderChunk["alphatest_fragment"]}
      ${ShaderChunk["specularmap_fragment"]}
      ${ShaderChunk["lights_phong_fragment"]}
      ${ShaderChunk["lightmap_fragment"]}
      ${ShaderChunk["color_fragment"]}
      ${ShaderChunk["envmap_fragment"]}
      ${ShaderChunk["shadowmap_fragment"]}
      ${ShaderChunk["linear_to_gamma_fragment"]}
      ${ShaderChunk["fog_fragment"]}
    }
  """},

/*
 * Particle basic
 */
"particle_basic": {
  
  "uniforms": UniformsUtils.merge([UniformsLib["particle"],
                                   UniformsLib["shadowmap"]]),
    
  "vertexShader": """
    uniform float size;
    uniform float scale;
    ${ShaderChunk["color_pars_vertex"]}
    ${ShaderChunk["shadowmap_pars_vertex"]}
    void main() {
      ${ShaderChunk["color_vertex"]}
      vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
      #ifdef USE_SIZEATTENUATION
        gl_PointSize = size * (scale / length(mvPosition.xyz));
      #else
        gl_PointSize = size;
      #endif
      gl_Position = projectionMatrix * mvPosition;
      ${ShaderChunk["worldpos_vertex"]}
      ${ShaderChunk["shadowmap_vertex"]}
    }
  """,
  
  "fragmentShader": """
    uniform vec3 psColor;
    uniform float opacity;
    ${ShaderChunk["color_pars_fragment"]}
    ${ShaderChunk["map_particle_pars_fragment"]}
    ${ShaderChunk["fog_pars_fragment"]}
    ${ShaderChunk["shadowmap_pars_fragment"]}
    void main() {
      gl_FragColor = vec4(psColor, opacity);
      ${ShaderChunk["map_particle_fragment"]}
      ${ShaderChunk["alphatest_fragment"]}
      ${ShaderChunk["color_fragment"]}
      ${ShaderChunk["shadowmap_fragment"]}
      ${ShaderChunk["fog_fragment"]}
    }
  """},

/*
 * Dashed
 */
"dashed": {
  "uniforms": UniformsUtils.merge([UniformsLib["common"],
                                   UniformsLib["fog"],
                                  {"scale": new Uniform.float(1.0),
                                   "dashSize": new Uniform.float(1.0),
                                   "totalSize": new Uniform.float(2.0)}]),
    
  "vertexShader": """
    uniform float scale;
    attribute float lineDistance;
    varying float vLineDistance;
    ${ShaderChunk["color_pars_vertex"]}
    void main() {
      ${ShaderChunk["color_vertex"]}
      vLineDistance = scale * lineDistance;
      vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
      gl_Position = projectionMatrix * mvPosition;
    }
  """,

  "fragmentShader": """
    uniform vec3 diffuse;
    uniform float opacity;
    uniform float dashSize;
    uniform float totalSize;
    varying float vLineDistance;
    ${ShaderChunk["color_pars_fragment"]}
    ${ShaderChunk["fog_pars_fragment"]}
    void main() {
      if (mod(vLineDistance, totalSize) > dashSize) {
        discard;
      }
      gl_FragColor = vec4(diffuse, opacity);
      ${ShaderChunk["color_fragment"]}
      ${ShaderChunk["fog_fragment"]}
    }
  """},

/*
 * Depth
 */
"depth": {
  
  "uniforms": UniformsUtils.merge([{"mNear": new Uniform.float(1.0),
                                    "mFar": new Uniform.float(2000.0),
                                    "opacity": new Uniform.float(1.0)}]),
        
  "vertexShader": """
    void main() {
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  """,
    
  "fragmentShader": """
    uniform float mNear;
    uniform float mFar;
    uniform float opacity;
    void main() {
      float depth = gl_FragCoord.z / gl_FragCoord.w;
      float color = 1.0 - smoothstep(mNear, mFar, depth);
      gl_FragColor = vec4(vec3(color), opacity);
    }
  """},

"normal": {
            
  "uniforms": UniformsUtils.merge([{"opacity": new Uniform.float(1.0)}]),
    
  "vertexShader": """
    varying vec3 vNormal;
    ${ShaderChunk["morphtarget_pars_vertex"]}
    void main() {
      vNormal = normalize(normalMatrix * normal);
      ${ShaderChunk["morphtarget_vertex"]}
      ${ShaderChunk["default_vertex"]}
    }
  """,
  
  "fragmentShader": """
    uniform float opacity;
    varying vec3 vNormal;
    void main() {
      gl_FragColor = vec4(0.5 * normalize(vNormal) + 0.5, opacity);
    }
  """},

/* -------------------------------------------------------------------------
//        Normal map shader
//                - Blinn-Phong
//                - normal + diffuse + specular + AO + displacement + reflection + shadow maps
//                - point and directional lights (use with "lights: true" material option)
 ------------------------------------------------------------------------- */
"normalmap": {
  
  "uniforms": UniformsUtils.merge([UniformsLib["fog"],
                                   UniformsLib["lights"],
                                   UniformsLib["shadowmap"],
                                  {"enableAO":           new Uniform.int(0),
                                   "enableDiffuse":      new Uniform.int(0),
                                   "enableSpecular":     new Uniform.int(0),
                                   "enableReflection":   new Uniform.int(0),
                                   "enableDisplacement": new Uniform.int(0),
                            
                                   "tDisplacement": new Uniform.texture(), // must go first as this is vertex texture
                                   "tDiffuse":      new Uniform.texture(),
                                   "tCube":         new Uniform.texture(),
                                   "tNormal":       new Uniform.texture(),
                                   "tSpecular":     new Uniform.texture(),
                                   "tAO":           new Uniform.texture(),
                            
                                   "uNormalScale": new Uniform.vector2(1.0, 1.0),
                            
                                   "uDisplacementBias":  new Uniform.float(0.0),
                                   "uDisplacementScale": new Uniform.float(1.0),
                            
                                   "uDiffuseColor":  new Uniform.color(0xffffff),
                                   "uSpecularColor": new Uniform.color(0x111111),
                                   "uAmbientColor":  new Uniform.color(0xffffff),
                                   "uShininess": new Uniform.float(30.0),
                                   "uOpacity":   new Uniform.float(1.0),
                            
                                   "useRefract":       new Uniform.int(0),
                                   "uRefractionRatio": new Uniform.float(0.98),
                                   "uReflectivity":    new Uniform.float(0.5),
                            
                                   "uOffset" : new Uniform.vector2(0.0, 0.0),
                                   "uRepeat" : new Uniform.vector2(1.0, 1.0), 
                            
                                   "wrapRGB"  : new Uniform.vector3(1.0, 1.0, 1.0)}]),
    
  "vertexShader": """
    attribute vec4 tangent;
    uniform vec2 uOffset;
    uniform vec2 uRepeat;
    uniform bool enableDisplacement;
    #ifdef VERTEX_TEXTURES
      uniform sampler2D tDisplacement;
      uniform float uDisplacementScale;
      uniform float uDisplacementBias;
    #endif
    varying vec3 vTangent;
    varying vec3 vBinormal;
    varying vec3 vNormal;
    varying vec2 vUv;
    varying vec3 vWorldPosition;
    varying vec3 vViewPosition;
    ${ShaderChunk["skinning_pars_vertex"]}
    ${ShaderChunk["shadowmap_pars_vertex"]}
    void main() {
      ${ShaderChunk["skinbase_vertex"]}
      ${ShaderChunk["skinnormal_vertex"]}
      // normal, tangent and binormal vectors
      #ifdef USE_SKINNING
        vNormal = normalize(normalMatrix * skinnedNormal.xyz);
        vec4 skinnedTangent = skinMatrix * vec4(tangent.xyz, 0.0);
        vTangent = normalize(normalMatrix * skinnedTangent.xyz);
      #else
        vNormal = normalize(normalMatrix * normal);
        vTangent = normalize(normalMatrix * tangent.xyz);
      #endif
      
      vBinormal = normalize(cross(vNormal, vTangent) * tangent.w);
      vUv = uv * uRepeat + uOffset;
      
      // displacement mapping
      vec3 displacedPosition;
      #ifdef VERTEX_TEXTURES
        if (enableDisplacement) {
          vec3 dv = texture2D(tDisplacement, uv).xyz;
          float df = uDisplacementScale * dv.x + uDisplacementBias;
          displacedPosition = position + normalize(normal) * df;
        } else {
          #ifdef USE_SKINNING
            vec4 skinVertex = vec4(position, 1.0);
            vec4 skinned  = boneMatX * skinVertex * skinWeight.x;
            skinned += boneMatY * skinVertex * skinWeight.y;
            displacedPosition  = skinned.xyz;
          #else
            displacedPosition = position;
          #endif
        }
    
      #else
        #ifdef USE_SKINNING
          vec4 skinVertex = vec4(position, 1.0);
          vec4 skinned  = boneMatX * skinVertex * skinWeight.x;
          skinned += boneMatY * skinVertex * skinWeight.y;
          displacedPosition  = skinned.xyz;
        #else
          displacedPosition = position;
        #endif
      #endif
    
      vec4 mvPosition = modelViewMatrix * vec4(displacedPosition, 1.0);
      vec4 worldPosition = modelMatrix * vec4(displacedPosition, 1.0);
      gl_Position = projectionMatrix * mvPosition;
      vWorldPosition = worldPosition.xyz;
      vViewPosition = -mvPosition.xyz;
      
    // shadows
      #ifdef USE_SHADOWMAP
        for(int i = 0; i < MAX_SHADOWS; i ++) {
          vShadowCoord[i] = shadowMatrix[i] * worldPosition;
        }
      #endif
    }
  """,
  
  "fragmentShader": """
    uniform vec3 uAmbientColor;
    uniform vec3 uDiffuseColor;
    uniform vec3 uSpecularColor;
    
    uniform float uShininess;
    uniform float uOpacity;
    
    uniform bool enableDiffuse;
    uniform bool enableSpecular;
    uniform bool enableAO;
    uniform bool enableReflection;
    
    uniform sampler2D tDiffuse;
    uniform sampler2D tNormal;
    uniform sampler2D tSpecular;
    uniform sampler2D tAO;
    
    uniform samplerCube tCube;
    
    uniform vec2 uNormalScale;
    
    uniform bool useRefract;
    uniform float uRefractionRatio;
    uniform float uReflectivity;
    
    varying vec3 vTangent;
    varying vec3 vBinormal;
    varying vec3 vNormal;
    varying vec2 vUv;
    uniform vec3 ambientLightColor;
    
    #if MAX_DIR_LIGHTS > 0
      uniform vec3 directionalLightColor[MAX_DIR_LIGHTS];
      uniform vec3 directionalLightDirection[MAX_DIR_LIGHTS];
    #endif
    
    #if MAX_HEMI_LIGHTS > 0
      uniform vec3 hemisphereLightSkyColor[MAX_HEMI_LIGHTS];
      uniform vec3 hemisphereLightGroundColor[MAX_HEMI_LIGHTS];
      uniform vec3 hemisphereLightDirection[MAX_HEMI_LIGHTS];
    #endif
    
    #if MAX_POINT_LIGHTS > 0
      uniform vec3 pointLightColor[MAX_POINT_LIGHTS];
      uniform vec3 pointLightPosition[MAX_POINT_LIGHTS];
      uniform float pointLightDistance[MAX_POINT_LIGHTS];
    #endif
    
    #if MAX_SPOT_LIGHTS > 0
      uniform vec3 spotLightColor[MAX_SPOT_LIGHTS];
      uniform vec3 spotLightPosition[MAX_SPOT_LIGHTS];
      uniform vec3 spotLightDirection[MAX_SPOT_LIGHTS];
      uniform float spotLightAngleCos[MAX_SPOT_LIGHTS];
      uniform float spotLightExponent[MAX_SPOT_LIGHTS];
      uniform float spotLightDistance[MAX_SPOT_LIGHTS];
    #endif
    
    #ifdef WRAP_AROUND
      uniform vec3 wrapRGB;
    #endif
    
    varying vec3 vWorldPosition;
    varying vec3 vViewPosition;
    
    ${ShaderChunk["shadowmap_pars_fragment"]}
    ${ShaderChunk["fog_pars_fragment"]}
    
    void main() {
      gl_FragColor = vec4(vec3(1.0), uOpacity);
      vec3 specularTex = vec3(1.0);
      vec3 normalTex = texture2D(tNormal, vUv).xyz * 2.0 - 1.0;
      normalTex.xy *= uNormalScale;
      normalTex = normalize(normalTex);
      
      if(enableDiffuse) {
        #ifdef GAMMA_INPUT
          vec4 texelColor = texture2D(tDiffuse, vUv);
          texelColor.xyz *= texelColor.xyz;
          gl_FragColor = gl_FragColor * texelColor;
        #else
          gl_FragColor = gl_FragColor * texture2D(tDiffuse, vUv);
        #endif
      }
      
      if(enableAO) {
        #ifdef GAMMA_INPUT
          vec4 aoColor = texture2D(tAO, vUv);
          aoColor.xyz *= aoColor.xyz;
          gl_FragColor.xyz = gl_FragColor.xyz * aoColor.xyz;
        #else
          gl_FragColor.xyz = gl_FragColor.xyz * texture2D(tAO, vUv).xyz;
        #endif
      }
      
      if(enableSpecular)
        specularTex = texture2D(tSpecular, vUv).xyz;
      mat3 tsb = mat3(normalize(vTangent), normalize(vBinormal), normalize(vNormal));
      vec3 finalNormal = tsb * normalTex;
      #ifdef FLIP_SIDED
        finalNormal = -finalNormal;
      #endif
      
      vec3 normal = normalize(finalNormal);
      vec3 viewPosition = normalize(vViewPosition);
      
      // point lights
      #if MAX_POINT_LIGHTS > 0
        vec3 pointDiffuse = vec3(0.0);
        vec3 pointSpecular = vec3(0.0);
        
        for (int i = 0; i < MAX_POINT_LIGHTS; i ++) {
          vec4 lPosition = viewMatrix * vec4(pointLightPosition[i], 1.0);
          vec3 pointVector = lPosition.xyz + vViewPosition.xyz;
          float pointDistance = 1.0;
          
          if (pointLightDistance[i] > 0.0)
            pointDistance = 1.0 - min((length(pointVector) / pointLightDistance[i]), 1.0);
          pointVector = normalize(pointVector);
           
          // diffuse
          #ifdef WRAP_AROUND
            float pointDiffuseWeightFull = max(dot(normal, pointVector), 0.0);
            float pointDiffuseWeightHalf = max(0.5 * dot(normal, pointVector) + 0.5, 0.0);
            vec3 pointDiffuseWeight = mix(vec3 (pointDiffuseWeightFull), vec3(pointDiffuseWeightHalf), wrapRGB);
          #else
            float pointDiffuseWeight = max(dot(normal, pointVector), 0.0);
          #endif
          pointDiffuse += pointDistance * pointLightColor[i] * uDiffuseColor * pointDiffuseWeight;
          
          // specular
          vec3 pointHalfVector = normalize(pointVector + viewPosition);
          float pointDotNormalHalf = max(dot(normal, pointHalfVector), 0.0);
          float pointSpecularWeight = specularTex.r * max(pow(pointDotNormalHalf, uShininess), 0.0);
          
          #ifdef PHYSICALLY_BASED_SHADING
            // 2.0 => 2.0001 is hack to work around ANGLE bug
            float specularNormalization = (uShininess + 2.0001) / 8.0;
            vec3 schlick = uSpecularColor + vec3(1.0 - uSpecularColor) * pow(1.0 - dot(pointVector, pointHalfVector), 5.0);
            pointSpecular += schlick * pointLightColor[i] * pointSpecularWeight * pointDiffuseWeight * pointDistance * specularNormalization;
          #else
            pointSpecular += pointDistance * pointLightColor[i] * uSpecularColor * pointSpecularWeight * pointDiffuseWeight;
          #endif
        }
      #endif
    
      // spot lights
      #if MAX_SPOT_LIGHTS > 0
        vec3 spotDiffuse = vec3(0.0);
        vec3 spotSpecular = vec3(0.0);
        
        for (int i = 0; i < MAX_SPOT_LIGHTS; i ++) {
          vec4 lPosition = viewMatrix * vec4(spotLightPosition[i], 1.0);
          vec3 spotVector = lPosition.xyz + vViewPosition.xyz;
          float spotDistance = 1.0;
          
          if (spotLightDistance[i] > 0.0)
            spotDistance = 1.0 - min((length(spotVector) / spotLightDistance[i]), 1.0);
    
          spotVector = normalize(spotVector);
          float spotEffect = dot(spotLightDirection[i], normalize(spotLightPosition[i] - vWorldPosition));
          
          if (spotEffect > spotLightAngleCos[i]) {
            spotEffect = max(pow(spotEffect, spotLightExponent[i]), 0.0);
            
            // diffuse
            #ifdef WRAP_AROUND
              float spotDiffuseWeightFull = max(dot(normal, spotVector), 0.0);
              float spotDiffuseWeightHalf = max(0.5 * dot(normal, spotVector) + 0.5, 0.0);
              vec3 spotDiffuseWeight = mix(vec3 (spotDiffuseWeightFull), vec3(spotDiffuseWeightHalf), wrapRGB);
            #else
              float spotDiffuseWeight = max(dot(normal, spotVector), 0.0);
            #endif
    
            spotDiffuse += spotDistance * spotLightColor[i] * uDiffuseColor * spotDiffuseWeight * spotEffect;
            
            // specular
            vec3 spotHalfVector = normalize(spotVector + viewPosition);
            float spotDotNormalHalf = max(dot(normal, spotHalfVector), 0.0);
            float spotSpecularWeight = specularTex.r * max(pow(spotDotNormalHalf, uShininess), 0.0);
            
            #ifdef PHYSICALLY_BASED_SHADING
              // 2.0 => 2.0001 is hack to work around ANGLE bug
              float specularNormalization = (uShininess + 2.0001) / 8.0;
              vec3 schlick = uSpecularColor + vec3(1.0 - uSpecularColor) * pow(1.0 - dot(spotVector, spotHalfVector), 5.0);
              spotSpecular += schlick * spotLightColor[i] * spotSpecularWeight * spotDiffuseWeight * spotDistance * specularNormalization * spotEffect;
            #else
              spotSpecular += spotDistance * spotLightColor[i] * uSpecularColor * spotSpecularWeight * spotDiffuseWeight * spotEffect;
            #endif
          }
        }
      #endif
    
      // directional lights
      #if MAX_DIR_LIGHTS > 0
        vec3 dirDiffuse = vec3(0.0);
        vec3 dirSpecular = vec3(0.0);
        for(int i = 0; i < MAX_DIR_LIGHTS; i++) {
          vec4 lDirection = viewMatrix * vec4(directionalLightDirection[i], 0.0);
          vec3 dirVector = normalize(lDirection.xyz);
          
          // diffuse
          #ifdef WRAP_AROUND
            float directionalLightWeightingFull = max(dot(normal, dirVector), 0.0);
            float directionalLightWeightingHalf = max(0.5 * dot(normal, dirVector) + 0.5, 0.0);
            vec3 dirDiffuseWeight = mix(vec3(directionalLightWeightingFull), vec3(directionalLightWeightingHalf), wrapRGB);
          #else
            float dirDiffuseWeight = max(dot(normal, dirVector), 0.0);
          #endif
          
          dirDiffuse += directionalLightColor[i] * uDiffuseColor * dirDiffuseWeight;
          
          // specular
          vec3 dirHalfVector = normalize(dirVector + viewPosition);
          float dirDotNormalHalf = max(dot(normal, dirHalfVector), 0.0);
          float dirSpecularWeight = specularTex.r * max(pow(dirDotNormalHalf, uShininess), 0.0);
          
          #ifdef PHYSICALLY_BASED_SHADING
            // 2.0 => 2.0001 is hack to work around ANGLE bug
            float specularNormalization = (uShininess + 2.0001) / 8.0;
            vec3 schlick = uSpecularColor + vec3(1.0 - uSpecularColor) * pow(1.0 - dot(dirVector, dirHalfVector), 5.0);
            dirSpecular += schlick * directionalLightColor[i] * dirSpecularWeight * dirDiffuseWeight * specularNormalization;
          #else
            dirSpecular += directionalLightColor[i] * uSpecularColor * dirSpecularWeight * dirDiffuseWeight;
          #endif
        }
      #endif
    
      // hemisphere lights
      #if MAX_HEMI_LIGHTS > 0
        vec3 hemiDiffuse  = vec3(0.0);
        vec3 hemiSpecular = vec3(0.0);
    
        for(int i = 0; i < MAX_HEMI_LIGHTS; i ++) {
          vec4 lDirection = viewMatrix * vec4(hemisphereLightDirection[i], 0.0);
          vec3 lVector = normalize(lDirection.xyz);
    
          // diffuse
          float dotProduct = dot(normal, lVector);
          float hemiDiffuseWeight = 0.5 * dotProduct + 0.5;
          vec3 hemiColor = mix(hemisphereLightGroundColor[i], hemisphereLightSkyColor[i], hemiDiffuseWeight);
          hemiDiffuse += uDiffuseColor * hemiColor;
          
          // specular (sky light)
          vec3 hemiHalfVectorSky = normalize(lVector + viewPosition);
          float hemiDotNormalHalfSky = 0.5 * dot(normal, hemiHalfVectorSky) + 0.5;
          float hemiSpecularWeightSky = specularTex.r * max(pow(hemiDotNormalHalfSky, uShininess), 0.0);
          
          // specular (ground light)
          vec3 lVectorGround = -lVector;
          vec3 hemiHalfVectorGround = normalize(lVectorGround + viewPosition);
          float hemiDotNormalHalfGround = 0.5 * dot(normal, hemiHalfVectorGround) + 0.5;
          float hemiSpecularWeightGround = specularTex.r * max(pow(hemiDotNormalHalfGround, uShininess), 0.0);
          
          #ifdef PHYSICALLY_BASED_SHADING
            float dotProductGround = dot(normal, lVectorGround);
            
            // 2.0 => 2.0001 is hack to work around ANGLE bug
            float specularNormalization = (uShininess + 2.0001) / 8.0;
            
            vec3 schlickSky = uSpecularColor + vec3(1.0 - uSpecularColor) * pow(1.0 - dot(lVector, hemiHalfVectorSky), 5.0);
            vec3 schlickGround = uSpecularColor + vec3(1.0 - uSpecularColor) * pow(1.0 - dot(lVectorGround, hemiHalfVectorGround), 5.0);
            hemiSpecular += hemiColor * specularNormalization * (schlickSky * hemiSpecularWeightSky * max(dotProduct, 0.0) + schlickGround * hemiSpecularWeightGround * max(dotProductGround, 0.0));
          #else
            hemiSpecular += uSpecularColor * hemiColor * (hemiSpecularWeightSky + hemiSpecularWeightGround) * hemiDiffuseWeight;
          #endif
        }
      #endif
    
      // all lights contribution summation
      vec3 totalDiffuse = vec3(0.0);
      vec3 totalSpecular = vec3(0.0);
    
      #if MAX_DIR_LIGHTS > 0
        totalDiffuse += dirDiffuse;
        totalSpecular += dirSpecular;
      #endif
    
      #if MAX_HEMI_LIGHTS > 0
        totalDiffuse += hemiDiffuse;
        totalSpecular += hemiSpecular;
      #endif
    
      #if MAX_POINT_LIGHTS > 0
        totalDiffuse += pointDiffuse;
        totalSpecular += pointSpecular;
      #endif
    
      #if MAX_SPOT_LIGHTS > 0
        totalDiffuse += spotDiffuse;
        totalSpecular += spotSpecular;
      #endif
    
      #ifdef METAL
        gl_FragColor.xyz = gl_FragColor.xyz * (totalDiffuse + ambientLightColor * uAmbientColor + totalSpecular);
      #else
        gl_FragColor.xyz = gl_FragColor.xyz * (totalDiffuse + ambientLightColor * uAmbientColor) + totalSpecular;
      #endif
    
      if (enableReflection) {
        vec3 vReflect;
        vec3 cameraToVertex = normalize(vWorldPosition - cameraPosition);
        
        if (useRefract) {
          vReflect = refract(cameraToVertex, normal, uRefractionRatio);
        } else {
          vReflect = reflect(cameraToVertex, normal);
        }
    
        vec4 cubeColor = textureCube(tCube, vec3(-vReflect.x, vReflect.yz));
        
        #ifdef GAMMA_INPUT
          cubeColor.xyz *= cubeColor.xyz;
        #endif
        gl_FragColor.xyz = mix(gl_FragColor.xyz, cubeColor.xyz, specularTex.r * uReflectivity);
      }
      ${ShaderChunk["shadowmap_fragment"]}
      ${ShaderChunk["linear_to_gamma_fragment"]}
      ${ShaderChunk["fog_fragment"]}
    }
  """},

/* -------------------------------------------------------------------------
//        Cube map shader
 ------------------------------------------------------------------------- */
"cube": {
  
  "uniforms": UniformsUtils.merge([{"tCube": new Uniform.texture(),
                                    "tFlip": new Uniform.float(-1.0)}]),
    
  "vertexShader": """
    varying vec3 vWorldPosition;
    void main() {
      vec4 worldPosition = modelMatrix * vec4(position, 1.0);
      vWorldPosition = worldPosition.xyz;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  """,
  
  "fragmentShader": """
    uniform samplerCube tCube;
    uniform float tFlip;
    varying vec3 vWorldPosition;
    void main() {
      gl_FragColor = textureCube(tCube, vec3(tFlip * vWorldPosition.x, vWorldPosition.yz));
    }
  """},

// Depth encoding into RGBA texture
//         based on SpiderGL shadow map example
//                 http://spidergl.org/example.php?id=6
//         originally from
//                http://www.gamedev.net/topic/442138-packing-a-float-into-a-a8r8g8b8-texture-shader/page__whichpage__1%25EF%25BF%25BD
//         see also here:
//                http://aras-p.info/blog/2009/07/30/encoding-floats-to-rgba-the-final/

"depthRGBA": {
  
  "uniforms": {},
    
  "vertexShader": """
    ${ShaderChunk["morphtarget_pars_vertex"]}
    ${ShaderChunk["skinning_pars_vertex"]}
    void main() {
      ${ShaderChunk["skinbase_vertex"]}
      ${ShaderChunk["morphtarget_vertex"]}
      ${ShaderChunk["skinning_vertex"]}
      ${ShaderChunk["default_vertex"]}
    }
  """,
  
  "fragmentShader": """
    vec4 pack_depth(const in float depth) {
      const vec4 bit_shift = vec4(256.0 * 256.0 * 256.0, 256.0 * 256.0, 256.0, 1.0);
      const vec4 bit_mask  = vec4(0.0, 1.0 / 256.0, 1.0 / 256.0, 1.0 / 256.0);
      vec4 res = fract(depth * bit_shift);
      res -= res.xxyz * bit_mask;
      return res;
    }
    void main() {
      gl_FragData[0] = pack_depth(gl_FragCoord.z);
    }
  """}};