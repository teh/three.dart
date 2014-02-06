part of postprocessing;

class DotScreenPass extends EffectPass {
  Map<String, Uniform> uniforms;
  ShaderMaterial material;
  
  bool renderToScreen = false;
  
  DotScreenPass({Vector3 center, double angle, double scale}) {
    var shader = Shaders.dotscreen;
    
    uniforms = UniformsUtils.clone(shader["uniforms"]);
    
    if (center != null) uniforms["center"].value.setFrom(center);
    if (angle != null) uniforms["angle"].value = angle;
    if (scale != null) uniforms["scale"].value = scale;
    
    material = new ShaderMaterial(
        uniforms: uniforms,
        vertexShader: shader["vertexShader"],
        fragmentShader: shader["fragmentShader"]);
    
    needsSwap = true;
  }
  
  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer, [double delta, bool maskActive]) {
    uniforms["tDiffuse"].value = readBuffer;
    uniforms["tSize"].value.set(readBuffer.width, readBuffer.height);

    EffectComposer.quad.material = material;

    if (renderToScreen) {
      renderer.render(EffectComposer.scene, EffectComposer.camera );
    } else {
      renderer.render(EffectComposer.scene, EffectComposer.camera, renderTarget: writeBuffer, forceClear: false);
    }
  }
}