part of postprocessing;

class BokehPass extends EffectPass {
  Scene scene;
  Camera camera;
  
  WebGLRenderTarget renderTargetColor;
  WebGLRenderTarget renderTargetDepth;
  
  /// Depth material.
  MeshDepthMaterial materialDepth = new MeshDepthMaterial();
  
  ShaderMaterial materialBokeh;
  
  Map<String, Uniform> uniforms;
  
  bool renderToScreen = false;
  bool clear = false;
  
  BokehPass(this.scene, this.camera, 
           {double focus: 1.0, 
            double aspect, 
            double aperture: 0.025,
            double maxblur: 1.0,
            int width,
            int height}) {
    
    width = width != null ? width : window.innerWidth != 0 ? window.innerWidth : 1;
    height = height != null ? height : window.innerHeight != 0 ? window.innerHeight : 1;

    renderTargetColor = new WebGLRenderTarget(width, height,
        minFilter: LINEAR_FILTER,
        magFilter: LINEAR_FILTER,
        format: RGB_FORMAT);

    renderTargetDepth = renderTargetColor.clone();

    var bokehShader = Shaders.bokeh;
    var bokehUniforms = UniformsUtils.clone(bokehShader["uniforms"]);

    bokehUniforms["tDepth"].value = renderTargetDepth;
    
    bokehUniforms["focus"].value = focus;
    bokehUniforms["aspect"].value = aspect;
    bokehUniforms["aperture"].value = aperture;
    bokehUniforms["maxblur"].value = maxblur;

    materialBokeh = new ShaderMaterial(
        uniforms: bokehUniforms,
        vertexShader: bokehShader["vertexShader"],
        fragmentShader: bokehShader["fragmentShader"]);

    uniforms = bokehUniforms;
    
    needsSwap = false;
  }
  
  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer, [double delta, bool maskActive]) {
    EffectComposer.quad.material = materialBokeh;

    // Render depth into texture
    scene.overrideMaterial = materialDepth;

    renderer.render(scene, camera, renderTarget: renderTargetDepth, forceClear: true);

    // Render bokeh composite
    uniforms["tColor"].value = readBuffer;

    if (renderToScreen) {
      renderer.render(EffectComposer.scene, EffectComposer.camera);
    } else {
      renderer.render(EffectComposer.scene, EffectComposer.camera, renderTarget: writeBuffer, forceClear: clear);
    }

    scene.overrideMaterial = null;
  }
}