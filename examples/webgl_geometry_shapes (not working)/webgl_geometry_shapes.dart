import 'dart:html' hide Path;
import 'dart:async';
import 'dart:math' as Math;
import 'package:three/three.dart';
import 'package:three/extras/utils/scene_utils.dart' as SceneUtils;

WebGLRenderer renderer = new WebGLRenderer()
    ..setClearColor(0xf0f0f0)
    ..setSize(window.innerWidth, window.innerHeight);

PerspectiveCamera camera = new PerspectiveCamera(50.0, window.innerWidth / window.innerHeight, 1.0, 1000.0)
    ..position.setValues(0.0, 150.0, 500.0);

Object3D group = new Object3D()
    ..position.y = 50.0;

Scene scene = new Scene()
    ..add(new DirectionalLight(0xffffff)..position = new Vector3.backward())
    ..add(group);

double targetRotation = 0.0,
       targetRotationOnMouseDown = 0.0;

int mouseX = 0,
    mouseXOnMouseDown = 0;

int windowHalfX = window.innerWidth ~/ 2,
    windowHalfY = window.innerHeight ~/ 2;

StreamSubscription onDocumentMouseMoveSubscription,
                   onDocumentMouseUpSubscription,
                   onDocumentMouseOutSubscription;
    
void main() {
  init();
  animate(0);
}

