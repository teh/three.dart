/*
  Copyright (C) 2013 John McCutchan <john@johnmccutchan.com>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

*/

part of three;

class Ray {
  final Vector3 _origin;
  final Vector3 _direction;

  Vector3 get origin => _origin;
  Vector3 get direction => _direction;

  Ray() :
    _origin = new Vector3.zero(),
    _direction = new Vector3.zero() {}

  Ray.copy(Ray other) :
    _origin = new Vector3.copy(other._origin),
    _direction = new Vector3.copy(other._direction) {}

  Ray.originDirection(Vector3 origin_, Vector3 direction_) :
    _origin = new Vector3.copy(origin_),
    _direction = new Vector3.copy(direction_) {}

  void copyOriginDirection(Vector3 origin_, Vector3 direction_) {
    origin_.setFrom(_origin);
    direction_.setFrom(_direction);
  }

  void copyFrom(Ray o) {
    _origin.setFrom(o._origin);
    _direction.setFrom(o._direction);
  }

  void copyInto(Ray o) {
    o._origin.setFrom(_origin);
    o._direction.setFrom(_direction);
  }

  /// Returns the position on [this] with a distance of [t] from [origin].
  Vector3 at(double t) {
    return _direction.scaled(t).add(_origin);
  }

  /// Return the distance from the origin of [this] to the intersection with
  /// [other] if [this] intersects with [other], or null if the don't intersect.
  double intersectsWithSphere(Sphere other) {
    final r2 = other.radius * other.radius;
    final l = other.center.clone().sub(origin);
    final s = l.dot(direction);
    final l2 = l.dot(l);
    if(s < 0 && l2 > r2) {
      return null;
    }
    final m2 = l2 - s * s;
    if(m2 > r2) {
      return null;
    }
    final q = Math.sqrt(r2 - m2);

    return (l2 > r2) ? s - q : s + q;
  }
  
  /* This doesn't support backface culling.

  /// Return the distance from the origin of [this] to the intersection with
  /// [other] if [this] intersects with [other], or null if the don't intersect.
  double intersectsWithTriangle(Triangle other) {
    const double EPSILON = 10e-5;

    final e1 = other.point1.clone().sub(other.point0);
    final e2 = other.point2.clone().sub(other.point0);

    final q = direction.cross(e2);
    final a = e1.dot(q);

    if(a > -EPSILON && a < EPSILON) {
      return null;
    }

    final f = 1 / a;
    final s = origin.clone().sub(other.point0);
    final u = f * (s.dot(q));

    if(u < 0.0) {
      return null;
    }

    final r = s.cross(e1);
    final v = f * (direction.dot(r));

    if(v < 0.0 || u + v > 1.0) {
      return null;
    }

    final t = f * (e2.dot(r));

    return t;
  }
  
  */

  /// Return the distance from the origin of [this] to the intersection with
  /// [other] if [this] intersects with [other], or null if the don't intersect.
  double intersectsWithBox3(Box3 other) {
    Vector3 t1 = new Vector3.zero(), t2 = new Vector3.zero();
    double tNear = -double.MAX_FINITE;
    double tFar = double.MAX_FINITE;

    for(int i = 0; i < 3; ++i){
      if(direction[i] == 0.0){
        if((origin[i] < other.min[i]) || (origin[i] > other.max[i])) {
          return null;
        }
      }
      else {
        t1[i] = (other.min[i] - origin[i]) / direction[i];
        t2[i] = (other.max[i] - origin[i]) / direction[i];

        if(t1[i] > t2[i]){
          final temp = t1;
          t1 = t2;
          t2 = temp;
        }

        if(t1[i] > tNear){
          tNear = t1[i];
        }

        if(t2[i] < tFar){
          tFar = t2[i];
        }

        if((tNear > tFar) || (tFar < 0)){
          return null;
        }
      }
    }

    return tNear;
  }
  
  /*
   * Additions based on three.js ray
   */
  
  double distanceToPoint(Vector3 point) {
    var directionDistance = (point - origin).dot(direction);
    
    // Point behind the ray
    if (directionDistance < 0) {
      return origin.distanceTo(point);
    }
    
    return (direction * directionDistance + origin).distanceTo(point);
  }
  
