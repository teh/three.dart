part of three;

/*
 * @author zz85 / http://www.lab4games.net/zz85/blog
 * Creates free form 2d path using series of points, lines or curves.
 */



class PathAction {
	static const MOVE_TO = "moveTo";
	static const LINE_TO = "lineTo";
	static const QUADRATIC_CURVE_TO = "quadraticCurveTo"; // Bezier quadratic curve
	static const BEZIER_CURVE_TO = "bezierCurveTo";       // Bezier cubic curve
	static const CSPLINE_THRU = "splineThru";             // Catmull-rom spline
	static const ARC = "arc";                             // Circle
	static const ELLIPSE = "ellipse";

	String action;
	List args;

	PathAction([this.action, this.args]);
}

class Path extends CurvePath {
  bool useSpacedPoints = false;
  
  List<PathAction> actions = [];

  Path([List points]) : super() {
    if (points != null) {
       moveTo(points[0]);
    
       for (var v = 1; v < points.length; v++) {
         lineTo(points[v]);
       }
    }
  }
  
  void addAction(String action, List args) {
    actions.add(new PathAction(action, args));
  }

  void moveTo(Vector2 point) {
    addAction(PathAction.MOVE_TO, [point]);
  }

  void lineTo(Vector2 point) {
  	var lastPoint = actions.last.args.last;

  	var curve = new LineCurve(point, lastPoint);
  	curves.add(curve);
  	
  	addAction(PathAction.LINE_TO, [lastPoint]);
  }

  void quadraticCurveTo(Vector2 controlPoint, Vector2 endPoint) {
  	var lastPoint = actions.last.args.last;

  	var curve = new QuadraticBezierCurve(lastPoint, controlPoint, endPoint);
  	curves.add(curve);
  	
  	addAction(PathAction.QUADRATIC_CURVE_TO, [controlPoint, endPoint]);
  }

  void bezierCurveTo(Vector2 controlPoint1, Vector2 controlPoint2, Vector2 endPoint) {
  	var lastPoint = actions.last.args.last;

  	var curve = new CubicBezierCurve(lastPoint, controlPoint1, controlPoint2, endPoint);
  	curves.add(curve);
  	
  	addAction(PathAction.BEZIER_CURVE_TO, [controlPoint1, controlPoint2, endPoint]);
  }

  void splineThru(List<Vector2> points) {
  	var lastPoint = actions.last.args.last;
  	
  	var npts = [lastPoint]..addAll(points);

  	var curve = new SplineCurve(npts);
  	curves.add(curve);

  	addAction(PathAction.CSPLINE_THRU, [points]);
  }

  void arc(Vector2 point, double radius, double startAngle, double endAngle, bool clockwise) {
    var lastPoint = actions.last.args.last;

    absarc(lastPoint + point, radius, startAngle, endAngle, clockwise);
   }

  void absarc(Vector2 point, double radius, double startAngle, double endAngle, bool clockwise) {
    absellipse(point, new Vector2(radius, radius), startAngle, endAngle, clockwise);
  }

  void ellipse(Vector2 point, Vector2 radiusXY, double startAngle, double endAngle, bool clockwise) {
    var lastPoint = actions.last.args.last;

    absellipse(lastPoint + point, radiusXY, startAngle, endAngle, clockwise);
  }

  void absellipse(Vector2 point, Vector2 radiusXY, double startAngle, double endAngle, bool clockwise) {
    var curve = new EllipseCurve(point, radiusXY, startAngle, endAngle, clockwise);
    curves.add(curve);

    var lastPoint = curve.getPoint(clockwise ? 1.0 : 0.0);

    addAction(PathAction.ELLIPSE, [point, radiusXY, startAngle, endAngle, clockwise, lastPoint]);
  }

  List<Vector2> getSpacedPoints([int divisions = 40, bool closedPath = false]) =>
      new List.generate(divisions, (i) => getPoint(i / divisions));

