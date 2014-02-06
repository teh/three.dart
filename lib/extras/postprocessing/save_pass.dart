part of postprocessing;

class SavePass extends EffectPass {
  WebGLRenderTarget renderTarget;
  
  String textureID = "tDiffuse";
  
  Map<String, Uniform> uniforms;
  
  ShaderMaterial material;
  
  bool clear = false;
  
  SavePass([this.renderTarget]) {
    var shader = Shaders.copy;

    uniforms = UniformsUtils.clone(shader["uniforms"]);

    material = new ShaderMaterial(
        uniforms: uniforms,
        vertexShader: shader["vertexShader"],
        fragmentShader: shader["fragmentShader"]);


    if (renderTarget == null) {
      renderTarget = new WebGLRenderTarget(window.innerWidth, window.innerHeight, minFilter: LINEAR_FILTER, magFilter: LINEAR_FILTER, format: RGB_FORMAT, stencilBuffer: false);
    }
    
    needsSwap = false;
  }
  
  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer, [double delta, bool maskActive]) {
    if (uniforms.containsKey(textureID)) {
      uniforms[textureID].value = readBuffer;
    }

    EffectComposer.quad.material = material;

    renderer.render(EffectComposer.scene, EffectComposer.camera, renderTarget: renderTarget, forceClear: clear);
  }
}