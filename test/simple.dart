import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:three/three.dart';
import 'dart:html';
import 'package:three/extras/utils/math_utils.dart' as MathUtils;


void typed() {
  WebGLRenderer renderer = new WebGLRenderer()..setSize(window.innerWidth,
      window.innerHeight);

  PerspectiveCamera camera = new PerspectiveCamera(45.0, window.innerWidth /
      window.innerHeight, 1.0, 2000.0)..position.y = 400.0;

  Scene scene = new Scene()
      ..add(new DirectionalLight(0xffffff)..position.setValues(0.0, 1.0, 0.0))
      ..add(new AmbientLight(0x404040))
      ..add(new AxisHelper(50.0)..position.setValues(200.0, 0.0, -200.0))
      ..add(new ArrowHelper(new Vector3.up(), new Vector3.zero(), 50.0
          )..position.setValues(400.0, 0.0, -200.0));
  renderer.render(scene, camera);
}

void imaterialBug() {
  // Test failed: Caught type 'ParticleSystemMaterial' is not a
  // subtype of type 'ITextureMaterial' in type cast.
  WebGLRenderer renderer = new WebGLRenderer()..setSize(window.innerWidth,
      window.innerHeight);

  PerspectiveCamera camera = new PerspectiveCamera(45.0, window.innerWidth /
      window.innerHeight, 1.0, 2000.0)..position.y = 400.0;
  var geometry = new Geometry()..vertices = new List.generate(10000, (i) =>
      new Vector3(MathUtils.randFloatSpread(2000.0), MathUtils.randFloatSpread(2000.0
      ), MathUtils.randFloatSpread(2000.0)));
  Scene scene = new Scene();
  scene.add(new ParticleSystem(geometry, new ParticleSystemMaterial(color:
      0x888888)));
  renderer.render(scene, camera);
}

void pointLightBug() {
  // Test failed: Caught type 'ParticleSystemMaterial' is not a
  // subtype of type 'ITextureMaterial' in type cast.
  WebGLRenderer renderer = new WebGLRenderer()..setSize(window.innerWidth,
      window.innerHeight);

  OrthographicCamera camera = new OrthographicCamera(-10.0, -10.0, 10.0, 10.0,
      0.1, 1.0);
  Scene scene = new Scene();
  Mesh sphere = new Mesh(new SphereGeometry(40.0, 10, 10),
      new MeshLambertMaterial(color: 0xaa00aa));
  scene.add(sphere);

  PointLight pl = new PointLight(0xffffff, .8, 100.0);
  pl.position = new Vector3(10.0, 20.0, -100.0);
  scene.add(pl);

  renderer.render(scene, camera);
}

void main() {
  test("typed array bug", typed);
  test("imaterial bug", imaterialBug);
  test("point light array size bug", pointLightBug);
  var g = new Geometry();
}
