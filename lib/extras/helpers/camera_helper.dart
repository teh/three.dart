/*
 * @author alteredq / http://alteredqualia.com/
 *
 *  - shows frustum, line of sight and up of the camera
 *  - suitable for fast updates
 *  - based on frustum visualization in lightgl.js shadowmap example
 *    http://evanw.github.com/lightgl.js/tests/shadowmap.html
 */

part of three;

class CameraHelper extends Line {
  Camera camera;
  
  Map pointMap = {};

  CameraHelper(this.camera) 
      : super(new Geometry(), new LineBasicMaterial(color: 0xffffff, vertexColors: FACE_COLORS), 
              LINE_PIECES) {
    // colors
    var hexFrustum = 0xffaa00;
    var hexCone = 0xff0000;
    var hexUp = 0x00aaff;
    var hexTarget = 0xffffff;
    var hexCross = 0x333333;

    // near
    addLine("n1", "n2", hexFrustum);
    addLine("n2", "n4", hexFrustum);
    addLine("n4", "n3", hexFrustum);
    addLine("n3", "n1", hexFrustum);

    // far
    addLine("f1", "f2", hexFrustum);
    addLine("f2", "f4", hexFrustum);
    addLine("f4", "f3", hexFrustum);
    addLine("f3", "f1", hexFrustum);

    // sides
    addLine("n1", "f1", hexFrustum);
    addLine("n2", "f2", hexFrustum);
    addLine("n3", "f3", hexFrustum);
    addLine("n4", "f4", hexFrustum);

    // cone
    addLine("p", "n1", hexCone);
    addLine("p", "n2", hexCone);
    addLine("p", "n3", hexCone);
    addLine("p", "n4", hexCone);

    // up
    addLine("u1", "u2", hexUp);
    addLine("u2", "u3", hexUp);
    addLine("u3", "u1", hexUp);

    // target
    addLine("c", "t", hexTarget);
    addLine("p", "c", hexCross);

    // cross
    addLine("cn1", "cn2", hexCross);
    addLine("cn3", "cn4", hexCross);

    addLine("cf1", "cf2", hexCross);
    addLine("cf3", "cf4", hexCross);
    
    matrixWorld = camera.matrixWorld;
    matrixAutoUpdate = false;

    update();
  }

  void addLine(String a, String b, int hex) {
    addPoint(a, hex);
    addPoint(b, hex);
  }

  void addPoint(String id, int hex) {
    geometry.vertices.add(new Vector3.zero());
    geometry.colors.add(new Color(hex));

    if (!pointMap.containsKey(id)) { 
      pointMap[id] = [];
    }

    pointMap[id].add(geometry.vertices.length - 1);
  }

  void update() {
    var vector = new Vector3.zero();
    var camera = new Camera();
    var projector = new Projector();
    
    var setPoint = (String point, double x, double y, double z) {
      vector.setValues(x, y, z);
      projector.unprojectVector(vector, camera);

      var points = pointMap[point];

      if (points != null) {
        points.forEach((point) => geometry.vertices[point].setFrom(vector));
      }
    };
    
    var w = 1.0, h = 1.0;

    camera.projectionMatrix.setFrom(camera.projectionMatrix);

    // center / target
    setPoint("c", 0.0, 0.0, -1.0);
    setPoint("t", 0.0, 0.0,  1.0);

    // near
    setPoint("n1", -w, -h, -1.0);
    setPoint("n2",  w, -h, -1.0);
    setPoint("n3", -w,  h, -1.0);
    setPoint("n4",  w,  h, -1.0);

    // far
    setPoint("f1", -w, -h, 1.0);
    setPoint("f2",  w, -h, 1.0);
    setPoint("f3", -w,  h, 1.0);
    setPoint("f4",  w,  h, 1.0);

    // up
    setPoint("u1",  w * 0.7, h * 1.1, -1.0);
    setPoint("u2", -w * 0.7, h * 1.1, -1.0);
    setPoint("u3",      0.0, h * 2.0, -1.0);

    // cross
    setPoint("cf1", -w,  0.0, 1.0);
    setPoint("cf2",  w,  0.0, 1.0);
    setPoint("cf3",  0.0, -h, 1.0);
    setPoint("cf4",  0.0,  h, 1.0);

    setPoint("cn1", -w,  0.0, -1.0);
    setPoint("cn2",  w,  0.0, -1.0);
    setPoint("cn3",  0.0, -h, -1.0);
    setPoint("cn4",  0.0,  h, -1.0);

    geometry.verticesNeedUpdate = true;
  }
}


