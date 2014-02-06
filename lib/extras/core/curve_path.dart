/*
 * @author zz85 / http://www.lab4games.net/zz85/blog
 */

part of three;


/// Curved Path - a curve path is simply a array of connected
/// curves, but retains the api of a curve.
class CurvePath extends Curve {
	List<Curve> curves = [];
	List bends = [];

	bool autoClose = false; // Automatically closes the path

	List cacheLengths;

	void add(Curve curve) => curves.add(curve);

	void closePath() {
		var startPoint = curves[0].getPoint(0.0);
		var endPoint = curves[curves.length - 1].getPoint(1.0);

		if (!startPoint == endPoint) {
			curves.add(new LineCurve(endPoint, startPoint));
		}
	}

	// To get accurate point with reference to
	// entire path distance at time t,
	// following has to be done:

	// 1. Length of each sub path have to be known
	// 2. Locate and identify type of curve
	// 3. Get t for the curve
	// 4. Return curve.getPointAt(t)
	getPoint(double t) {
		var d = t * length;
		var curveLengths = getCurveLengths();

		var i = 0;
		while (i < curveLengths.length) {
			if (curveLengths[i] >= d) {
				var diff = curveLengths[i] - d;
				var curve = curves[i];

				var u = 1 - diff / curve.length;

				return curve.getPointAt(u);
			}

			i++;
		}

		return null;
	}

	// We cannot use the default Curve getPoint() with getLength() because in
	// Curve, getLength() depends on getPoint() but in CurvePath
	// getPoint() depends on getLength
	double get length => getCurveLengths().last;

	// Compute lengths and cache them
	// We cannot overwrite getLengths() because UtoT mapping uses it.
	List<double> getCurveLengths() {
		if (cacheLengths != null && cacheLengths.length == curves.length) {
			return cacheLengths;
		}

		// Get length of subsurve
		// Push sums into cached array
		var lengths = [], sums = 0;

		for (var i = 0; i < curves.length; i++) {
			sums += curves[i].length;
			lengths.add(sums);
		}

		cacheLengths = lengths;
		return lengths;
	}

	// Returns min and max coordinates, as well as centroid
	Map getBoundingBox() {
		var points = getPoints();

		var maxX, maxY, maxZ;
		var minX, minY, minZ;

		maxX = maxY = double.NEGATIVE_INFINITY;
		minX = minY = double.INFINITY;

		var v3 = points[0] is Vector3;
		var sum = v3 ? new Vector3.zero() : new Vector2.zero();

		points.forEach((p) {
		  if (p.x > maxX) { maxX = p.x; }
		  else if (p.x < minX) { minX = p.x; }

      if (p.y > maxY) { maxY = p.y; }
      else if (p.y < minY) { minY = p.y; }
      
      
      if (v3) {
        if (p.z > maxZ) { maxZ = p.z; }
        else if (p.z < minZ) { minZ = p.z; }
      }
      
      sum.add(p);
		});

		var ret = {"minX": minX,
			         "minY": minY,
			         "maxX": maxX,
			         "maxY": maxY,
			         "centroid": sum.scale(1.0 / points.length)};
		if (v3) {
	    ret["maxZ"] = maxZ;
	    ret["minZ"] = minZ;
	  }

	  return ret;
	}

	/*
	 * Create Geometries Helpers
	 */

	/// Generate geometry from path points (for [Line] or [ParticleSystem] objects).
	Geometry createPointsGeometry([int divisions]) => createGeometry(getPoints(divisions, true));

	/// Generate geometry from equidistance sampling along the path.
	Geometry createSpacedPointsGeometry([int divisions]) {
		var pts = getSpacedPoints(divisions, true);
		return createGeometry(pts);
	}

	Geometry createGeometry(List points) =>
	    new Geometry()..vertices = new List.generate(points.length, (i) =>
	        new Vector3(points[i].x, points[i].y, points[i] is Vector3 ? points[i].z : 0.0));

	/*
	 *	Bend / Wrap Helper Methods
	 */

	// Wrap path / Bend modifiers?
	void addWrapPath(bendpath) { 
	  bends.add(bendpath);
	}

	List getTransformedPoints(int segments, [List bends]) {
		var oldPts = getPoints(segments); // getPoints getSpacedPoints

		if (bends == null) {
			bends = this.bends;
		}
		
		bends.forEach((bend) => oldPts = getWrapPoints(oldPts, bend));

		return oldPts;
	}

	List getTransformedSpacedPoints([int segments, List bends]) {
		var oldPts = getSpacedPoints(segments);

		if (bends == null) {
			bends = this.bends;
		}
		
		bends.forEach((bend) => oldPts = getWrapPoints(oldPts, bend));

		return oldPts;
	}

	// This returns getPoints() bend/wrapped around the contour of a path.
	// Read http://www.planetclegg.com/projects/WarpingTextToSplines.html
	List getWrapPoints(List oldPts, CurvePath path) {
		var bounds = getBoundingBox();
		
		oldPts.forEach((p) {
		  var oldX = p.x;
      var oldY = p.y;

      var xNorm = oldX / bounds["maxX"];

      // If using actual distance, for length > path, requires line extrusions
      // xNorm = path.getUtoTmapping(xNorm, oldX); // 3 styles. 1) wrap stretched. 2) wrap stretch by arc length 3) warp by actual distance

      xNorm = path.getUtoTmapping(xNorm, oldX);

      // check for out of bounds?
      var pathPt = path.getPoint(xNorm);
      var normal = path.getTangent(xNorm);
      normal.setValues(-normal.y, normal.x).scale(oldY);

      p.x = pathPt.x + normal.x;
      p.y = pathPt.y + normal.y;
		  
		});

		return oldPts;
	}
}
