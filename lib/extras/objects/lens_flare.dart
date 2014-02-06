part of three;

class LensFlare extends Object3D {
  List<LensFlareObject> lensFlares = [];
  
  Vector3 positionScreen = new Vector3.zero();
  Function customUpdateCallback;
  
  LensFlare({Texture texture, double size, double distance, int blending, Color color}) {
    if (texture != null) {
      lensFlares.add(
          new LensFlareObject(
              texture, 
              size: size, 
              distance: distance, 
              blending: blending, 
              color: color));
    }
  }
  
  /// Update lens flares update positions on all flares based on the screen position
  /// Set [customUpdateCallback] to alter the flares in your project in a specific way.
  void updateLensFlares() {
    var vecX = -positionScreen.x * 2;
    var vecY = -positionScreen.y * 2;
    
    lensFlares.forEach((flare) {
      flare.x = positionScreen.x + vecX * flare.distance;
      flare.y = positionScreen.y + vecY * flare.distance;

      flare.wantedRotation = flare.x * Math.PI * 0.25;
      flare.rotation += (flare.wantedRotation - flare.rotation) * 0.25;
    });
  }
}

class LensFlareObject {
  Texture texture;
  double size, distance, x, y, z, scale, rotation, opacity;
  Color color;
  int blending;
  double wantedRotation;
  
  LensFlareObject(this.texture, 
                 {this.size: -1.0, 
                  double distance: 0.0, 
                  this.blending: NORMAL_BLENDING, 
                  Color color,
                  this.opacity: 1.0}) {
    this.color = color != null ? color : new Color(0xffffff);
    this.distance = Math.min(distance, Math.max(0, distance));
  }
}