part of three;

class PointLightHelper extends Mesh {
  PointLight light;
  
  PointLightHelper(this.light, double sphereSize) 
      : super(new SphereGeometry(sphereSize, 4, 2),
              new MeshBasicMaterial(wireframe: true, fog: false)) {
    light.updateMatrixWorld();
    
    (material as MeshBasicMaterial).color = light.color * light.intensity;

    matrixWorld = light.matrixWorld;
    matrixAutoUpdate = false;
  }
  
  void dispose() {
    geometry = null;
    material = null;
  }
  
  void update() {
    (material as MeshBasicMaterial).color = light.color * light.intensity;
  }
}