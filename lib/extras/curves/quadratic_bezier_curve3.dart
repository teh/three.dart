part of three;

class QuadraticBezierCurve3 extends Curve3D {
  Vector3 v0, v1, v2;
  
  QuadraticBezierCurve3(this.v0, this.v1, this.v2) : super();

  Vector3 getPoint(double t) => MathUtils.quadraticBezier(v0, v1, v2, t);
}