import 'dart:html';
import 'package:three/three.dart';
import 'package:three/extras/utils/image_utils.dart' as ImageUtils;

WebGLRenderer renderer = new WebGLRenderer()
    ..setSize(window.innerWidth, window.innerHeight);

PerspectiveCamera camera = new PerspectiveCamera(70.0, window.innerWidth / window.innerHeight, 1.0, 1000.0)
    ..position.z = 400.0;

Mesh mesh;

Scene scene = new Scene();

void main() {
  init();
  animate(0);
}

void init() {
  document.body.append(new DivElement()..append(renderer.domElement));

  var geometry = new CubeGeometry(200.0, 200.0, 200.0);
  
  var texture = ImageUtils.loadTexture('textures/crate.gif')
      ..anisotropy = renderer.maxAnisotropy;

  var material = new MeshBasicMaterial(map: texture);

  mesh = new Mesh(geometry, material);
  scene.add(mesh);

  window.onResize.listen(onWindowResize);
}

void onWindowResize(Event e) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  mesh.rotation.x += 0.005;
  mesh.rotation.y += 0.01;

  renderer.render(scene, camera);
}