void init() {
  document.body.append(new DivElement()..append(renderer.domElement));
  
  addShape(Shape shape, Map extrudeSettings, color, x, y, z, rx, ry, rz, s) {
    var points = shape.createPointsGeometry();
    var spacedPoints = shape.createSpacedPointsGeometry(100);

    // Flat shape.
    group.add(
        SceneUtils.createMultiMaterialObject(
            new ShapeGeometry([shape]), 
            [new MeshLambertMaterial(color: color), 
             new MeshBasicMaterial(color: 0x000000, wireframe: true, transparent: true)]) 
            ..position.setValues(x, y, z - 125.0)
            ..rotation.setValues(rx, ry, rz)
            ..scale.setValues(s, s, s));
    
    // 3D shape.
    group.add(
        SceneUtils.createMultiMaterialObject(
            new ExtrudeGeometry([shape], 
                amount: extrudeSettings["amount"], 
                bevelEnabled: extrudeSettings["bevelEnabled"], 
                bevelSegments: extrudeSettings["bevelSegments"], 
                steps: extrudeSettings["steps"], 
                extrudePath: extrudeSettings["extrudePath"]),
            [new MeshLambertMaterial(color: color), 
             new MeshBasicMaterial(color: 0x000000, wireframe: true, transparent: true)])
            ..position.setValues(x, y, z - 75.0)
            ..rotation.setValues(rx, ry, rz)
            ..scale.setValues(s, s, s));

    // Solid line.
    group.add(
        new Line(points, new LineBasicMaterial(color: color, linewidth: 2.0))
            ..position.setValues(x, y, z + 25.0)
            ..rotation.setValues(rx, ry, rz)
            ..scale.setValues(s, s, s));

    // Transparent line from real points.
    group.add(
        new Line(points, new LineBasicMaterial(color: color, opacity: 0.5))
            ..position.setValues(x, y, z + 75.0)
            ..rotation.setValues(rx, ry, rz)
            ..scale.setValues(s, s, s));

    // Vertices from real points.
    group.add(
        new ParticleSystem(points.clone(), new ParticleSystemMaterial(color: color, size: 2.0, opacity: 0.75))
            ..position.setValues(x, y, z + 75.0)
            ..rotation.setValues(rx, ry, rz)
            ..scale.setValues(s, s, s));

    // Transparent line from equidistance sampled points.
    group.add(
        new Line(spacedPoints, new LineBasicMaterial(color: color, opacity: 0.2))
            ..position.setValues(x, y, z + 125.0)
            ..rotation.setValues(rx, ry, rz)
            ..scale.setValues(s, s, s));

    // equidistance sampled points
    group.add(
        new ParticleSystem(spacedPoints.clone(), new ParticleSystemMaterial(color: color, size: 2.0, opacity: 0.5))
            ..position.setValues(x, y, z + 125.0)
            ..rotation.setValues(rx, ry, rz)
            ..scale.setValues(s, s, s));
  }

  /*
   *  California
   */
  
  var californiaPts = 
      [new Vector2(610.0, 320.0),
       new Vector2(450.0, 300.0),
       new Vector2(392.0, 392.0),
       new Vector2(266.0, 438.0),
       new Vector2(190.0, 570.0),
       new Vector2(160.0, 620.0),
       new Vector2(180.0, 640.0),
       new Vector2(165.0, 680.0),
       new Vector2(150.0, 670.0),
       new Vector2(90.0, 737.0),
       new Vector2(80.0, 795.0),
       new Vector2(50.0, 835.0),
       new Vector2(64.0, 870.0),
       new Vector2(60.0, 945.0),
       new Vector2(300.0, 945.0),
       new Vector2(300.0, 743.0),
       new Vector2(600.0, 473.0),
       new Vector2(626.0, 425.0),
       new Vector2(600.0, 370.0),
       new Vector2(610.0, 320.0)];

  var californiaShape = new Shape(californiaPts);

  /*
   *  Triangle
   */
  
  var triangleShape = new Shape()
      ..moveTo(new Vector2(80.0, 20.0))
      ..lineTo(new Vector2(40.0, 80.0))
      ..lineTo(new Vector2(120.0, 80.0))
      ..lineTo(new Vector2(80.0, 20.0)); // close path

  /*
   *  Heart
   */

  var heartShape = new Shape() // From http://blog.burlock.org/html5/130-paths
      ..moveTo(new Vector2(25.0, 25.0))
      ..bezierCurveTo(new Vector2(25.0, 25.0), new Vector2(20.0, 0.0),  new Vector2.zero())    
      ..bezierCurveTo(new Vector2(30.0, 0.0),  new Vector2(30.0, 35.0), new Vector2(30.0, 35.0))
      ..bezierCurveTo(new Vector2(30.0, 55.0), new Vector2(10.0, 77.0), new Vector2(25.0, 95.0))
      ..bezierCurveTo(new Vector2(60.0, 77.0), new Vector2(80.0, 55.0), new Vector2(80.0, 35.0))
      ..bezierCurveTo(new Vector2(80.0, 35.0), new Vector2(80.0, 0.0),  new Vector2(50.0, 0.0))
      ..bezierCurveTo(new Vector2(35.0, 0.0),  new Vector2(25.0, 25.0), new Vector2(25.0, 25.0));

  /*
   *  Square
   */

  var sqLength = 80.0;

  var squareShape = new Shape()
      ..moveTo(new Vector2.zero())
      ..lineTo(new Vector2(0.0, sqLength))
      ..lineTo(new Vector2(sqLength, sqLength))
      ..lineTo(new Vector2(sqLength, 0.0))
      ..lineTo(new Vector2.zero());

  /*
   *  Rectangle
   */

  var rectLength = 120.0, rectWidth = 40.0;

  var rectShape = new Shape()
      ..moveTo(new Vector2.zero())
      ..lineTo(new Vector2(0.0, rectWidth))
      ..lineTo(new Vector2(rectLength, rectWidth))
      ..lineTo(new Vector2(rectLength, 0.0))
      ..lineTo(new Vector2.zero());

  /*
   *  Rounded rectangle
   */

  var roundedRectShape = new Shape();

  // Round rectangle
  ((Shape ctx, width, height, radius) {
    ctx.moveTo(new Vector2(0.0, radius));
    ctx.lineTo(new Vector2(0.0, height - radius));
    ctx.quadraticCurveTo(new Vector2(0.0, height), new Vector2(radius, height));
    ctx.lineTo(new Vector2(width - radius, height));
    ctx.quadraticCurveTo(new Vector2(width, height), new Vector2(width, height - radius));
    ctx.lineTo(new Vector2(width, radius));
    ctx.quadraticCurveTo(new Vector2(width, 0.0), new Vector2(width - radius, 0.0));
    ctx.lineTo(new Vector2(radius, 0.0));
    ctx.quadraticCurveTo(new Vector2.zero(), new Vector2(0.0, radius));
  })(roundedRectShape, 50.0, 50.0, 20.0);

  /*
   *  Circle
   */

  var circleRadius = 40.0;
  var circleShape = new Shape()
      ..moveTo(new Vector2(0.0, circleRadius))
      ..quadraticCurveTo(new Vector2(circleRadius, circleRadius),   new Vector2(circleRadius, 0.0))
      ..quadraticCurveTo(new Vector2(circleRadius, -circleRadius),  new Vector2(0.0, -circleRadius))
      ..quadraticCurveTo(new Vector2(-circleRadius, -circleRadius), new Vector2(-circleRadius, 0.0))
      ..quadraticCurveTo(new Vector2(-circleRadius, circleRadius),  new Vector2(0.0, circleRadius));

  /*
   *  Fish
   */

  var fishShape = new Shape()
      ..moveTo(new Vector2.zero())
      ..quadraticCurveTo(new Vector2(50.0, 80.0),  new Vector2(90.0, 10.0))
      ..quadraticCurveTo(new Vector2(100.0, 10.0), new Vector2(115.0, 40.0))
      ..quadraticCurveTo(new Vector2(115.0, 0.0),  new Vector2(115.0, 40.0))
      ..quadraticCurveTo(new Vector2(100.0, 10.0), new Vector2(90.0, 10.0))
      ..quadraticCurveTo(new Vector2(50.0, 80.0),  new Vector2.zero());

  /*
   * Arc circle
   */

  var arcShape = new Shape()
      ..moveTo(new Vector2(50.0, 10.0))
      ..absarc(new Vector2(10.0, 10.0), 40.0, 0.0, Math.PI * 2, false);

  var holePath = new Path()
      ..moveTo(new Vector2(20.0, 10.0))
      ..absarc(new Vector2(10.0, 10.0), 10.0, 0.0, Math.PI * 2, true);
  
  arcShape.holes.add(holePath);

  /*
   *  Smiley
   */

  var smileyShape = new Shape()
      ..moveTo(new Vector2(80.0, 40.0))
      ..absarc(new Vector2(40.0, 40.0), 40.0, 0.0, Math.PI * 2, false);

  var smileyEye1Path = new Path()
      ..moveTo(new Vector2(35.0, 20.0))
      ..absellipse(new Vector2(25.0, 20.0), new Vector2(10.0, 10.0), 0.0, Math.PI*  2, true);

  var smileyEye2Path = new Path()
      ..moveTo(new Vector2(65.0, 20.0))
      ..absarc(new Vector2(55.0, 20.0), 10.0, 0.0, Math.PI * 2, true);  

  var smileyMouthPath = new Path()
      ..moveTo(new Vector2(20.0, 40.0))
      ..quadraticCurveTo(new Vector2(40.0, 60.0), new Vector2(60.0, 40.0))
      ..bezierCurveTo(new Vector2(70.0, 45.0), new Vector2(70.0, 50.0), new Vector2(60.0, 60.0))
      ..quadraticCurveTo(new Vector2(40.0, 80.0), new Vector2(20.0, 60.0))
      ..quadraticCurveTo(new Vector2(5.0, 50.0), new Vector2(20.0, 40.0));
  
  smileyShape.holes.addAll([smileyEye1Path, smileyEye2Path, smileyMouthPath]);


  // Spline shape + path extrusion

  var splinepts = 
      [new Vector2(350.0, 100.0),
       new Vector2(400.0, 450.0),
       new Vector2(-140.0, 350.0),
       new Vector2.zero()];

  var splineShape = new Shape()
      ..moveTo(new Vector2.zero())
      ..splineThru(splinepts);

  var apath = new SplineCurve3()
      ..points.add(new Vector3(-50.0, 150.0, 10.0))
      ..points.add(new Vector3(-20.0, 180.0, 20.0))
      ..points.add(new Vector3(40.0, 220.0, 50.0))
      ..points.add(new Vector3(200.0, 290.0, 100.0));


  var extrudeSettings = {"amount": 20,
                         "bevelEnabled": true,
                         "bevelSegments": 3,
                         "steps": 1}; 

  // addShape(shape, color, x, y, z, rx, ry, rz, s);

  addShape(californiaShape, extrudeSettings, 0xffaa00, -300.0, -100.0, 0.0, 0.0, 0.0, 0.0, 0.25);

  extrudeSettings["bevelSegments"] = 2;
  extrudeSettings["steps"] = 2;

  addShape(triangleShape,    extrudeSettings, 0xffee00, -180.0, 0.0,   0.0, 0.0, 0.0, 0.0,     1.0);
  addShape(roundedRectShape, extrudeSettings, 0x005500, -150.0, 150.0, 0.0, 0.0, 0.0, 0.0,     1.0);
  addShape(squareShape,      extrudeSettings, 0x0055ff,  150.0, 100.0, 0.0, 0.0, 0.0, 0.0,     1.0);
  addShape(heartShape,       extrudeSettings, 0xff1100,  60.0,  100.0, 0.0, 0.0, 0.0, Math.PI, 1.0);
  addShape(circleShape,      extrudeSettings, 0x00ff11,  120.0, 250.0, 0.0, 0.0, 0.0, 0.0,     1.0);
  addShape(fishShape,        extrudeSettings, 0x222222, -60.0,  200.0, 0.0, 0.0, 0.0, 0.0,     1.0);
  addShape(smileyShape,      extrudeSettings, 0xee00ff, -200.0, 250.0, 0.0, 0.0, 0.0, Math.PI, 1.0);
  addShape(arcShape,         extrudeSettings, 0xbb4422,  150.0, 0.0,   0.0, 0.0, 0.0, 0.0,     1.0);

  extrudeSettings["extrudePath"] = apath;
  extrudeSettings["bevelEnabled"] = false;
  extrudeSettings["steps"] = 20;

  addShape(splineShape, extrudeSettings, 0x888888, -50.0, -100.0, -50.0, 0.0, 0.0, 0.0, 0.2);
  
  document.onMouseDown.listen(onDocumentMouseDown);
  
  onDocumentMouseMoveSubscription = document.onMouseMove.listen(onDocumentMouseMove)..pause();
  onDocumentMouseUpSubscription = document.onMouseUp.listen(onDocumentMouseUp)..pause();
  onDocumentMouseOutSubscription = document.onMouseOut.listen(onDocumentMouseOut)..pause();
  
  window.onResize.listen(onWindowResize);
}       

void onWindowResize(Event e) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}


void onDocumentMouseDown(MouseEvent event) {
  event.preventDefault();

  onDocumentMouseMoveSubscription.resume();
  onDocumentMouseUpSubscription.resume();
  onDocumentMouseOutSubscription.resume();
  
  mouseXOnMouseDown = event.client.x - windowHalfX;
  targetRotationOnMouseDown = targetRotation;
}

void onDocumentMouseMove(MouseEvent event) {
  mouseX = event.client.x - windowHalfX;
  
  targetRotation = targetRotationOnMouseDown + (mouseX - mouseXOnMouseDown) * 0.02;
}


void onDocumentMouseUp(MouseEvent event) {
  onDocumentMouseMoveSubscription.pause();
  onDocumentMouseUpSubscription.pause();
  onDocumentMouseOutSubscription.pause();
}

void onDocumentMouseOut(MouseEvent event) {
  onDocumentMouseMoveSubscription.pause();
  onDocumentMouseUpSubscription.pause();
  onDocumentMouseOutSubscription.pause();
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  group.rotation.y += (targetRotation - group.rotation.y) * 0.05;
  renderer.render(scene, camera);
}