  // Return an array of vectors based on contour of the path 
  List<Vector2> getPoints([int divisions, bool closedPath = false]) {
  	if (useSpacedPoints) return getSpacedPoints(divisions, closedPath);

  	if (divisions == null) divisions = 12;

  	var points = <Vector2>[];
  	
  	for (var i = 0; i < actions.length; i++) {
  		var args = actions[i].args;

  		switch(actions[i].action) {
    		case PathAction.MOVE_TO:
    			points.add(args.last);
    			break;
    		case PathAction.LINE_TO:
    			points.add(args.last);
    			break;
    		case PathAction.QUADRATIC_CURVE_TO:
    		  var cp  = args[1];
    			var cp1 = args[0];
    			var cp0 = points.length > 0 ? points.last : actions[i - 1].args.last; 
    			
    			for (var j = 1; j <= divisions; j++) {
    				var t = j / divisions;
    				var v = MathUtils.quadraticBezier(cp0, cp1, cp, t);
    				points.add(v);
    			}
    			break;
    		case PathAction.BEZIER_CURVE_TO:
    			var cp  = args[2];
    			var cp1 = args[0];
    			var cp2 = args[1];
    			var cp0 = points.length > 0 ? points.last : actions[i - 1].args.last;
  
    			for (var j = 1; j <= divisions; j++) {
    				var t = j / divisions;
    				var v = MathUtils.cubicBezier(cp0, cp1, cp2, cp, t);
    				points.add(v);
    			}
    			break;
    		case PathAction.CSPLINE_THRU:
    			var spts = [actions[i - 1].args.last]..addAll(args[0]);
    			var n = divisions * args[0].length;
    			var spline = new SplineCurve(spts);
    			
    			for (var j = 1; j <= n; j++) {
    				points.add(spline.getPointAt(j / n));
    			}
    			break;
    		case PathAction.ARC:
    			var point = args[0],
    			    radius = args[1],
    			    startAngle = args[2], 
    			    endAngle = args[3],
    			    clockwise = args[4];
    			
    			var deltaAngle = endAngle - startAngle;
    			var tdivisions = divisions * 2;
  
    			for (var j = 1; j <= tdivisions; j ++) {
    				var t = j / divisions * 2;
  
    				if (!clockwise) t = 1 - t;
  
    				var angle = startAngle + t * deltaAngle;
  
    				var tx = point.x + radius * Math.cos(angle);
    				var ty = point.y + radius * Math.sin(angle);
  
    				points.add(new Vector2(tx, ty));
    			}
    		  break;
    		case PathAction.ELLIPSE:
          var point = args[0],
              radiusXY = args[1],
              startAngle = args[2], 
              endAngle = args[3],
              clockwise = args[4];
  
        var deltaAngle = endAngle - startAngle;
        var tdivisions = divisions * 2;
  
        for (var j = 1; j <= tdivisions; j ++) {
          var t = j / tdivisions;
  
          if (!clockwise) t = 1 - t;
  
          var angle = startAngle + t * deltaAngle;
  
          var tx = point.x + radiusXY.x * Math.cos(angle);
          var ty = point.y + radiusXY.y * Math.sin(angle);
  
          points.add(new Vector2(tx, ty));
        }      
        break;
  		}
  	}

  	// Normalize to remove the closing point by default.
  	var lastPoint = points.last;
  	var EPSILON = 0.0000000001;
  	if ((lastPoint.x - points[0].x).abs() < EPSILON &&
        (lastPoint.y - points[0].y).abs() < EPSILON) {
  	  points.removeLast();
  	}
  	
  	if (closedPath) {
  		points.add(points[0]);
  	}

  	return points;
  }

  // Breaks path into shapes
  List<Shape> toShapes([bool isCCW = false]) {
    List subPaths = [];
    var lastPath = new Path();

    actions.forEach((item) {
      if (item.action == PathAction.MOVE_TO) {
        if (lastPath.actions.length != 0) {
          subPaths.add(lastPath);
          lastPath = new Path();
        }
      }
      
      reflect(this).invoke(new Symbol(item.action), item.args);
    }); 
 
    if (lastPath.actions.isNotEmpty) {
      subPaths.add(lastPath);
    }

    if (subPaths.length == 0) return [];

    var solid, shapes = [];

    if (subPaths.length == 1) {
      var tmpPath = subPaths[0];
      var tmpShape = new Shape();
      tmpShape.actions = tmpPath.actions;
      tmpShape.curves = tmpPath.curves;
      shapes.add(tmpShape);
      return shapes;
    }
    
    var holesFirst = !ShapeUtils.isClockWise(subPaths[0].getPoints());
    holesFirst = isCCW ? !holesFirst : holesFirst;
    
    if (holesFirst) {
      var tmpShape = new Shape();

      subPaths.forEach((path) {
        solid = ShapeUtils.isClockWise(path.getPoints());
        solid = isCCW ? !solid : solid;

        if (solid) {
          tmpShape.actions = path.actions;
          tmpShape.curves = path.curves;

          shapes.add(tmpShape);
          tmpShape = new Shape();
        } else {
          tmpShape.holes.add(path);
        }
      });
    } else {
      var tmpShape;
      
      subPaths.forEach((path) {
        solid = ShapeUtils.isClockWise(path.getPoints());
        solid = isCCW ? !solid : solid;

        if (solid) {
          if (tmpShape) shapes.add(tmpShape);

          tmpShape = new Shape();
          tmpShape.actions = path.actions;
          tmpShape.curves = path.curves;
        } else {
          tmpShape.holes.add(path);
        }
      });

      shapes.add(tmpShape);
    }
    
    return shapes;
  }
}