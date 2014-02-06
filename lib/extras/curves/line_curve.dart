part of three;

class LineCurve extends Curve2D {
  Vector2 v1, v2;

  LineCurve(this.v1, this.v2) : super();

  Vector2 getPoint(double t) => (v2 - v1) * t + v1;

  // Line curve is linear, so we can overwrite default getPointAt
  Vector2 getPointAt(double u) => getPoint(u);

  Vector2 getTangent(double t) => (v2 - v1).normalize();

}