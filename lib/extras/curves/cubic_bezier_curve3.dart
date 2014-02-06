part of three;

class CubicBezierCurve3 extends Curve3D {
  Vector3 v0, v1, v2, v3;
  
  CubicBezierCurve3(this.v0, this.v1, this.v2, this.v3) : super();

  Vector3 getPoint(double t) => MathUtils.cubicBezier(v0, v1, v2, v3, t);
}
