library shaders;

import 'dart:math' as Math;
import 'package:three/three.dart' show Uniform, UniformsLib, Matrix4;
import 'package:three/extras/utils/uniforms_utils.dart' as UniformsUtils;

final Map lensFlareVertexTexture = {
'vertexShader': """
  uniform lowp int renderType;
  uniform vec3 screenPosition;
  uniform vec2 scale;
  uniform float rotation;
  uniform sampler2D occlusionMap;
  attribute vec2 position;
  attribute vec2 uv;
  varying vec2 vUV;
  varying float vVisibility;
  void main() {
  vUV = uv;
  vec2 pos = position;
  if(renderType == 2) {
  vec4 visibility = texture2D(occlusionMap, vec2(0.1, 0.1));
  visibility += texture2D(occlusionMap, vec2(0.5, 0.1));
  visibility += texture2D(occlusionMap, vec2(0.9, 0.1));
  visibility += texture2D(occlusionMap, vec2(0.9, 0.5));
  visibility += texture2D(occlusionMap, vec2(0.9, 0.9));
  visibility += texture2D(occlusionMap, vec2(0.5, 0.9));
  visibility += texture2D(occlusionMap, vec2(0.1, 0.9));
  visibility += texture2D(occlusionMap, vec2(0.1, 0.5));
  visibility += texture2D(occlusionMap, vec2(0.5, 0.5));
  vVisibility =        visibility.r / 9.0;
  vVisibility *= 1.0 - visibility.g / 9.0;
  vVisibility *=       visibility.b / 9.0;
  vVisibility *= 1.0 - visibility.a / 9.0;
  pos.x = cos(rotation) * position.x - sin(rotation) * position.y;
  pos.y = sin(rotation) * position.x + cos(rotation) * position.y;
  }
  gl_Position = vec4((pos * scale + screenPosition.xy).xy, screenPosition.z, 1.0);
  }
""",

'fragmentShader': """
  uniform lowp int renderType;
  uniform sampler2D map;
  uniform float opacity;
  uniform vec3 color;
  varying vec2 vUV;
  varying float vVisibility;
  void main() {
  if(renderType == 0) {
  gl_FragColor = vec4(1.0, 0.0, 1.0, 0.0);
  } else if(renderType == 1) {
  gl_FragColor = texture2D(map, vUV);
  } else {
  vec4 texture = texture2D(map, vUV);
  texture.a *= opacity * vVisibility;
  gl_FragColor = texture;
  gl_FragColor.rgb *= color;
  }
  }
"""};

final Map lensFlare = {
'vertexShader': """
  uniform lowp int renderType;
  uniform vec3 screenPosition;
  uniform vec2 scale;
  uniform float rotation;
  attribute vec2 position;
  attribute vec2 uv;
  varying vec2 vUV;
  void main() {
  vUV = uv;
  vec2 pos = position;
  if(renderType == 2) {
  pos.x = cos(rotation) * position.x - sin(rotation) * position.y;
  pos.y = sin(rotation) * position.x + cos(rotation) * position.y;
  }
  gl_Position = vec4((pos * scale + screenPosition.xy).xy, screenPosition.z, 1.0);
  }
""",

'fragmentShader': """
  precision mediump float;
  uniform lowp int renderType;
  uniform sampler2D map;
  uniform sampler2D occlusionMap;
  uniform float opacity;
  uniform vec3 color;
  varying vec2 vUV;
  void main() {
  if(renderType == 0) {
  gl_FragColor = vec4(texture2D(map, vUV).rgb, 0.0);
  } else if(renderType == 1) {
  gl_FragColor = texture2D(map, vUV);
  } else {
  float visibility = texture2D(occlusionMap, vec2(0.5, 0.1)).a;
  visibility += texture2D(occlusionMap, vec2(0.9, 0.5)).a;
  visibility += texture2D(occlusionMap, vec2(0.5, 0.9)).a;
  visibility += texture2D(occlusionMap, vec2(0.1, 0.5)).a;
  visibility = (1.0 - visibility / 4.0);
  vec4 texture = texture2D(map, vUV);
  texture.a *= opacity * visibility;
  gl_FragColor = texture;
  gl_FragColor.rgb *= color;
  }
  }
"""};

final Map copy = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "opacity": new Uniform.float(1.0)},

'vertexShader': """
  void main() {
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  void main() {
  gl_FragColor = vec4(1.0, 0.0, 0.0, 0.5);
  }
"""};

final Map bleachBypass = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "opacity": new Uniform.float(1.0)},

'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform float opacity;
  uniform sampler2D tDiffuse;
  varying vec2 vUv;
  void main() {
  vec4 base = texture2D(tDiffuse, vUv);
  vec3 lumCoeff = vec3(0.25, 0.65, 0.1);
  float lum = dot(lumCoeff, base.rgb);
  vec3 blend = vec3(lum);
  float L = min(1.0, max(0.0, 10.0 * (lum - 0.45)));
  vec3 result1 = 2.0 * base.rgb * blend;
  vec3 result2 = 1.0 - 2.0 * (1.0 - blend) * (1.0 - base.rgb);
  vec3 newColor = mix(result1, result2, L);
  float A2 = opacity * base.a;
  vec3 mixRGB = A2 * newColor.rgb;
  mixRGB += ((1.0 - A2) * base.rgb);
  gl_FragColor = vec4(mixRGB, base.a);
  }
"""};

final Map convolution = {
'defines': {"KERNEL_SIZE_FLOAT": '25.0',
            "KERNEL_SIZE_INT": '25'},
  
'uniforms': {"tDiffuse": new Uniform.texture(),
             "uImageIncrement": new Uniform.vector2(0.001953125, 0.0),
             "cKernel": new Uniform.floatv1([])},
  
'vertexShader': """
  uniform vec2 imageIncrement;
  varying vec2 vUv;
  void main() {
  vUv = uv - ((KERNEL_SIZE - 1.0) / 2.0) * imageIncrement;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform float cKernel[KERNEL_SIZE];
  uniform sampler2D tDiffuse;
  uniform vec2 uImageIncrement;
  varying vec2 vUv;
  void main() {
  vec2 imageCoord = vUv;
  vec4 sum = vec4(0.0, 0.0, 0.0, 0.0);
  for(int i = 0; i < KERNEL_SIZE; i ++) {
  sum += texture2D(tDiffuse, imageCoord) * cKernel[i];
  imageCoord += uImageIncrement;
  }
  gl_FragColor = sum;
  }
""",

'buildKernel': (double sigma) {
  gauss(x, sigma) => Math.exp(-(x * x) / (2.0 * sigma * sigma));

  var halfWidth, kMaxKernelSize = 25, kernelSize = 2 * (sigma * 3.0).ceil() + 1;

  if (kernelSize > kMaxKernelSize) kernelSize = kMaxKernelSize;
  halfWidth = (kernelSize - 1) * 0.5;
 
  var values = new List(kernelSize);
  var sum = 0.0;
  for (var i = 0; i < kernelSize; i++) {
    values[i] = gauss(i - halfWidth, sigma);
    sum += values[i];
  }
  
  values.forEach((value) => value /= sum);
  return values;
}};

final Map film = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "time": new Uniform.float(0.0),
             "nIntensity": new Uniform.float(0.5),
             "sIntensity": new Uniform.float(0.05),
             "sCount": new Uniform.float(4095.0),
             "grayscale": new Uniform.int(1)},
                                
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform float time;
  uniform bool grayscale;
  uniform float nIntensity;
  uniform float sIntensity;
  uniform float sCount;
  uniform sampler2D tDiffuse;
  varying vec2 vUv;
  void main() {
  vec4 cTextureScreen = texture2D(tDiffuse, vUv);
  float x = vUv.x * vUv.y * time *  1000.0;
  x = mod(x, 13.0) * mod(x, 123.0);
  float dx = mod(x, 0.01);
  vec3 cResult = cTextureScreen.rgb + cTextureScreen.rgb * clamp(0.1 + dx * 100.0, 0.0, 1.0);
  vec2 sc = vec2(sin(vUv.y * sCount), cos(vUv.y * sCount));
  cResult += cTextureScreen.rgb * vec3(sc.x, sc.y, sc.x) * sIntensity;
  cResult = cTextureScreen.rgb + clamp(nIntensity, 0.0,1.0) * (cResult - cTextureScreen.rgb);
  if(grayscale) {
  cResult = vec3(cResult.r * 0.3 + cResult.g * 0.59 + cResult.b * 0.11);
  }
  gl_FragColor =  vec4(cResult, cTextureScreen.a);
  }
"""};

final Map bokeh = {
'uniforms': {"tColor": new Uniform.texture(),
             "tDepth": new Uniform.texture(),
             "focus": new Uniform.float(1.0),
             "aspect": new Uniform.float(1.0),
             "aperture": new Uniform.float(0.025),
             "maxblur": new Uniform.float(1.0)},
             
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  varying vec2 vUv;
  uniform sampler2D tColor;
  uniform sampler2D tDepth;
  uniform float maxblur;
  uniform float aperture;
  uniform float focus;
  uniform float aspect;
  void main() {
  vec2 aspectcorrect = vec2(1.0, aspect);
  vec4 depth1 = texture2D(tDepth, vUv);
  float factor = depth1.x - focus;
  vec2 dofblur = vec2 (clamp(factor * aperture, -maxblur, maxblur));
  vec2 dofblur9 = dofblur * 0.9;
  vec2 dofblur7 = dofblur * 0.7;
  vec2 dofblur4 = dofblur * 0.4;
  vec4 col = vec4(0.0);
  col += texture2D(tColor, vUv.xy);
  col += texture2D(tColor, vUv.xy + (vec2(0.0,   0.4) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.15,  0.37) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.29,  0.29) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(-0.37,  0.15) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.40,  0.0) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.37, -0.15) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.29, -0.29) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(-0.15, -0.37) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.0,  -0.4) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(-0.15,  0.37) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(-0.29,  0.29) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.37,  0.15) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(-0.4,   0.0) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(-0.37, -0.15) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(-0.29, -0.29) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.15, -0.37) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.15,  0.37) * aspectcorrect) * dofblur9);
  col += texture2D(tColor, vUv.xy + (vec2(-0.37,  0.15) * aspectcorrect) * dofblur9);
  col += texture2D(tColor, vUv.xy + (vec2(0.37, -0.15) * aspectcorrect) * dofblur9);
  col += texture2D(tColor, vUv.xy + (vec2(-0.15, -0.37) * aspectcorrect) * dofblur9);
  col += texture2D(tColor, vUv.xy + (vec2(-0.15,  0.37) * aspectcorrect) * dofblur9);
  col += texture2D(tColor, vUv.xy + (vec2(0.37,  0.15) * aspectcorrect) * dofblur9);
  col += texture2D(tColor, vUv.xy + (vec2(-0.37, -0.15) * aspectcorrect) * dofblur9);
  col += texture2D(tColor, vUv.xy + (vec2(0.15, -0.37) * aspectcorrect) * dofblur9);
  col += texture2D(tColor, vUv.xy + (vec2(0.29,  0.29) * aspectcorrect) * dofblur7);
  col += texture2D(tColor, vUv.xy + (vec2(0.40,  0.0) * aspectcorrect) * dofblur7);
  col += texture2D(tColor, vUv.xy + (vec2(0.29, -0.29) * aspectcorrect) * dofblur7);
  col += texture2D(tColor, vUv.xy + (vec2(0.0,  -0.4) * aspectcorrect) * dofblur7);
  col += texture2D(tColor, vUv.xy + (vec2(-0.29,  0.29) * aspectcorrect) * dofblur7);
  col += texture2D(tColor, vUv.xy + (vec2(-0.4,   0.0) * aspectcorrect) * dofblur7);
  col += texture2D(tColor, vUv.xy + (vec2(-0.29, -0.29) * aspectcorrect) * dofblur7);
  col += texture2D(tColor, vUv.xy + (vec2(0.0,   0.4) * aspectcorrect) * dofblur7);
  col += texture2D(tColor, vUv.xy + (vec2(0.29,  0.29) * aspectcorrect) * dofblur4);
  col += texture2D(tColor, vUv.xy + (vec2(0.4,   0.0) * aspectcorrect) * dofblur4);
  col += texture2D(tColor, vUv.xy + (vec2(0.29, -0.29) * aspectcorrect) * dofblur4);
  col += texture2D(tColor, vUv.xy + (vec2(0.0,  -0.4) * aspectcorrect) * dofblur4);
  col += texture2D(tColor, vUv.xy + (vec2(-0.29,  0.29) * aspectcorrect) * dofblur4);
  col += texture2D(tColor, vUv.xy + (vec2(-0.4,   0.0) * aspectcorrect) * dofblur4);
  col += texture2D(tColor, vUv.xy + (vec2(-0.29, -0.29) * aspectcorrect) * dofblur4);
  col += texture2D(tColor, vUv.xy + (vec2(0.0,   0.4) * aspectcorrect) * dofblur4);
  gl_FragColor = col / 41.0;
  gl_FragColor.a = 1.0;
  }
"""};

final Map bokeh2 = {
'uniforms': {"textureWidth": new Uniform.float(1.0),
             "textureHeight": new Uniform.float(1.0),
          
             "focalDepth": new Uniform.float(1.0),
             "focalLength": new Uniform.float(24.0),
             "fstop": new Uniform.float(0.9),
          
             "tColor":  new Uniform.texture(),
             "tDepth":  new Uniform.texture(),
          
             "maxblur": new Uniform.float(1.0),
          
             "showFocus":  new Uniform.int(0),
             "manualdof":  new Uniform.int(0),
             "vignetting":  new Uniform.int(0),
             "depthblur":  new Uniform.int(0),
          
             "threshold": new Uniform.float(0.5),
             "gain": new Uniform.float(2.0),
             "bias": new Uniform.float(0.5),
             "fringe": new Uniform.float(0.7),
          
             "znear": new Uniform.float(0.1),
             "zfar": new Uniform.float(100.0),
          
             "noise": new Uniform.int(1),
             "dithering": new Uniform.float(0.0001),
             "pentagon": new Uniform.int(0),
          
             "shaderFocus": new Uniform.int(1),
             "focusCoords":  new Uniform.vector2(0.0, 0.0)},

'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  varying vec2 vUv;
  uniform sampler2D tColor;
  uniform sampler2D tDepth;
  uniform float textureWidth;
  uniform float textureHeight;
  const float PI = 3.14159265;
  float width = textureWidth; //texture width
  float height = textureHeight; //texture height
  vec2 texel = vec2(1.0/width,1.0/height);
  uniform float focalDepth;  //focal distance value in meters, but you may use autofocus option below
  uniform float focalLength; //focal length in mm
  uniform float fstop; //f-stop value
  uniform bool showFocus; //show debug focus point and focal range (red = focal point, green = focal range)
  /*
  make sure that these two values are the same for your camera, otherwise distances will be wrong.
  */
  uniform float znear; // camera clipping start
  uniform float zfar; // camera clipping end
  //------------------------------------------
  //user variables
  const int samples = SAMPLES; //samples on the first ring
  const int rings = RINGS; //ring count
  const int maxringsamples = rings * samples;
  uniform bool manualdof; // manual dof calculation
  float ndofstart = 1.0; // near dof blur start
  float ndofdist = 2.0; // near dof blur falloff distance
  float fdofstart = 1.0; // far dof blur start
  float fdofdist = 3.0; // far dof blur falloff distance
  float CoC = 0.03; //circle of confusion size in mm (35mm film = 0.03mm)
  uniform bool vignetting; // use optical lens vignetting
  float vignout = 1.3; // vignetting outer border
  float vignin = 0.0; // vignetting inner border
  float vignfade = 22.0; // f-stops till vignete fades
  uniform bool shaderFocus;
  bool autofocus = shaderFocus;
  //use autofocus in shader - use with focusCoords
  // disable if you use external focalDepth value
  uniform vec2 focusCoords;
  // autofocus point on screen (0.0,0.0 - left lower corner, 1.0,1.0 - upper right)
  // if center of screen use vec2(0.5, 0.5);
  uniform float maxblur;
  //clamp value of max blur (0.0 = no blur, 1.0 default)
  uniform float threshold; // highlight threshold;
  uniform float gain; // highlight gain;
  uniform float bias; // bokeh edge bias
  uniform float fringe; // bokeh chromatic aberration / fringing
  uniform bool noise; //use noise instead of pattern for sample dithering
  uniform float dithering;
  float namount = dithering; //dither amount
  uniform bool depthblur; // blur the depth buffer
  float dbsize = 1.25; // depth blur size
  /*
  next part is experimental
  not looking good with small sample and ring count
  looks okay starting from samples = 4, rings = 4
  */
  uniform bool pentagon; //use pentagon as bokeh shape?
  float feather = 0.4; //pentagon shape feather
  //------------------------------------------
  float penta(vec2 coords) {
  //pentagonal shape
  float scale = float(rings) - 1.3;
  vec4  HS0 = vec4(1.0,         0.0,         0.0,  1.0);
  vec4  HS1 = vec4(0.309016994, 0.951056516, 0.0,  1.0);
  vec4  HS2 = vec4(-0.809016994, 0.587785252, 0.0,  1.0);
  vec4  HS3 = vec4(-0.809016994,-0.587785252, 0.0,  1.0);
  vec4  HS4 = vec4(0.309016994,-0.951056516, 0.0,  1.0);
  vec4  HS5 = vec4(0.0        ,0.0         , 1.0,  1.0);
  vec4  one = vec4(1.0);
  vec4 P = vec4((coords),vec2(scale, scale));
  vec4 dist = vec4(0.0);
  float inorout = -4.0;
  dist.x = dot(P, HS0);
  dist.y = dot(P, HS1);
  dist.z = dot(P, HS2);
  dist.w = dot(P, HS3);
  dist = smoothstep(-feather, feather, dist);
  inorout += dot(dist, one);
  dist.x = dot(P, HS4);
  dist.y = HS5.w - abs(P.z);
  dist = smoothstep(-feather, feather, dist);
  inorout += dist.x;
  return clamp(inorout, 0.0, 1.0);
  }
  float bdepth(vec2 coords) {
  // Depth buffer blur
  float d = 0.0;
  float kernel[9];
  vec2 offset[9];
  vec2 wh = vec2(texel.x, texel.y) * dbsize;
  offset[0] = vec2(-wh.x,-wh.y);
  offset[1] = vec2(0.0, -wh.y);
  offset[2] = vec2(wh.x -wh.y);
  offset[3] = vec2(-wh.x,  0.0);
  offset[4] = vec2(0.0,   0.0);
  offset[5] = vec2(wh.x,  0.0);
  offset[6] = vec2(-wh.x, wh.y);
  offset[7] = vec2(0.0,  wh.y);
  offset[8] = vec2(wh.x, wh.y);
  kernel[0] = 1.0/16.0;   kernel[1] = 2.0/16.0;   kernel[2] = 1.0/16.0;
  kernel[3] = 2.0/16.0;   kernel[4] = 4.0/16.0;   kernel[5] = 2.0/16.0;
  kernel[6] = 1.0/16.0;   kernel[7] = 2.0/16.0;   kernel[8] = 1.0/16.0;
  for(int i=0; i<9; i++) {
  float tmp = texture2D(tDepth, coords + offset[i]).r;
  d += tmp * kernel[i];
  }
  return d;
  }
  vec3 color(vec2 coords,float blur) {
  //processing the sample
  vec3 col = vec3(0.0);
  col.r = texture2D(tColor,coords + vec2(0.0,1.0)*texel*fringe*blur).r;
  col.g = texture2D(tColor,coords + vec2(-0.866,-0.5)*texel*fringe*blur).g;
  col.b = texture2D(tColor,coords + vec2(0.866,-0.5)*texel*fringe*blur).b;
  vec3 lumcoeff = vec3(0.299,0.587,0.114);
  float lum = dot(col.rgb, lumcoeff);
  float thresh = max((lum-threshold)*gain, 0.0);
  return col+mix(vec3(0.0),col,thresh*blur);
  }
  vec2 rand(vec2 coord) {
  // generating noise / pattern texture for dithering
  float noiseX = ((fract(1.0-coord.s*(width/2.0))*0.25)+(fract(coord.t*(height/2.0))*0.75))*2.0-1.0;
  float noiseY = ((fract(1.0-coord.s*(width/2.0))*0.75)+(fract(coord.t*(height/2.0))*0.25))*2.0-1.0;
  if (noise) {
  noiseX = clamp(fract(sin(dot(coord ,vec2(12.9898,78.233))) * 43758.5453),0.0,1.0)*2.0-1.0;
  noiseY = clamp(fract(sin(dot(coord ,vec2(12.9898,78.233)*2.0)) * 43758.5453),0.0,1.0)*2.0-1.0;
  }
  return vec2(noiseX,noiseY);
  }
  vec3 debugFocus(vec3 col, float blur, float depth) {
  float edge = 0.002*depth; //distance based edge smoothing
  float m = clamp(smoothstep(0.0,edge,blur),0.0,1.0);
  float e = clamp(smoothstep(1.0-edge,1.0,blur),0.0,1.0);
  col = mix(col,vec3(1.0,0.5,0.0),(1.0-m)*0.6);
  col = mix(col,vec3(0.0,0.5,1.0),((1.0-e)-(1.0-m))*0.2);
  return col;
  }
  float linearize(float depth) {
  return -zfar * znear / (depth * (zfar - znear) - zfar);
  }
  float vignette() {
  float dist = distance(vUv.xy, vec2(0.5,0.5));
  dist = smoothstep(vignout+(fstop/vignfade), vignin+(fstop/vignfade), dist);
  return clamp(dist,0.0,1.0);
  }
  float gather(float i, float j, int ringsamples, inout vec3 col, float w, float h, float blur) {
  float rings2 = float(rings);
  float step = PI*2.0 / float(ringsamples);
  float pw = cos(j*step)*i;
  float ph = sin(j*step)*i;
  float p = 1.0;
  if (pentagon) {
  p = penta(vec2(pw,ph));
  }
  col += color(vUv.xy + vec2(pw*w,ph*h), blur) * mix(1.0, i/rings2, bias) * p;
  return 1.0 * mix(1.0, i /rings2, bias) * p;
  }
  void main() {
  //scene depth calculation
  float depth = linearize(texture2D(tDepth,vUv.xy).x);
  // Blur depth?
  if (depthblur) {
  depth = linearize(bdepth(vUv.xy));
  }
  //focal plane calculation
  float fDepth = focalDepth;
  if (autofocus) {
  fDepth = linearize(texture2D(tDepth,focusCoords).x);
  }
  // dof blur factor calculation
  float blur = 0.0;
  if (manualdof) {
  float a = depth-fDepth; // Focal plane
  float b = (a-fdofstart)/fdofdist; // Far DoF
  float c = (-a-ndofstart)/ndofdist; // Near Dof
  blur = (a>0.0) ? b : c;
  } else {
  float f = focalLength; // focal length in mm
  float d = fDepth*1000.0; // focal plane in mm
  float o = depth*1000.0; // depth in mm
  float a = (o*f)/(o-f);
  float b = (d*f)/(d-f);
  float c = (d-f)/(d*fstop*CoC);
  blur = abs(a-b)*c;
  }
  blur = clamp(blur,0.0,1.0);
  // calculation of pattern for dithering
  vec2 noise = rand(vUv.xy)*namount*blur;
  // getting blur x and y step factor
  float w = (1.0/width)*blur*maxblur+noise.x;
  float h = (1.0/height)*blur*maxblur+noise.y;
  // calculation of final color
  vec3 col = vec3(0.0);
  if(blur < 0.05) {
  //some optimization thingy
  col = texture2D(tColor, vUv.xy).rgb;
  } else {
  col = texture2D(tColor, vUv.xy).rgb;
  float s = 1.0;
  int ringsamples;
  for (int i = 1; i <= rings; i++) {
  /*unboxstart*/
  ringsamples = i * samples;
  for (int j = 0 ; j < maxringsamples ; j++) {
  if (j >= ringsamples) break;
  s += gather(float(i), float(j), ringsamples, col, w, h, blur);
  }
  /*unboxend*/
  }
  col /= s; //divide by sample count
  }
  if (showFocus) {
  col = debugFocus(col, blur, depth);
  }
  if (vignetting) {
  col *= vignette();
  }
  gl_FragColor.rgb = col;
  gl_FragColor.a = 1.0;
  } 
"""};

