/*
 * @author mr.doob / http://mrdoob.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 * 
 * based on r63.
 */

part of three;

class Color {
  /// RGB values.
  final List<double> values;
  
  /// Red channel value represented as a double between 0.0 and 1.0.
  double get r => values[0];
         set r(double v) => values[0] = v;
  
  /// Green channel value represented as a double between 0.0 and 1.0. 
  double get g => values[1];
         set g(double v) => values[1] = v;
  
  /// Blue channel value represented as a double between 0.0 and 1.0.
  double get b => values[2];
         set b(double v) => values[0] = v;
 
  /// Red channel value represented as an integer between 0 and 255. 
  int get rr => (r * 255).floor();
      set rr(int v) => values[0] = (1 / 255) * v;
  
  /// Green channel value represented as an integer between 0 and 255.
  int get gg => (g * 255).floor();
      set gg(int v) => values[1] = (1 / 255) * v; 
  
  /// Blue channel value represented as an integer between 0 and 255. 
  int get bb => (b * 255).floor();
      set bb(int v) => values[2] = (1 / 255) * v; 

  /// Constructs a new color with RGB values [0.0, 0.0, 0.0]
  Color.black() : values = [0.0, 0.0, 0.0];
  
  /// Constructs a new color with RGB values [1.0, 1.0, 1.0]
  Color.white() : values = [1.0, 1.0, 1.0];
  
  /// Constructs a new color with RGB values [1.0, 0.0, 0.0]
  Color.red() : values = [1.0, 0.0, 0.0];
  
  /// Constructs a new color with RGB values [0.0, 1.0, 0.0]
  Color.green() : values = [0.0, 1.0, 0.0];
  
  /// Constructs a new color with RGB values [0.0, 0.0, 1.0]
  Color.blue() : values = [0.0, 0.0, 1.0];
  
  /// Constructs a new color with specified hex value.
  Color(int hex) : values = new List<double>(3) {
    setHex(hex);
  }
  
  /// Construct a new color with specified RGB values.
  Color.fromRGB(double r, double g, double b) : values = new List<double>(3) {
    setRGB(r, g, b);
  }
  
  /// Construct a new color with specified HSL values.
  Color.fromHSL(double h, double s, double l) : values = new List<double>(3) {
    setHSL(h, s, l);
  }
  
  /// Copy of [other].
  Color.copy(Color other) : values = new List<double>(3) {
    setRGB(other.r, other.g, other.b);
  }
  
  /// Constructs a new color from a CSS-style string,
  /// e.g. "rgb(250, 0,0)", "rgb(100%,0%,0%)", "#ff0000", "#f00", or "red".
  Color.fromStyle(String style) : values = new List<double>(3) {
    setStyle(style);
  }
  
  /// Initialized with values from [array]
  Color.fromArray(List<double> array) : values = [array[0], array[1], array[2]];
  
  Color.random() : values = new List<double>(3) {
    setHex(MathUtils.randHex());
  }
  
  /// Sets [this] from [value]. Can be a [Color], hexadecimal, [HSL], or a CSS-style string.
  Color setFrom(value) {
    if (value is Color) setRGB(value.r, value.g, value.b);
    else if (value is int) setHex(value);
    else if (value is String) setStyle(value);
    else throw new ArgumentError(value);
    return this;
  }
  
  /// Sets [this] from specified RGB values, ranging from 0.0 to 1.0.
  Color setRGB(double r, double g, double b) {
    values[0] = r;
    values[1] = g;
    values[2] = b;
    return this;
  }
  
  /// Sets [this] from specified HSL values, ranging from 0.0 to 1.0.
  Color setHSL(double h, double s, double l) {
    if (s == 0) {
      values[0] = values[1] = values[2] = l;
    } else {
      var hue2rgb = (p, q, t) {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * 6 * (2 / 3 - t);
        return p;
      };

      var p = l <= 0.5 ? l * (1 + s) : l + s - (l * s);
      var q = (2 * l) - p;

      values[0] = hue2rgb(q, p, h + 1 / 3);
      values[1] = hue2rgb(q, p, h);
      values[2] = hue2rgb(q, p, h - 1 / 3);
    }
  }
  
  /// Sets [this] from a CSS-style string, e.g. "rgb(250, 0,0)", "rgb(100%,0%,0%)", "#ff0000", "#f00", or "red".
  Color setStyle(String style) {
    var color;
    
    // rgb(255,0,0)
    color = new RegExp(r'^rgb\((\d+), ?(\d+), ?(\d+)\)$', caseSensitive: true).firstMatch(style);
    if (color != null) {
      values[0] = Math.min(255, int.parse(color[1])) / 255;
      values[1] = Math.min(255, int.parse(color[2])) / 255;
      values[2] = Math.min(255, int.parse(color[3])) / 255;
      return this;
    }

    // rgb(100%,0%,0%)
    color = new RegExp(r'^rgb\((\d+)\%, ?(\d+)\%, ?(\d+)\%\)$', caseSensitive: true).firstMatch(style);
    if (color != null) {
      values[0] = Math.min(100, int.parse(color[1])) / 100;
      values[1] = Math.min(100, int.parse(color[2])) / 100;
      values[2] = Math.min(100, int.parse(color[3])) / 100;
      return this;
    }

    // #ff0000
    color = new RegExp(r'^\#([0-9a-f]{6})$', caseSensitive: true).firstMatch(style);
    if (color != null) {
      setHex(int.parse(color[1]));
      return this;
    }

    // #f00
    color = new RegExp(r'^\#([0-9a-f])([0-9a-f])([0-9a-f])$', caseSensitive: true).firstMatch(style);
    if (color != null) {
      setHex(int.parse('${color[1]}${color[1]}${color[2]}${color[2]}${color[3]}${color[3]}'));
      return this;
    }

    // red
    if (new RegExp(r'^(\w+)$', caseSensitive: true).hasMatch(style)) {
      setHex(Colors[style]);
      return this;
    }
  }
  
