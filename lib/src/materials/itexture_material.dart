part of three;

abstract class ITextureMaterial {
  Texture map;
  Texture envMap;
  Texture lightMap;
  Texture specularMap;
  int combine;
  double reflectivity;
  double refractionRatio;
}
