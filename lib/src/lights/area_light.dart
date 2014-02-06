part of three;

class AreaLight extends Light {
  Vector3 normal = new Vector3.down();
  Vector3 right = new Vector3.right();
  
  double intensity;
  
  double width = 1.0;
  double height = 1.0;
  
  double constantAttenuation = 1.5;
  double linearAttenuation = 0.5;
  double quadraticAttenuation = 0.1;
  
  AreaLight(int hex, [this.intensity = 1.0]): super(hex);
}