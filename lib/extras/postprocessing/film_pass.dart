part of postprocessing;

class FilmPass extends EffectPass {
  ShaderMaterial material;
  Map<String, Uniform> uniforms;
  
  bool renderToScreen = false;
  
  FilmPass({double noiseIntensity, double scanlinesIntensity, double scanlinesCount, int grayscale}) {
    var shader = Shaders.film;
    
    material = new ShaderMaterial(
        uniforms: uniforms,
        vertexShader: shader["vertexShader"],
        fragmentShader: shader["fragmentShader"]);
    
    if (grayscale != null) uniforms["grayscale"].value = grayscale;
    if (noiseIntensity != null) uniforms["nIntensity"].value = noiseIntensity;
    if (scanlinesIntensity != null) uniforms["sIntensity"].value = scanlinesIntensity;
    if (scanlinesCount != null) uniforms["sCount"].value = scanlinesCount;

    needsSwap = true;
  }
  
  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer, double delta, [bool maskActive]) {
    uniforms["tDiffuse"].value = readBuffer;
    uniforms["time"].value += delta;

    EffectComposer.quad.material = material;

    if (renderToScreen) {
      renderer.render(EffectComposer.scene, EffectComposer.camera);
    } else {
      renderer.render(EffectComposer.scene, EffectComposer.camera, renderTarget: writeBuffer, forceClear: false);
    }
  }
}