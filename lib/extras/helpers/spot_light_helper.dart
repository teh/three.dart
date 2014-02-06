part of three;

class SpotLightHelper extends Object3D {
  SpotLight light;
  Mesh cone;
  
  SpotLightHelper(this.light) {
    light.updateMatrixWorld();

    matrixWorld = light.matrixWorld;
    matrixAutoUpdate = false;

    var geometry = new CylinderGeometry(0.0, 1.0, 1.0, 8, 1, true);

    geometry.applyMatrix(new Matrix4.translation(new Vector3(0.0, -0.5, 0.0)));
    geometry.applyMatrix(new Matrix4.rotationX(-Math.PI / 2));

    var material = new MeshBasicMaterial(wireframe: true, fog: false);
    
    cone = new Mesh(geometry, material);
    add(cone);

    update();
  }
  
  void dispose() {
    cone.geometry = null;
    cone.material = null;
  }
  
  update() {
    var coneLength = light.distance != null ? light.distance : 10000.0;
    var coneWidth = coneLength * Math.tan(light.angle);

    cone.scale.setValues(coneWidth, coneWidth, coneLength);

    var vector = light.matrixWorld.getTranslation();
    var vector2 = light.target.matrixWorld.getTranslation();

    cone.lookAt(vector2 - vector);

    (cone.material as MeshBasicMaterial).color = light.color * light.intensity;
  }
}