/**
  * @author mrdoob / http://mrdoob.com/
  * @author alteredq / http://alteredqualia.com/
  * @author paulirish / http://paulirish.com/
  *
  * Ported to Dart from JS by:
  * @author jessevogt / http://jvogt.net/
  *
  * based on rev 04b652ae26e228796f67838c0ec4d555e8b16528
  */
library FirstPersonControls;

import "dart:html";
import "dart:math" as Math;
import "package:three/three.dart";
import 'package:three/extras/utils/math_utils.dart' as MathUtils;

class FirstPersonControls {
  Object3D object;
  Vector3 target = new Vector3.zero();

  Element domElement;

  num movementSpeed = 1.0;
  num lookSpeed = 0.005;

  bool lookVertical = true;
  bool autoForward = false;
  // bool invertVertical = false;

  bool activeLook = true;

  bool heightSpeed = false;
  num heightCoef = 1.0;
  num heightMin = 0.0;
  num heightMax = 1.0;

  bool constrainVertical = false;
  num verticalMin = 0;
  num verticalMax = Math.PI;

  num autoSpeedFactor = 0.0;

  num mouseX = 0;
  num mouseY = 0;

  num lat = 0;
  num lon = 0;
  num phi = 0;
  num theta = 0;

  bool moveForward = false;
  bool moveBackward = false;
  bool moveLeft = false;
  bool moveRight = false;
  bool moveUp = false;
  bool moveDown = false;
  bool freeze = false;

  bool mouseDragOn = false;

  num viewHalfX = 0;
  num viewHalfY = 0;

  FirstPersonControls(this.object, [Element domElement]) {
    this.domElement = (domElement != null) ? domElement : document.body;

    if (this.domElement != document.body) {
      this.domElement.tabIndex = -1;
    }

    this.domElement.onContextMenu.listen((event) => event.preventDefault());

    this.domElement.onMouseMove.listen(onMouseMove);
    this.domElement.onMouseDown.listen(onMouseDown);
    this.domElement.onMouseUp.listen(onMouseUp);
    this.domElement.onKeyDown.listen(onKeyDown);
    this.domElement.onKeyUp.listen(onKeyUp);

    handleResize();
  }

   void handleResize() {
    if (domElement == document.body) {
      viewHalfX = window.innerWidth / 2;
      viewHalfY = window.innerHeight / 2;
    } else {
      viewHalfX = domElement.offsetWidth / 2;
      viewHalfY = domElement.offsetHeight / 2;
    }
  }

  void onMouseDown(event) {

    if (domElement != document.body) {
      domElement.focus();
    }

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

  void onMouseUp(event) {
    event.preventDefault();
    event.stopPropagation();

    if (this.activeLook) {
      switch (event.button) {
        case 0: moveForward = false; break;
        case 2: moveBackward = false; break;
      }
    }
    this.mouseDragOn = false;
  }

  void onMouseMove(event) {
    if (this.domElement == document.body) {
      mouseX = event.page.x - viewHalfX;
      mouseY = event.page.y - viewHalfY;
    } else {
      mouseX = event.page.x - domElement.offsetLeft - viewHalfX;
      mouseY = event.page.y - domElement.offsetTop - viewHalfY;
    }
  }

  void onKeyDown(event) {

    //event.preventDefault();

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

  void onKeyUp(event) {

    switch(event.keyCode) {

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

  void update(delta) {
    var actualMoveSpeed = 0;
    var actualLookSpeed = 0;
    if (freeze) {
      return;
    } else {

      if (heightSpeed) {
        var y = MathUtils.clamp(object.position.y, heightMin, heightMax);
        var heightDelta = y - heightMin;

        autoSpeedFactor = delta * (heightDelta * heightCoef);
      } else {
        autoSpeedFactor = 0.0;
      }

      actualMoveSpeed = delta * movementSpeed;

      if (moveForward || (autoForward && !moveBackward)) object.translateZ(-(actualMoveSpeed + autoSpeedFactor));
      if (moveBackward) object.translateZ(actualMoveSpeed);

      if (moveLeft) object.translateX(-actualMoveSpeed);
      if (moveRight) object.translateX(actualMoveSpeed);

      if (moveUp) object.translateY(actualMoveSpeed);
      if (moveDown) object.translateY(-actualMoveSpeed);

      var actualLookSpeed = delta * lookSpeed;

      if (!activeLook) actualLookSpeed = 0;

      lon += mouseX * actualLookSpeed;
      if (lookVertical) lat -= mouseY * actualLookSpeed; // * invertVertical?-1:1;

      lat = Math.max(- 85, Math.min(85, lat));
      phi = (90 - lat) * Math.PI / 180;
      theta = lon * Math.PI / 180;

      var targetPosition = target,
          position = object.position;

      targetPosition.x = position.x + 100 * Math.sin(phi) * Math.cos(theta);
      targetPosition.y = position.y + 100 * Math.cos(phi);
      targetPosition.z = position.z + 100 * Math.sin(phi) * Math.sin(theta);
    }

    var verticalLookRatio = 1;

    if (this.constrainVertical) {
      verticalLookRatio = Math.PI / (verticalMax - verticalMin);
    }

    lon += mouseX * actualLookSpeed;
    if(lookVertical) lat -= mouseY * actualLookSpeed * verticalLookRatio;

    lat = Math.max(- 85, Math.min(85, lat));
    phi = (90 - lat) * Math.PI / 180;

    theta = lon * Math.PI / 180;

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
