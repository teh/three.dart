part of three;

class CombinedCamera extends Camera {
  double _fov;
  
  double left;
  double right;
  double top;
  double bottom;
  
  OrthographicCamera cameraO;
  PerspectiveCamera cameraP;
  
  double _zoom = 1.0;
  
  bool inPerspectiveMode;
  bool inOrthographicMode;
  
  double get fov => _fov;
  set fov(double fov) {
    this.fov = fov;

    if (inPerspectiveMode) {
      toPerspective();
    } else {
      toOrthographic();
    }
  }
  
  double get zoom => _zoom;
  set zoom(double zoom) {
    _zoom = zoom;

    if (inPerspectiveMode) {
      toPerspective();
    } else {
      toOrthographic();
    }
  }
  
  CombinedCamera(double width, 
                 double height, 
                 double fov,
                 double near, 
                 double far, 
                 double orthoNear, 
                 double orthoFar) {
    _fov = fov;
    
    left = -width / 2;
    right = width / 2;
    top = height / 2;
    bottom = -height / 2;
    
    cameraO = new OrthographicCamera(width / -2, width / 2, height / 2, height / -2, orthoNear, orthoFar);
    cameraP = new PerspectiveCamera(_fov, width / height, near, far);
    
    toPerspective();
  }
  
  void toPerspective() {
    // Switches to the Perspective Camera
    near = cameraP.near;
    far = cameraP.far;

    cameraP.fov = _fov / zoom;

    cameraP.updateProjectionMatrix();

    projectionMatrix = cameraP.projectionMatrix;

    inPerspectiveMode = true;
    inOrthographicMode = false;
  }
  
  void toOrthographic() {
    // Switches to the Orthographic camera estimating viewport from Perspective
    var aspect = cameraP.aspect;
    var near = cameraP.near;
    var far = cameraP.far;

    // The size that we set is the mid plane of the viewing frustum
    var hyperfocus = (near + far) / 2;

    var halfHeight = Math.tan(_fov / 2) * hyperfocus;
    var planeHeight = 2 * halfHeight;
    var planeWidth = planeHeight * aspect;
    var halfWidth = planeWidth / 2;

    halfHeight /= zoom;
    halfWidth /= zoom;

    cameraO.left = -halfWidth;
    cameraO.right = halfWidth;
    cameraO.top = halfHeight;
    cameraO.bottom = -halfHeight;

    cameraO.updateProjectionMatrix();

    near = cameraO.near;
    far = cameraO.far;
    projectionMatrix = cameraO.projectionMatrix;

    inPerspectiveMode = false;
    inOrthographicMode = true;
  }
  
  void setSize(double width, double height) {
    cameraP.aspect = width / height;
    left = -width / 2;
    right = width / 2;
    top = height / 2;
    bottom = -height / 2;
  }
  
  double setLens(double focalLength, [double frameHeight = 24.0]) =>
      (fov = 2 * MathUtils.radToDeg(Math.atan(frameHeight / (focalLength * 2))));
  
  void toFrontView() {
    rotation.x = 0.0;
    rotation.y = 0.0;
    rotation.z = 0.0;
    rotationAutoUpdate = false;
  }
  
  void toBackView() {
    rotation.x = 0.0;
    rotation.y = Math.PI;
    rotation.z = 0.0;
    rotationAutoUpdate = false;
  }
  
  void toLeftView() {
    rotation.x = 0.0;
    rotation.y = -Math.PI / 2;
    rotation.z = 0.0;
    rotationAutoUpdate = false;
  }
  
  void toRightView() {
    rotation.x = 0.0;
    rotation.y = Math.PI / 2;
    rotation.z = 0.0;
    rotationAutoUpdate = false;
  }
  
  void toTopView() {
    rotation.x = - Math.PI / 2;
    rotation.y = 0.0;
    rotation.z = 0.0;
    rotationAutoUpdate = false;
  }

  void toBottomView() {
    rotation.x = Math.PI / 2;
    rotation.y = 0.0;
    rotation.z = 0.0;
    rotationAutoUpdate = false;
  }
}