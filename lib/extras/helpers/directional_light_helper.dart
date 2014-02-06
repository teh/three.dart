/*
 * @author alteredq / http://alteredqualia.com/
 * @author mrdoob / http://mrdoob.com/
 * @author WestLangley / http://github.com/WestLangley
 */

part of three;

class DirectionalLightHelper extends Object3D {
  Light light;
  Mesh lightPlane;
  Line targetLine;
  
  DirectionalLightHelper(this.light, [double size = 1.0]) : super() {
    light.updateMatrixWorld();

    matrixWorld = light.matrixWorld;
    matrixAutoUpdate = false;
    
    var geometry = new PlaneGeometry( size, size );
    var material = new MeshBasicMaterial(wireframe: true, fog: false);
    material.color.setFrom(light.color).multiplyScalar((light as DirectionalLight).intensity);

    lightPlane = new Mesh(geometry, material);
    add(lightPlane);

    geometry = new Geometry();
    geometry.vertices.add(new Vector3.zero());
    geometry.vertices.add(new Vector3.zero());

    material = new LineBasicMaterial(fog: false);
    material.color.setFrom(light.color).multiplyScalar((light as DirectionalLight).intensity);

    targetLine = new Line(geometry, material);
    add(targetLine);

    update();
  }
  
  void dispose() {
    lightPlane.geometry = null;
    lightPlane.material = null;
    targetLine.geometry = null;
    targetLine.material = null;
  }
  
  void update() {
    var v1 = light.matrixWorld.getTranslation();
    var v2 = (light as DirectionalLight).target.matrixWorld.getTranslation();
    var v3 = v2 - v1;
  
    lightPlane.lookAt(v3);
    (lightPlane.material as MeshBasicMaterial).color
    ..setFrom(light.color)
    ..multiplyScalar((light as DirectionalLight).intensity);
  
    targetLine.geometry.vertices[1].setFrom(v3);
    targetLine.geometry.verticesNeedUpdate = true;
    (targetLine.material as MeshBasicMaterial).color.setFrom((lightPlane.material as MeshBasicMaterial).color);
  }
}