final Map brightnessContrast = {                               
'uniforms': {"tDiffuse": new Uniform.texture(),
             "brightness": new Uniform.float(0.0),
             "contrast": new Uniform.float(0.0)},
             
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform sampler2D tDiffuse;
  uniform float brightness;
  uniform float contrast;
  varying vec2 vUv;
  void main() {
  gl_FragColor = texture2D(tDiffuse, vUv);
  gl_FragColor.rgb += brightness;
  if (contrast > 0.0) {
  gl_FragColor.rgb = (gl_FragColor.rgb - 0.5) / (1.0 - contrast) + 0.5;
  } else {
  gl_FragColor.rgb = (gl_FragColor.rgb - 0.5) * (1.0 + contrast) + 0.5;
  }
  }
"""};

final Map dofmipmap = {                
'uniforms': {"tColor": new Uniform.texture(),
             "tDepth": new Uniform.texture(),
             "focus": new Uniform.float(1.0),
             "maxblur": new Uniform.float(1.0)},
             
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform float focus;
  uniform float maxblur;
  uniform sampler2D tColor;
  uniform sampler2D tDepth;
  varying vec2 vUv;
  void main() {
  vec4 depth = texture2D(tDepth, vUv);
  float factor = depth.x - focus;
  vec4 col = texture2D(tColor, vUv, 2.0 * maxblur * abs(focus - depth.x));
  gl_FragColor = col;
  gl_FragColor.a = 1.0;
  }
"""};

final Map edge = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "aspect": new Uniform.vector2(512.0, 512.0)},
             
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform sampler2D tDiffuse;
  varying vec2 vUv;
  uniform vec2 aspect;
  vec2 texel = vec2(1.0 / aspect.x, 1.0 / aspect.y);
  mat3 G[9];
  const mat3 g0 = mat3(0.3535533845424652, 0, -0.3535533845424652, 0.5, 0, -0.5, 0.3535533845424652, 0, -0.3535533845424652);
  const mat3 g1 = mat3(0.3535533845424652, 0.5, 0.3535533845424652, 0, 0, 0, -0.3535533845424652, -0.5, -0.3535533845424652);
  const mat3 g2 = mat3(0, 0.3535533845424652, -0.5, -0.3535533845424652, 0, 0.3535533845424652, 0.5, -0.3535533845424652, 0);
  const mat3 g3 = mat3(0.5, -0.3535533845424652, 0, -0.3535533845424652, 0, 0.3535533845424652, 0, 0.3535533845424652, -0.5);
  const mat3 g4 = mat3(0, -0.5, 0, 0.5, 0, 0.5, 0, -0.5, 0);
  const mat3 g5 = mat3(-0.5, 0, 0.5, 0, 0, 0, 0.5, 0, -0.5);
  const mat3 g6 = mat3(0.1666666716337204, -0.3333333432674408, 0.1666666716337204, -0.3333333432674408, 0.6666666865348816, -0.3333333432674408, 0.1666666716337204, -0.3333333432674408, 0.1666666716337204);
  const mat3 g7 = mat3(-0.3333333432674408, 0.1666666716337204, -0.3333333432674408, 0.1666666716337204, 0.6666666865348816, 0.1666666716337204, -0.3333333432674408, 0.1666666716337204, -0.3333333432674408);
  const mat3 g8 = mat3(0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408);
  void main(void)
  {
  G[0] = g0,
  G[1] = g1,
  G[2] = g2,
  G[3] = g3,
  G[4] = g4,
  G[5] = g5,
  G[6] = g6,
  G[7] = g7,
  G[8] = g8;
  mat3 I;
  float cnv[9];
  vec3 sample;
  for (float i=0.0; i<3.0; i++) {
  for (float j=0.0; j<3.0; j++) {
  sample = texture2D(tDiffuse, vUv + texel * vec2(i-1.0,j-1.0)).rgb;
  I[int(i)][int(j)] = length(sample);
  }
  }
  for (int i=0; i<9; i++) {
  float dp3 = dot(G[i][0], I[0]) + dot(G[i][1], I[1]) + dot(G[i][2], I[2]);
  cnv[i] = dp3 * dp3;
  }
  float M = (cnv[0] + cnv[1]) + (cnv[2] + cnv[3]);
  float S = (cnv[4] + cnv[5]) + (cnv[6] + cnv[7]) + (cnv[8] + M);
  gl_FragColor = vec4(vec3(sqrt(M/S)), 1.0);
  }
"""};

final Map edge2 = {          
'uniforms': {"tDiffuse": new Uniform.texture(),
             "aspect": new Uniform.vector2(512.0, 512.0)},
             
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform sampler2D tDiffuse;
  varying vec2 vUv;
  uniform vec2 aspect;
  vec2 texel = vec2(1.0 / aspect.x, 1.0 / aspect.y);
  mat3 G[2];
  const mat3 g0 = mat3(1.0, 2.0, 1.0, 0.0, 0.0, 0.0, -1.0, -2.0, -1.0);
  const mat3 g1 = mat3(1.0, 0.0, -1.0, 2.0, 0.0, -2.0, 1.0, 0.0, -1.0);
  void main(void)
  {
  mat3 I;
  float cnv[2];
  vec3 sample;
  G[0] = g0;
  G[1] = g1;
  for (float i=0.0; i<3.0; i++)
  for (float j=0.0; j<3.0; j++) {
  sample = texture2D(tDiffuse, vUv + texel * vec2(i-1.0,j-1.0)).rgb;
  I[int(i)][int(j)] = length(sample);
  }
  for (int i=0; i<2; i++) {
  float dp3 = dot(G[i][0], I[0]) + dot(G[i][1], I[1]) + dot(G[i][2], I[2]);
  cnv[i] = dp3 * dp3; 
  }
  gl_FragColor = vec4(0.5 * sqrt(cnv[0]*cnv[0]+cnv[1]*cnv[1]));
  } 
"""};

final Map sepia = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "amount": new Uniform.float(1.0)},
             
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform float amount;
  uniform sampler2D tDiffuse;
  varying vec2 vUv;
  void main() {
  vec4 color = texture2D(tDiffuse, vUv);
  vec3 c = color.rgb;
  color.r = dot(c, vec3(1.0 - 0.607 * amount, 0.769 * amount, 0.189 * amount));
  color.g = dot(c, vec3(0.349 * amount, 1.0 - 0.314 * amount, 0.168 * amount));
  color.b = dot(c, vec3(0.272 * amount, 0.534 * amount, 1.0 - 0.869 * amount));
  gl_FragColor = vec4(min(vec3(1.0), color.rgb), color.a);
  }
"""};

final Map dotscreen = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "tSize": new Uniform.vector2(256.0, 256.0),
             "center": new Uniform.vector2(0.5, 0.5),
             "angle": new Uniform.float(1.57),
             "scale": new Uniform.float(1.0)},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform vec2 center;
  uniform float angle;
  uniform float scale;
  uniform vec2 tSize;
  uniform sampler2D tDiffuse;
  varying vec2 vUv;
  float pattern() {
  float s = sin(angle), c = cos(angle);
  vec2 tex = vUv * tSize - center;
  vec2 point = vec2(c * tex.x - s * tex.y, s * tex.x + c * tex.y) * scale;
  return (sin(point.x) * sin(point.y)) * 4.0;
  }
  void main() {
  vec4 color = texture2D(tDiffuse, vUv);
  float average = (color.r + color.g + color.b) / 3.0;
  gl_FragColor = vec4(vec3(average * 10.0 - 5.0 + pattern()), color.a);
  }
"""};

final Map vignette = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "offset": new Uniform.float(1.0),
             "darkness": new Uniform.float(1.0)},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform float offset;
  uniform float darkness;
  uniform sampler2D tDiffuse;
  varying vec2 vUv;
  void main() {
  vec4 texel = texture2D(tDiffuse, vUv);
  vec2 uv = (vUv - vec2(0.5)) * vec2(offset);
  gl_FragColor = vec4(mix(texel.rgb, vec3(1.0 - darkness), dot(uv, uv)), texel.a);
  }
"""};

final Map bleachbypass = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "opacity": new Uniform.float(1.0)},
             
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform float opacity;
  uniform sampler2D tDiffuse;
  varying vec2 vUv;
  void main() {
  vec4 base = texture2D(tDiffuse, vUv);
  vec3 lumCoeff = vec3(0.25, 0.65, 0.1);
  float lum = dot(lumCoeff, base.rgb);
  vec3 blend = vec3(lum);
  float L = min(1.0, max(0.0, 10.0 * (lum - 0.45)));
  vec3 result1 = 2.0 * base.rgb * blend;
  vec3 result2 = 1.0 - 2.0 * (1.0 - blend) * (1.0 - base.rgb);
  vec3 newColor = mix(result1, result2, L);
  float A2 = opacity * base.a;
  vec3 mixRGB = A2 * newColor.rgb;
  mixRGB += ((1.0 - A2) * base.rgb);
  gl_FragColor = vec4(mixRGB, base.a);
  }
"""};

final Map focus = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "screenWidth": new Uniform.float(1024.0),
             "screenHeight": new Uniform.float(1024.0),
             "sampleDistance": new Uniform.float(0.94),
             "waveFactor": new Uniform.float(0.00125)},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform float screenWidth;
  uniform float screenHeight;
  uniform float sampleDistance;
  uniform float waveFactor;
  uniform sampler2D tDiffuse;
  varying vec2 vUv;
  void main() {
  vec4 color, org, tmp, add;
  float sample_dist, f;
  vec2 vin;
  vec2 uv = vUv;
  add = color = org = texture2D(tDiffuse, uv);
  vin = (uv - vec2(0.5)) * vec2(1.4);
  sample_dist = dot(vin, vin) * 2.0;
  f = (waveFactor * 100.0 + sample_dist) * sampleDistance * 4.0;
  vec2 sampleSize = vec2(1.0 / screenWidth, 1.0 / screenHeight) * vec2(f);
  add += tmp = texture2D(tDiffuse, uv + vec2(0.111964, 0.993712) * sampleSize);
  if(tmp.b < color.b) color = tmp;
  add += tmp = texture2D(tDiffuse, uv + vec2(0.846724, 0.532032) * sampleSize);
  if(tmp.b < color.b) color = tmp;
  add += tmp = texture2D(tDiffuse, uv + vec2(0.943883, -0.330279) * sampleSize);
  if(tmp.b < color.b) color = tmp;
  add += tmp = texture2D(tDiffuse, uv + vec2(0.330279, -0.943883) * sampleSize);
  if(tmp.b < color.b) color = tmp;
  add += tmp = texture2D(tDiffuse, uv + vec2(-0.532032, -0.846724) * sampleSize);
  if(tmp.b < color.b) color = tmp;
  add += tmp = texture2D(tDiffuse, uv + vec2(-0.993712, -0.111964) * sampleSize);
  if(tmp.b < color.b) color = tmp;
  add += tmp = texture2D(tDiffuse, uv + vec2(-0.707107, 0.707107) * sampleSize);
  if(tmp.b < color.b) color = tmp;
  color = color * vec4(2.0) - (add / vec4(8.0));
  color = color + (add / vec4(8.0) - color) * (vec4(1.0) - vec4(sample_dist * 0.5));
  gl_FragColor = vec4(color.rgb * color.rgb * vec3(0.95) + color.rgb, 1.0);
  }
"""};

final Map fresnel = {
'uniforms': {"mRefractionRatio": new Uniform.float(1.02),
             "mFresnelBias": new Uniform.float(0.1),
             "mFresnelPower": new Uniform.float(2.0),
             "mFresnelScale": new Uniform.float(1.0),
             "tCube": new Uniform.texture()},
  
'vertexShader': """
  uniform float refractionRatio;
  uniform float mfresnelBias;
  uniform float mfresnelScale;
  uniform float mfresnelPower;
  varying vec3 vReflect;
  varying vec3 vRefract[3];
  varying float vReflectionFactor;
  void main() {
  vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
  vec4 worldPosition = modelMatrix * vec4(position, 1.0);
  vec3 worldNormal = normalize(mat3(modelMatrix[0].xyz, modelMatrix[1].xyz, modelMatrix[2].xyz) * normal);
  vec3 I = worldPosition.xyz - cameraPosition;
  vReflect = reflect(I, worldNormal);
  vRefract[0] = refract(normalize(I), worldNormal, refractionRatio);
  vRefract[1] = refract(normalize(I), worldNormal, refractionRatio * 0.99);
  vRefract[2] = refract(normalize(I), worldNormal, refractionRatio * 0.98);
  vReflectionFactor = mfresnelBias + mfresnelScale * pow(1.0 + dot(normalize(I), worldNormal), mfresnelPower);
  gl_Position = projectionMatrix * mvPosition;
  }
""",

'fragmentShader': """
  uniform samplerCube tCube;
  varying vec3 vReflect;
  varying vec3 vRefract[3];
  varying float vReflectionFactor;
  void main() {
  vec4 reflectedColor = textureCube(tCube, vec3(-vReflect.x, vReflect.yz));
  vec4 refractedColor = vec4(1.0);
  refractedColor.r = textureCube(tCube, vec3(-vRefract[0].x, vRefract[0].yz)).r;
  refractedColor.g = textureCube(tCube, vec3(-vRefract[1].x, vRefract[1].yz)).g;
  refractedColor.b = textureCube(tCube, vec3(-vRefract[2].x, vRefract[2].yz)).b;
  gl_FragColor = mix(refractedColor, reflectedColor, clamp(vReflectionFactor, 0.0, 1.0));
  }
"""};

final Map triangleBlur = {
'uniforms': {"texture": new Uniform.texture(),
             "delta": new Uniform.vector2(1.0, 1.0)},
                          
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  #define ITERATIONS 10.0
  uniform sampler2D texture;
  uniform vec2 delta;
  varying vec2 vUv;
  float random(vec3 scale, float seed) {
  return fract(sin(dot(gl_FragCoord.xyz + seed, scale)) * 43758.5453 + seed);
  }
  void main() {
  vec4 color = vec4(0.0);
  float total = 0.0;
  float offset = random(vec3(12.9898, 78.233, 151.7182), 0.0);
  for (float t = -ITERATIONS; t <= ITERATIONS; t ++) {
  float percent = (t + offset - 0.5) / ITERATIONS;
  float weight = 1.0 - abs(percent);
  color += texture2D(texture, vUv + delta * percent) * weight;
  total += weight;
  }
  gl_FragColor = color / total;
  }
"""};

final Map basic = {
'uniforms': {},

'vertexShader': """
  void main() {
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  void main() {
  gl_FragColor = vec4(1.0, 0.0, 0.0, 0.5);
  }
"""};

final Map horizontalBlur = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "h": new Uniform.float(1 / 512)},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform sampler2D tDiffuse;
  uniform float h;
  varying vec2 vUv;
  void main() {
  vec4 sum = vec4(0.0);
  sum += texture2D(tDiffuse, vec2(vUv.x - 4.0 * h, vUv.y)) * 0.051;
  sum += texture2D(tDiffuse, vec2(vUv.x - 3.0 * h, vUv.y)) * 0.0918;
  sum += texture2D(tDiffuse, vec2(vUv.x - 2.0 * h, vUv.y)) * 0.12245;
  sum += texture2D(tDiffuse, vec2(vUv.x - 1.0 * h, vUv.y)) * 0.1531;
  sum += texture2D(tDiffuse, vec2(vUv.x,                           vUv.y)) * 0.1633;
  sum += texture2D(tDiffuse, vec2(vUv.x + 1.0 * h, vUv.y)) * 0.1531;
  sum += texture2D(tDiffuse, vec2(vUv.x + 2.0 * h, vUv.y)) * 0.12245;
  sum += texture2D(tDiffuse, vec2(vUv.x + 3.0 * h, vUv.y)) * 0.0918;
  sum += texture2D(tDiffuse, vec2(vUv.x + 4.0 * h, vUv.y)) * 0.051;
  gl_FragColor = sum;
  }
