part of three;

class CubicBezierCurve extends Curve2D {
  Vector2 v0, v1, v2, v3;

  CubicBezierCurve(this.v0, this.v1, this.v2, this.v3) : super();

  Vector2 getPoint(double t) => MathUtils.cubicBezier(v0, v1, v2, v3, t);
  
  Vector2 getTangent(double t) => CurveUtils.tangentCubicBezier(v0, v1, v2, v3, t);
}