  /// Copies [color] making conversion from gamma to linear space.
  Color copyGammaToLinear(Color color) {
    values[0] = color.r * color.r;
    values[1] = color.g * color.g;
    values[2] = color.b * color.b;
    return this;
  }

  /// Copies [color] making conversion from linear to gamma space.
  Color copyLinearToGamma(Color color) {
    var x = Math.sqrt(color.r);
    values[0] = Math.sqrt(color.r);
    values[1] = Math.sqrt(color.g);
    values[2] = Math.sqrt(color.b);
    return this;
  }

  /// Converts RGB values from gamma to linear space.
  Color convertGammaToLinear() {
    values[0] *= values[0];
    values[1] *= values[1];
    values[2] *= values[2];
    return this;
  }

  /// Converts RGB values from linear to gamma space.
  Color convertLinearToGamma() {
    values[0] = Math.sqrt(r);
    values[1] = Math.sqrt(g);
    values[2] = Math.sqrt(b);
    return this;
  }
  
  /// The hexadecimal value of this color.
  int getHex() => (rr << 16) ^ (gg << 8) ^ (bb);
  
  /// Sets this color from a hexadecimal value.
  Color setHex(int hex) {
    var h = hex.floor();
    values[0] = ((h & 0xFF0000) >> 16) / 255;
    values[1] = ((h & 0x00FF00) >> 8) / 255;
    values[2] = (h & 0x0000FF) / 255;
    return this;
  }
  
  /// The string formated hexadecimal value of this color.
  String get hexString => '${getHex().toRadixString(16)}';
  
  /// HSL representation of this color
  HSL getHSL() => new HSL.fromRGB(r, g, b);
  
  /// The value of this color as a CSS-style string, e.g. "rgb(255,0,0)"
  String getStyle() => 'rgb($rr,$gg, $bb)';
  
  /// Adds given h, s, and l to this color's existing h, s, and l values.
  Color offsetHSL(double h, double s, double l) {
    var hsl = getHSL();
    setHSL(hsl.h + h, hsl.s + s, hsl.l + l);
    return this;
  }
  
  /// Adds rgb values of [color] to RGB values of this color
  Color add(Color color) {
    values[0] += color.r;
    values[1] += color.g;
    values[2] += color.b;
    return this;
  }
  
  /// Adds [s] to the RGB values of this color
  Color addScalar(double s) {
    values[0] += s;
    values[1] += s;
    values[2] += s;
    return this;
  }
  
  /// Multiplies this color's RGB values by [color].
  Color multiply(Color color) {
    values[0] *= color.r;
    values[1] *= color.g;
    values[2] *= color.b;
    return this;
  }
  
  /// Multiplies this color's RGB values by [s]
  Color multiplyScalar(double s) {
    values[0] *= s;
    values[1] *= s;
    values[2] *= s;
    return this;
  }
  
  Color lerp(Color color, int alpha) {
    values[0] += (color.r - values[0]) * alpha;
    values[1] += (color.g - values[1]) * alpha;
    values[2] += (color.b - values[2]) * alpha;
    return this;
  }
  
  /// Clones color.
  Color clone() => new Color.copy(this);
  
  Color operator +(dynamic v) {
    if (v is Color) return add(v);
    if (v is double) return addScalar(v);
    throw new ArgumentError(v);
  }
  
  Color operator *(dynamic v) {
    if (v is Color) return multiply(v);
    if (v is double) return multiplyScalar(v);
    throw new ArgumentError(v);
  }
}

class HSL {
  /// Hue.
  double get h => _h;
  double _h;
  
  /// Saturation.
  double get s => _s;
  double _s;
  
  /// Lightness
  double get l => _l;
  double _l;
  
  HSL.fromRGB(double r, double g, double b) {
    // h,s,l ranges are in 0.0 - 1.0
    var max = Math.max(Math.max(r, g), b);
    var min = Math.min(Math.min(r, g), b);

    _l = (min + max) / 2.0;

    if (min == max) {
      _h = _s = 0.0;
    } else {
      var delta = max - min;
      
      _s = _l <= 0.5 ? delta / (max + min) : delta / (2 - max - min);
      
      if (max == r) {
        _h = (g - b) / delta + (g < b ? 6 : 0);
      } else if (max == g) {
        _h = (b - r) / delta + 2;
      } else if (max == b) {
        _h = (r - g) / delta + 4;
      }

      _h /= 6;
    }
  }
}
