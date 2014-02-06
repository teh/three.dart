part of postprocessing;

class BloomPass extends EffectPass {
  double strength;
  double kernelSize;
  double sigma;
  int resolution;
  
  WebGLRenderTarget renderTargetX;
  WebGLRenderTarget renderTargetY;
  
  Map<String, Uniform> copyUniforms;
  ShaderMaterial materialCopy;
  
  Map<String, Uniform> convolutionUniforms;
  ShaderMaterial materialConvolution;
  
  bool clear = false;
  
  BloomPass({this.strength: 1.0, this.kernelSize: 25.0, this.sigma: 4.0, this.resolution: 256}) {
    // render targets
    renderTargetX = new WebGLRenderTarget(resolution, resolution, minFilter: LINEAR_FILTER, magFilter: LINEAR_FILTER, format: RGB_FORMAT);
    renderTargetY = new WebGLRenderTarget(resolution, resolution, minFilter: LINEAR_FILTER, magFilter: LINEAR_FILTER, format: RGB_FORMAT);

    // copy material
    var copyShader = Shaders.copy;

    copyUniforms = UniformsUtils.clone(copyShader["uniforms"]);

    copyUniforms["opacity"].value = strength;

    materialCopy = new ShaderMaterial(
        uniforms: copyUniforms,
        vertexShader: copyShader["vertexShader"],
        fragmentShader: copyShader["fragmentShader"],
        blending: ADDITIVE_BLENDING,
        transparent: true,
        defines: {"KERNEL_SIZE_FLOAT": kernelSize,
                  "KERNEL_SIZE_INT": kernelSize.toInt()});
    
    // convolution material
    var convolutionShader = Shaders.convolution;

    convolutionUniforms = UniformsUtils.clone(convolutionShader["uniforms"]);

    convolutionUniforms["uImageIncrement"].value = BloomPass.blurX;
    convolutionUniforms["cKernel"].value = convolutionShader["buildKernel"](sigma);

    materialConvolution = new ShaderMaterial(
        uniforms: convolutionUniforms,
        vertexShader:  convolutionShader["vertexShader"],
        fragmentShader: convolutionShader["fragmentShader"]);
    
    needsSwap = false;
  }
  
  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer, double delta, bool maskActive) {
    if (maskActive) renderer.context.disable(gl.STENCIL_TEST);

    // Render quad with blured scene into texture (convolution pass 1)
    EffectComposer.quad.material = materialConvolution;

    convolutionUniforms["tDiffuse"].value = readBuffer;
    convolutionUniforms["uImageIncrement"].value = BloomPass.blurX;

    renderer.render(EffectComposer.scene, EffectComposer.camera, renderTarget: renderTargetX, forceClear: true);


    // Render quad with blured scene into texture (convolution pass 2)
    convolutionUniforms["tDiffuse"].value = renderTargetX;
    convolutionUniforms["uImageIncrement"].value = BloomPass.blurY;

    renderer.render(EffectComposer.scene, EffectComposer.camera, renderTarget: renderTargetY, forceClear: true);

    // Render original scene with superimposed blur to texture
    EffectComposer.quad.material = materialCopy;

    copyUniforms["tDiffuse"].value = renderTargetY;

    if (maskActive) renderer.context.enable(gl.STENCIL_TEST);

    renderer.render(EffectComposer.scene, EffectComposer.camera, renderTarget: readBuffer, forceClear: clear);
  }
  
  static final blurX = new Vector2(0.001953125, 0.0);
  static final blurY = new Vector2(0.0, 0.001953125);
}