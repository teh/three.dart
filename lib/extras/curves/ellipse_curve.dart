part of three;

class EllipseCurve extends Curve2D {
  Vector2 center, radius;
  double startAngle, endAngle;
  bool clockwise;

  EllipseCurve(this.center, this.radius, this.startAngle, this.endAngle, this.clockwise) : super();
  
  Vector2 getPoint(double t) {
    var deltaAngle = endAngle - startAngle;

    if (deltaAngle < 0) deltaAngle += Math.PI * 2;
    if (deltaAngle > Math.PI * 2) deltaAngle -= Math.PI * 2;

    var angle = clockwise ? endAngle + (1 - t) * (Math.PI * 2 - deltaAngle)
                          : startAngle + t * deltaAngle;

    var tx = center.x + radius.x * Math.cos(angle);
    var ty = center.y + radius.y * Math.sin(angle);

    return new Vector2(tx, ty);
  }
}