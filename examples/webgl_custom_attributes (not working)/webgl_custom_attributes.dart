import 'dart:html';
import 'dart:math' as Math;
import 'package:three/three.dart';
import 'package:three/extras/utils/image_utils.dart' as ImageUtils;

Renderer renderer = new WebGLRenderer()
    ..setClearColor(0x050505, 1)
    ..setSize(window.innerWidth, window.innerHeight);

PerspectiveCamera camera = new PerspectiveCamera(30.0, window.innerWidth / window.innerHeight, 1.0, 10000.0)
    ..position.z = 300.0;

Uniform<double> amplitude = new Uniform.float(1.0);

Uniform<Color> color = new Uniform.color(0xff2200);

Uniform<Texture> texture = new Uniform.texture(
    ImageUtils.loadTexture("textures/water.jpg")
        ..wrapS = REPEAT_WRAPPING
        ..wrapT = REPEAT_WRAPPING);

Attribute<double> displacement = new Attribute.float();

Mesh sphere;

List<double> noise;

Scene scene = new Scene();

Math.Random rnd = new Math.Random();

void main() {
  init();
  animate(0);
}

void init() {
  document.body.append(new DivElement()..append(renderer.domElement));

  var shaderMaterial = new ShaderMaterial(
      uniforms: {"amplitude": amplitude,
                 "color": color,
                 "texture": texture},
      attributes: {"displacement": displacement},
      vertexShader: vertexShader,
      fragmentShader: fragmentShader);

  var radius = 50.0,
      segments = 128,
      rings = 64;

  var geometry = new SphereGeometry(radius, segments, rings)
      ..dynamic = true;

  sphere = new Mesh(geometry, shaderMaterial);

  scene.add(sphere);

  var vertices = sphere.geometry.vertices;

  noise = new List.generate(vertices.length, (_) => rnd.nextDouble() * 5);
  displacement.value = new List.filled(vertices.length, 0.0);

  window.onResize.listen(onWindowResize);
}

void onWindowResize(event) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}


void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  var time = new DateTime.now().millisecondsSinceEpoch * 0.01;

  sphere.rotation.y = sphere.rotation.z = 0.01 * time;

  amplitude.value = 2.5 * Math.sin(sphere.rotation.y * 0.125);
  color.value.offsetHSL(0.0005, 0.0, 0.0);

  for (var i = 0; i < displacement.value.length; i++) {
    displacement.value[i] = Math.sin(0.1 * i + time);

    noise[i] += 0.5 * (0.5 - rnd.nextDouble());
    noise[i] = noise[i].clamp(-5.0, 5.0);

    displacement.value[i] += noise[i];
  }

  displacement.needsUpdate = true;

  renderer.render(scene, camera);
}

final String vertexShader= """
uniform float amplitude;

attribute float displacement;

varying vec3 vNormal;
varying vec2 vUv;

void main() {
  vNormal = normal;
  vUv = (0.5 + amplitude) * uv + vec2(amplitude);
  
  vec3 newPosition = position + amplitude * normal * vec3(displacement);
  gl_Position = projectionMatrix * modelViewMatrix * vec4(newPosition, 1.0);
}
""";

final String fragmentShader = """
varying vec3 vNormal;
varying vec2 vUv;

uniform vec3 color;
uniform sampler2D texture;

void main() {
  vec3 light = vec3(0.5, 0.2, 1.0);
  light = normalize(light);
  
  float dProd = dot(vNormal, light) * 0.5 + 0.5;
  
  vec4 tcolor = texture2D(texture, vUv);
  vec4 gray = vec4(vec3(tcolor.r * 0.3 + tcolor.g * 0.59 + tcolor.b * 0.11), 1.0);
  
  gl_FragColor = gray * vec4(vec3(dProd) * vec3(color), 1.0);
}
""";