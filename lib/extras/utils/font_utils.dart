/*
 * @author zz85 / http://www.lab4games.net/zz85/blog
 * @author alteredq / http://alteredqualia.com/
 *
 * For Text operations in three.js (See TextGeometry)
 *
 * It uses techniques used in:
 *
 *  typeface.js and canvastext
 *    For converting fonts and rendering with javascript
 *    http://typeface.neocracy.org
 *
 *  Triangulation ported from AS3
 *    Simple Polygon Triangulation
 *    http://actionsnippet.com/?p=1462
 *
 *  A Method to triangulate shapes with holes
 *    http://www.sakri.net/blog/2009/06/12/an-approach-to-triangulating-polygons-with-holes/
 *
 */

library FontUtils;

import "package:three/three.dart";
import 'package:three/extras/utils/math_utils.dart' as MathUtils;

String _face = "helvetiker";
String _weight = "normal";
String _style = "normal";

double _size = 150.0;
int _divisions = 10;

/// Map of [FontFace]
Map<String, Map<String, Map<String, Map<String, Map>>>> _faces = {};

Map<String, Map> getFace() => _faces[_face][_weight][_style];

Map loadFace(data) {

  var family = data["familyName"].toLowerCase();

  if (_faces[family] == null) _faces[family] = {};

  if (_faces[family][data["cssFontWeight"]] == null) _faces[family][data["cssFontWeight"]] = {};
  _faces[family][data["cssFontWeight"]][data["cssFontStyle"]] = data;

  // TODO - Parse data
  var face = _faces[family][data["cssFontWeight"]][data["cssFontStyle"]] = data;

  return data;
}

Map drawText(String text) {
  var characterPts = [], allPts = [], fontPaths = [];

  // RenderText
  var face = getFace(),
      scale = _size / face["resolution"],
      offset = 0;
  
  text.split('').forEach((char) {
    var ret = extractGlyphPoints(char, face, scale, offset, new Path());
    offset += ret["offset"];

    fontPaths.add(ret["path"]);
  });

  var width = offset / 2;

  return {"paths": fontPaths, "offset": width};
}

Map extractGlyphPoints(String c, face, scale, offset, Path path) {
  List<Vector2> pts = [];
  
  var outline;

  var glyph = face["glyphs"][c] != null ? face["glyphs"][c] : face["glyphs"]['?'];

  if (glyph == null) return null;

  if (glyph["o"] != null) {
    outline = glyph["_cachedOutline"];
    
    if (outline == null) {
      glyph["_cachedOutline"] = glyph["o"].split(' ');
      outline = glyph["_cachedOutline"];
    }
    
    var length = outline.length;

    var scaleX = scale;
    var scaleY = scale;

    for (var i = 0; i < length;) {
      var action = outline[i++];

      switch(action) {
        case 'm':
        var x = double.parse(outline[i++]) * scaleX + offset;
        var y = double.parse(outline[i++]) * scaleY;

        path.moveTo(new Vector2(x, y));
        break;
        
        case 'l':
        var x = double.parse(outline[i++]) * scaleX + offset;
        var y = double.parse(outline[i++]) * scaleY;
        
        path.lineTo(new Vector2(x, y));
        break;
        case 'q':
        var cpx  = double.parse(outline[i++]) * scaleX + offset;
        var cpy  = double.parse(outline[i++]) * scaleY;
        var cpx1 = double.parse(outline[i++]) * scaleX + offset;
        var cpy1 = double.parse(outline[i++]) * scaleY;
        path.quadraticCurveTo(new Vector2(cpx1, cpy1), 
                              new Vector2(cpx, cpy));
        break;
        
        case 'b':
        var cpx  = double.parse(outline[i++]) *  scaleX + offset;
        var cpy  = double.parse(outline[i++]) *  scaleY;
        var cpx1 = double.parse(outline[i++]) *  scaleX + offset;
        var cpy1 = double.parse(outline[i++]) * -scaleY;
        var cpx2 = double.parse(outline[i++]) *  scaleX + offset;
        var cpy2 = double.parse(outline[i++]) * -scaleY;

        path.bezierCurveTo(new Vector2(cpx, cpy), 
                           new Vector2(cpx1, cpy1), 
                           new Vector2(cpx2, cpy2));
        break;
      }
    }
  }

  return {"offset": glyph["ha"] * scale, "path": path};
}

