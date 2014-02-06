part of postprocessing;

class ShaderPass extends EffectPass {
  Map shader;
  String textureID;
  
  Map<String, Uniform> uniforms;
  
  ShaderMaterial material;
  
  bool renderToScreen = false;
  
  bool clear = false;
  
  ShaderPass(this.shader, [this.textureID = "tDiffuse"]) {
    uniforms = UniformsUtils.clone(shader["uniforms"]);
    
    material = new ShaderMaterial(
        uniforms: uniforms, 
        vertexShader: shader["vertexShader"],
        fragmentShader: shader["fragmentShader"]);
    
    needsSwap = true;
  }
  
  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer, [double delta, bool maskActive]) {
    if (uniforms.containsKey(textureID)) { 
      uniforms[textureID].value = readBuffer;
    }

    EffectComposer.quad.material = material;

    if (renderToScreen) {
      renderer.render(EffectComposer.scene, EffectComposer.camera);
    } else {
      renderer.render(EffectComposer.scene, EffectComposer.camera, renderTarget: writeBuffer, forceClear: clear);
    }
  }
}