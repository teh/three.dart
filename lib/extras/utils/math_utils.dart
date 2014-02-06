/**
 * Based on three.js math.
 * 
 * @author alteredq / http://alteredqualia.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 */

library MathUtils;

import "dart:math" as Math;
import 'package:three/three.dart' show Vector2, Vector3, Vector4, Quaternion;

const DEG_2_RAD =  Math.PI / 180;
const RAD_2_DEG =  180 / Math.PI;
const EPSILON = 0.0000000001;

Math.Random _rand = new Math.Random();

String generateUUID() {
  // http://www.broofa.com/Tools/Math.uuid.htm
  var chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.split('');
  var uuid = new List(36);
  var rnd = 0;
    for (var i = 0; i < 36; i++) {
      if (i == 8 || i == 13 || i == 18 || i == 23) {
        uuid[i] = '-';
      } else if (i == 14) {
        uuid[i] = '4';
      } else {
        if (rnd <= 0x02) rnd = 0x2000000 + (random16().toInt() * 0x1000000);
        var r = rnd & 0xf;
        rnd = rnd >> 4;
        uuid[i] = chars[(i == 19) ? (r & 0x3) | 0x8 : r];
      }
    }
    
    return uuid.join('');
}

// Clamp value to range <a, b>
num clamp(num x, num a, num b) => x < a ? a : (x > b ? b : x);

// Clamp value to range <a, inf)
num clampBottom(num x, num a) => x < a ? a : x;

// Linear mapping from range <a1, a2> to range <b1, b2>
num mapLinear(num x, num a1, num a2, num b1, num b2) => b1 + (x - a1) * (b2 - b1) / (a2 - a1);

// http://en.wikipedia.org/wiki/Smoothstep
double smoothstep(double x, double min, double max) {
  if (x <= min) return 0.0;
  if (x >= max) return 1.0;
  x = (x - min) / (max - min);
  return x * x * (3 - 2 * x);
}

double smootherstep(double x, double min, double max) {
  if (x <= min) return 0.0;
  if (x >= max) return 0.0;
  x = (x - min) / (max - min);
  return x * x * x * (x * (x * 6 - 15) + 10);
}

bool isPowerOfTwo(int value) => (value & (value - 1)) == 0 && value != 0;

// Random float from <0, 1> with 16 bits of randomness
// (standard Math.random() creates repetitive patterns when applied over larger space)
double random16() => (65280 * _randDouble() + 255 * _randDouble()) / 65535;

// Random integer from <low, high> interval
int randInt(int low, int high) => low + (_randDouble() * (high - low + 1)).floor();

int randHex() => _rand.nextInt(0xffffff);

// Random float from <low, high> interval
double randFloat(double low, double high) => low + _randDouble() * (high - low);

// Random float from <-range/2, range/2> interval
double randFloatSpread(double range) => range * (0.5 - _randDouble());

double _randDouble() => _rand.nextDouble();

double degToRad(double degrees) => degrees * DEG_2_RAD;

double radToDeg(double radians) => radians * RAD_2_DEG;

lerp(a, b, double t) {
  var c = a + b;
  if (c is num) return a + (b - a) * t;
  if (c is Vector2 || c is Vector3 || c is Vector4 || c is Quaternion) return a.clone().lerp(b, t);
  throw new ArgumentError("[a] and [b] must be either numbers, vectors or quaternions.");
}

/*
 *  Quad Bezier Functions
 */

_b2p0(double p, double t) {
  var k = 1 - t;
  return k * k * p;
}

_b2p1(double p, double t) => 2 * (1 - t) * t * p;

_b2p2(double p, double t) => t * t * p;

quadraticBezier(p0, p1, p2, double t) {
  var components = new List.generate(p0.storage.length, (i) =>
      _b2p0(p0[i], t) + _b2p1(p1[i], t) + _b2p2(p2[i], t));
  
  return p0 is Vector2 ? new Vector2.array(components) : new Vector3.array(components);
}


/*
 *  Cubic Bezier Functions
 */

_b3p0(double p, double t) {
  var k = 1 - t;
  return k * k * k * p;
}

_b3p1(double p, double t) {
  var k = 1 - t;
  return 3 * k * k * t * p;
}

_b3p2(double p, double t) {
  var k = 1 - t;
  return 3 * k * t * t * p;
}

_b3p3(double p, double t) => t * t * t * p;

cubicBezier(p0, p1, p2, p3, double t) {
  var components = new List.generate(p0.storage.length, (i) =>
      _b3p0(p0[i], t) + _b3p1(p1[i], t) + _b3p2(p2[i], t) +  _b3p3(p3[i], t));
 
  return p0 is Vector2 ? new Vector2.array(components) : new Vector3.array(components);
}