List<Shape> generateShapes(String text,
                          [double size = 100.0,
                           int curveSegments = 4,
                           String font = "helvetiker",
                           String weight = "normal",
                           String style = "normal"]) {

  var face = _faces[font][weight][style];

  if (_faces == null) {
    face = new FontFace(size, curveSegments);
    _faces[font][weight][style] = face;
  }
  
  _size = size;
  _divisions = curveSegments;

  _face = font;
  _weight = weight;
  _style = style;

  // Get a Font data json object
  
  var data = drawText(text);
  
  var shapes = [];
  data["paths"].forEach((path) => shapes.addAll(path.toShapes()));

  return shapes;
}

class Glyph {
  String o; /// outline
  List _cachedOutline;

  num ha;
}

class FontFace {
  Map<String, Map> _data;

  Map<String, Glyph> glyphs = {};

  double size;
  int divisions;

  num resolution;

  FontFace([this.size = 150.0, this.divisions = 10]);

  Map operator [](String weight) => _data[weight];
}

/**
 * This code is a quick port of code written in C++ which was submitted to
 * flipcode.com by John W. Ratcliff  // July 22, 2000
 * See original code and more information here:
 * http://www.flipcode.com/archives/Efficient_Polygon_Triangulation.shtml
 *
 * ported to actionscript by Zevan Rosser
 * www.actionsnippet.com
 *
 * ported to javascript by Joshua Koo
 * http://www.lab4games.net/zz85/blog
 *
 */

// takes in an contour array and returns
List<List<Vector2>> process(List<Vector2> contour, bool indices) {
  var n = contour.length;

  if (n < 3) return null;

  var result = [],
      verts = new List(n),
      vertIndices = [];

  int u, v, w;

  if (area(contour) > 0.0) {
    for (v = 0; v < n; v++) { 
      verts[v] = v;
    }

  } else {
    for (v = 0; v < n; v++) { 
      verts[v] = (n - 1) - v;
    }
  }

  int nv = n;

  var count = 2 * nv; 

  for(v = nv - 1; nv > 2;) {
    if ((count--) <= 0) {
      print("Warning, unable to triangulate polygon!");

      if (indices) return vertIndices;
      return result;
    }

    u = v;      if (nv <= u) u = 0;  
    v = u + 1;  if (nv <= v) v = 0;  
    w = v + 1;  if (nv <= w) w = 0; 

    if (snip(contour, u, v, w, nv, verts)) {
      var a = verts[u];
      var b = verts[v];
      var c = verts[w];

      result.add([contour[a], contour[b], contour[c]]);

      vertIndices.addAll([verts[u], verts[v], verts[w]]);

      var s = v;
      for(var t = v + 1; t < nv; t++) {
        verts[s] = verts[t];
        s++;
      }

      nv--;
      count = 2 * nv;
    }
  }

  if (indices) return vertIndices;
  return result;
}

// calculate area of the contour polygon
double area(List<Vector2> contour) {
  var n = contour.length;
  
  var a = 0;
  for(var p = n - 1, q = 0; q < n; p = q++) {
    a += contour[p].x * contour[q].y - contour[q].x * contour[p].y;
  }

  return a * 0.5;
}

bool snip(List<Vector2> contour, int u, int v, int w, int n, List<int> verts) {
  var a = contour[verts[u]],
      b = contour[verts[v]],
      c = contour[verts[w]];

  if (MathUtils.EPSILON > ((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x))) return false;

    for (var i = 0; i < n; i++) {
      if ((i == u) || (i == v) || (i == w)) continue;

      if (new Triangle.vector2(a, b, c).containsPoint(new Vector3.vector2(contour[verts[i]]))) {
        return false;
      }
    }

    return true;
}