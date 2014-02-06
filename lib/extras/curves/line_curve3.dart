part of three;

class LineCurve3 extends Curve3D {
  Vector3 v1, v2;

  LineCurve3(this.v1, this.v2) : super();

  Vector3 getPoint(double t) => (v2 - v1) * t + v1;
}