"""};

final Map verticalBlur = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "v": new Uniform.float(1 / 512)},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform sampler2D tDiffuse;
  uniform float v;
  varying vec2 vUv;
  void main() {
  vec4 sum = vec4(0.0);
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 4.0 * v)) * 0.051;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 3.0 * v)) * 0.0918;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 2.0 * v)) * 0.12245;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 1.0 * v)) * 0.1531;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y                      )) * 0.1633;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 1.0 * v)) * 0.1531;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 2.0 * v)) * 0.12245;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 3.0 * v)) * 0.0918;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 4.0 * v)) * 0.051;
  gl_FragColor = sum;
  }
"""};

final Map horizontalTiltShift = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "h": new Uniform.float(1 / 512),
             "r": new Uniform.float(0.35)},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform sampler2D tDiffuse;
  uniform float h;
  uniform float r;
  varying vec2 vUv;
  void main() {
  vec4 sum = vec4(0.0);
  float hh = h * abs(r - vUv.y);
  sum += texture2D(tDiffuse, vec2(vUv.x - 4.0 * hh, vUv.y)) * 0.051;
  sum += texture2D(tDiffuse, vec2(vUv.x - 3.0 * hh, vUv.y)) * 0.0918;
  sum += texture2D(tDiffuse, vec2(vUv.x - 2.0 * hh, vUv.y)) * 0.12245;
  sum += texture2D(tDiffuse, vec2(vUv.x - 1.0 * hh, vUv.y)) * 0.1531;
  sum += texture2D(tDiffuse, vec2(vUv.x,                            vUv.y)) * 0.1633;
  sum += texture2D(tDiffuse, vec2(vUv.x + 1.0 * hh, vUv.y)) * 0.1531;
  sum += texture2D(tDiffuse, vec2(vUv.x + 2.0 * hh, vUv.y)) * 0.12245;
  sum += texture2D(tDiffuse, vec2(vUv.x + 3.0 * hh, vUv.y)) * 0.0918;
  sum += texture2D(tDiffuse, vec2(vUv.x + 4.0 * hh, vUv.y)) * 0.051;
  gl_FragColor = sum;
  }
"""};

final Map verticalTiltShift = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "v": new Uniform.float(1 / 512),
             "r": new Uniform.float(0.35)},
             
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform sampler2D tDiffuse;
  uniform float v;
  uniform float r;
  varying vec2 vUv;
  void main() {
  vec4 sum = vec4(0.0);
  float vv = v * abs(r - vUv.y);
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 4.0 * vv)) * 0.051;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 3.0 * vv)) * 0.0918;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 2.0 * vv)) * 0.12245;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 1.0 * vv)) * 0.1531;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y                       )) * 0.1633;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 1.0 * vv)) * 0.1531;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 2.0 * vv)) * 0.12245;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 3.0 * vv)) * 0.0918;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 4.0 * vv)) * 0.051;
  gl_FragColor = sum;
  }
"""};

final Map blend = {
'uniforms': {"tDiffuse1": new Uniform.texture(),
             "tDiffuse2": new Uniform.texture(),
             "mixRatio": new Uniform.float(0.5),
             "opacity": new Uniform.float(1.0)},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform float opacity;
  uniform float mixRatio;
  uniform sampler2D tDiffuse1;
  uniform sampler2D tDiffuse2;
  varying vec2 vUv;
  void main() {
  vec4 texel1 = texture2D(tDiffuse1, vUv);
  vec4 texel2 = texture2D(tDiffuse2, vUv);
  gl_FragColor = opacity * mix(texel1, texel2, mixRatio);
  }
"""};

final Map fxaa = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "resolution": new Uniform.vector2(1 / 1024, 1 / 512)},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform sampler2D tDiffuse;
  uniform vec2 resolution;
  varying vec2 vUv;
  #define FXAA_REDUCE_MIN   (1.0/128.0)
  #define FXAA_REDUCE_MUL   (1.0/8.0)
  #define FXAA_SPAN_MAX     8.0
  void main() {
  vec3 rgbNW = texture2D(tDiffuse, (gl_FragCoord.xy + vec2(-1.0, -1.0)) * resolution).xyz;
  vec3 rgbNE = texture2D(tDiffuse, (gl_FragCoord.xy + vec2(1.0, -1.0)) * resolution).xyz;
  vec3 rgbSW = texture2D(tDiffuse, (gl_FragCoord.xy + vec2(-1.0, 1.0)) * resolution).xyz;
  vec3 rgbSE = texture2D(tDiffuse, (gl_FragCoord.xy + vec2(1.0, 1.0)) * resolution).xyz;
  vec4 rgbaM = texture2D(tDiffuse,  gl_FragCoord.xy  * resolution);
  vec3 rgbM  = rgbaM.xyz;
  float opacity  = rgbaM.w;
  vec3 luma = vec3(0.299, 0.587, 0.114);
  float lumaNW = dot(rgbNW, luma);
  float lumaNE = dot(rgbNE, luma);
  float lumaSW = dot(rgbSW, luma);
  float lumaSE = dot(rgbSE, luma);
  float lumaM  = dot(rgbM,  luma);
  float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
  float lumaMax = max(lumaM, max(max(lumaNW, lumaNE) , max(lumaSW, lumaSE)));
  vec2 dir;
  dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
  dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));
  float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
  float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
  dir = min(vec2(FXAA_SPAN_MAX,  FXAA_SPAN_MAX),
  max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
  dir * rcpDirMin)) * resolution;
  vec3 rgbA = 0.5 * (
  texture2D(tDiffuse, gl_FragCoord.xy  * resolution + dir * (1.0 / 3.0 - 0.5)).xyz +
  texture2D(tDiffuse, gl_FragCoord.xy  * resolution + dir * (2.0 / 3.0 - 0.5)).xyz);
  vec3 rgbB = rgbA * 0.5 + 0.25 * (
  texture2D(tDiffuse, gl_FragCoord.xy  * resolution + dir * -0.5).xyz +
  texture2D(tDiffuse, gl_FragCoord.xy  * resolution + dir * 0.5).xyz);
  float lumaB = dot(rgbB, luma);
  if ((lumaB < lumaMin) || (lumaB > lumaMax)) {
  gl_FragColor = vec4(rgbA, opacity);
  } else {
  gl_FragColor = vec4(rgbB, opacity);
  }
  }
"""};

final Map luminosity = {
'uniforms': {"tDiffuse": new Uniform.texture()},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform sampler2D tDiffuse;
  varying vec2 vUv;
  void main() {
  vec4 texel = texture2D(tDiffuse, vUv);
  vec3 luma = vec3(0.299, 0.587, 0.114);
  float v = dot(texel.xyz, luma);
  gl_FragColor = vec4(v, v, v, texel.w);
  }
"""};

final Map colorCorrection = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "powRGB": new Uniform.vector3(2.0, 2.0, 2.0),
             "mulRGB": new Uniform.vector3(1.0, 1.0, 1.0)},

'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform sampler2D tDiffuse;
  uniform vec3 powRGB;
  uniform vec3 mulRGB;
  varying vec2 vUv;
  void main() {
  gl_FragColor = texture2D(tDiffuse, vUv);
  gl_FragColor.rgb = mulRGB * pow(gl_FragColor.rgb, powRGB);
  }
"""};

final Map normalmap = {
'uniforms': {"heightMap": new Uniform.texture(),
             "resolution": new Uniform.vector2(512.0, 512.0),
             "scale": new Uniform.vector2(1.0, 1.0),
             "height": new Uniform.float(0.05)},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform float height;
  uniform vec2 resolution;
  uniform sampler2D heightMap;
  varying vec2 vUv;
  void main() {
  float val = texture2D(heightMap, vUv).x;
  float valU = texture2D(heightMap, vUv + vec2(1.0 / resolution.x, 0.0)).x;
  float valV = texture2D(heightMap, vUv + vec2(0.0, 1.0 / resolution.y)).x;
  gl_FragColor = vec4((0.5 * normalize(vec3(val - valU, val - valV, height)) + 0.5), 1.0);
  }
"""};

final Map ssao = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "tDepth": new Uniform.texture(),
             "size": new Uniform.vector2(512.0, 512.0),
             "cameraNear":   new Uniform.float(1.0),
             "cameraFar":    new Uniform.float(100.0),
             "fogNear":      new Uniform.float(5.0),
             "fogFar":       new Uniform.float(100.0),
             "fogEnabled":   new Uniform.int(1),
             "onlyAO":       new Uniform.int(1),
             "aoClamp":      new Uniform.float(0.3),
             "lumInfluence": new Uniform.float(0.9)},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform float cameraNear;
  uniform float cameraFar;
  uniform float fogNear;
  uniform float fogFar;
  uniform bool fogEnabled;
  uniform bool onlyAO;
  uniform vec2 size;
  uniform float aoClamp;
  uniform float lumInfluence;
  uniform sampler2D tDiffuse;
  uniform sampler2D tDepth;
  varying vec2 vUv;
  #define DL 2.399963229728653
  #define EULER 2.718281828459045
  float width = size.x;
  float height = size.y;
  float cameraFarPlusNear = cameraFar + cameraNear;
  float cameraFarMinusNear = cameraFar - cameraNear;
  float cameraCoef = 2.0 * cameraNear;
  const int samples = 8;
  const float radius = 5.0;
  const bool useNoise = false;
  const float noiseAmount = 0.0003;
  const float diffArea = 0.4;
  const float gDisplace = 0.4;
  const vec3 onlyAOColor = vec3(1.0, 0.7, 0.5);
  float unpackDepth(const in vec4 rgba_depth) {
  const vec4 bit_shift = vec4(1.0 / (256.0 * 256.0 * 256.0), 1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0);
  float depth = dot(rgba_depth, bit_shift);
  return depth;
  }
  vec2 rand(const vec2 coord) {
  vec2 noise;
  if (useNoise) {
  float nx = dot (coord, vec2(12.9898, 78.233));
  float ny = dot (coord, vec2(12.9898, 78.233) * 2.0);
  noise = clamp(fract (43758.5453 * sin(vec2(nx, ny))), 0.0, 1.0);
  } else {
  float ff = fract(1.0 - coord.s * (width / 2.0));
  float gg = fract(coord.t * (height / 2.0));
  noise = vec2(0.25, 0.75) * vec2(ff) + vec2(0.75, 0.25) * gg;
  }
  return (noise * 2.0  - 1.0) * noiseAmount;
  }
  float doFog() {
  float zdepth = unpackDepth(texture2D(tDepth, vUv));
  float depth = -cameraFar * cameraNear / (zdepth * cameraFarMinusNear - cameraFar);
  return smoothstep(fogNear, fogFar, depth);
  }
  float readDepth(const in vec2 coord) {
  return cameraCoef / (cameraFarPlusNear - unpackDepth(texture2D(tDepth, coord)) * cameraFarMinusNear);
  }
  float compareDepths(const in float depth1, const in float depth2, inout int far) {
  float garea = 2.0;
  float diff = (depth1 - depth2) * 100.0;
  if (diff < gDisplace) {
  garea = diffArea;
  } else {
  far = 1;
  }
  float dd = diff - gDisplace;
  float gauss = pow(EULER, -2.0 * dd * dd / (garea * garea));
  return gauss;
  }
  float calcAO(float depth, float dw, float dh) {
  float dd = radius - depth * radius;
  vec2 vv = vec2(dw, dh);
  vec2 coord1 = vUv + dd * vv;
  vec2 coord2 = vUv - dd * vv;
  float temp1 = 0.0;
  float temp2 = 0.0;
  int far = 0;
  temp1 = compareDepths(depth, readDepth(coord1), far);
  if (far > 0) {
  temp2 = compareDepths(readDepth(coord2), depth, far);
  temp1 += (1.0 - temp1) * temp2;
  }
  return temp1;
  }
  void main() {
  vec2 noise = rand(vUv);
  float depth = readDepth(vUv);
  float tt = clamp(depth, aoClamp, 1.0);
  float w = (1.0 / width)  / tt + (noise.x * (1.0 - noise.x));
  float h = (1.0 / height) / tt + (noise.y * (1.0 - noise.y));
  float pw;
  float ph;
  float ao;
  float dz = 1.0 / float(samples);
  float z = 1.0 - dz / 2.0;
  float l = 0.0;
  for (int i = 0; i <= samples; i ++) {
  float r = sqrt(1.0 - z);
  pw = cos(l) * r;
  ph = sin(l) * r;
  ao += calcAO(depth, pw * w, ph * h);
  z = z - dz;
  l = l + DL;
  }
  ao /= float(samples);
  ao = 1.0 - ao;
  if (fogEnabled) {
  ao = mix(ao, 1.0, doFog());
  }
  vec3 color = texture2D(tDiffuse, vUv).rgb;
  vec3 lumcoeff = vec3(0.299, 0.587, 0.114);
  float lum = dot(color.rgb, lumcoeff);
  vec3 luminance = vec3(lum);
  vec3 final = vec3(color * mix(vec3(ao), vec3(1.0), luminance * lumInfluence));
  if (onlyAO) {
  final = onlyAOColor * vec3(mix(vec3(ao), vec3(1.0), luminance * lumInfluence));
  }
  gl_FragColor = vec4(final, 1.0);
  }
"""};

final Map colorify = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "color": new Uniform.color(0xffffff)},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform vec3 color;
  uniform sampler2D tDiffuse;
  varying vec2 vUv;
  void main() {
  vec4 texel = texture2D(tDiffuse, vUv);
  vec3 luma = vec3(0.299, 0.587, 0.114);
  float v = dot(texel.xyz, luma);
  gl_FragColor = vec4(v * color, texel.w);
  }
"""};

final Map unpackDepthRGBA = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "opacity": new Uniform.float(1.0)},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform float opacity;
  uniform sampler2D tDiffuse;
  varying vec2 vUv;
  float unpackDepth(const in vec4 rgba_depth) {
  const vec4 bit_shift = vec4(1.0 / (256.0 * 256.0 * 256.0), 1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0);
  float depth = dot(rgba_depth, bit_shift);
  return depth;
  }
  void main() {
  float depth = 1.0 - unpackDepth(texture2D(tDiffuse, vUv));
  gl_FragColor = opacity * vec4(vec3(depth), 1.0);
  }
"""};

final Map kaleido = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "sides": new Uniform.float(6.0),
             "angle": new Uniform.float(0.0)},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform sampler2D tDiffuse;
  uniform float sides;
  uniform float angle;
  varying vec2 vUv;
  void main() {
  vec2 p = vUv - 0.5;
  float r = length(p);
  float a = atan(p.y, p.x) + angle;
  float tau = 2. * 3.1416 ;
  a = mod(a, tau/sides);
  a = abs(a - tau/sides/2.) ;
  p = r * vec2(cos(a), sin(a));
  vec4 color = texture2D(tDiffuse, p + 0.5);
  gl_FragColor = color;
  }
"""};

final Map mirror = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "side": new Uniform.int(1)},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform sampler2D tDiffuse;
  uniform int side;
  varying vec2 vUv;
  void main() {
  vec2 p = vUv;
  if (side == 0){
  if (p.x > 0.5) p.x = 1.0 - p.x;
  }else if (side == 1){
  if (p.x < 0.5) p.x = 1.0 - p.x;
  }else if (side == 2){
  if (p.y < 0.5) p.y = 1.0 - p.y;
  }else if (side == 3){
  if (p.y > 0.5) p.y = 1.0 - p.y;
  } 
  vec4 color = texture2D(tDiffuse, p);
  gl_FragColor = color;
  }
"""};

final Map rgbShift = {
'uniforms': {"tDiffuse": new Uniform.texture(),
             "amount": new Uniform.float(0.005),
             "angle": new Uniform.float(1.0)},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  uniform sampler2D tDiffuse;
  uniform float amount;
  uniform float angle;
  varying vec2 vUv;
  void main() {
  vec2 offset = amount * vec2(cos(angle), sin(angle));
  vec4 cr = texture2D(tDiffuse, vUv + offset);
  vec4 cga = texture2D(tDiffuse, vUv);
  vec4 cb = texture2D(tDiffuse, vUv - offset);
  gl_FragColor = vec4(cr.r, cga.g, cb.b, cga.a);
  }
"""};

final Map godraysGenerate = {
'uniforms': {"tInput": new Uniform.texture(),
             "fStepSize": new Uniform.float(1.0),
             "vSunPositionScreenSpace": new Uniform.vector2(0.5, 0.5)},
  
'vertexShader':  """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader':  """
  #define TAPS_PER_PASS 6.0
  varying vec2 vUv;
  uniform sampler2D tInput;
  uniform vec2 vSunPositionScreenSpace;
  uniform float fStepSize;
  void main() {
  vec2 delta = vSunPositionScreenSpace - vUv;
  float dist = length(delta);
  vec2 stepv = fStepSize * delta / dist;
  float iters = dist/fStepSize;
  vec2 uv = vUv.xy;
  float col = 0.0;
  if (0.0 <= iters && uv.y < 1.0) col += texture2D(tInput, uv).r;
  uv += stepv;
  if (1.0 <= iters && uv.y < 1.0) col += texture2D(tInput, uv).r;
  uv += stepv;
  if (2.0 <= iters && uv.y < 1.0) col += texture2D(tInput, uv).r;
  uv += stepv;
  if (3.0 <= iters && uv.y < 1.0) col += texture2D(tInput, uv).r;
  uv += stepv;
  if (4.0 <= iters && uv.y < 1.0) col += texture2D(tInput, uv).r;
  uv += stepv;
  if (5.0 <= iters && uv.y < 1.0) col += texture2D(tInput, uv).r;
  uv += stepv;
  gl_FragColor = vec4(col/TAPS_PER_PASS);
  gl_FragColor.a = 1.0;
  }
"""};

final Map godraysCombine = {
'uniforms': {"tColors": new Uniform.texture(),
             "tGodRays": new Uniform.texture(),
             "fGodRayIntensity": new Uniform.float(0.69),
             "vSunPositionScreenSpace": new Uniform.vector2(0.5, 0.5)},
  
'vertexShader':  """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader':  """
  varying vec2 vUv;
  uniform sampler2D tColors;
  uniform sampler2D tGodRays;
  uniform vec2 vSunPositionScreenSpace;
  uniform float fGodRayIntensity;
  void main() {
  gl_FragColor = texture2D(tColors, vUv) + fGodRayIntensity * vec4(1.0 - texture2D(tGodRays, vUv).r);
  gl_FragColor.a = 1.0;
  }
"""};

final Map godraysFakeSun = {
'uniforms': {"vSunPositionScreenSpace": new Uniform.vector2(0.5, 0.5),
             "fAspect": new Uniform.float(1.0),
             "sunColor": new Uniform.color(0xffee00),
             "bgColor": new Uniform.color(0x000000)},
  
'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  varying vec2 vUv;
  uniform vec2 vSunPositionScreenSpace;
  uniform float fAspect;
  uniform vec3 sunColor;
  uniform vec3 bgColor;
  void main() {
  vec2 diff = vUv - vSunPositionScreenSpace;
  diff.x *= fAspect;
  float prop = clamp(length(diff) / 0.5, 0.0, 1.0);
  prop = 0.35 * pow(1.0 - prop, 3.0);
  gl_FragColor.xyz = mix(sunColor, bgColor, 1.0 - prop);
  gl_FragColor.w = 1.0;
  }
"""};

