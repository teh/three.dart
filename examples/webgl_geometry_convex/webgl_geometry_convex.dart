import 'dart:html';
import 'dart:math' as Math;
import 'package:three/three.dart';
import 'package:three/extras/utils/image_utils.dart' as ImageUtils;
import 'package:three/extras/utils/scene_utils.dart' as SceneUtils;

Renderer renderer = new WebGLRenderer(antialias: true)
    ..setSize(window.innerWidth, window.innerHeight);

PerspectiveCamera camera = new PerspectiveCamera(45.0, window.innerWidth / window.innerHeight, 1.0, 2000.0)
    ..position.y = 400.0;

Scene scene = new Scene()
..add(new AmbientLight(0x404040))
..add(new DirectionalLight(0xffffff)..position = new Vector3.up());

Math.Random rnd = new Math.Random();

void main() {
  init();
  animate(0);
}

void init() {
  document.body.append(new DivElement()..append(renderer.domElement));

  var materials, points;

  var map = ImageUtils.loadTexture('textures/UV_Grid_Sm.jpg');
  map.wrapS = map.wrapT = REPEAT_WRAPPING;
  map.anisotropy = 16;

  materials = 
      [new MeshLambertMaterial(ambient: 0xbbbbbb, map: map),
       new MeshBasicMaterial(color: 0xffffff, wireframe: true, transparent: true, opacity: 0.1)];


  // tetrahedron
  points = 
      [new Vector3(100.0, 0.0, 0.0),
       new Vector3(0.0, 100.0, 0.0),
       new Vector3(0.0, 0.0, 100.0),
       new Vector3.zero()];

  scene.add(
      SceneUtils.createMultiMaterialObject(new ConvexGeometry(points), materials)
          ..position.setZero());

  // cube

  points = 
      [new Vector3.splat(50.0),
       new Vector3(50.0, 50.0, -50.0),
       new Vector3(-50.0, 50.0, -50.0),
       new Vector3(-50.0, 50.0, 50.0),
       new Vector3(50.0, -50.0, 50.0),
       new Vector3(50.0, -50.0, -50.0),
       new Vector3.splat(-50.0),
       new Vector3(-50.0, -50.0, 50.0)];

  scene.add(
      SceneUtils.createMultiMaterialObject(new ConvexGeometry(points), materials)
          ..position.setValues(-200.0, 0.0, -200.0));
  
  randomPointInSphere(double radius) =>
      new Vector3((rnd.nextDouble() - 0.5) * 2 * radius,
                  (rnd.nextDouble() - 0.5) * 2 * radius,
                  (rnd.nextDouble() - 0.5) * 2 * radius);
  
  // random convex
  points = new List.generate(30, (i) => randomPointInSphere(50.0));

  scene.add(
      SceneUtils.createMultiMaterialObject(new ConvexGeometry(points), materials)
          ..position.setValues(-200.0, 0.0, 200.0));

  scene.add(
      new AxisHelper(50.0)
          ..position.setValues(200.0, 0.0, -200.0));

  scene.add(
      new ArrowHelper(new Vector3.up(), new Vector3.zero(), 50.0)
          ..position.setValues(200.0, 0.0, 400.0));

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
  var timer = new DateTime.now().millisecondsSinceEpoch * 0.0001;
  
  camera.position.x = Math.cos(timer) * 800;
  camera.position.z = Math.sin(timer) * 800;

  camera.lookAt(scene.position);

  scene.children.forEach((object) {
    object.rotation.x = timer * 5;
    object.rotation.y = timer * 2.5;
  });
  
  renderer.render(scene, camera);
}