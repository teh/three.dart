import 'dart:html';
import 'package:three/three.dart';
import 'package:unittest/unittest.dart';

void typed() {
  WebGLRenderer renderer = new WebGLRenderer()
      ..setSize(window.innerWidth, window.innerHeight);

  PerspectiveCamera camera = new PerspectiveCamera(45.0, window.innerWidth / window.innerHeight, 1.0, 2000.0)
      ..position.y = 400.0;

  Scene scene = new Scene()
      ..add(new DirectionalLight(0xffffff)..position.setValues(0.0, 1.0, 0.0))
      ..add(new AmbientLight(0x404040))
      ..add(new AxisHelper(50.0)..position.setValues(200.0, 0.0, -200.0))
      ..add(new ArrowHelper(new Vector3.up(), new Vector3.zero(), 50.0)..position.setValues(400.0, 0.0, -200.0));
  renderer.render(scene, camera);
}

void main() {
  test("typed array bug", typed);
  var g = new Geometry();
}