final Map deferredColor = {
'uniforms': UniformsUtils.merge([UniformsLib["common"],
                                 UniformsLib["fog"],
                                 UniformsLib["shadowmap"],
                                {"emissive" : new Uniform.color(0x000000),
                                 "specular" : new Uniform.color(0x111111),
                                 "shininess": new Uniform.float(30.0),
                                 "wrapAround": new Uniform.float(1.0),
                                 "additiveSpecular": new Uniform.float(1.0),
                                 
                                 "samplerNormalDepth": new Uniform.texture(),
                                 "viewWidth": new Uniform.float(800.0),
                                 "viewHeight": new Uniform.float(600.0)}]),
'fragmentShader': """
  uniform vec3 diffuse;
  uniform vec3 specular;
  uniform vec3 emissive;
  uniform float shininess;
  uniform float wrapAround;
  uniform float additiveSpecular;
  #ifdef USE_COLOR
  varying vec3 vColor;
  #endif
  #if defined(USE_MAP) || defined(USE_BUMPMAP) || defined(USE_NORMALMAP) || defined(USE_SPECULARMAP)
  varying vec2 vUv;
  #endif
  #ifdef USE_MAP
  uniform sampler2D map;
  #endif
  #ifdef USE_LIGHTMAP
  varying vec2 vUv2;
  uniform sampler2D lightMap;
  #endif
  #ifdef USE_ENVMAP
  varying vec3 vWorldPosition;
  uniform float reflectivity;
  uniform samplerCube envMap;
  uniform float flipEnvMap;
  uniform int combine;
  uniform bool useRefract;
  uniform float refractionRatio;
  uniform sampler2D samplerNormalDepth;
  uniform float viewHeight;
  uniform float viewWidth;
  #endif
  #ifdef USE_FOG
  uniform vec3 fogColor;
  #ifdef FOG_EXP2
  uniform float fogDensity;
  #else
  uniform float fogNear;
  uniform float fogFar;
  #endif
  #endif
  #ifdef USE_SHADOWMAP
  uniform sampler2D shadowMap[MAX_SHADOWS];
  uniform vec2 shadowMapSize[MAX_SHADOWS];
  uniform float shadowDarkness[MAX_SHADOWS];
  uniform float shadowBias[MAX_SHADOWS];
  varying vec4 vShadowCoord[MAX_SHADOWS];
  float unpackDepth(const in vec4 rgba_depth) {
  const vec4 bit_shift = vec4(1.0 / (256.0 * 256.0 * 256.0), 1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0);
  float depth = dot(rgba_depth, bit_shift);
  return depth;
  }
  #endif
  #ifdef USE_SPECULARMAP
  uniform sampler2D specularMap;
  #endif
  const float unit = 255.0/256.0;
  float vec3_to_float(vec3 data) {
  highp float compressed = fract(data.x * unit) + floor(data.y * unit * 255.0) + floor(data.z * unit * 255.0) * 255.0;
  return compressed;
  }
  void main() {
  const float opacity = 1.0;
  gl_FragColor = vec4(diffuse, opacity);
  #ifdef USE_MAP
  vec4 texelColor = texture2D(map, vUv);
  #ifdef GAMMA_INPUT
  texelColor.xyz *= texelColor.xyz;
  #endif
  gl_FragColor = gl_FragColor * texelColor;
  #endif
  #ifdef ALPHATEST
  if (gl_FragColor.a < ALPHATEST) discard;
  #endif
  float specularStrength;
  #ifdef USE_SPECULARMAP
  vec4 texelSpecular = texture2D(specularMap, vUv);
  specularStrength = texelSpecular.r;
  #else
  specularStrength = 1.0;
  #endif
  #ifdef USE_LIGHTMAP
  gl_FragColor = gl_FragColor * texture2D(lightMap, vUv2);
  #endif
  #ifdef USE_COLOR
  gl_FragColor = gl_FragColor * vec4(vColor, 1.0);
  #endif
  #ifdef USE_ENVMAP
  vec2 texCoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
  vec4 normalDepth = texture2D(samplerNormalDepth, texCoord);
  vec3 normal = normalDepth.xyz * 2.0 - 1.0;
  vec3 reflectVec;
  vec3 cameraToVertex = normalize(vWorldPosition - cameraPosition);
  if (useRefract) {
  reflectVec = refract(cameraToVertex, normal, refractionRatio);
  } else { 
  reflectVec = reflect(cameraToVertex, normal);
  }
  #ifdef DOUBLE_SIDED
  float flipNormal = (-1.0 + 2.0 * float(gl_FrontFacing));
  vec4 cubeColor = textureCube(envMap, flipNormal * vec3(flipEnvMap * reflectVec.x, reflectVec.yz));
  #else
  vec4 cubeColor = textureCube(envMap, vec3(flipEnvMap * reflectVec.x, reflectVec.yz));
  #endif
  #ifdef GAMMA_INPUT
  cubeColor.xyz *= cubeColor.xyz;
  #endif
  if (combine == 1) {
  gl_FragColor.xyz = mix(gl_FragColor.xyz, cubeColor.xyz, specularStrength * reflectivity);
  } else if (combine == 2) {
  gl_FragColor.xyz += cubeColor.xyz * specularStrength * reflectivity;
  } else {
  gl_FragColor.xyz = mix(gl_FragColor.xyz, gl_FragColor.xyz * cubeColor.xyz, specularStrength * reflectivity);
  }
  #endif
  #ifdef USE_SHADOWMAP
  #ifdef SHADOWMAP_DEBUG
  vec3 frustumColors[3];
  frustumColors[0] = vec3(1.0, 0.5, 0.0);
  frustumColors[1] = vec3(0.0, 1.0, 0.8);
  frustumColors[2] = vec3(0.0, 0.5, 1.0);
  #endif
  #ifdef SHADOWMAP_CASCADE
  int inFrustumCount = 0;
  #endif
  float fDepth;
  vec3 shadowColor = vec3(1.0);
  for(int i = 0; i < MAX_SHADOWS; i ++) {
  vec3 shadowCoord = vShadowCoord[i].xyz / vShadowCoord[i].w;
  bvec4 inFrustumVec = bvec4 (shadowCoord.x >= 0.0, shadowCoord.x <= 1.0, shadowCoord.y >= 0.0, shadowCoord.y <= 1.0);
  bool inFrustum = all(inFrustumVec);
  #ifdef SHADOWMAP_CASCADE
  inFrustumCount += int(inFrustum);
  bvec3 frustumTestVec = bvec3(inFrustum, inFrustumCount == 1, shadowCoord.z <= 1.0);
  #else
  bvec2 frustumTestVec = bvec2(inFrustum, shadowCoord.z <= 1.0);
  #endif
  bool frustumTest = all(frustumTestVec);
  if (frustumTest) {
  shadowCoord.z += shadowBias[i];
  #if defined(SHADOWMAP_TYPE_PCF)
  float shadow = 0.0;
  const float shadowDelta = 1.0 / 9.0;
  float xPixelOffset = 1.0 / shadowMapSize[i].x;
  float yPixelOffset = 1.0 / shadowMapSize[i].y;
  float dx0 = -1.25 * xPixelOffset;
  float dy0 = -1.25 * yPixelOffset;
  float dx1 = 1.25 * xPixelOffset;
  float dy1 = 1.25 * yPixelOffset;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, dy0)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(0.0, dy0)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, dy0)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, 0.0)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, 0.0)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, dy1)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(0.0, dy1)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, dy1)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  shadowColor = shadowColor * vec3((1.0 - shadowDarkness[i] * shadow));
  #elif defined(SHADOWMAP_TYPE_PCF_SOFT)
  float shadow = 0.0;
  float xPixelOffset = 1.0 / shadowMapSize[i].x;
  float yPixelOffset = 1.0 / shadowMapSize[i].y;
  float dx0 = -1.0 * xPixelOffset;
  float dy0 = -1.0 * yPixelOffset;
  float dx1 = 1.0 * xPixelOffset;
  float dy1 = 1.0 * yPixelOffset;
  mat3 shadowKernel;
  mat3 depthKernel;
  depthKernel[0][0] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, dy0)));
  depthKernel[0][1] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, 0.0)));
  depthKernel[0][2] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, dy1)));
  depthKernel[1][0] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(0.0, dy0)));
  depthKernel[1][1] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy));
  depthKernel[1][2] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(0.0, dy1)));
  depthKernel[2][0] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, dy0)));
  depthKernel[2][1] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, 0.0)));
  depthKernel[2][2] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, dy1)));
  vec3 shadowZ = vec3(shadowCoord.z);
  shadowKernel[0] = vec3(lessThan(depthKernel[0], shadowZ));
  shadowKernel[0] *= vec3(0.25);
  shadowKernel[1] = vec3(lessThan(depthKernel[1], shadowZ));
  shadowKernel[1] *= vec3(0.25);
  shadowKernel[2] = vec3(lessThan(depthKernel[2], shadowZ));
  shadowKernel[2] *= vec3(0.25);
  vec2 fractionalCoord = 1.0 - fract(shadowCoord.xy * shadowMapSize[i].xy);
  shadowKernel[0] = mix(shadowKernel[1], shadowKernel[0], fractionalCoord.x);
  shadowKernel[1] = mix(shadowKernel[2], shadowKernel[1], fractionalCoord.x);
  vec4 shadowValues;
  shadowValues.x = mix(shadowKernel[0][1], shadowKernel[0][0], fractionalCoord.y);
  shadowValues.y = mix(shadowKernel[0][2], shadowKernel[0][1], fractionalCoord.y);
  shadowValues.z = mix(shadowKernel[1][1], shadowKernel[1][0], fractionalCoord.y);
  shadowValues.w = mix(shadowKernel[1][2], shadowKernel[1][1], fractionalCoord.y);
  shadow = dot(shadowValues, vec4(1.0));
  shadowColor = shadowColor * vec3((1.0 - shadowDarkness[i] * shadow));
  #else
  vec4 rgbaDepth = texture2D(shadowMap[i], shadowCoord.xy);
  float fDepth = unpackDepth(rgbaDepth);
  if (fDepth < shadowCoord.z)
  shadowColor = shadowColor * vec3(1.0 - shadowDarkness[i]);
  #endif
  }
  #ifdef SHADOWMAP_DEBUG
  #ifdef SHADOWMAP_CASCADE
  if (inFrustum && inFrustumCount == 1) gl_FragColor.xyz *= frustumColors[i];
  #else
  if (inFrustum) gl_FragColor.xyz *= frustumColors[i];
  #endif
  #endif
  }
  #ifdef GAMMA_OUTPUT
  shadowColor *= shadowColor;
  #endif
  gl_FragColor.xyz = gl_FragColor.xyz * shadowColor;
  #endif
  #ifdef USE_FOG
  float depth = gl_FragCoord.z / gl_FragCoord.w;
  #ifdef FOG_EXP2
  const float LOG2 = 1.442695;
  float fogFactor = exp2(- fogDensity * fogDensity * depth * depth * LOG2);
  fogFactor = 1.0 - clamp(fogFactor, 0.0, 1.0);
  #else
  float fogFactor = smoothstep(fogNear, fogFar, depth);
  #endif
  gl_FragColor = mix(gl_FragColor, vec4(fogColor, gl_FragColor.w), fogFactor);
  #endif
  const float compressionScale = 0.999;
  vec3 diffuseMapColor;
  #ifdef USE_MAP
  diffuseMapColor = texelColor.xyz;
  #else
  diffuseMapColor = vec3(1.0);
  #endif
  gl_FragColor.x = vec3_to_float(compressionScale * gl_FragColor.xyz);
  if (additiveSpecular < 0.0) {
  gl_FragColor.y = vec3_to_float(compressionScale * specular);
  } else {
  gl_FragColor.y = vec3_to_float(compressionScale * specular * diffuseMapColor);
  }
  gl_FragColor.y *= additiveSpecular;
  gl_FragColor.z = wrapAround * shininess;
  #ifdef USE_COLOR
  gl_FragColor.w = vec3_to_float(compressionScale * emissive * diffuseMapColor * vColor);
  #else
  gl_FragColor.w = vec3_to_float(compressionScale * emissive * diffuseMapColor);
  #endif
  }
""",

'vertexShader': """
  #if defined(USE_MAP) || defined(USE_BUMPMAP) || defined(USE_NORMALMAP) || defined(USE_SPECULARMAP)
  varying vec2 vUv;
  uniform vec4 offsetRepeat;
  #endif
  #ifdef USE_LIGHTMAP
  varying vec2 vUv2;
  #endif
  #ifdef USE_COLOR
  varying vec3 vColor;
  #endif
  #ifdef USE_MORPHTARGETS
  #ifndef USE_MORPHNORMALS
  uniform float morphTargetInfluences[8];
  #else
  uniform float morphTargetInfluences[4];
  #endif
  #endif
  #ifdef USE_SKINNING
  #ifdef BONE_TEXTURE
  uniform sampler2D boneTexture;
  uniform int boneTextureWidth;
  uniform int boneTextureHeight;
  mat4 getBoneMatrix(const in float i) {
  float j = i * 4.0;
  float x = mod(j, float(boneTextureWidth));
  float y = floor(j / float(boneTextureWidth));
  float dx = 1.0 / float(boneTextureWidth);
  float dy = 1.0 / float(boneTextureHeight);
  y = dy * (y + 0.5);
  vec4 v1 = texture2D(boneTexture, vec2(dx * (x + 0.5), y));
  vec4 v2 = texture2D(boneTexture, vec2(dx * (x + 1.5), y));
  vec4 v3 = texture2D(boneTexture, vec2(dx * (x + 2.5), y));
  vec4 v4 = texture2D(boneTexture, vec2(dx * (x + 3.5), y));
  mat4 bone = mat4(v1, v2, v3, v4);
  return bone;
  }
  #else
  uniform mat4 boneGlobalMatrices[MAX_BONES];
  mat4 getBoneMatrix(const in float i) {
  mat4 bone = boneGlobalMatrices[int(i)];
  return bone;
  }
  #endif
  #endif
  #ifdef USE_SHADOWMAP
  varying vec4 vShadowCoord[MAX_SHADOWS];
  uniform mat4 shadowMatrix[MAX_SHADOWS];
  #endif
  #ifdef USE_ENVMAP
  varying vec3 vWorldPosition;
  #endif
  void main() {
  #if defined(USE_MAP) || defined(USE_BUMPMAP) || defined(USE_NORMALMAP) || defined(USE_SPECULARMAP)
  vUv = uv * offsetRepeat.zw + offsetRepeat.xy;
  #endif
  #ifdef USE_LIGHTMAP
  vUv2 = uv2;
  #endif
  #ifdef USE_COLOR
  #ifdef GAMMA_INPUT
  vColor = color * color;
  #else
  vColor = color;
  #endif
  #endif
  #ifdef USE_SKINNING
  mat4 boneMatX = getBoneMatrix(skinIndex.x);
  mat4 boneMatY = getBoneMatrix(skinIndex.y);
  #endif
  #ifdef USE_MORPHTARGETS
  vec3 morphed = vec3(0.0);
  morphed += (morphTarget0 - position) * morphTargetInfluences[0];
  morphed += (morphTarget1 - position) * morphTargetInfluences[1];
  morphed += (morphTarget2 - position) * morphTargetInfluences[2];
  morphed += (morphTarget3 - position) * morphTargetInfluences[3];
  #ifndef USE_MORPHNORMALS
  morphed += (morphTarget4 - position) * morphTargetInfluences[4];
  morphed += (morphTarget5 - position) * morphTargetInfluences[5];
  morphed += (morphTarget6 - position) * morphTargetInfluences[6];
  morphed += (morphTarget7 - position) * morphTargetInfluences[7];
  #endif
  morphed += position;
  #endif
  #ifdef USE_SKINNING
  #ifdef USE_MORPHTARGETS
  vec4 skinVertex = vec4(morphed, 1.0);
  #else
  vec4 skinVertex = vec4(position, 1.0);
  #endif
  vec4 skinned  = boneMatX * skinVertex * skinWeight.x;
  skinned           += boneMatY * skinVertex * skinWeight.y;
  #endif
  vec4 mvPosition;
  #ifdef USE_SKINNING
  mvPosition = modelViewMatrix * skinned;
  #endif
  #if !defined(USE_SKINNING) && defined(USE_MORPHTARGETS)
  mvPosition = modelViewMatrix * vec4(morphed, 1.0);
  #endif
  #if !defined(USE_SKINNING) && ! defined(USE_MORPHTARGETS)
  mvPosition = modelViewMatrix * vec4(position, 1.0);
  #endif
  gl_Position = projectionMatrix * mvPosition;
  #if defined(USE_ENVMAP) || defined(PHONG) || defined(LAMBERT) || defined (USE_SHADOWMAP)
  #ifdef USE_SKINNING
  vec4 worldPosition = modelMatrix * skinned;
  #endif
  #if defined(USE_MORPHTARGETS) && ! defined(USE_SKINNING)
  vec4 worldPosition = modelMatrix * vec4(morphed, 1.0);
  #endif
  #if ! defined(USE_MORPHTARGETS) && ! defined(USE_SKINNING)
  vec4 worldPosition = modelMatrix * vec4(position, 1.0);
  #endif
  #endif
  #ifdef USE_SHADOWMAP
  for(int i = 0; i < MAX_SHADOWS; i ++) {
  vShadowCoord[i] = shadowMatrix[i] * worldPosition;
  }
  #endif
  #ifdef USE_ENVMAP
  vWorldPosition = worldPosition.xyz;
  #endif
  }
"""};

final Map deferredNormalDepth = {
'uniforms': {"bumpMap": new Uniform.texture(),
             "bumpScale": new Uniform.float(1.0),
             "offsetRepeat": new Uniform.vector4(0.0, 0.0, 1.0, 1.0)},
             
'fragmentShader': """
  #ifdef USE_BUMPMAP
  #extension GL_OES_standard_derivatives : enable
  
  varying vec2 vUv;
  varying vec3 vViewPosition;
  #ifdef USE_BUMPMAP
  uniform sampler2D bumpMap;
  uniform float bumpScale;
  vec2 dHdxy_fwd() {
  vec2 dSTdx = dFdx(vUv);
  vec2 dSTdy = dFdy(vUv);
  float Hll = bumpScale * texture2D(bumpMap, vUv).x;
  float dBx = bumpScale * texture2D(bumpMap, vUv + dSTdx).x - Hll;
  float dBy = bumpScale * texture2D(bumpMap, vUv + dSTdy).x - Hll;
  return vec2(dBx, dBy);
  }
  vec3 perturbNormalArb(vec3 surf_pos, vec3 surf_norm, vec2 dHdxy) {
  vec3 vSigmaX = dFdx(surf_pos);
  vec3 vSigmaY = dFdy(surf_pos);
  vec3 vN = surf_norm;
  vec3 R1 = cross(vSigmaY, vN);
  vec3 R2 = cross(vN, vSigmaX);
  float fDet = dot(vSigmaX, R1);
  vec3 vGrad = sign(fDet) * (dHdxy.x * R1 + dHdxy.y * R2);
  return normalize(abs(fDet) * surf_norm - vGrad);
  }
  #endif
  #endif
  varying vec3 normalView;
  varying vec4 clipPos;
  void main() {
  vec3 normal = normalize(normalView);
  #ifdef USE_BUMPMAP
  normal = perturbNormalArb(-vViewPosition, normal, dHdxy_fwd());
  #endif
  gl_FragColor.xyz = normal * 0.5 + 0.5;
  gl_FragColor.w = clipPos.z / clipPos.w;
  }
""",

'vertexShader': """
  varying vec3 normalView;
  varying vec4 clipPos;
  #ifdef USE_BUMPMAP
  varying vec2 vUv;
  varying vec3 vViewPosition;
  uniform vec4 offsetRepeat;
  #endif
  #ifdef USE_MORPHTARGETS
  #ifndef USE_MORPHNORMALS
  uniform float morphTargetInfluences[8];
  #else
  uniform float morphTargetInfluences[4];
  #endif
  #endif
  #ifdef USE_SKINNING
  #ifdef BONE_TEXTURE
  uniform sampler2D boneTexture;
  uniform int boneTextureWidth;
  uniform int boneTextureHeight;
  mat4 getBoneMatrix(const in float i) {
  float j = i * 4.0;
  float x = mod(j, float(boneTextureWidth));
  float y = floor(j / float(boneTextureWidth));
  float dx = 1.0 / float(boneTextureWidth);
  float dy = 1.0 / float(boneTextureHeight);
  y = dy * (y + 0.5);
  vec4 v1 = texture2D(boneTexture, vec2(dx * (x + 0.5), y));
  vec4 v2 = texture2D(boneTexture, vec2(dx * (x + 1.5), y));
  vec4 v3 = texture2D(boneTexture, vec2(dx * (x + 2.5), y));
  vec4 v4 = texture2D(boneTexture, vec2(dx * (x + 3.5), y));
  mat4 bone = mat4(v1, v2, v3, v4);
  return bone;
  }
  #else
  uniform mat4 boneGlobalMatrices[MAX_BONES];
  mat4 getBoneMatrix(const in float i) {
  mat4 bone = boneGlobalMatrices[int(i)];
  return bone;
  }
  #endif
  #endif
  void main() {
  #ifdef USE_MORPHNORMALS
  vec3 morphedNormal = vec3(0.0);
  morphedNormal +=  (morphNormal0 - normal) * morphTargetInfluences[0];
  morphedNormal +=  (morphNormal1 - normal) * morphTargetInfluences[1];
  morphedNormal +=  (morphNormal2 - normal) * morphTargetInfluences[2];
  morphedNormal +=  (morphNormal3 - normal) * morphTargetInfluences[3];
  morphedNormal += normal;
  #endif
  #ifdef USE_SKINNING
  mat4 boneMatX = getBoneMatrix(skinIndex.x);
  mat4 boneMatY = getBoneMatrix(skinIndex.y);
  #endif
  #ifdef USE_SKINNING
  mat4 skinMatrix = skinWeight.x * boneMatX;
  skinMatrix         += skinWeight.y * boneMatY;
  #ifdef USE_MORPHNORMALS
  vec4 skinnedNormal = skinMatrix * vec4(morphedNormal, 0.0);
  #else
  vec4 skinnedNormal = skinMatrix * vec4(normal, 0.0);
  #endif
  #endif
  vec3 objectNormal;
  #ifdef USE_SKINNING
  objectNormal = skinnedNormal.xyz;
  #endif
  #if !defined(USE_SKINNING) && defined(USE_MORPHNORMALS)
  objectNormal = morphedNormal;
  #endif
  #if !defined(USE_SKINNING) && ! defined(USE_MORPHNORMALS)
  objectNormal = normal;
  #endif
  #ifdef FLIP_SIDED
  objectNormal = -objectNormal;
  #endif
  vec3 transformedNormal = normalMatrix * objectNormal;
  #ifdef USE_MORPHTARGETS
  vec3 morphed = vec3(0.0);
  morphed += (morphTarget0 - position) * morphTargetInfluences[0];
  morphed += (morphTarget1 - position) * morphTargetInfluences[1];
  morphed += (morphTarget2 - position) * morphTargetInfluences[2];
  morphed += (morphTarget3 - position) * morphTargetInfluences[3];
  #ifndef USE_MORPHNORMALS
  morphed += (morphTarget4 - position) * morphTargetInfluences[4];
  morphed += (morphTarget5 - position) * morphTargetInfluences[5];
  morphed += (morphTarget6 - position) * morphTargetInfluences[6];
  morphed += (morphTarget7 - position) * morphTargetInfluences[7];
  #endif
  morphed += position;
  #endif
  #ifdef USE_SKINNING
  #ifdef USE_MORPHTARGETS
  vec4 skinVertex = vec4(morphed, 1.0);
  #else
  vec4 skinVertex = vec4(position, 1.0);
  #endif
  vec4 skinned  = boneMatX * skinVertex * skinWeight.x;
  skinned           += boneMatY * skinVertex * skinWeight.y;
  #endif
  vec4 mvPosition;
  #ifdef USE_SKINNING
  mvPosition = modelViewMatrix * skinned;
  #endif
  #if !defined(USE_SKINNING) && defined(USE_MORPHTARGETS)
  mvPosition = modelViewMatrix * vec4(morphed, 1.0);
  #endif
  #if !defined(USE_SKINNING) && ! defined(USE_MORPHTARGETS)
  mvPosition = modelViewMatrix * vec4(position, 1.0);
  #endif
  gl_Position = projectionMatrix * mvPosition;
  normalView = normalize(normalMatrix * objectNormal);
  #ifdef USE_BUMPMAP
  vUv = uv * offsetRepeat.zw + offsetRepeat.xy;
  vViewPosition = -mvPosition.xyz;
  #endif
  clipPos = gl_Position;
  }
"""};

