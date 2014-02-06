library CurveUtils;

import 'package:three/three.dart' show Vector2, Vector3;

tangentQuadraticBezier(p0, p1, p2, double t) {
  var components = new List.generate(p0.storage.length, (i) =>
      2.0 * (1.0 - t) * (p1[i] - p0[i]) + 2.0 * t * (p2[i] - p1[i]));
  
  return p0 is Vector2 ? new Vector2.array(components) : new Vector3.array(components);
}
    

tangentCubicBezier(p0, p1, p2, p3, double t) {
  var components = new List.generate(p0.storage.length, (i) =>
      -3.0 * p0[i] * (1.0 - t) * (1.0 - t)  +
       3.0 * p1[i] * (1.0 - t) * (1.0 - t) - 6.0 * t * p1[i] * (1.0 - t) +
       6.0 * t * p2[i] * (1.0 - t) - 3.0 * t * t * p2[i] +
       3.0 * t * t * p3[i]);
  
  return p0 is Vector2 ? new Vector2.array(components) : new Vector3.array(components);
}
    

tangentSpline(p0, p1, p2, p3, double t) {
  var h00 = 6 * t * t - 6 * t;  
  var h10 = 3 * t * t - 4 * t + 1;
  var h01 = -6 * t * t + 6 * t;  
  var h11 = 3 * t * t - 2 * t; 

  return h00 + h10 + h01 + h11;
}

/// Catmullrom.
interpolate(p0, p1, p2, p3, double t) {
  var components = new List.generate(p0.storage.length, (i) {
    var v0 = (p2[i] - p0[i]) * 0.5;
    var v1 = (p3[i] - p1[i]) * 0.5;
    var t2 = t * t;
    var t3 = t * t2;
    return (2.0 * p1[i] - 2.0 * p2[i] + v0 + v1) * t3 + (-3.0 * p1[i] + 3.0 * p2[i] - 2.0 * v0 - v1) * t2 + v0 * t + p1[i];
  });
  
  return p0 is Vector2 ? new Vector2.array(components) : new Vector3.array(components);
}