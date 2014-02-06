part of three;

class SplineCurve extends Curve2D {
  List<Vector2> points;

  SplineCurve([List<Vector2> points]) 
      : this.points = points != null ? points : [], 
        super();

  Vector2 getPoint(double t) {
    var point = (points.length - 1) * t,
        intPoint = point.floor().toInt(),
        weight = point - intPoint;

    var c = [intPoint == 0 ? intPoint : intPoint - 1,
             intPoint,
             intPoint > points.length - 2 ? points.length - 1 : intPoint + 1,
             intPoint > points.length - 3 ? points.length - 1 : intPoint + 2];

    var v = CurveUtils.interpolate(points[c[0]], points[c[1]], points[c[2]], points[c[3]], weight);
    
    return v;
  }
}