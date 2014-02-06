part of three;

class ArcCurve extends EllipseCurve {
  ArcCurve(Vector2 center, 
           double radius, 
           double startAngle, 
           double endAngle, 
           bool clockwise) 
      : super(center, new Vector2(radius, radius), startAngle, endAngle, clockwise);
}