final Map deferredComposite = {
'uniforms': {"samplerLight": new Uniform.texture(),
             "brightness": new Uniform.float(1.0)},
  
'fragmentShader': """
  varying vec2 texCoord;
  uniform sampler2D samplerLight;
  uniform float brightness;
  #ifdef TONEMAP_UNCHARTED
  const float A = 0.15;
  const float B = 0.50;
  const float C = 0.10;
  const float D = 0.20;
  const float E = 0.02;
  const float F = 0.30;
  const float W = 11.2;
  vec3 Uncharted2Tonemap(vec3 x) {
  return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
  }
  #endif
  void main() {
  vec3 inColor = texture2D(samplerLight, texCoord).xyz;
  inColor *= brightness;
  vec3 outColor;
  #if defined(TONEMAP_SIMPLE)
  outColor = sqrt(inColor);
  #elif defined(TONEMAP_LINEAR)
  outColor = pow(inColor, vec3(1.0 / 2.2));
  #elif defined(TONEMAP_REINHARD)
  inColor = inColor / (1.0 + inColor);
  outColor = pow(inColor, vec3(1.0 / 2.2));
  #elif defined(TONEMAP_FILMIC)
  vec3 x = max(vec3(0.0), inColor - 0.004);
  outColor = (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
  #elif defined(TONEMAP_UNCHARTED)
  float ExposureBias = 2.0;
  vec3 curr = Uncharted2Tonemap(ExposureBias * inColor);
  vec3 whiteScale = vec3(1.0) / Uncharted2Tonemap(vec3(W));
  vec3 color = curr * whiteScale;
  outColor = pow(color, vec3(1.0 / 2.2));
  #else
  outColor = inColor;
  #endif
  gl_FragColor = vec4(outColor, 1.0);
  }
""",

'vertexShader': """
  varying vec2 texCoord;
  void main() {
  vec4 pos = vec4(sign(position.xy), 0.0, 1.0);
  texCoord = pos.xy * vec2(0.5) + 0.5;
  gl_Position = pos;
  }
"""};

final Map deferredPointLight = {
'uniforms': {"samplerNormalDepth": new Uniform.texture(),
             "samplerColor": new Uniform.texture(),
             "matProjInverse": new Uniform.matrix4(new Matrix4.identity()),
             "viewWidth": new Uniform.float(800.0),
             "viewHeight": new Uniform.float(600.0),
             
             "lightPositionVS": new Uniform.vector3(0.0, 0.0, 0.0),
             "lightColor": new Uniform.color(0x000000),
             "lightIntensity": new Uniform.float(1.0),
             "lightRadius": new Uniform.float(1.0)},
  
'fragmentShader': """
  uniform sampler2D samplerColor;
  uniform sampler2D samplerNormalDepth;
  uniform float lightRadius;
  uniform float lightIntensity;
  uniform float viewHeight;
  uniform float viewWidth;
  uniform vec3 lightColor;
  uniform vec3 lightPositionVS;
  uniform mat4 matProjInverse;
  vec3 float_to_vec3(float data) {
  vec3 uncompressed;
  uncompressed.x = fract(data);
  float zInt = floor(data / 255.0);
  uncompressed.z = fract(zInt / 255.0);
  uncompressed.y = fract(floor(data - (zInt * 255.0)) / 255.0);
  return uncompressed;
  }
  void main() {
  vec2 texCoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
  vec4 normalDepth = texture2D(samplerNormalDepth, texCoord);
  float z = normalDepth.w;
  if (z == 0.0) discard;
  vec2 xy = texCoord * 2.0 - 1.0;
  vec4 vertexPositionProjected = vec4(xy, z, 1.0);
  vec4 vertexPositionVS = matProjInverse * vertexPositionProjected;
  vertexPositionVS.xyz /= vertexPositionVS.w;
  vertexPositionVS.w = 1.0;
  vec3 lightVector = lightPositionVS - vertexPositionVS.xyz;
  float distance = length(lightVector);
  if (distance > lightRadius) discard;
  vec3 normal = normalDepth.xyz * 2.0 - 1.0;
  vec4 colorMap = texture2D(samplerColor, texCoord);
  vec3 albedo = float_to_vec3(abs(colorMap.x));
  vec3 specularColor = float_to_vec3(abs(colorMap.y));
  float shininess = abs(colorMap.z);
  float wrapAround = sign(colorMap.z);
  float additiveSpecular = sign(colorMap.y);
  lightVector = normalize(lightVector);
  float dotProduct = dot(normal, lightVector);
  float diffuseFull = max(dotProduct, 0.0);
  vec3 diffuse;
  if (wrapAround < 0.0) {
  float diffuseHalf = max(0.5 * dotProduct + 0.5, 0.0);
  const vec3 wrapRGB = vec3(1.0, 1.0, 1.0);
  diffuse = mix(vec3(diffuseFull), vec3(diffuseHalf), wrapRGB);
  } else {
  diffuse = vec3(diffuseFull);
  }
  vec3 halfVector = normalize(lightVector - normalize(vertexPositionVS.xyz));
  float dotNormalHalf = max(dot(normal, halfVector), 0.0);
  float specularNormalization = (shininess + 2.0001) / 8.0;
  vec3 schlick = specularColor + vec3(1.0 - specularColor) * pow(1.0 - dot(lightVector, halfVector), 5.0);
  vec3 specular = schlick * max(pow(dotNormalHalf, shininess), 0.0) * diffuse * specularNormalization;
  float cutoff = 0.3;
  float denom = distance / lightRadius + 1.0;
  float attenuation = 1.0 / (denom * denom);
  attenuation = (attenuation - cutoff) / (1.0 - cutoff);
  attenuation = max(attenuation, 0.0);
  attenuation *= attenuation;
  vec3 light = lightIntensity * lightColor;
  gl_FragColor = vec4(light * (albedo * diffuse + specular), attenuation);
  }
""",

'vertexShader': """
  void main() { 
  vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
  gl_Position = projectionMatrix * mvPosition;
  }
"""};

final Map deferredSpotLight = {
'uniforms': {"samplerNormalDepth": new Uniform.texture(),
             "samplerColor": new Uniform.texture(),
             "matProjInverse": new Uniform.matrix4(new Matrix4.identity()),
             "viewWidth": new Uniform.float(800.0),
             "viewHeight": new Uniform.float(600.0),
             
             "lightPositionVS": new Uniform.vector3(0.0, 1.0, 0.0),
             "lightDirectionVS": new Uniform.vector3(0.0, 1.0, 0.0),
             "lightColor": new Uniform.color(0x000000),
             "lightIntensity": new Uniform.float(1.0),
             "lightDistance": new Uniform.float(1.0),
             "lightAngle": new Uniform.float(1.0)},
  
'fragmentShader': """
  uniform vec3 lightPositionVS;
  uniform vec3 lightDirectionVS;
  uniform sampler2D samplerColor;
  uniform sampler2D samplerNormalDepth;
  uniform float viewHeight;
  uniform float viewWidth;
  uniform float lightAngle;
  uniform float lightIntensity;
  uniform vec3 lightColor;
  uniform mat4 matProjInverse;
  vec3 float_to_vec3(float data) {
  vec3 uncompressed;
  uncompressed.x = fract(data);
  float zInt = floor(data / 255.0);
  uncompressed.z = fract(zInt / 255.0);
  uncompressed.y = fract(floor(data - (zInt * 255.0)) / 255.0);
  return uncompressed;
  }
  void main() {
  vec2 texCoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
  vec4 normalDepth = texture2D(samplerNormalDepth, texCoord);
  float z = normalDepth.w;
  if (z == 0.0) discard;
  vec2 xy = texCoord * 2.0 - 1.0;
  vec4 vertexPositionProjected = vec4(xy, z, 1.0);
  vec4 vertexPositionVS = matProjInverse * vertexPositionProjected;
  vertexPositionVS.xyz /= vertexPositionVS.w;
  vertexPositionVS.w = 1.0;
  vec3 normal = normalDepth.xyz * 2.0 - 1.0;
  vec4 colorMap = texture2D(samplerColor, texCoord);
  vec3 albedo = float_to_vec3(abs(colorMap.x));
  vec3 specularColor = float_to_vec3(abs(colorMap.y));
  float shininess = abs(colorMap.z);
  float wrapAround = sign(colorMap.z);
  float additiveSpecular = sign(colorMap.y);
  vec3 lightVector = normalize(lightPositionVS.xyz - vertexPositionVS.xyz);
  float rho = dot(lightDirectionVS, lightVector);
  float rhoMax = cos(lightAngle * 0.5);
  if (rho <= rhoMax) discard;
  float theta = rhoMax + 0.0001;
  float phi = rhoMax + 0.05;
  float falloff = 4.0;
  float spot = 0.0;
  if (rho >= phi) {
  spot = 1.0;
  } else if (rho <= theta) {
  spot = 0.0;
  } else { 
  spot = pow((rho - theta) / (phi - theta), falloff);
  }
  float dotProduct = dot(normal, lightVector);
  float diffuseFull = max(dotProduct, 0.0);
  vec3 diffuse;
  if (wrapAround < 0.0) {
  float diffuseHalf = max(0.5 * dotProduct + 0.5, 0.0);
  const vec3 wrapRGB = vec3(1.0, 1.0, 1.0);
  diffuse = mix(vec3(diffuseFull), vec3(diffuseHalf), wrapRGB);
  } else {
  diffuse = vec3(diffuseFull);
  }
  diffuse *= spot;
  vec3 halfVector = normalize(lightVector - normalize(vertexPositionVS.xyz));
  float dotNormalHalf = max(dot(normal, halfVector), 0.0);
  float specularNormalization = (shininess + 2.0001) / 8.0;
  vec3 schlick = specularColor + vec3(1.0 - specularColor) * pow(1.0 - dot(lightVector, halfVector), 5.0);
  vec3 specular = schlick * max(pow(dotNormalHalf, shininess), 0.0) * diffuse * specularNormalization;
  const float attenuation = 1.0;
  vec3 light = lightIntensity * lightColor;
  gl_FragColor = vec4(light * (albedo * diffuse + specular), attenuation);
  }
""",

'vertexShader': """
  void main() { 
  gl_Position = vec4(sign(position.xy), 0.0, 1.0);
  }
"""};

final Map deferredDirectionalLight = {
'uniforms': {"samplerNormalDepth": new Uniform.texture(),
             "samplerColor": new Uniform.texture(),
             "matProjInverse": new Uniform.matrix4(new Matrix4.identity()),
             "viewWidth": new Uniform.float(800.0),
             "viewHeight": new Uniform.float(600.0),
             
             "lightDirectionVS": new Uniform.vector3(0.0, 1.0, 0.0),
             "lightColor": new Uniform.color(0x000000),
             "lightIntensity": new Uniform.float(1.0)},
  
'fragmentShader': """
  uniform sampler2D samplerColor;
  uniform sampler2D samplerNormalDepth;
  uniform float lightRadius;
  uniform float lightIntensity;
  uniform float viewHeight;
  uniform float viewWidth;
  uniform vec3 lightColor;
  uniform vec3 lightDirectionVS;
  uniform mat4 matProjInverse;
  vec3 float_to_vec3(float data) {
  vec3 uncompressed;
  uncompressed.x = fract(data);
  float zInt = floor(data / 255.0);
  uncompressed.z = fract(zInt / 255.0);
  uncompressed.y = fract(floor(data - (zInt * 255.0)) / 255.0);
  return uncompressed;
  }
  void main() {
  vec2 texCoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
  vec4 normalDepth = texture2D(samplerNormalDepth, texCoord);
  float z = normalDepth.w;
  if (z == 0.0) discard;
  vec2 xy = texCoord * 2.0 - 1.0;
  vec4 vertexPositionProjected = vec4(xy, z, 1.0);
  vec4 vertexPositionVS = matProjInverse * vertexPositionProjected;
  vertexPositionVS.xyz /= vertexPositionVS.w;
  vertexPositionVS.w = 1.0;
  vec3 normal = normalDepth.xyz * 2.0 - 1.0;
  vec4 colorMap = texture2D(samplerColor, texCoord);
  vec3 albedo = float_to_vec3(abs(colorMap.x));
  vec3 specularColor = float_to_vec3(abs(colorMap.y));
  float shininess = abs(colorMap.z);
  float wrapAround = sign(colorMap.z);
  float additiveSpecular = sign(colorMap.y);
  vec3 lightVector = lightDirectionVS;
  float dotProduct = dot(normal, lightVector);
  float diffuseFull = max(dotProduct, 0.0);
  vec3 diffuse;
  if (wrapAround < 0.0) {
  float diffuseHalf = max(0.5 * dotProduct + 0.5, 0.0);
  const vec3 wrapRGB = vec3(1.0, 1.0, 1.0);
  diffuse = mix(vec3(diffuseFull), vec3(diffuseHalf), wrapRGB);
  } else {
  diffuse = vec3(diffuseFull);
  }
  vec3 halfVector = normalize(lightVector - normalize(vertexPositionVS.xyz));
  float dotNormalHalf = max(dot(normal, halfVector), 0.0);
  float specularNormalization = (shininess + 2.0001) / 8.0;
  vec3 schlick = specularColor + vec3(1.0 - specularColor) * pow(1.0 - dot(lightVector, halfVector), 5.0);
  vec3 specular = schlick * max(pow(dotNormalHalf, shininess), 0.0) * diffuse * specularNormalization;
  const float attenuation = 1.0;
  vec3 light = lightIntensity * lightColor;
  gl_FragColor = vec4(light * (albedo * diffuse + specular), attenuation);
  }
""",

'vertexShader': """
  void main() { 
  gl_Position = vec4(sign(position.xy), 0.0, 1.0);
  }
"""};

final Map deferredHemisphereLight = {
'uniforms': {"samplerNormalDepth": new Uniform.texture(),
             "samplerColor": new Uniform.texture(),
             "matProjInverse": new Uniform.matrix4(new Matrix4.identity()),
             "viewWidth": new Uniform.float(800.0),
             "viewHeight": new Uniform.float(600.0),
            
             "lightPositionVS": new Uniform.vector3(0.0, 1.0, 0.0),
             "lightColorSky": new Uniform.color(0x000000),
             "lightColorGround": new Uniform.color(0x000000),
             "lightIntensity": new Uniform.float(1.0)},
  
'fragmentShader': """
  uniform sampler2D samplerColor;
  uniform sampler2D samplerNormalDepth;
  uniform float lightRadius;
  uniform float lightIntensity;
  uniform float viewHeight;
  uniform float viewWidth;
  uniform vec3 lightColorSky;
  uniform vec3 lightColorGround;
  uniform vec3 lightDirectionVS;
  uniform mat4 matProjInverse;
  vec3 float_to_vec3(float data) {
  vec3 uncompressed;
  uncompressed.x = fract(data);
  float zInt = floor(data / 255.0);
  uncompressed.z = fract(zInt / 255.0);
  uncompressed.y = fract(floor(data - (zInt * 255.0)) / 255.0);
  return uncompressed;
  }
  void main() {
  vec2 texCoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
  vec4 normalDepth = texture2D(samplerNormalDepth, texCoord);
  float z = normalDepth.w;
  if (z == 0.0) discard;
  vec2 xy = texCoord * 2.0 - 1.0;
  vec4 vertexPositionProjected = vec4(xy, z, 1.0);
  vec4 vertexPositionVS = matProjInverse * vertexPositionProjected;
  vertexPositionVS.xyz /= vertexPositionVS.w;
  vertexPositionVS.w = 1.0;
  vec3 normal = normalDepth.xyz * 2.0 - 1.0;
  vec4 colorMap = texture2D(samplerColor, texCoord);
  vec3 albedo = float_to_vec3(abs(colorMap.x));
  vec3 specularColor = float_to_vec3(abs(colorMap.y));
  float shininess = abs(colorMap.z);
  float wrapAround = sign(colorMap.z);
  float additiveSpecular = sign(colorMap.y);
  vec3 lightVector = lightDirectionVS;
  float dotProduct = dot(normal, lightVector);
  float hemiDiffuseWeight = 0.5 * dotProduct + 0.5;
  vec3 hemiColor = mix(lightColorGround, lightColorSky, hemiDiffuseWeight);
  vec3 diffuse = hemiColor;
  vec3 hemiHalfVectorSky = normalize(lightVector - vertexPositionVS.xyz);
  float hemiDotNormalHalfSky = 0.5 * dot(normal, hemiHalfVectorSky) + 0.5;
  float hemiSpecularWeightSky = max(pow(hemiDotNormalHalfSky, shininess), 0.0);
  vec3 lVectorGround = -lightVector;
  vec3 hemiHalfVectorGround = normalize(lVectorGround - vertexPositionVS.xyz);
  float hemiDotNormalHalfGround = 0.5 * dot(normal, hemiHalfVectorGround) + 0.5;
  float hemiSpecularWeightGround = max(pow(hemiDotNormalHalfGround, shininess), 0.0);
  float dotProductGround = dot(normal, lVectorGround);
  float specularNormalization = (shininess + 2.0001) / 8.0;
  vec3 schlickSky = specularColor + vec3(1.0 - specularColor) * pow(1.0 - dot(lightVector, hemiHalfVectorSky), 5.0);
  vec3 schlickGround = specularColor + vec3(1.0 - specularColor) * pow(1.0 - dot(lVectorGround, hemiHalfVectorGround), 5.0);
  vec3 specular = hemiColor * specularNormalization * (schlickSky * hemiSpecularWeightSky * max(dotProduct, 0.0) + schlickGround * hemiSpecularWeightGround * max(dotProductGround, 0.0));
  gl_FragColor = vec4(lightIntensity * (albedo * diffuse + specular), 1.0);
  }
""",

'vertexShader': """
  void main() { 
  gl_Position = vec4(sign(position.xy), 0.0, 1.0);
  }
"""};

