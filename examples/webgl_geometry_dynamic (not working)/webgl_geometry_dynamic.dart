import 'dart:html';
import 'dart:math' as Math;
import 'package:three/three.dart';
import 'package:three/extras/controls.dart';
import 'package:three/extras/utils/image_utils.dart' as ImageUtils;

WebGLRenderer renderer = new WebGLRenderer(antialias: true)
    ..setSize(window.innerWidth, window.innerHeight)
    ..setClearColor(0xaaccff, 1);

PerspectiveCamera camera = new PerspectiveCamera(60.0, window.innerWidth / window.innerHeight, 1.0, 20000.0)
    ..position.y = 200.0;

FirstPersonControls controls = new FirstPersonControls(camera)
    ..movementSpeed = 500.0
    ..lookSpeed = 0.1;

Clock clock = new Clock();

int worldWidth = 128, worldDepth = 128;

Geometry geometry = new PlaneGeometry(20000.0, 20000.0, worldWidth - 1, worldDepth - 1)
    ..applyMatrix(new Matrix4.rotationX(-Math.PI / 2))
    ..dynamic = true;

Mesh mesh;

Scene scene = new Scene()
    ..fog = new FogExp2(0xaaccff, 0.0007);

Math.Random rnd = new Math.Random();

void main() {
  init();
  animate(0);
}

void init() {
  document.body.append(new DivElement()..append(renderer.domElement));
  
  for (var i = 0; i < geometry.vertices.length; i++) {
    geometry.vertices[i].y = 5 * Math.sin(i / 2);
  }

  geometry.computeFaceNormals();
  geometry.computeVertexNormals();

  
  var texture = ImageUtils.loadTexture("textures/water.jpg")
      ..wrapS = REPEAT_WRAPPING
      ..wrapT = REPEAT_WRAPPING
      ..repeat.setValues(5.0, 5.0);

  var material = new MeshBasicMaterial(color: 0x0044ff, map: texture);

  mesh = new Mesh(geometry, material);
  scene.add(mesh);
  
  window.onResize.listen(onWindowResize);
}

void onWindowResize(Event e) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
  
  controls.handleResize();
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  var delta = clock.getDelta(),
      time = clock.elapsedTime * 10;


  controls.update(delta);
  renderer.render(scene, camera);
}