  Vector3 intersectsWithTriangle(Triangle triangle, [backfaceCulling = false]) { 
    // Compute the offset origin, edges, and normal.
    // from http://www.geometrictools.com/LibMathematics/Intersection/Wm5IntrRay3Triangle3.cpp
    var edge1 = triangle.point1 - triangle.point0;
    var edge2 = triangle.point2 - triangle.point0;
    var normal = edge1.cross(edge2);

    // Solve Q + t*D = b1*E1 + b2*E2 (Q = kDiff, D = ray direction,
    // E1 = kEdge1, E2 = kEdge2, N = Cross(E1,E2)) by
    //   |Dot(D,N)|*b1 = sign(Dot(D,N))*Dot(D,Cross(Q,E2))
    //   |Dot(D,N)|*b2 = sign(Dot(D,N))*Dot(D,Cross(E1,Q))
    //   |Dot(D,N)|*t = -sign(Dot(D,N))*Dot(Q,N)
    var DdN = direction.dot(normal);
    var sign;
    
    if (DdN > 0) {
      if (backfaceCulling) return null;
      sign = 1;
    } else if (DdN < 0) {
      sign = -1;
      DdN = -DdN;
    } else {
      return null;
    }
    
    var diff = origin - triangle.point0;
    var DdQxE2 = sign * direction.dot(diff.cross(edge2));
    
    // b1 < 0, no intersection
    if (DdQxE2 < 0) return null;
    
    var DdE1xQ = sign * direction.dot(edge1.cross(diff));
    
    // b2 < 0, no intersection
    if (DdE1xQ < 0) return null;
    
    // b1+b2 > 1, no intersection
    if (DdQxE2 + DdE1xQ > DdN) return null;
    
    // Line intersects triangle, check if ray does.
    var QdN = -sign * diff.dot(normal);
    
    // t < 0, no intersection
    if (QdN < 0) return null;

    return at(QdN / DdN);
  }
  
  double distanceToSegmentSquared(Vector3 v0, Vector3 v1, [Vector3 pointOnRay, Vector3 pointOnSegment]) {
    // from http://www.geometrictools.com/LibMathematics/Distance/Wm5DistRay3Segment3.cpp
    // It returns the min distance between the ray and the segment
    // defined by v0 and v1
    // It can also set two optional targets :
    // - The closest point on the ray
    // - The closest point on the segment
    var segCenter = (v0 + v1) * 0.5;
    var segDir = v1 - v0;
    var segExtent = v0.distanceTo(v1) * 0.5;
    var diff = origin - segCenter;
    var a01 = -direction.dot(segDir);
    var b0 = diff.dot(direction);
    var b1 = -diff.dot(segDir);
    var c = diff.length2;
    var det = (1 - a01 * a01).abs();
    var sqrDist, extDet;
    var s0, s1;

    if (det >= 0) {
      // The ray and segment are not parallel.
      s0 = direction.dot(segDir) * diff.dot(segDir) - diff.dot(direction);
      s1 = a01 * b0 - b1;
      extDet = segExtent * det;

      if (s0 >= 0) {
        if (s1 >= -extDet) {
          if (s1 <= extDet) {
            // region 0
            // Minimum at interior points of ray and segment.
            var invDet = 1 / det;
            s0 *= invDet;
            s1 *= invDet;
            sqrDist = s0 * (s0 + a01 * s1 + 2 * b0) + s1 * (a01 * s0 + s1 + 2 * b1) + c;
          } else {
            // region 1
            s1 = segExtent;
            s0 = Math.max(0, -(a01 * s1 + b0));
            sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
          }
        } else {
          // region 5
          s1 = -segExtent;
          s0 = Math.max(0, - (a01 * s1 + b0));
          sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
        }
      } else {
        if (s1 <= -extDet) {
          // region 4
          s0 = Math.max(0, -(-a01 * segExtent + b0));
          s1 = (s0 > 0) ? -segExtent : Math.min(Math.max(-segExtent, -b1), segExtent);
          sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
        } else if (s1 <= extDet) {
          // region 3
          s0 = 0;
          s1 = Math.min(Math.max(-segExtent, -b1), segExtent);
          sqrDist = s1 * (s1 + 2 * b1) + c;
        } else {
          // region 2
          s0 = Math.max(0, -(a01 * segExtent + b0));
          s1 = (s0 > 0) ? segExtent : Math.min(Math.max(-segExtent, -b1), segExtent);
          sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
        }
      }
    } else {
      // Ray and segment are parallel.
      s1 = (a01 > 0) ? -segExtent : segExtent;
      s0 = Math.max(0, -(a01 * s1 + b0));
      sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
    }

    if (pointOnRay != null) {
      pointOnRay = (direction * s0) + origin;
    }

    if (pointOnSegment != null) {
      pointOnSegment = (segDir * s1) + segCenter;
    }

    return sqrDist;
  }
}

class RayIntersection {
  double distance;
  Vector3 point;
  Face3 face;
  int faceIndex;
  Object3D object;
  RayIntersection({this.distance, this.point, this.object, this.face, this.faceIndex});
}