final Map deferredAreaLight = {
'uniforms': {"samplerNormalDepth": new Uniform.texture(),
             "samplerColor": new Uniform.texture(),
             "matProjInverse": new Uniform.matrix4(new Matrix4.identity()),
             "viewWidth": new Uniform.float(800.0),
             "viewHeight": new Uniform.float(600.0),
            
             "lightPositionVS": new Uniform.vector3(0.0, 1.0, 0.0),
             "lightNormalVS": new Uniform.vector3(0.0, -1.0, 0.0),
             "lightRightVS": new Uniform.vector3(1.0, 0.0, 0.0),
             "lightUpVS": new Uniform.vector3(1.0, 0.0, 0.0),
             
             "lightColor": new Uniform.color(0x000000),
             "lightIntensity": new Uniform.float(1.0),
             
             "lightWidth": new Uniform.float(1.0),
             "lightHeight": new Uniform.float(1.0),
             
             "constantAttenuation": new Uniform.float(1.5),
             "linearAttenuation": new Uniform.float(0.5),
             "quadraticAttenuation": new Uniform.float(0.1)},
  
'fragmentShader': """
  uniform vec3 lightPositionVS;
  uniform vec3 lightNormalVS;
  uniform vec3 lightRightVS;
  uniform vec3 lightUpVS;
  uniform sampler2D samplerColor;
  uniform sampler2D samplerNormalDepth;
  uniform float lightWidth;
  uniform float lightHeight;
  uniform float constantAttenuation;
  uniform float linearAttenuation;
  uniform float quadraticAttenuation;
  uniform float lightIntensity;
  uniform vec3 lightColor;
  uniform float viewHeight;
  uniform float viewWidth;
  uniform mat4 matProjInverse;
  vec3 float_to_vec3(float data) {
  vec3 uncompressed;
  uncompressed.x = fract(data);
  float zInt = floor(data / 255.0);
  uncompressed.z = fract(zInt / 255.0);
  uncompressed.y = fract(floor(data - (zInt * 255.0)) / 255.0);
  return uncompressed;
  }
  vec3 projectOnPlane(vec3 point, vec3 planeCenter, vec3 planeNorm) {
  return point - dot(point - planeCenter, planeNorm) * planeNorm;
  }
  bool sideOfPlane(vec3 point, vec3 planeCenter, vec3 planeNorm) {
  return (dot(point - planeCenter, planeNorm) >= 0.0);
  }
  vec3 linePlaneIntersect(vec3 lp, vec3 lv, vec3 pc, vec3 pn) {
  return lp + lv * (dot(pn, pc - lp) / dot(pn, lv));
  }
  float calculateAttenuation(float dist) {
  return (1.0 / (constantAttenuation + linearAttenuation * dist + quadraticAttenuation * dist * dist));
  }
  void main() {
  vec2 texCoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
  vec4 normalDepth = texture2D(samplerNormalDepth, texCoord);
  float z = normalDepth.w;
  if (z == 0.0) discard;
  vec2 xy = texCoord * 2.0 - 1.0;
  vec4 vertexPositionProjected = vec4(xy, z, 1.0);
  vec4 vertexPositionVS = matProjInverse * vertexPositionProjected;
  vertexPositionVS.xyz /= vertexPositionVS.w;
  vertexPositionVS.w = 1.0;
  vec3 normal = normalDepth.xyz * 2.0 - 1.0;
  vec4 colorMap = texture2D(samplerColor, texCoord);
  vec3 albedo = float_to_vec3(abs(colorMap.x));
  vec3 specularColor = float_to_vec3(abs(colorMap.y));
  float shininess = abs(colorMap.z);
  float wrapAround = sign(colorMap.z);
  float additiveSpecular = sign(colorMap.y);
  float w = lightWidth;
  float h = lightHeight;
  vec3 proj = projectOnPlane(vertexPositionVS.xyz, lightPositionVS, lightNormalVS);
  vec3 dir = proj - lightPositionVS;
  vec2 diagonal = vec2(dot(dir, lightRightVS), dot(dir, lightUpVS));
  vec2 nearest2D = vec2(clamp(diagonal.x, -w, w), clamp(diagonal.y, -h, h));
  vec3 nearestPointInside = vec3(lightPositionVS) + (lightRightVS * nearest2D.x + lightUpVS * nearest2D.y);
  vec3 lightDir = normalize(nearestPointInside - vertexPositionVS.xyz);
  float NdotL = max(dot(lightNormalVS, -lightDir), 0.0);
  float NdotL2 = max(dot(normal, lightDir), 0.0);
  if (NdotL2 * NdotL > 0.0) {
  vec3 diffuse = vec3(sqrt(NdotL * NdotL2));
  vec3 specular = vec3(0.0);
  vec3 R = reflect(normalize(-vertexPositionVS.xyz), normal);
  vec3 E = linePlaneIntersect(vertexPositionVS.xyz, R, vec3(lightPositionVS), lightNormalVS);
  float specAngle = dot(R, lightNormalVS);
  if (specAngle > 0.0) {
  vec3 dirSpec = E - vec3(lightPositionVS);
  vec2 dirSpec2D = vec2(dot(dirSpec, lightRightVS), dot(dirSpec, lightUpVS));
  vec2 nearestSpec2D = vec2(clamp(dirSpec2D.x, -w, w), clamp(dirSpec2D.y, -h, h));
  float specFactor = 1.0 - clamp(length(nearestSpec2D - dirSpec2D) * 0.05 * shininess, 0.0, 1.0);
  specular = specularColor * specFactor * specAngle * diffuse;
  }
  float dist = distance(vertexPositionVS.xyz, nearestPointInside);
  float attenuation = calculateAttenuation(dist);
  vec3 light = lightIntensity * lightColor;
  gl_FragColor = vec4(light * (albedo * diffuse + specular), attenuation);
  } else {
  discard;
  }
  }
""",

'vertexShader': """
  void main() {
  gl_Position = vec4(sign(position.xy), 0.0, 1.0);
  }
"""};

final Map deferredEmissiveLight = {
'uniforms': {"samplerColor": new Uniform.texture(),
             "viewWidth": new Uniform.float(800.0),
             "viewHeight": new Uniform.float(600.0)},
  
'fragmentShader': """
  uniform sampler2D samplerColor;
  uniform float viewHeight;
  uniform float viewWidth;
  vec3 float_to_vec3(float data) {
  vec3 uncompressed;
  uncompressed.x = fract(data);
  float zInt = floor(data / 255.0);
  uncompressed.z = fract(zInt / 255.0);
  uncompressed.y = fract(floor(data - (zInt * 255.0)) / 255.0);
  return uncompressed;
  }
  void main() {
  vec2 texCoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
  vec4 colorMap = texture2D(samplerColor, texCoord);
  vec3 emissiveColor = float_to_vec3(abs(colorMap.w));
  gl_FragColor = vec4(emissiveColor, 1.0);
  }
""",

'vertexShader': """
  void main() { 
  gl_Position = vec4(sign(position.xy), 0.0, 1.0);
  }
"""};

final Map skinSimple = {
'uniforms': UniformsUtils.merge([UniformsLib["fog"],
                                 UniformsLib["lights"],
                                 UniformsLib["shadowmap"],
                                {"enableBump": new Uniform.int(0),
                                 "enableSpecular": new Uniform.int(0),

                                 "tDiffuse": new Uniform.texture(),
                                 "tBeckmann": new Uniform.texture(),

                                 "diffuse": new Uniform.color(0xeeeeee),
                                 "specular": new Uniform.color(0x111111),
                                 "ambient": new Uniform.color(0x050505),
                                 "opacity": new Uniform.float(1.0),

                                 "uRoughness": new Uniform.float(0.15),
                                 "uSpecularBrightness": new Uniform.float(0.75),

                                 "bumpMap": new Uniform.texture(),
                                 "bumpScale": new Uniform.float(1.0),

                                 "specularMap": new Uniform.texture(),

                                 "offsetRepeat": new Uniform.vector4(0.0, 0.0, 1.0, 1.0),

                                 "uWrapRGB": new Uniform.vector3(0.75, 0.375, 0.1875)}]),
'fragmentShader':  """
  #define USE_BUMPMAP
  #extension GL_OES_standard_derivatives : enable
  uniform bool enableBump;
  uniform bool enableSpecular;
  uniform vec3 ambient;
  uniform vec3 diffuse;
  uniform vec3 specular;
  uniform float opacity;
  uniform float uRoughness;
  uniform float uSpecularBrightness;
  uniform vec3 uWrapRGB;
  uniform sampler2D tDiffuse;
  uniform sampler2D tBeckmann;
  uniform sampler2D specularMap;
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
  varying vec3 vViewPosition;
  #ifdef USE_SHADOWMAP
  uniform sampler2D shadowMap[MAX_SHADOWS];
  uniform vec2 shadowMapSize[MAX_SHADOWS];
  uniform float shadowDarkness[MAX_SHADOWS];
  uniform float shadowBias[MAX_SHADOWS];
  varying vec4 vShadowCoord[MAX_SHADOWS];
  float unpackDepth(const in vec4 rgba_depth) {
  const vec4 bit_shift = vec4(1.0 / (256.0 * 256.0 * 256.0), 1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0);
  float depth = dot(rgba_depth, bit_shift);
  return depth;
  }
  #endif
  #ifdef USE_FOG
  uniform vec3 fogColor;
  #ifdef FOG_EXP2
  uniform float fogDensity;
  #else
  uniform float fogNear;
  uniform float fogFar;
  #endif
  #endif
  #ifdef USE_BUMPMAP
  uniform sampler2D bumpMap;
  uniform float bumpScale;
  vec2 dHdxy_fwd() {
  vec2 dSTdx = dFdx(vUv);
  vec2 dSTdy = dFdy(vUv);
  float Hll = bumpScale * texture2D(bumpMap, vUv).x;
  float dBx = bumpScale * texture2D(bumpMap, vUv + dSTdx).x - Hll;
  float dBy = bumpScale * texture2D(bumpMap, vUv + dSTdy).x - Hll;
  return vec2(dBx, dBy);
  }
  vec3 perturbNormalArb(vec3 surf_pos, vec3 surf_norm, vec2 dHdxy) {
  vec3 vSigmaX = dFdx(surf_pos);
  vec3 vSigmaY = dFdy(surf_pos);
  vec3 vN = surf_norm;
  vec3 R1 = cross(vSigmaY, vN);
  vec3 R2 = cross(vN, vSigmaX);
  float fDet = dot(vSigmaX, R1);
  vec3 vGrad = sign(fDet) * (dHdxy.x * R1 + dHdxy.y * R2);
  return normalize(abs(fDet) * surf_norm - vGrad);
  }
  #endif
  float fresnelReflectance(vec3 H, vec3 V, float F0) {
  float base = 1.0 - dot(V, H);
  float exponential = pow(base, 5.0);
  return exponential + F0 * (1.0 - exponential);
  }
  float KS_Skin_Specular(vec3 N,
  vec3 L,
  vec3 V,
  float m,
  float rho_s
 ) {
  float result = 0.0;
  float ndotl = dot(N, L);
  if(ndotl > 0.0) {
  vec3 h = L + V;
  vec3 H = normalize(h);
  float ndoth = dot(N, H);
  float PH = pow(2.0 * texture2D(tBeckmann, vec2(ndoth, m)).x, 10.0);
  float F = fresnelReflectance(H, V, 0.028);
  float frSpec = max(PH * F / dot(h, h), 0.0);
  result = ndotl * rho_s * frSpec;
  }
  return result;
  }
  void main() {
  gl_FragColor = vec4(vec3(1.0), opacity);
  vec4 colDiffuse = texture2D(tDiffuse, vUv);
  colDiffuse.rgb *= colDiffuse.rgb;
  gl_FragColor = gl_FragColor * colDiffuse;
  vec3 normal = normalize(vNormal);
  vec3 viewPosition = normalize(vViewPosition);
  float specularStrength;
  if (enableSpecular) {
  vec4 texelSpecular = texture2D(specularMap, vUv);
  specularStrength = texelSpecular.r;
  } else {
  specularStrength = 1.0;
  }
  #ifdef USE_BUMPMAP
  if (enableBump) normal = perturbNormalArb(-vViewPosition, normal, dHdxy_fwd());
  #endif
  vec3 specularTotal = vec3(0.0);
  #if MAX_POINT_LIGHTS > 0
  vec3 pointTotal = vec3(0.0);
  for (int i = 0; i < MAX_POINT_LIGHTS; i ++) {
  vec4 lPosition = viewMatrix * vec4(pointLightPosition[i], 1.0);
  vec3 lVector = lPosition.xyz + vViewPosition.xyz;
  float lDistance = 1.0;
  if (pointLightDistance[i] > 0.0)
  lDistance = 1.0 - min((length(lVector) / pointLightDistance[i]), 1.0);
  lVector = normalize(lVector);
  float pointDiffuseWeightFull = max(dot(normal, lVector), 0.0);
  float pointDiffuseWeightHalf = max(0.5 * dot(normal, lVector) + 0.5, 0.0);
  vec3 pointDiffuseWeight = mix(vec3 (pointDiffuseWeightFull), vec3(pointDiffuseWeightHalf), uWrapRGB);
  float pointSpecularWeight = KS_Skin_Specular(normal, lVector, viewPosition, uRoughness, uSpecularBrightness);
  pointTotal    += lDistance * diffuse * pointLightColor[i] * pointDiffuseWeight;
  specularTotal += lDistance * specular * pointLightColor[i] * pointSpecularWeight * specularStrength;
  }
  #endif
  #if MAX_DIR_LIGHTS > 0
  vec3 dirTotal = vec3(0.0);
  for(int i = 0; i < MAX_DIR_LIGHTS; i++) {
  vec4 lDirection = viewMatrix * vec4(directionalLightDirection[i], 0.0);
  vec3 dirVector = normalize(lDirection.xyz);
  float dirDiffuseWeightFull = max(dot(normal, dirVector), 0.0);
  float dirDiffuseWeightHalf = max(0.5 * dot(normal, dirVector) + 0.5, 0.0);
  vec3 dirDiffuseWeight = mix(vec3 (dirDiffuseWeightFull), vec3(dirDiffuseWeightHalf), uWrapRGB);
  float dirSpecularWeight =  KS_Skin_Specular(normal, dirVector, viewPosition, uRoughness, uSpecularBrightness);
  dirTotal            += diffuse * directionalLightColor[i] * dirDiffuseWeight;
  specularTotal += specular * directionalLightColor[i] * dirSpecularWeight * specularStrength;
  }
  #endif
  #if MAX_HEMI_LIGHTS > 0
  vec3 hemiTotal = vec3(0.0);
  for (int i = 0; i < MAX_HEMI_LIGHTS; i ++) {
  vec4 lDirection = viewMatrix * vec4(hemisphereLightDirection[i], 0.0);
  vec3 lVector = normalize(lDirection.xyz);
  float dotProduct = dot(normal, lVector);
  float hemiDiffuseWeight = 0.5 * dotProduct + 0.5;
  hemiTotal += diffuse * mix(hemisphereLightGroundColor[i], hemisphereLightSkyColor[i], hemiDiffuseWeight);
  float hemiSpecularWeight = 0.0;
  hemiSpecularWeight += KS_Skin_Specular(normal, lVector, viewPosition, uRoughness, uSpecularBrightness);
  vec3 lVectorGround = -lVector;
  hemiSpecularWeight += KS_Skin_Specular(normal, lVectorGround, viewPosition, uRoughness, uSpecularBrightness);
  specularTotal += specular * mix(hemisphereLightGroundColor[i], hemisphereLightSkyColor[i], hemiDiffuseWeight) * hemiSpecularWeight * specularStrength;
  }
  #endif
  vec3 totalLight = vec3(0.0);
  #if MAX_DIR_LIGHTS > 0
  totalLight += dirTotal;
  #endif
  #if MAX_POINT_LIGHTS > 0
  totalLight += pointTotal;
  #endif
  #if MAX_HEMI_LIGHTS > 0
  totalLight += hemiTotal;
  #endif
  gl_FragColor.xyz = gl_FragColor.xyz * (totalLight + ambientLightColor * ambient) + specularTotal;
  #ifdef USE_SHADOWMAP
  #ifdef SHADOWMAP_DEBUG
  vec3 frustumColors[3];
  frustumColors[0] = vec3(1.0, 0.5, 0.0);
  frustumColors[1] = vec3(0.0, 1.0, 0.8);
  frustumColors[2] = vec3(0.0, 0.5, 1.0);
  #endif
  #ifdef SHADOWMAP_CASCADE
  int inFrustumCount = 0;
  #endif
  float fDepth;
  vec3 shadowColor = vec3(1.0);
  for(int i = 0; i < MAX_SHADOWS; i ++) {
  vec3 shadowCoord = vShadowCoord[i].xyz / vShadowCoord[i].w;
  bvec4 inFrustumVec = bvec4 (shadowCoord.x >= 0.0, shadowCoord.x <= 1.0, shadowCoord.y >= 0.0, shadowCoord.y <= 1.0);
  bool inFrustum = all(inFrustumVec);
  #ifdef SHADOWMAP_CASCADE
  inFrustumCount += int(inFrustum);
  bvec3 frustumTestVec = bvec3(inFrustum, inFrustumCount == 1, shadowCoord.z <= 1.0);
  #else
  bvec2 frustumTestVec = bvec2(inFrustum, shadowCoord.z <= 1.0);
  #endif
  bool frustumTest = all(frustumTestVec);
  if (frustumTest) {
  shadowCoord.z += shadowBias[i];
  #if defined(SHADOWMAP_TYPE_PCF)
  float shadow = 0.0;
  const float shadowDelta = 1.0 / 9.0;
  float xPixelOffset = 1.0 / shadowMapSize[i].x;
  float yPixelOffset = 1.0 / shadowMapSize[i].y;
  float dx0 = -1.25 * xPixelOffset;
  float dy0 = -1.25 * yPixelOffset;
  float dx1 = 1.25 * xPixelOffset;
  float dy1 = 1.25 * yPixelOffset;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, dy0)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(0.0, dy0)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, dy0)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, 0.0)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, 0.0)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, dy1)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(0.0, dy1)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, dy1)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  shadowColor = shadowColor * vec3((1.0 - shadowDarkness[i] * shadow));
  #elif defined(SHADOWMAP_TYPE_PCF_SOFT)
  float shadow = 0.0;
  float xPixelOffset = 1.0 / shadowMapSize[i].x;
  float yPixelOffset = 1.0 / shadowMapSize[i].y;
  float dx0 = -1.0 * xPixelOffset;
  float dy0 = -1.0 * yPixelOffset;
  float dx1 = 1.0 * xPixelOffset;
  float dy1 = 1.0 * yPixelOffset;
  mat3 shadowKernel;
  mat3 depthKernel;
  depthKernel[0][0] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, dy0)));
  depthKernel[0][1] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, 0.0)));
  depthKernel[0][2] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, dy1)));
  depthKernel[1][0] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(0.0, dy0)));
  depthKernel[1][1] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy));
  depthKernel[1][2] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(0.0, dy1)));
  depthKernel[2][0] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, dy0)));
  depthKernel[2][1] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, 0.0)));
  depthKernel[2][2] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, dy1)));
  vec3 shadowZ = vec3(shadowCoord.z);
  shadowKernel[0] = vec3(lessThan(depthKernel[0], shadowZ));
  shadowKernel[0] *= vec3(0.25);
  shadowKernel[1] = vec3(lessThan(depthKernel[1], shadowZ));
  shadowKernel[1] *= vec3(0.25);
  shadowKernel[2] = vec3(lessThan(depthKernel[2], shadowZ));
  shadowKernel[2] *= vec3(0.25);
  vec2 fractionalCoord = 1.0 - fract(shadowCoord.xy * shadowMapSize[i].xy);
  shadowKernel[0] = mix(shadowKernel[1], shadowKernel[0], fractionalCoord.x);
  shadowKernel[1] = mix(shadowKernel[2], shadowKernel[1], fractionalCoord.x);
  vec4 shadowValues;
  shadowValues.x = mix(shadowKernel[0][1], shadowKernel[0][0], fractionalCoord.y);
  shadowValues.y = mix(shadowKernel[0][2], shadowKernel[0][1], fractionalCoord.y);
  shadowValues.z = mix(shadowKernel[1][1], shadowKernel[1][0], fractionalCoord.y);
  shadowValues.w = mix(shadowKernel[1][2], shadowKernel[1][1], fractionalCoord.y);
  shadow = dot(shadowValues, vec4(1.0));
  shadowColor = shadowColor * vec3((1.0 - shadowDarkness[i] * shadow));
  #else
  vec4 rgbaDepth = texture2D(shadowMap[i], shadowCoord.xy);
  float fDepth = unpackDepth(rgbaDepth);
  if (fDepth < shadowCoord.z)
  shadowColor = shadowColor * vec3(1.0 - shadowDarkness[i]);
  #endif
  }
  #ifdef SHADOWMAP_DEBUG
  #ifdef SHADOWMAP_CASCADE
  if (inFrustum && inFrustumCount == 1) gl_FragColor.xyz *= frustumColors[i];
  #else
  if (inFrustum) gl_FragColor.xyz *= frustumColors[i];
  #endif
  #endif
  }
  #ifdef GAMMA_OUTPUT
  shadowColor *= shadowColor;
  #endif
  gl_FragColor.xyz = gl_FragColor.xyz * shadowColor;
  #endif
  #ifdef GAMMA_OUTPUT
  gl_FragColor.xyz = sqrt(gl_FragColor.xyz);
  #endif
  #ifdef USE_FOG
  float depth = gl_FragCoord.z / gl_FragCoord.w;
  #ifdef FOG_EXP2
  const float LOG2 = 1.442695;
  float fogFactor = exp2(- fogDensity * fogDensity * depth * depth * LOG2);
  fogFactor = 1.0 - clamp(fogFactor, 0.0, 1.0);
  #else
  float fogFactor = smoothstep(fogNear, fogFar, depth);
  #endif
  gl_FragColor = mix(gl_FragColor, vec4(fogColor, gl_FragColor.w), fogFactor);
  #endif
  }
""",

'vertexShader':  """
  uniform vec4 offsetRepeat;
  varying vec3 vNormal;
  varying vec2 vUv;
  varying vec3 vViewPosition;
  #ifdef USE_SHADOWMAP
  varying vec4 vShadowCoord[MAX_SHADOWS];
  uniform mat4 shadowMatrix[MAX_SHADOWS];
  #endif
  void main() {
  vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
  vec4 worldPosition = modelMatrix * vec4(position, 1.0);
  vViewPosition = -mvPosition.xyz;
  vNormal = normalize(normalMatrix * normal);
  vUv = uv * offsetRepeat.zw + offsetRepeat.xy;
  gl_Position = projectionMatrix * mvPosition;
  #ifdef USE_SHADOWMAP
  for(int i = 0; i < MAX_SHADOWS; i ++) {
  vShadowCoord[i] = shadowMatrix[i] * worldPosition;
  }
  #endif
  }
"""};

