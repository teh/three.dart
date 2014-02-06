/*
 * @author zz85 / http://www.lab4games.net/zz85/blog
 */

part of three;

/**
 * Extensible curve object.
 *
 * ## Subclasses of [Curve]
 * 
 * ### 2d classes
 * * [LineCurve]
 * * [QuadraticBezierCurve]
 * * [CubicBezierCurve]
 * * [SplineCurve]
 * * [ArcCurve]
 * * [EllipseCurve]
 *
 * ### 3d classes
 * * [LineCurve3]
 * * [QuadraticBezierCurve3]
 * * [CubicBezierCurve3]
 * * [SplineCurve3]
 * * [ClosedSplineCurve3]
 *
 * A series of curves can be represented as a [CurvePath]
 *
 */
class Curve<V> {
  int _arcLengthDivisions;
  List cacheArcLengths;
  bool needsUpdate;
  
  Function _getPoint;
  
  Curve();
  
  Curve.create(this._getPoint);

  /// Returns a vector for point t of the curve where t is between 0 and 1.
  V getPoint(double t) => _getPoint(t);

  /// Returns a vector for point at relative position in curve according to arc length.
  V getPointAt(double u) => getPoint(getUtoTmapping(u));

	/// Get sequence of points using getPoint(t).
	List<V> getPoints([int divisions = 5, bool closedPath = false]) =>
	    new List.generate(divisions + 1, (d) => getPoint(d / divisions));

	/// Get sequence of equi-spaced points using getPointAt(u).
	List<V> getSpacedPoints([int divisions = 5, bool closedPath = false]) =>
	    new List.generate(divisions + 1, (d) => getPointAt(d / divisions));
	
	/// Get total curve arc length.
	double get length => getLengths().last;

	/// Get list of cumulative segment lengths.
	List<double> getLengths([int divisions]) {
		if (divisions == null) {
		  divisions = _arcLengthDivisions != null ? _arcLengthDivisions : 200;
		}

		if (cacheArcLengths != null && 
		    cacheArcLengths.length == divisions + 1 && 
		    !needsUpdate) {
			// print("cached [$cacheArcLengths]"); takes way too long to complete.
			return cacheArcLengths;
		}

		needsUpdate = false;
		
		var cache = [];
		var last = getPoint(0.0);
		var sum = 0;

		cache.add(0.0);

		for (var p = 1; p <= divisions; p++) {
			var current = getPoint(p / divisions);
			sum += (current as dynamic).distanceTo(last);
			cache.add(sum);
			last = current;
		}

		cacheArcLengths = cache;
		return cache;
	}

	/// Update the cumlative segment distance cache
	void updateArcLengths() {
		needsUpdate = true;
		getLengths();
	}

	/// Given u (0 .. 1), get a t to find p. This gives you points which are equidistant.
	double getUtoTmapping(double u, [double distance]) {
		var arcLengths = getLengths();

		var i = 0, il = arcLengths.length,
		    targetArcLength;

		if (distance != null) {
			targetArcLength = distance;
		} else {
			targetArcLength = u * arcLengths[arcLengths.length - 1];
		}

		var low = 0, high = il - 1, comparison;

		while (low <= high) {
			i = (low + (high - low) / 2).floor().toInt();

			comparison = arcLengths[i] - targetArcLength;

			if (comparison < 0) {
				low = i + 1;
				continue;
			} else if (comparison > 0) {
				high = i - 1;
				continue;
			} else {
				high = i;
				break;
			}
		}

		i = high;

		if (arcLengths[i] == targetArcLength) {
			var t = i / (il - 1);
			return t;
		}

		var lengthBefore = arcLengths[i];
    var lengthAfter = arcLengths[i + 1];

    var segmentLength = lengthAfter - lengthBefore;
    var segmentFraction = (targetArcLength - lengthBefore) / segmentLength;

    var t = (i + segmentFraction) / (il -1);

		return t;
	}

  /// Returns a unit vector tangent at t. If the subclassed curve do not implement its 
  /// tangent derivation, 2 points a small delta apart will be used to find its gradient 
  /// which seems to give a reasonable approximation.
	V getTangent(double t) {
		var delta = 0.0001;
		var t1 = t - delta;
		var t2 = t + delta;
		
		// Capping in case of danger
		if (t1 < 0) t1 = 0.0;
		if (t2 > 1) t2 = 1.0;

		var pt1 = getPoint(t1);
		var pt2 = getPoint(t2);

		return (pt2 - pt1).normalize();
	}

	/// Returns tangent at equidistant point u on the curve.
	V getTangentAt(u) => getTangent(getUtoTmapping(u));
}

class Curve2D extends Curve<Vector2> {}
class Curve3D extends Curve<Vector3> {}