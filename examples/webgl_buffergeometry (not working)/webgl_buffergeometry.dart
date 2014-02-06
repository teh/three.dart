import 'dart:html';
import 'dart:math' as Math;
import 'package:three/three.dart';

WebGLRenderer renderer = new WebGLRenderer(antialias: false)
    ..setClearColor(scene.fog.color, 1)
    ..setSize(window.innerWidth, window.innerHeight)
    ..gammaInput = true
    ..gammaOutput = true;

PerspectiveCamera camera = new PerspectiveCamera(27.0, window.innerWidth / window.innerHeight, 1.0, 3500.0)
    ..position.z = 2750.0;

Mesh mesh;

Scene scene = new Scene()
    ..fog = new FogLinear(0x050505, 2000.0, 3500.0)
    ..add(new AmbientLight(0x444444))
    ..add(new DirectionalLight(0xffffff, 0.5)..position = new Vector3.splat(1.0))
    ..add(new DirectionalLight(0xffffff, 1.5)..position = new Vector3.down());

Math.Random rnd = new Math.Random();

void main() {
  init();
  animate(0);
}

void init() {
  document.body.append(new DivElement()..append(renderer.domElement));

  var triangles = 160000;

  var geometry = new BufferGeometry()
      ..aIndex = new GeometryAttribute.int16(triangles * 3, 1)
      ..aPosition = new GeometryAttribute.float32(triangles * 3, 3)
      ..aNormal = new GeometryAttribute.float32(triangles * 3, 3)
      ..aColor = new GeometryAttribute.float32(triangles * 3, 3);

  // break geometry into
  // chunks of 21,845 triangles (3 unique vertices per triangle)
  // for indices to fit into 16 bit integer number
  // floor(2^16 / 3) = 21845

  var chunkSize = 21845;

  var indices = geometry.aIndex.array;

  for (var i = 0; i < indices.length; i++) {
    indices[i] = i % (3 * chunkSize);
  }

  var positions = geometry.aPosition.array;
  var normals = geometry.aNormal.array;
  var colors = geometry.aColor.array;

  var color = new Color.white();

  var n = 800, n2 = n / 2;   // Triangles spread in the cube.
  var d = 12, d2 = d / 2;    // Individual triangle size.

  for (var i = 0; i < positions.length; i += 9) {
    // positions
    var x = rnd.nextDouble() * n - n2;
    var y = rnd.nextDouble() * n - n2;
    var z = rnd.nextDouble() * n - n2;

    var ax = x + rnd.nextDouble() * d - d2;
    var ay = y + rnd.nextDouble() * d - d2;
    var az = z + rnd.nextDouble() * d - d2;

    var bx = x + rnd.nextDouble() * d - d2;
    var by = y + rnd.nextDouble() * d - d2;
    var bz = z + rnd.nextDouble() * d - d2;

    var cx = x + rnd.nextDouble() * d - d2;
    var cy = y + rnd.nextDouble() * d - d2;
    var cz = z + rnd.nextDouble() * d - d2;

    positions[i]     = ax;
    positions[i + 1] = ay;
    positions[i + 2] = az;

    positions[i + 3] = bx;
    positions[i + 4] = by;
    positions[i + 5] = bz;

    positions[i + 6] = cx;
    positions[i + 7] = cy;
    positions[i + 8] = cz;

    // flat face normals
    var pA = new Vector3(ax, ay, az);
    var pB = new Vector3(bx, by, bz);
    var pC = new Vector3(cx, cy, cz);

    var cb = (pC - pB).cross(pA - pB).normalize();

    var nx = cb.x;
    var ny = cb.y;
    var nz = cb.z;

    normals[i]     = nx;
    normals[i + 1] = ny;
    normals[i + 2] = nz;

    normals[i + 3] = nx;
    normals[i + 4] = ny;
    normals[i + 5] = nz;
    
    normals[i + 6] = nx;
    normals[i + 7] = ny;
    normals[i + 8] = nz;

    // colors
    var vx = (x / n) + 0.5;
    var vy = (y / n) + 0.5;
    var vz = (z / n) + 0.5;

    color.setRGB(vx, vy, vz);

    colors[i]     = color.r;
    colors[i + 1] = color.g;
    colors[i + 2] = color.b;

    colors[i + 3] = color.r;
    colors[i + 4] = color.g;
    colors[i + 5] = color.b;

    colors[i + 6] = color.r;
    colors[i + 7] = color.g;
    colors[i + 8] = color.b;
  }

  var offsets = triangles ~/ chunkSize;
  
  geometry.offsets = new List.generate(offsets, (i) =>
      new Chunk(start: i * chunkSize * 3,
          index: i * chunkSize * 3,
          count: Math.min(triangles - (i * chunkSize), chunkSize) * 3));

  geometry.computeBoundingSphere();

  var material = new MeshPhongMaterial(
      color: 0xaaaaaa, ambient: 0xaaaaaa, specular: 0xffffff, shininess: 250.0,
      side: DOUBLE_SIDE, vertexColors: VERTEX_COLORS);

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
 var time = new DateTime.now().millisecondsSinceEpoch * 0.001;
  
  mesh.rotation.x = time * 0.25;
  mesh.rotation.y = time * 0.5;

  renderer.render(scene, camera);
}