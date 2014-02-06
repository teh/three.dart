part of postprocessing;

class RenderPass extends EffectPass {
  Scene scene;
  Camera camera;
  
  ShaderMaterial overrideMaterial;
  
  Color clearColor;
  int clearAlpha;
  
  Color oldClearColor = new Color.white();
  int oldClearAlpha = 1;
  
  bool clear = true;
  
  RenderPass(this.scene, this.camera, this.overrideMaterial, this.clearColor, [this.clearAlpha = 1]) {
    needsSwap = false;
  }
  
  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer, [double delta, bool maskActive]) {
    scene.overrideMaterial = this.overrideMaterial;

    if (clearColor != null) {
      oldClearColor.setFrom(renderer.clearColor);
      oldClearAlpha = renderer.clearAlpha;

      renderer.setClearColor(clearColor, clearAlpha);

    }

    renderer.render(scene, camera, renderTarget: readBuffer, forceClear: clear);

    if (clearColor != null) {
      renderer.setClearColor(oldClearColor, oldClearAlpha);
    }

    scene.overrideMaterial = null;
  }
}