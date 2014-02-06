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

class Triangle {
  final Vector3 a;
  final Vector3 b;
  final Vector3 c;

  Triangle([Vector3 a, Vector3 b, Vector3 c]) 
      : this.a = a != null ? new Vector3.copy(a) : new Vector3.zero(),
        this.b = b != null ? new Vector3.copy(b) : new Vector3.zero(),
        this.c = c != null ? new Vector3.copy(c) : new Vector3.zero();
        
  Triangle.vector2(Vector2 a, Vector2 b, Vector2 c) 
      : this.a = new Vector3.vector2(a),
        this.b = new Vector3.vector2(b),
        this.c = new Vector3.vector2(c);

  Triangle.copy(Triangle other) 
      : a = new Vector3.copy(other.a),
        b = new Vector3.copy(other.b),
        c = new Vector3.copy(other.c);

  void copyFrom(Triangle triangle) {
    a.setFrom(triangle.a);
    b.setFrom(triangle.b);
    c.setFrom(triangle.c);
  }

  void copyInto(Triangle o) {
    o.a.setFrom(a);
    o.b.setFrom(b);
    o.c.setFrom(c);
  }
  
  /*
   * Additions based on three.js triangle
   */
  
  Vector3 barycoordFromPoint(Vector3 point) {
    var v0 = c - a;
    var v1 = b - a;
    var v2 = point - a;

    var dot00 = v0.dot(v0);
    var dot01 = v0.dot(v1);
    var dot02 = v0.dot(v2);
    var dot11 = v1.dot(v1);
    var dot12 = v1.dot(v2);
  
    var denom = (dot00 * dot11 - dot01 * dot01);
  
    // colinear or singular triangle
    if (denom == 0) return null;
  
    var u = (dot11 * dot02 - dot01 * dot12) / denom;
    var v = (dot00 * dot12 - dot01 * dot02) / denom;
  
    // barycoordinates must always sum to 1
    return new Vector3(1 - u - v, v, u);
  }
  
  bool containsPoint(Vector3 point) {
    var result = barycoordFromPoint(point);
    return (result.x >= 0 && result.y >= 0 && (result.x + result.y) <= 1);
  }
  
  /// Get random point in triangle (via barycentric coordinates) (uniform distribution)
  Vector3 randomPoint() {
    var a = MathUtils.random16();
    var b = MathUtils.random16();
    
    if ((a + b) > 1) {
      a = 1 - a;
      b = 1 - b;
    }
    
    var c = 1 - a - b;
    return (this.a * a) + (this.b * b) + (this.c * c);
  }
}
