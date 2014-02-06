part of three;

class HemisphereLight extends Light {
  Vector3 position = new Vector3(0.0, 100.0, 0.0);
  double intensity;
  Color groundColor;

  HemisphereLight(int skyColorHex, int groundColorHex, [this.intensity = 1.0])
      : groundColor = new Color(groundColorHex),
        super(skyColorHex);
}