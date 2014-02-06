part of three;

class HemisphereLightHelper extends Object3D {
  HemisphereLight light;
  List<Color> colors = [new Color.white(), new Color.white()];
  Mesh lightSphere;
  
  HemisphereLightHelper(this.light, double sphereSize, double arrowLength, double domeSize) : super() {
    light.updateMatrixWorld();
    
    matrixWorld = light.matrixWorld;
    matrixAutoUpdate = false;
    
    var geometry = new SphereGeometry(sphereSize, 4, 2);
    geometry.applyMatrix(new Matrix4.rotationX(-Math.PI / 2));

    for (var i = 0; i < 8; i++) {
      geometry.faces[i].color = colors[i < 4 ? 0 : 1];
    }

    var material = new MeshBasicMaterial(vertexColors: FACE_COLORS, wireframe: true);

    lightSphere = new Mesh(geometry, material);
    add(lightSphere);

    update();
  }
  
  void dispose() {
    lightSphere.geometry = null;
    lightSphere.material = null;
  }
  
  void update() {
    var vector = new Vector3.zero();

    colors[0] = light.color * light.intensity;
    colors[1] = light.groundColor * light.intensity;

    lightSphere.lookAt(light.matrixWorld.getTranslation().negate());
    lightSphere.geometry.colorsNeedUpdate = true;
  }
}