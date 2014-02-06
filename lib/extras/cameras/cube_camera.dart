part of three;

/// Camera for rendering cube maps. Renders scene into axis-aligned cube.
class CubeCamera extends Object3D {
  WebGLRenderTargetCube renderTarget;
  
  PerspectiveCamera cameraPX,
                    cameraNX,
                    cameraPY,
                    cameraNY,
                    cameraPZ,
                    cameraNZ;
                    
  CubeCamera(double near, double far, int cubeResolution) {
    var fov = 90.0, aspect = 1.0;

    cameraPX = new PerspectiveCamera(fov, aspect, near, far);
    cameraPX.up = new Vector3.down();
    cameraPX.lookAt(new Vector3.right());
    add(cameraPX);

    cameraNX = new PerspectiveCamera(fov, aspect, near, far);
    cameraNX.up = new Vector3.down();
    cameraNX.lookAt(new Vector3.left());
    add(cameraNX);

    cameraPY = new PerspectiveCamera(fov, aspect, near, far);
    cameraPY.up = new Vector3.backward();
    cameraPY.lookAt(new Vector3.up());
    add(cameraPY);

    cameraNY = new PerspectiveCamera(fov, aspect, near, far);
    cameraNY.up = new Vector3.forward();
    cameraNY.lookAt(new Vector3.down());
    add(cameraNY);

    cameraPZ = new PerspectiveCamera(fov, aspect, near, far);
    cameraPZ.up = new Vector3.down();
    cameraPZ.lookAt(new Vector3.backward());
    add(cameraPZ);

    cameraNZ = new PerspectiveCamera(fov, aspect, near, far);
    cameraNZ.up = new Vector3.down();
    cameraNZ.lookAt(new Vector3.forward());
    add(cameraNZ);

    renderTarget = new WebGLRenderTargetCube(cubeResolution, cubeResolution, format: RGB_FORMAT, magFilter: LINEAR_FILTER, minFilter: LINEAR_FILTER);
  }
  
  void updateCubeMap(WebGLRenderer renderer, Scene scene) {
    var generateMipmaps = renderTarget.generateMipmaps;

    renderTarget.generateMipmaps = false;

    renderTarget.activeCubeFace = 0;
    renderer.render(scene, cameraPX, renderTarget: renderTarget);

    renderTarget.activeCubeFace = 1;
    renderer.render(scene, cameraNX, renderTarget: renderTarget);

    renderTarget.activeCubeFace = 2;
    renderer.render( scene, cameraPY, renderTarget: renderTarget);

    renderTarget.activeCubeFace = 3;
    renderer.render(scene, cameraNY, renderTarget: renderTarget);

    renderTarget.activeCubeFace = 4;
    renderer.render(scene, cameraPZ, renderTarget: renderTarget);

    renderTarget.generateMipmaps = generateMipmaps;

    renderTarget.activeCubeFace = 5;
    renderer.render(scene, cameraNZ, renderTarget: renderTarget);
  }
}