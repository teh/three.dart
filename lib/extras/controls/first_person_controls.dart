part of controls;

class FirstPersonControls {
  Object3D object;
  Vector3 target = new Vector3.zero();
  
  var domElement; // HtmlDocument or Element
  
  double movementSpeed = 1.0;
  double lookSpeed = 0.005;
  
  bool lookVertical = true;
  bool autoForward = false;
  
  bool activeLook = true;
  
  bool heightSpeed = false;
  double heightCoef = 1.0;
  double heightMin = 0.0;
  double heightMax = 1.0;
  
  bool constrainVertical = false;
  double verticalMin = 0.0;
  double verticalMax = Math.PI;

  double autoSpeedFactor = 0.0;

  int mouseX = 0;
  int mouseY = 0;

  double lat = 0.0;
  double lon = 0.0;
  double phi = 0.0;
  double theta = 0.0;

  bool moveForward = false;
  bool moveBackward = false;
  bool moveLeft = false;
  bool moveRight = false;
  bool moveUp = false;
  bool moveDown = false;
  bool freeze = false;

  bool mouseDragOn = false;

  int viewHalfX = 0;
  int viewHalfY = 0;
  
  FirstPersonControls(this.object, [Element domElement])
      : this.domElement = domElement != null ? domElement : document {
    if (domElement != null) {
      this.domElement.tabIndex = -1;
    }
    
    this.domElement
        ..onContextMenu.listen((event) => event.preventDefault())
        ..onMouseMove.listen(_onMouseMove)
        ..onMouseDown.listen(_onMouseDown)
        ..onMouseUp.listen(_onMouseUp)
        ..onKeyDown.listen(_onKeyDown)
        ..onKeyUp.listen(_onKeyUp);
    
    handleResize();
  }
  
  void handleResize() {
    if (domElement == document) {
      viewHalfX = window.innerWidth ~/ 2;
      viewHalfY = window.innerHeight ~/ 2;
    } else {
      viewHalfX = domElement.offsetWidth ~/ 2;
      viewHalfY = domElement.offsetHeight ~/ 2;
    }
  }
  
  void _onMouseDown(MouseEvent event) {
    if (domElement != document) domElement.focus();

    event.preventDefault();
    event.stopPropagation();

    if (activeLook) {
      switch (event.button) {
        case 0: moveForward = true; break;
        case 2: moveBackward = true; break;
      }
    }

    mouseDragOn = true;
  }
  
  void _onMouseUp(MouseEvent event) {
    event.preventDefault();
    event.stopPropagation();

    if (activeLook) {
      switch (event.button) {
        case 0: moveForward = false; break;
        case 2: moveBackward = false; break;
      }
    }

    mouseDragOn = false;
  }
  
  void _onMouseMove(MouseEvent event) {
    if (domElement == document) {
      mouseX = event.page.x - this.viewHalfX;
      mouseY = event.page.y - this.viewHalfY;
    } else {
      mouseX = event.page.x - domElement.offsetLeft - viewHalfX;
      mouseY = event.page.y - domElement.offsetTop - viewHalfY;
    }
  }
  
  void _onKeyDown(KeyboardEvent event) {
    switch (event.keyCode) {
      case KeyCode.UP:
      case KeyCode.W: moveForward = true; break;

      case KeyCode.LEFT:
      case KeyCode.A: moveLeft = true; break;
      
      case KeyCode.DOWN:
      case KeyCode.S: moveBackward = true; break;
      
      case KeyCode.RIGHT:
      case KeyCode.D: moveRight = true; break;

      case KeyCode.R: moveUp = true; break;
      case KeyCode.F: moveDown = true; break;

      case KeyCode.Q: freeze = !freeze; break;
    }
  }
  
  void _onKeyUp(KeyboardEvent event) {
    switch (event.keyCode) {
      case KeyCode.UP:
      case KeyCode.W: moveForward = false; break;

      case KeyCode.LEFT:
      case KeyCode.A: moveLeft = false; break;
      
      case KeyCode.DOWN:
      case KeyCode.S: moveBackward = false; break;
      
      case KeyCode.RIGHT:
      case KeyCode.D: moveRight = false; break;

      case KeyCode.R: moveUp = false; break;
      case KeyCode.F: moveDown = false; break;
    }
  }
  
  void update(double delta) {
    if (freeze) return;

    if (heightSpeed) {
      var y = object.position.y.clamp(heightMin, heightMax);
      var heightDelta = y - heightMin;

      autoSpeedFactor = delta * (heightDelta * heightCoef);
    } else {
      autoSpeedFactor = 0.0;
    }

    var actualMoveSpeed = delta * movementSpeed;

    if (moveForward || (autoForward && !moveBackward)) object.translateZ(-(actualMoveSpeed + autoSpeedFactor));
    if (moveBackward) object.translateZ(actualMoveSpeed);

    if (moveLeft) object.translateX(-actualMoveSpeed);
    if (moveRight) object.translateX(actualMoveSpeed);

    if (moveUp) object.translateY(actualMoveSpeed);
    if (moveDown) object.translateY(-actualMoveSpeed);

    var actualLookSpeed = delta * lookSpeed;

    if (!activeLook) actualLookSpeed = 0;

    var verticalLookRatio = 1;

    if (constrainVertical) {
      verticalLookRatio = Math.PI / (verticalMax - verticalMin);
    }

    lon += mouseX * actualLookSpeed;
    if (lookVertical) lat -= mouseY * actualLookSpeed * verticalLookRatio;

    lat = Math.max(-85.0, Math.min(85.0, lat));
    phi = MathUtils.degToRad(90 - lat);

    theta = MathUtils.degToRad(lon);

    if (constrainVertical) {
      phi = MathUtils.mapLinear(phi, 0, Math.PI, verticalMin, verticalMax);
    }

    var targetPosition = target,
        position = object.position;

    targetPosition.x = position.x + 100 * Math.sin(phi) * Math.cos(theta);
    targetPosition.y = position.y + 100 * Math.cos(phi);
    targetPosition.z = position.z + 100 * Math.sin(phi) * Math.sin(theta);

    object.lookAt(targetPosition);
  }
}