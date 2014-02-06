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

class Sphere {
  final Vector3 center;
  double radius;

  Sphere([Vector3 center, double radius]) 
      : this.center = center != null ? center : new Vector3.zero(),
        this.radius = radius != null ? radius : 0.0;


  Sphere.copy(Sphere other)
      : center = new Vector3.copy(other.center),
        radius = other.radius;
  
  void copyFrom(Sphere o) {
    center.setFrom(o.center);
    radius = o.radius;
  }

  /// Return if [this] contains [other].
  bool containsVector3(Vector3 other) => other.distanceToSquared(center) < radius * radius;

  /// Return if [this] intersects with [other].
  bool intersectsWithVector3(Vector3 other) => other.distanceToSquared(center) <= radius * radius;

  /// Return if [this] intersects with [other].
  bool intersectsWithSphere(Sphere other) {
    var radiusSum = radius + other.radius;
    return other.center.distanceToSquared(center) <= (radiusSum * radiusSum);
  }
  
  /*
   * Additions based on three.js sphere
   */
  
  Sphere.fromPoints(List<Vector3> points, [Vector3 optionalCenter]) 
    : center = new Vector3.zero(),
      radius = 0.0 {
        
    if (optionalCenter != null) {
      center.setFrom(optionalCenter);
    } else {
      center.setFrom(new Box3.fromPoints(points).center);
    }
    
    var maxRadiusSq = 0;
    points.forEach((point) => maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(point)));
    
    radius = Math.sqrt(maxRadiusSq);
  }
  
  Sphere applyMatrix4(Matrix4 matrix) {
    center.applyMatrix4(matrix);
    radius *= matrix.getMaxScaleOnAxis();
    return this;
  }
}