final Map skin = {
'uniforms': UniformsUtils.merge([UniformsLib["fog"],
                                 UniformsLib["lights"],
                                {"passID": new Uniform.int(0),

                                 "tDiffuse": new Uniform.texture(),
                                 "tNormal": new Uniform.texture(),

                                 "tBlur1": new Uniform.texture(),
                                 "tBlur2": new Uniform.texture(),
                                 "tBlur3": new Uniform.texture(),
                                 "tBlur4": new Uniform.texture(),

                                 "tBeckmann": new Uniform.texture(),

                                 "uNormalScale": new Uniform.float(1.0),

                                 "diffuse": new Uniform.color(0xeeeeee),
                                 "specular": new Uniform.color(0x111111),
                                 "ambient": new Uniform.color(0x050505),
                                 "opacity": new Uniform.float(1.0),

                                 "uRoughness":  new Uniform.float(0.15),
                                 "uSpecularBrightness": new Uniform.float(0.75)}]),

'fragmentShader':  """
  uniform vec3 ambient;
  uniform vec3 diffuse;
  uniform vec3 specular;
  uniform float opacity;
  uniform float uRoughness;
  uniform float uSpecularBrightness;
  uniform int passID;
  uniform sampler2D tDiffuse;
  uniform sampler2D tNormal;
  uniform sampler2D tBlur1;
  uniform sampler2D tBlur2;
  uniform sampler2D tBlur3;
  uniform sampler2D tBlur4;
  uniform sampler2D tBeckmann;
  uniform float uNormalScale;
  varying vec3 vTangent;
  varying vec3 vBinormal;
  varying vec3 vNormal;
  varying vec2 vUv;
  uniform vec3 ambientLightColor;
  #if MAX_DIR_LIGHTS > 0
  uniform vec3 directionalLightColor[MAX_DIR_LIGHTS];
  uniform vec3 directionalLightDirection[MAX_DIR_LIGHTS];
  #endif
  #if MAX_POINT_LIGHTS > 0
  uniform vec3 pointLightColor[MAX_POINT_LIGHTS];
  varying vec4 vPointLight[MAX_POINT_LIGHTS];
  #endif
  varying vec3 vViewPosition;
  #ifdef USE_FOG
  uniform vec3 fogColor;
  #ifdef FOG_EXP2
  uniform float fogDensity;
  #else
  uniform float fogNear;
  uniform float fogFar;
  #endif
  #endif
  float fresnelReflectance(vec3 H, vec3 V, float F0) {
  float base = 1.0 - dot(V, H);
  float exponential = pow(base, 5.0);
  return exponential + F0 * (1.0 - exponential);
  }
  float KS_Skin_Specular(vec3 N,
  vec3 L,
  vec3 V,
  float m,
  float rho_s
 ) {
  float result = 0.0;
  float ndotl = dot(N, L);
  if(ndotl > 0.0) {
  vec3 h = L + V;
  vec3 H = normalize(h);
  float ndoth = dot(N, H);
  float PH = pow(2.0 * texture2D(tBeckmann, vec2(ndoth, m)).x, 10.0);
  float F = fresnelReflectance(H, V, 0.028);
  float frSpec = max(PH * F / dot(h, h), 0.0);
  result = ndotl * rho_s * frSpec;
  }
  return result;
  }
  void main() {
  gl_FragColor = vec4(1.0);
  vec4 mColor = vec4(diffuse, opacity);
  vec4 mSpecular = vec4(specular, opacity);
  vec3 normalTex = texture2D(tNormal, vUv).xyz * 2.0 - 1.0;
  normalTex.xy *= uNormalScale;
  normalTex = normalize(normalTex);
  vec4 colDiffuse = texture2D(tDiffuse, vUv);
  colDiffuse *= colDiffuse;
  gl_FragColor = gl_FragColor * colDiffuse;
  mat3 tsb = mat3(vTangent, vBinormal, vNormal);
  vec3 finalNormal = tsb * normalTex;
  vec3 normal = normalize(finalNormal);
  vec3 viewPosition = normalize(vViewPosition);
  vec3 specularTotal = vec3(0.0);
  #if MAX_POINT_LIGHTS > 0
  vec4 pointTotal = vec4(vec3(0.0), 1.0);
  for (int i = 0; i < MAX_POINT_LIGHTS; i ++) {
  vec3 pointVector = normalize(vPointLight[i].xyz);
  float pointDistance = vPointLight[i].w;
  float pointDiffuseWeight = max(dot(normal, pointVector), 0.0);
  pointTotal  += pointDistance * vec4(pointLightColor[i], 1.0) * (mColor * pointDiffuseWeight);
  if (passID == 1)
  specularTotal += pointDistance * mSpecular.xyz * pointLightColor[i] * KS_Skin_Specular(normal, pointVector, viewPosition, uRoughness, uSpecularBrightness);
  }
  #endif
  #if MAX_DIR_LIGHTS > 0
  vec4 dirTotal = vec4(vec3(0.0), 1.0);
  for(int i = 0; i < MAX_DIR_LIGHTS; i++) {
  vec4 lDirection = viewMatrix * vec4(directionalLightDirection[i], 0.0);
  vec3 dirVector = normalize(lDirection.xyz);
  float dirDiffuseWeight = max(dot(normal, dirVector), 0.0);
  dirTotal  += vec4(directionalLightColor[i], 1.0) * (mColor * dirDiffuseWeight);
  if (passID == 1)
  specularTotal += mSpecular.xyz * directionalLightColor[i] * KS_Skin_Specular(normal, dirVector, viewPosition, uRoughness, uSpecularBrightness);
  }
  #endif
  vec4 totalLight = vec4(vec3(0.0), opacity);
  #if MAX_DIR_LIGHTS > 0
  totalLight += dirTotal;
  #endif
  #if MAX_POINT_LIGHTS > 0
  totalLight += pointTotal;
  #endif
  gl_FragColor = gl_FragColor * totalLight;
  if (passID == 0) {
  gl_FragColor = vec4(sqrt(gl_FragColor.xyz), gl_FragColor.w);
  } else if (passID == 1) {
  #ifdef VERSION1
  vec3 nonblurColor = sqrt(gl_FragColor.xyz);
  #else
  vec3 nonblurColor = gl_FragColor.xyz;
  #endif
  vec3 blur1Color = texture2D(tBlur1, vUv).xyz;
  vec3 blur2Color = texture2D(tBlur2, vUv).xyz;
  vec3 blur3Color = texture2D(tBlur3, vUv).xyz;
  vec3 blur4Color = texture2D(tBlur4, vUv).xyz;
  gl_FragColor = vec4(vec3(0.22,  0.437, 0.635) * nonblurColor + 
  vec3(0.101, 0.355, 0.365) * blur1Color + 
  vec3(0.119, 0.208, 0.0)   * blur2Color + 
  vec3(0.114, 0.0,   0.0)   * blur3Color + 
  vec3(0.444, 0.0,   0.0)   * blur4Color, gl_FragColor.w);
  gl_FragColor.xyz *= pow(colDiffuse.xyz, vec3(0.5));
  gl_FragColor.xyz += ambientLightColor * ambient * colDiffuse.xyz + specularTotal;
  #ifndef VERSION1
  gl_FragColor.xyz = sqrt(gl_FragColor.xyz);
  #endif
  }
  #ifdef USE_FOG
  float depth = gl_FragCoord.z / gl_FragCoord.w;
  #ifdef FOG_EXP2
  const float LOG2 = 1.442695;
  float fogFactor = exp2(- fogDensity * fogDensity * depth * depth * LOG2);
  fogFactor = 1.0 - clamp(fogFactor, 0.0, 1.0);
  #else
  float fogFactor = smoothstep(fogNear, fogFar, depth);
  #endif
  gl_FragColor = mix(gl_FragColor, vec4(fogColor, gl_FragColor.w), fogFactor);
  #endif
  }
""",

'vertexShader': """
  attribute vec4 tangent;
  #ifdef VERTEX_TEXTURES
  uniform sampler2D tDisplacement;
  uniform float uDisplacementScale;
  uniform float uDisplacementBias;
  #endif
  varying vec3 vTangent;
  varying vec3 vBinormal;
  varying vec3 vNormal;
  varying vec2 vUv;
  #if MAX_POINT_LIGHTS > 0
  uniform vec3 pointLightPosition[MAX_POINT_LIGHTS];
  uniform float pointLightDistance[MAX_POINT_LIGHTS];
  varying vec4 vPointLight[MAX_POINT_LIGHTS];
  #endif
  varying vec3 vViewPosition;
  void main() {
  vec4 worldPosition = modelMatrix * vec4(position, 1.0);
  vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
  vViewPosition = -mvPosition.xyz;
  vNormal = normalize(normalMatrix * normal);
  vTangent = normalize(normalMatrix * tangent.xyz);
  vBinormal = cross(vNormal, vTangent) * tangent.w;
  vBinormal = normalize(vBinormal);
  vUv = uv;
  #if MAX_POINT_LIGHTS > 0
  for(int i = 0; i < MAX_POINT_LIGHTS; i++) {
  vec4 lPosition = viewMatrix * vec4(pointLightPosition[i], 1.0);
  vec3 lVector = lPosition.xyz - mvPosition.xyz;
  float lDistance = 1.0;
  if (pointLightDistance[i] > 0.0)
  lDistance = 1.0 - min((length(lVector) / pointLightDistance[i]), 1.0);
  lVector = normalize(lVector);
  vPointLight[i] = vec4(lVector, lDistance);
  }
  #endif
  #ifdef VERTEX_TEXTURES
  vec3 dv = texture2D(tDisplacement, uv).xyz;
  float df = uDisplacementScale * dv.x + uDisplacementBias;
  vec4 displacedPosition = vec4(vNormal.xyz * df, 0.0) + mvPosition;
  gl_Position = projectionMatrix * displacedPosition;
  #else
  gl_Position = projectionMatrix * mvPosition;
  #endif
  }
""",

'vertexShaderUV': """
  attribute vec4 tangent;
  #ifdef VERTEX_TEXTURES
  uniform sampler2D tDisplacement;
  uniform float uDisplacementScale;
  uniform float uDisplacementBias;
  #endif
  varying vec3 vTangent;
  varying vec3 vBinormal;
  varying vec3 vNormal;
  varying vec2 vUv;
  #if MAX_POINT_LIGHTS > 0
  uniform vec3 pointLightPosition[MAX_POINT_LIGHTS];
  uniform float pointLightDistance[MAX_POINT_LIGHTS];
  varying vec4 vPointLight[MAX_POINT_LIGHTS];
  #endif
  varying vec3 vViewPosition;
  void main() {
  vec4 worldPosition = modelMatrix * vec4(position, 1.0);
  vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
  vViewPosition = -mvPosition.xyz;
  vNormal = normalize(normalMatrix * normal);
  vTangent = normalize(normalMatrix * tangent.xyz);
  vBinormal = cross(vNormal, vTangent) * tangent.w;
  vBinormal = normalize(vBinormal);
  vUv = uv;
  #if MAX_POINT_LIGHTS > 0
  for(int i = 0; i < MAX_POINT_LIGHTS; i++) {
  vec4 lPosition = viewMatrix * vec4(pointLightPosition[i], 1.0);
  vec3 lVector = lPosition.xyz - mvPosition.xyz;
  float lDistance = 1.0;
  if (pointLightDistance[i] > 0.0)
  lDistance = 1.0 - min((length(lVector) / pointLightDistance[i]), 1.0);
  lVector = normalize(lVector);
  vPointLight[i] = vec4(lVector, lDistance);
  }
  #endif
  gl_Position = vec4(uv.x * 2.0 - 1.0, uv.y * 2.0 - 1.0, 0.0, 1.0);
  }
"""};


final Map beckmann = {
'uniforms': {},

'vertexShader': """
  varying vec2 vUv;
  void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""",

'fragmentShader': """
  varying vec2 vUv;
  float PHBeckmann(float ndoth, float m) {
  float alpha = acos(ndoth);
  float ta = tan(alpha);
  float val = 1.0 / (m * m * pow(ndoth, 4.0)) * exp(-(ta * ta) / (m * m));
  return val;
  }
  float KSTextureCompute(vec2 tex) {
  return 0.5 * pow(PHBeckmann(tex.x, tex.y), 0.1);
  }
  void main() {
  float x = KSTextureCompute(vUv);
  gl_FragColor = vec4(x, x, x, 1.0);
  }
""",

};

