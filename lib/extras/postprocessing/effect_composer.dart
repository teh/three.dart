part of postprocessing;

class EffectComposer {
  WebGLRenderer renderer;
  
  WebGLRenderTarget renderTarget1;
  WebGLRenderTarget renderTarget2;
  
  WebGLRenderTarget writeBuffer;
  WebGLRenderTarget readBuffer;
  
  List<EffectPass> passes = [];
  
  ShaderPass copyPass;
  
  EffectComposer(this.renderer, [WebGLRenderTarget renderTarget]) {
    if (renderTarget == null) {
      var width = window.innerWidth != 0 ? window.innerWidth : 1;
      var height = window.innerHeight != 0 ? window.innerHeight : 1;

      renderTarget = new WebGLRenderTarget(width, height, minFilter: LINEAR_FILTER, magFilter: LINEAR_FILTER, format: RGB_FORMAT, stencilBuffer: false);;
    }

    renderTarget1 = renderTarget;
    renderTarget2 = renderTarget.clone();

    writeBuffer = renderTarget1;
    readBuffer = renderTarget2;

    copyPass = new ShaderPass(Shaders.copy);
  }
  
  void swapBuffers() {
    var tmp = readBuffer;
    readBuffer = writeBuffer;
    writeBuffer = tmp;
  }
  
  void addPass(EffectPass pass) { 
    passes.add(pass);
  }

  void insertPass(EffectPass pass, int index) {
    passes.insert(index, pass);
  }

  void render(double delta) {
    writeBuffer = renderTarget1;
    readBuffer = renderTarget2;

    var maskActive = false;

    passes.where((e) => e.enabled).forEach((pass) {
      pass.render(renderer, writeBuffer, readBuffer, delta, maskActive);

      if (pass.needsSwap) {
        if (maskActive) {
          var context = renderer.context;
          context.stencilFunc(context.NOTEQUAL, 1, 0xffffffff);

          copyPass.render(renderer, writeBuffer, readBuffer, delta, maskActive);

          context.stencilFunc(context.EQUAL, 1, 0xffffffff);
        }

        swapBuffers();
      }

      if (pass is MaskPass) {
        maskActive = true;
      } else if (pass is ClearMaskPass) {
        maskActive = false;
      }
    });
  }

  void reset(WebGLRenderTarget renderTarget) {
    if (renderTarget == null) {
      renderTarget = renderTarget1.clone();

      renderTarget.width = window.innerWidth;
      renderTarget.height = window.innerHeight;

    }

    renderTarget1 = renderTarget;
    renderTarget2 = renderTarget.clone();

    writeBuffer = renderTarget1;
    readBuffer = renderTarget2;
  }

  void setSize(int width, int height) {
    var renderTarget = renderTarget1.clone();

    renderTarget.width = width;
    renderTarget.height = height;

    reset(renderTarget);
  }
  
  /// Shared ortho camera
  static OrthographicCamera camera = new OrthographicCamera(-1.0, 1.0, 1.0, -1.0, 0.0, 1.0);
  static Mesh quad = new Mesh(new PlaneGeometry(2.0, 2.0));
  static Scene scene = new Scene()..add(quad);
}