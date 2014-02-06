/*
 * @author James Baicoianu / http://www.baicoianu.com/
 */


part of controls;

class FlyControls {
  Object3D object;
  var domElement; // HtmlDocument or Element
  
  double movementSpeed = 1.0;
  double rollSpeed = 0.005;
  
  bool dragToLook = false;
  bool autoForward = false;
  
  Quaternion _tmpQuaternion = new Quaternion.identity();
  
  int _mouseStatus = 0;

  FlyControlsMoveState _moveState = new FlyControlsMoveState();
  
  Vector3 _moveVector = new Vector3.zero();
  Vector3 _rotationVector = new Vector3.zero();
  
  double _movementSpeedMultiplier;
  
  FlyControls(this.object, {Element domElement})
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
    
    _updateMovementVector();
    _updateRotationVector();
  }
  
  void _onKeyDown(KeyboardEvent event) {
    if (event.altKey) return;
    
    switch (event.keyCode) {
      case KeyCode.SHIFT: _movementSpeedMultiplier = 0.1; break;
      
      case KeyCode.W: _moveState.forward = true; break;
      case KeyCode.S: _moveState.back = true; break;

      case KeyCode.A: _moveState.left = true; break;
      case KeyCode.D: _moveState.right = true; break;

      case KeyCode.R: _moveState.up = true; break;
      case KeyCode.F: _moveState.down = true; break;

      case KeyCode.UP: _moveState.pitchUp = 1.0; break;
      case KeyCode.DOWN: _moveState.pitchDown = 1.0; break;

      case KeyCode.LEFT: _moveState.yawLeft = 1.0; break;
      case KeyCode.RIGHT: _moveState.yawRight = 1.0; break;

      case KeyCode.Q: _moveState.rollLeft = 1.0; break;
      case KeyCode.E: _moveState.rollRight = 1.0; break;
    }
    
    _updateMovementVector();
    _updateRotationVector();
  }
  
  void _onKeyUp(KeyboardEvent event) {
    switch (event.keyCode) {
      case KeyCode.SHIFT: _movementSpeedMultiplier = 0.1; break;
      
      case KeyCode.W: _moveState.forward = false; break;
      case KeyCode.S: _moveState.back = false; break;

      case KeyCode.A: _moveState.left = false; break;
      case KeyCode.D: _moveState.right = false; break;

      case KeyCode.R: _moveState.up = false; break;
      case KeyCode.F: _moveState.down = false; break;

      case KeyCode.UP: _moveState.pitchUp = 0.0; break;
      case KeyCode.DOWN: _moveState.pitchDown = 0.0; break;

      case KeyCode.LEFT: _moveState.yawLeft = 0.0; break;
      case KeyCode.RIGHT: _moveState.yawRight = 0.0; break;

      case KeyCode.Q: _moveState.rollLeft = 0.0; break;
      case KeyCode.E: _moveState.rollRight = 0.0; break;
    }
    
    _updateMovementVector();
    _updateRotationVector();
  }
  
  void _onMouseDown(MouseEvent event) {
    if (domElement != document) domElement.focus();

    event.preventDefault();
    event.stopPropagation();

    if (dragToLook) {
      _mouseStatus++;
    } else {
      switch (event.button) {
        case 0: _moveState.forward = true; break;
        case 2: _moveState.back = true; break;
      }

      _updateMovementVector();
    }
  }
  
  void _onMouseMove(MouseEvent event) {
    if (!dragToLook || _mouseStatus > 0) {
      var container = _getContainerDimensions();
      var halfWidth  = container["size"][0] / 2;
      var halfHeight = container["size"][1] / 2;

      _moveState.yawLeft = -((event.page.x - container["offset"][0]) - halfWidth) / halfWidth;
      _moveState.pitchDown = ((event.page.y - container["offset"][1]) - halfHeight) / halfHeight;

      _updateRotationVector();
    }
  }
  
  void _onMouseUp(MouseEvent event) {
    event.preventDefault();
    event.stopPropagation();

    if (dragToLook) {
      _mouseStatus--;
      _moveState.yawLeft = _moveState.pitchDown = 0.0;
    } else {
      switch (event.button) {
        case 0: _moveState.forward = false; break;
        case 2: _moveState.back = false; break;
      }

      _updateMovementVector();
    }

    _updateRotationVector();
  }
  
  void update(double delta) {
    var moveMult = delta * movementSpeed;
    var rotMult = delta * rollSpeed;

    object.translateX(_moveVector.x * moveMult);
    object.translateY(_moveVector.y * moveMult);
    object.translateZ(_moveVector.z * moveMult);

    _tmpQuaternion.setValues(_rotationVector.x * rotMult, _rotationVector.y * rotMult, _rotationVector.z * rotMult, 1.0).normalize();
    object.quaternion *= _tmpQuaternion;

    // expose the rotation vector for convenience
    object.rotation.setFromQuaternion(object.quaternion, order: object.rotation.order);
  }
  
  void _updateMovementVector() {
    var forward = _moveState.forward || (autoForward && !_moveState.back);

    _moveVector.x = (_moveState.left ? -1.0 : 0.0) + (_moveState.right ? 1.0 : 0.0);
    _moveVector.y = (_moveState.down ? -1.0 : 0.0) + (_moveState.up ? 1.0 : 0.0);
    _moveVector.z = (forward ? -1.0 : 0.0) + (_moveState.back ? 1.0 : 0.0);
  }
  
  void _updateRotationVector() {
    _rotationVector.x = -_moveState.pitchDown + _moveState.pitchUp;
    _rotationVector.y = -_moveState.yawRight  + _moveState.yawLeft;
    _rotationVector.z = -_moveState.rollRight + _moveState.rollLeft;
  }
  
  Map<String, List<int>> _getContainerDimensions() => 
      domElement != document ?
          {'size' : [domElement.offsetWidth, domElement.offsetHeight],
           'offset': [domElement.offsetLeft,  domElement.offsetTop]} : 
          {'size': [window.innerWidth, window.innerHeight],
           'offset': [0, 0]};
}

class FlyControlsMoveState {
  bool up = false, down = false, left = false, right = false, forward = false, back = false;
  double pitchUp = 0.0, pitchDown = 0.0, yawLeft = 0.0, yawRight = 0.0, rollLeft = 0.0, rollRight = 0.0;
}