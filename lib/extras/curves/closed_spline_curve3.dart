part of three;

class ClosedSplineCurve3 extends Curve3D {
  List<Vector3> points;

  ClosedSplineCurve3([List<Vector3> points]) 
      : this.points = points != null ? points : [], 
        super();
  
  Vector3 getPoint(double t) {
    var point = (points.length - 0) * t;
  
    var intPoint = point.floor().toInt();
    var weight = point - intPoint;
  
    intPoint += intPoint > 0 ? 0 : ((intPoint.abs() / points.length).floor() + 1) * points.length;
    var c = new List.generate(4, (i) => (i - 1) % points.length);
  
    var v = CurveUtils.interpolate(points[c[0]], points[c[1]], points[c[2]], points[c[3]], weight);
  
    return v;
  }
}