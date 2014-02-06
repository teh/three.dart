part of postprocessing;

abstract class EffectPass {
  bool enabled = true;
  bool needsSwap;
  
  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer, double delta, bool maskActive);
}