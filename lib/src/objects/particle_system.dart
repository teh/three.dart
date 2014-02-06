part of three;

class ParticleSystem extends Object3D {
  Geometry geometry;
  Material material;
  bool sortParticles = false;

  ParticleSystem(Geometry geometry, [Material material]) 
      : this.geometry = geometry != null ? geometry : new Geometry(),
        this.material = material != null ? material : new ParticleSystemMaterial(color: MathUtils.randHex()),
        super() {
  	frustumCulled = false;
  }
}