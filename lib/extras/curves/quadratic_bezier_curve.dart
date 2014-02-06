part of three;

class QuadraticBezierCurve extends Curve2D {
  Vector2 v0, v1, v2;

  QuadraticBezierCurve(this.v0, this.v1, this.v2);

  Vector2 getPoint(double t) => MathUtils.quadraticBezier(v0, v1, v2, t);
  
  Vector2 getTangent(double t) => CurveUtils.tangentQuadraticBezier(v0, v1, v2, t)..normalize();
}