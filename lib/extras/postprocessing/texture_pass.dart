part of postprocessing;

class TexturePass extends EffectPass {
  Map<String, Uniform> uniforms;
  ShaderMaterial material;
  
  TexturePass(Texture texture, [double opacity = 1.0]) {
    var shader = Shaders.copy;

    uniforms = UniformsUtils.clone(shader["uniforms"]);

    uniforms["opacity"].value = opacity;
    uniforms["tDiffuse"].value = texture;

    material = new ShaderMaterial(
        uniforms: uniforms,
        vertexShader: shader["vertexShader"],
        fragmentShader: shader["fragmentShader"]);

    needsSwap = false;
  }
  
  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer, [double delta, bool maskActive]) {
    EffectComposer.quad.material = material;

    renderer.render(EffectComposer.scene, EffectComposer.camera, renderTarget: readBuffer);
  }
}