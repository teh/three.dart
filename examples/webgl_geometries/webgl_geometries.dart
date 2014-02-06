import 'dart:html';
import 'dart:math' as Math;
import 'package:three/three.dart';
import 'package:three/extras/utils/image_utils.dart' as ImageUtils;

WebGLRenderer renderer = new WebGLRenderer()
    ..setSize(window.innerWidth, window.innerHeight);

PerspectiveCamera camera = new PerspectiveCamera(45.0, window.innerWidth / window.innerHeight, 1.0, 2000.0)
    ..position.y = 400.0;

Scene scene = new Scene()
    ..add(new DirectionalLight(0xffffff)..position.setValues(0.0, 1.0, 0.0))
    ..add(new AmbientLight(0x404040))
    ..add(new AxisHelper(50.0)..position.setValues(200.0, 0.0, -200.0))
    ..add(new ArrowHelper(new Vector3.up(), new Vector3.zero(), 50.0)..position.setValues(400.0, 0.0, -200.0));

void main() {
  init();
  animate(0);
}

void init() {
  document.body.append(new DivElement()..append(renderer.domElement));

  var map = ImageUtils.loadTexture('textures/UV_Grid_Sm.jpg');
  map.wrapS = map.wrapT = REPEAT_WRAPPING;
  map.anisotropy = 16;

  var material = new MeshLambertMaterial(ambient: 0xbbbbbb, map: map, side: DOUBLE_SIDE);

  scene.add(
      new Mesh(new SphereGeometry(75.0, 20, 10), material)
          ..position.setValues(-400.0, 0.0, 200.0));
  
  scene.add(
      new Mesh(new IcosahedronGeometry(75.0, 1), material)
          ..position.setValues(-200.0, 0.0, 200.0));

  scene.add(
      new Mesh(new OctahedronGeometry(75.0, 2), material)
          ..position.setValues(0.0, 0.0, 200.0));
  
  scene.add(
      new Mesh(new TetrahedronGeometry(75.0, 0), material)
          ..position.setValues(200.0, 0.0, 200.0));

  scene.add(
      new Mesh(new PlaneGeometry(100.0, 100.0, 4, 4), material)
          ..position.setValues(-400.0, 0.0, 0.0));

  scene.add(
      new Mesh(new CubeGeometry(100.0, 100.0, 100.0, 4, 4, 4), material)
          ..position.setValues(-200.0, 0.0, 0.0));
  
  scene.add(
      new Mesh(new CircleGeometry(50.0, 20, 0.0, Math.PI * 2), material)
          ..position.setZero());

  scene.add(
      new Mesh(new RingGeometry(10.0, 50.0, 20, 5, 0.0, Math.PI * 2), material)
          ..position.setValues(200.0, 0.0, 0.0));

  scene.add(
      new Mesh(new CylinderGeometry(25.0, 75.0, 100.0, 40, 5), material)
          ..position.setValues(400.0, 0.0, 0.0));

  var points = new List.generate(50, (i) => 
      new Vector3(Math.sin(i * 0.2) * Math.sin(i * 0.1) * 15 + 50, 0.0, (i - 5) * 2.0));
  
  scene.add(
      new Mesh(new LatheGeometry(points, 20), material)
      ..position.setValues(-400.0, 0.0, -200.0));

  scene.add(
      new Mesh(new TorusGeometry(50.0, 20.0, 20, 20), material)
          ..position.setValues(-200.0, 0.0, -200.0));

  scene.add(
      new Mesh(new TorusKnotGeometry(50.0, 10.0, 50, 20), material)
          ..position.setValues(0.0, 0.0, -200.0));
  
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
  var timer = new DateTime.now().millisecondsSinceEpoch * 0.0001;

  camera.position.x = Math.cos(timer) * 800.0;
  camera.position.z = Math.sin(timer) * 800.0;

  camera.lookAt(scene.position);

  scene.children.forEach((object) {
    object.rotation.x = timer * 5.0;
    object.rotation.y = timer * 2.5;
  });
  
  renderer.render(scene, camera);
}