final Map terrain = {
'uniforms': UniformsUtils.merge([UniformsLib["fog"],
                                 UniformsLib["lights"],
                                 UniformsLib["shadowmap"],
                                {"enableDiffuse1": new Uniform.int(0),
                                 "enableDiffuse2": new Uniform.int(0),
                                 "enableSpecular": new Uniform.int(0),
                                 "enableReflection": new Uniform.int(0),

                                 "tDiffuse1": new Uniform.texture(),
                                 "tDiffuse2": new Uniform.texture(),
                                 "tDetail": new Uniform.texture(),
                                 "tNormal": new Uniform.texture(),
                                 "tSpecular": new Uniform.texture(),
                                 "tDisplacement": new Uniform.texture(),

                                 "uNormalScale": new Uniform.float(1.0),

                                 "uDisplacementBias": new Uniform.float(0.0),
                                 "uDisplacementScale": new Uniform.float(1.0),

                                 "diffuse": new Uniform.color(0xeeeeee),
                                 "specular": new Uniform.color(0x111111),
                                 "ambient": new Uniform.color(0x050505),
                                 "shininess": new Uniform.float(30.0),
                                 "opacity": new Uniform.float(1.0),

                                 "uRepeatBase": new Uniform.vector2(1.0, 1.0),
                                 "uRepeatOverlay": new Uniform.vector2(1.0, 1.0),

                                 "uOffset" : new Uniform.vector2(0.0, 0.0)}]),
                                 
'fragmentShader': """
  uniform vec3 ambient;
  uniform vec3 diffuse;
  uniform vec3 specular;
  uniform float shininess;
  uniform float opacity;
  uniform bool enableDiffuse1;
  uniform bool enableDiffuse2;
  uniform bool enableSpecular;
  uniform sampler2D tDiffuse1;
  uniform sampler2D tDiffuse2;
  uniform sampler2D tDetail;
  uniform sampler2D tNormal;
  uniform sampler2D tSpecular;
  uniform sampler2D tDisplacement;
  uniform float uNormalScale;
  uniform vec2 uRepeatOverlay;
  uniform vec2 uRepeatBase;
  uniform vec2 uOffset;
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
  varying vec3 vViewPosition;
  #ifdef USE_SHADOWMAP
  uniform sampler2D shadowMap[MAX_SHADOWS];
  uniform vec2 shadowMapSize[MAX_SHADOWS];
  uniform float shadowDarkness[MAX_SHADOWS];
  uniform float shadowBias[MAX_SHADOWS];
  varying vec4 vShadowCoord[MAX_SHADOWS];
  float unpackDepth(const in vec4 rgba_depth) {
  const vec4 bit_shift = vec4(1.0 / (256.0 * 256.0 * 256.0), 1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0);
  float depth = dot(rgba_depth, bit_shift);
  return depth;
  }
  #endif
  #ifdef USE_FOG
  uniform vec3 fogColor;
  #ifdef FOG_EXP2
  uniform float fogDensity;
  #else
  uniform float fogNear;
  uniform float fogFar;
  #endif
  #endif
  void main() {
  gl_FragColor = vec4(vec3(1.0), opacity);
  vec3 specularTex = vec3(1.0);
  vec2 uvOverlay = uRepeatOverlay * vUv + uOffset;
  vec2 uvBase = uRepeatBase * vUv;
  vec3 normalTex = texture2D(tDetail, uvOverlay).xyz * 2.0 - 1.0;
  normalTex.xy *= uNormalScale;
  normalTex = normalize(normalTex);
  if(enableDiffuse1 && enableDiffuse2) {
  vec4 colDiffuse1 = texture2D(tDiffuse1, uvOverlay);
  vec4 colDiffuse2 = texture2D(tDiffuse2, uvOverlay);
  #ifdef GAMMA_INPUT
  colDiffuse1.xyz *= colDiffuse1.xyz;
  colDiffuse2.xyz *= colDiffuse2.xyz;
  #endif
  gl_FragColor = gl_FragColor * mix (colDiffuse1, colDiffuse2, 1.0 - texture2D(tDisplacement, uvBase));
   } else if(enableDiffuse1) {
  gl_FragColor = gl_FragColor * texture2D(tDiffuse1, uvOverlay);
  } else if(enableDiffuse2) {
  gl_FragColor = gl_FragColor * texture2D(tDiffuse2, uvOverlay);
  }
  if(enableSpecular)
  specularTex = texture2D(tSpecular, uvOverlay).xyz;
  mat3 tsb = mat3(vTangent, vBinormal, vNormal);
  vec3 finalNormal = tsb * normalTex;
  vec3 normal = normalize(finalNormal);
  vec3 viewPosition = normalize(vViewPosition);
  #if MAX_POINT_LIGHTS > 0
  vec3 pointDiffuse = vec3(0.0);
  vec3 pointSpecular = vec3(0.0);
  for (int i = 0; i < MAX_POINT_LIGHTS; i ++) {
  vec4 lPosition = viewMatrix * vec4(pointLightPosition[i], 1.0);
  vec3 lVector = lPosition.xyz + vViewPosition.xyz;
  float lDistance = 1.0;
  if (pointLightDistance[i] > 0.0)
  lDistance = 1.0 - min((length(lVector) / pointLightDistance[i]), 1.0);
  lVector = normalize(lVector);
  vec3 pointHalfVector = normalize(lVector + viewPosition);
  float pointDistance = lDistance;
  float pointDotNormalHalf = max(dot(normal, pointHalfVector), 0.0);
  float pointDiffuseWeight = max(dot(normal, lVector), 0.0);
  float pointSpecularWeight = specularTex.r * max(pow(pointDotNormalHalf, shininess), 0.0);
  pointDiffuse += pointDistance * pointLightColor[i] * diffuse * pointDiffuseWeight;
  pointSpecular += pointDistance * pointLightColor[i] * specular * pointSpecularWeight * pointDiffuseWeight;
  }
  #endif
  #if MAX_DIR_LIGHTS > 0
  vec3 dirDiffuse = vec3(0.0);
  vec3 dirSpecular = vec3(0.0);
  for(int i = 0; i < MAX_DIR_LIGHTS; i++) {
  vec4 lDirection = viewMatrix * vec4(directionalLightDirection[i], 0.0);
  vec3 dirVector = normalize(lDirection.xyz);
  vec3 dirHalfVector = normalize(dirVector + viewPosition);
  float dirDotNormalHalf = max(dot(normal, dirHalfVector), 0.0);
  float dirDiffuseWeight = max(dot(normal, dirVector), 0.0);
  float dirSpecularWeight = specularTex.r * max(pow(dirDotNormalHalf, shininess), 0.0);
  dirDiffuse += directionalLightColor[i] * diffuse * dirDiffuseWeight;
  dirSpecular += directionalLightColor[i] * specular * dirSpecularWeight * dirDiffuseWeight;
  }
  #endif
  #if MAX_HEMI_LIGHTS > 0
  vec3 hemiDiffuse  = vec3(0.0);
  vec3 hemiSpecular = vec3(0.0);
  for(int i = 0; i < MAX_HEMI_LIGHTS; i ++) {
  vec4 lDirection = viewMatrix * vec4(hemisphereLightDirection[i], 0.0);
  vec3 lVector = normalize(lDirection.xyz);
  float dotProduct = dot(normal, lVector);
  float hemiDiffuseWeight = 0.5 * dotProduct + 0.5;
  hemiDiffuse += diffuse * mix(hemisphereLightGroundColor[i], hemisphereLightSkyColor[i], hemiDiffuseWeight);
  float hemiSpecularWeight = 0.0;
  vec3 hemiHalfVectorSky = normalize(lVector + viewPosition);
  float hemiDotNormalHalfSky = 0.5 * dot(normal, hemiHalfVectorSky) + 0.5;
  hemiSpecularWeight += specularTex.r * max(pow(hemiDotNormalHalfSky, shininess), 0.0);
  vec3 lVectorGround = -lVector;
  vec3 hemiHalfVectorGround = normalize(lVectorGround + viewPosition);
  float hemiDotNormalHalfGround = 0.5 * dot(normal, hemiHalfVectorGround) + 0.5;
  hemiSpecularWeight += specularTex.r * max(pow(hemiDotNormalHalfGround, shininess), 0.0);
  hemiSpecular += specular * mix(hemisphereLightGroundColor[i], hemisphereLightSkyColor[i], hemiDiffuseWeight) * hemiSpecularWeight * hemiDiffuseWeight;
  }
  #endif
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
  gl_FragColor.xyz = gl_FragColor.xyz * (totalDiffuse + ambientLightColor * ambient + totalSpecular);
  #ifdef USE_SHADOWMAP
  #ifdef SHADOWMAP_DEBUG
  vec3 frustumColors[3];
  frustumColors[0] = vec3(1.0, 0.5, 0.0);
  frustumColors[1] = vec3(0.0, 1.0, 0.8);
  frustumColors[2] = vec3(0.0, 0.5, 1.0);
  #endif
  #ifdef SHADOWMAP_CASCADE
  int inFrustumCount = 0;
  #endif
  float fDepth;
  vec3 shadowColor = vec3(1.0);
  for(int i = 0; i < MAX_SHADOWS; i ++) {
  vec3 shadowCoord = vShadowCoord[i].xyz / vShadowCoord[i].w;
  bvec4 inFrustumVec = bvec4 (shadowCoord.x >= 0.0, shadowCoord.x <= 1.0, shadowCoord.y >= 0.0, shadowCoord.y <= 1.0);
  bool inFrustum = all(inFrustumVec);
  #ifdef SHADOWMAP_CASCADE
  inFrustumCount += int(inFrustum);
  bvec3 frustumTestVec = bvec3(inFrustum, inFrustumCount == 1, shadowCoord.z <= 1.0);
  #else
  bvec2 frustumTestVec = bvec2(inFrustum, shadowCoord.z <= 1.0);
  #endif
  bool frustumTest = all(frustumTestVec);
  if (frustumTest) {
  shadowCoord.z += shadowBias[i];
  #if defined(SHADOWMAP_TYPE_PCF)
  float shadow = 0.0;
  const float shadowDelta = 1.0 / 9.0;
  float xPixelOffset = 1.0 / shadowMapSize[i].x;
  float yPixelOffset = 1.0 / shadowMapSize[i].y;
  float dx0 = -1.25 * xPixelOffset;
  float dy0 = -1.25 * yPixelOffset;
  float dx1 = 1.25 * xPixelOffset;
  float dy1 = 1.25 * yPixelOffset;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, dy0)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(0.0, dy0)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, dy0)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, 0.0)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, 0.0)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, dy1)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(0.0, dy1)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  fDepth = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, dy1)));
  if (fDepth < shadowCoord.z) shadow += shadowDelta;
  shadowColor = shadowColor * vec3((1.0 - shadowDarkness[i] * shadow));
  #elif defined(SHADOWMAP_TYPE_PCF_SOFT)
  float shadow = 0.0;
  float xPixelOffset = 1.0 / shadowMapSize[i].x;
  float yPixelOffset = 1.0 / shadowMapSize[i].y;
  float dx0 = -1.0 * xPixelOffset;
  float dy0 = -1.0 * yPixelOffset;
  float dx1 = 1.0 * xPixelOffset;
  float dy1 = 1.0 * yPixelOffset;
  mat3 shadowKernel;
  mat3 depthKernel;
  depthKernel[0][0] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, dy0)));
  depthKernel[0][1] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, 0.0)));
  depthKernel[0][2] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx0, dy1)));
  depthKernel[1][0] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(0.0, dy0)));
  depthKernel[1][1] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy));
  depthKernel[1][2] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(0.0, dy1)));
  depthKernel[2][0] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, dy0)));
  depthKernel[2][1] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, 0.0)));
  depthKernel[2][2] = unpackDepth(texture2D(shadowMap[i], shadowCoord.xy + vec2(dx1, dy1)));
  vec3 shadowZ = vec3(shadowCoord.z);
  shadowKernel[0] = vec3(lessThan(depthKernel[0], shadowZ));
  shadowKernel[0] *= vec3(0.25);
  shadowKernel[1] = vec3(lessThan(depthKernel[1], shadowZ));
  shadowKernel[1] *= vec3(0.25);
  shadowKernel[2] = vec3(lessThan(depthKernel[2], shadowZ));
  shadowKernel[2] *= vec3(0.25);
  vec2 fractionalCoord = 1.0 - fract(shadowCoord.xy * shadowMapSize[i].xy);
  shadowKernel[0] = mix(shadowKernel[1], shadowKernel[0], fractionalCoord.x);
  shadowKernel[1] = mix(shadowKernel[2], shadowKernel[1], fractionalCoord.x);
  vec4 shadowValues;
  shadowValues.x = mix(shadowKernel[0][1], shadowKernel[0][0], fractionalCoord.y);
  shadowValues.y = mix(shadowKernel[0][2], shadowKernel[0][1], fractionalCoord.y);
  shadowValues.z = mix(shadowKernel[1][1], shadowKernel[1][0], fractionalCoord.y);
  shadowValues.w = mix(shadowKernel[1][2], shadowKernel[1][1], fractionalCoord.y);
  shadow = dot(shadowValues, vec4(1.0));
  shadowColor = shadowColor * vec3((1.0 - shadowDarkness[i] * shadow));
  #else
  vec4 rgbaDepth = texture2D(shadowMap[i], shadowCoord.xy);
  float fDepth = unpackDepth(rgbaDepth);
  if (fDepth < shadowCoord.z)
  shadowColor = shadowColor * vec3(1.0 - shadowDarkness[i]);
  #endif
  }
  #ifdef SHADOWMAP_DEBUG
  #ifdef SHADOWMAP_CASCADE
  if (inFrustum && inFrustumCount == 1) gl_FragColor.xyz *= frustumColors[i];
  #else
  if (inFrustum) gl_FragColor.xyz *= frustumColors[i];
  #endif
  #endif
  }
  #ifdef GAMMA_OUTPUT
  shadowColor *= shadowColor;
  #endif
  gl_FragColor.xyz = gl_FragColor.xyz * shadowColor;
  #endif
  #ifdef GAMMA_OUTPUT
  gl_FragColor.xyz = sqrt(gl_FragColor.xyz);
  #endif
  #ifdef USE_FOG
  float depth = gl_FragCoord.z / gl_FragCoord.w;
  #ifdef FOG_EXP2
  const float LOG2 = 1.442695;
  float fogFactor = exp2(- fogDensity * fogDensity * depth * depth * LOG2);
  fogFactor = 1.0 - clamp(fogFactor, 0.0, 1.0);
  #else
  float fogFactor = smoothstep(fogNear, fogFar, depth);
  #endif
  gl_FragColor = mix(gl_FragColor, vec4(fogColor, gl_FragColor.w), fogFactor);
  #endif
  }
""",

'vertexShader': """
  attribute vec4 tangent;
  uniform vec2 uRepeatBase;
  uniform sampler2D tNormal;
  #ifdef VERTEX_TEXTURES
  uniform sampler2D tDisplacement;
  uniform float uDisplacementScale;
  uniform float uDisplacementBias;
  #endif
  varying vec3 vTangent;
  varying vec3 vBinormal;
  varying vec3 vNormal;
  varying vec2 vUv;
  varying vec3 vViewPosition;
  #ifdef USE_SHADOWMAP
  varying vec4 vShadowCoord[MAX_SHADOWS];
  uniform mat4 shadowMatrix[MAX_SHADOWS];
  #endif
  void main() {
  vNormal = normalize(normalMatrix * normal);
  vTangent = normalize(normalMatrix * tangent.xyz);
  vBinormal = cross(vNormal, vTangent) * tangent.w;
  vBinormal = normalize(vBinormal);
  vUv = uv;
  vec2 uvBase = uv * uRepeatBase;
  #ifdef VERTEX_TEXTURES
  vec3 dv = texture2D(tDisplacement, uvBase).xyz;
  float df = uDisplacementScale * dv.x + uDisplacementBias;
  vec3 displacedPosition = normal * df + position;
  vec4 worldPosition = modelMatrix * vec4(displacedPosition, 1.0);
  vec4 mvPosition = modelViewMatrix * vec4(displacedPosition, 1.0);
  #else
  vec4 worldPosition = modelMatrix * vec4(position, 1.0);
  vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
  #endif
  gl_Position = projectionMatrix * mvPosition;
  vViewPosition = -mvPosition.xyz;
  vec3 normalTex = texture2D(tNormal, uvBase).xyz * 2.0 - 1.0;
  vNormal = normalMatrix * normalTex;
  #ifdef USE_SHADOWMAP
  for(int i = 0; i < MAX_SHADOWS; i ++) {
  vShadowCoord[i] = shadowMatrix[i] * worldPosition;
  }
  #endif
  }
"""};

final Map toon1 = {
'uniforms': {"uDirLightPos": new Uniform.vector3(0.0, 0.0, 0.0),
             "uDirLightColor": new Uniform.color(0xeeeeee),
          
             "uAmbientLightColor": new Uniform.color(0x050505),
          
             "uBaseColor": new Uniform.color(0xffffff)},
             
'vertexShader': """
  varying vec3 vNormal;
  varying vec3 vRefract;
  void main() {
  vec4 worldPosition = modelMatrix * vec4(position, 1.0);
  vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
  vec3 worldNormal = normalize (mat3(modelMatrix[0].xyz, modelMatrix[1].xyz, modelMatrix[2].xyz) * normal);
  vNormal = normalize(normalMatrix * normal);
  vec3 I = worldPosition.xyz - cameraPosition;
  vRefract = refract(normalize(I), worldNormal, 1.02);
  gl_Position = projectionMatrix * mvPosition;
  }
""",

'fragmentShader': """
  uniform vec3 uBaseColor;
  uniform vec3 uDirLightPos;
  uniform vec3 uDirLightColor;
  uniform vec3 uAmbientLightColor;
  varying vec3 vNormal;
  varying vec3 vRefract;
  void main() {
  float directionalLightWeighting = max(dot(normalize(vNormal), uDirLightPos), 0.0);
  vec3 lightWeighting = uAmbientLightColor + uDirLightColor * directionalLightWeighting;
  float intensity = smoothstep(- 0.5, 1.0, pow(length(lightWeighting), 20.0));
  intensity += length(lightWeighting) * 0.2;
  float cameraWeighting = dot(normalize(vNormal), vRefract);
  intensity += pow(1.0 - length(cameraWeighting), 6.0);
  intensity = intensity * 0.2 + 0.3;
  if (intensity < 0.50) {
  gl_FragColor = vec4(2.0 * intensity * uBaseColor, 1.0);
  } else {
  gl_FragColor = vec4(1.0 - 2.0 * (1.0 - intensity) * (1.0 - uBaseColor), 1.0);
  }
  }
"""};
final Map toon2 = {
'uniforms': {"uDirLightPos": new Uniform.vector3(0.0, 0.0, 0.0),
             "uDirLightColor": new Uniform.color(0xeeeeee),
              
             "uAmbientLightColor": new Uniform.color(0x050505),
              
             "uBaseColor": new Uniform.color(0xeeeeee),
             "uLineColor1": new Uniform.color(0x808080),
             "uLineColor2": new Uniform.color(0x000000),
             "uLineColor3": new Uniform.color(0x000000),
             "uLineColor4": new Uniform.color(0x000000)},
  
'vertexShader': """
  varying vec3 vNormal;
  void main() {
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  vNormal = normalize(normalMatrix * normal);
  }
""",

'fragmentShader': """
  uniform vec3 uBaseColor;
  uniform vec3 uLineColor1;
  uniform vec3 uLineColor2;
  uniform vec3 uLineColor3;
  uniform vec3 uLineColor4;
  uniform vec3 uDirLightPos;
  uniform vec3 uDirLightColor;
  uniform vec3 uAmbientLightColor;
  varying vec3 vNormal;
  void main() {
  float camera = max(dot(normalize(vNormal), vec3(0.0, 0.0, 1.0)), 0.4);
  float light = max(dot(normalize(vNormal), uDirLightPos), 0.0);
  gl_FragColor = vec4(uBaseColor, 1.0);
  if (length(uAmbientLightColor + uDirLightColor * light) < 1.00) {
  gl_FragColor *= vec4(uLineColor1, 1.0);
  }
  if (length(uAmbientLightColor + uDirLightColor * camera) < 0.50) {
  gl_FragColor *= vec4(uLineColor2, 1.0);
  }
  }
"""};

final Map hatching = {
'uniforms': {"uDirLightPos": new Uniform.vector3(0.0, 0.0, 0.0),
             "uDirLightColor": new Uniform.color(0xeeeeee),
            
             "uAmbientLightColor": new Uniform.color(0x050505),
            
             "uBaseColor": new Uniform.color(0xffffff),
             "uLineColor1": new Uniform.color(0x000000),
             "uLineColor2": new Uniform.color(0x000000),
             "uLineColor3": new Uniform.color(0x000000),
             "uLineColor4": new Uniform.color(0x000000)},
  
'vertexShader': """
  varying vec3 vNormal;
  void main() {
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  vNormal = normalize(normalMatrix * normal);
  }
""",

'fragmentShader': """
  uniform vec3 uBaseColor;
  uniform vec3 uLineColor1;
  uniform vec3 uLineColor2;
  uniform vec3 uLineColor3;
  uniform vec3 uLineColor4;
  uniform vec3 uDirLightPos;
  uniform vec3 uDirLightColor;
  uniform vec3 uAmbientLightColor;
  varying vec3 vNormal;
  void main() {
  float directionalLightWeighting = max(dot(normalize(vNormal), uDirLightPos), 0.0);
  vec3 lightWeighting = uAmbientLightColor + uDirLightColor * directionalLightWeighting;
  gl_FragColor = vec4(uBaseColor, 1.0);
  if (length(lightWeighting) < 1.00) {
  if (mod(gl_FragCoord.x + gl_FragCoord.y, 10.0) == 0.0) {
  gl_FragColor = vec4(uLineColor1, 1.0);
  }
  }
  if (length(lightWeighting) < 0.75) {
  if (mod(gl_FragCoord.x - gl_FragCoord.y, 10.0) == 0.0) {
  gl_FragColor = vec4(uLineColor2, 1.0);
  }
  }
  if (length(lightWeighting) < 0.50) {
  if (mod(gl_FragCoord.x + gl_FragCoord.y - 5.0, 10.0) == 0.0) {
  gl_FragColor = vec4(uLineColor3, 1.0);
  }
  }
  if (length(lightWeighting) < 0.3465) {
  if (mod(gl_FragCoord.x - gl_FragCoord.y - 5.0, 10.0) == 0.0) {
  gl_FragColor = vec4(uLineColor4, 1.0);
  }
  }
  }
"""};

final Map _dotted = {
'uniforms': {"uDirLightPos": new Uniform.vector3(0.0, 0.0, 0.0),
             "uDirLightColor": new Uniform.color(0xeeeeee),
            
             "uAmbientLightColor": new Uniform.color(0x050505),
             
             "uBaseColor": new Uniform.color(0xffffff),
             "uLineColor1": new Uniform.color(0x000000)},
  
'vertexShader': """
  varying vec3 vNormal;
  void main() {
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  vNormal = normalize(normalMatrix * normal);
  }
""",

'fragmentShader': """
  uniform vec3 uBaseColor;
  uniform vec3 uLineColor1;
  uniform vec3 uLineColor2;
  uniform vec3 uLineColor3;
  uniform vec3 uLineColor4;
  uniform vec3 uDirLightPos;
  uniform vec3 uDirLightColor;
  uniform vec3 uAmbientLightColor;
  varying vec3 vNormal;
  void main() {
  float directionalLightWeighting = max(dot(normalize(vNormal), uDirLightPos), 0.0);
  vec3 lightWeighting = uAmbientLightColor + uDirLightColor * directionalLightWeighting;
  gl_FragColor = vec4(uBaseColor, 1.0);
  if (length(lightWeighting) < 1.00) {
  if ((mod(gl_FragCoord.x, 4.001) + mod(gl_FragCoord.y, 4.0)) > 6.00) {
  gl_FragColor = vec4(uLineColor1, 1.0);
  }
  }
  if (length(lightWeighting) < 0.50) {
  if ((mod(gl_FragCoord.x + 2.0, 4.001) + mod(gl_FragCoord.y + 2.0, 4.0)) > 6.00) {
  gl_FragColor = vec4(uLineColor1, 1.0);
  }
  }
  }
"""};

/* TODO ?

abstract class dotted {
  static final Map<String, Uniform> uniforms = _dotted['uniforms'];
  static final String vertexShader = _dotted['vertexShader'];
  static final String fragmentShader = _dotted['fragmentShader'];
}

*/