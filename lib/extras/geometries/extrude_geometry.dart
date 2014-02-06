/*
 * @author zz85 / http://www.lab4games.net/zz85/blog
 * 
 * based on r63
 */

part of three;

/// Creates extruded geometry from a path shape.
class ExtrudeGeometry extends Geometry {
  /// An array of shapes.
  List<Shape> shapes;

  Map shapebb;

  /**
   * ## Parameters
   * * curveSegments: Number of points on the curves.
   * * steps: Number of points for z-side extrusions / used for subdividing segements of extrude spline too.
   * * amount: Depth to extrude the shape.
   * 
   * * bevelEnabled: Turn on bevel.
   * * bevelThickness: How deep into the original shape bevel goes.
   * * bevelSize: How far from shape outline is bevel.
   * * bevelSegments: Number of bevel layers.
   * 
   * * extrudePath: 3d spline path to extrude shape along. (creates frames if frames aren't defined).
   * * frames: Containing arrays of tangents, normals, binormals.
   * 
   * * material: Material index for front and back faces.
   * * extrudeMaterial: Material index for extrusion and beveled faces.
   * * uvGenerator: [WorldUVGenerator] that provide UV generator functions.
   */
  ExtrudeGeometry(List<Shape> shapes,
                 {int amount: 100,
                  double bevelThickness: 6.0,
                  double bevelSize,
                  int bevelSegments: 3,
                  bool bevelEnabled: true,
                  int curveSegments: 12,
                  steps: 1, //can assume a number of steps or a List with all U's of steps
                  Curve bendPath,
                  Curve extrudePath,
                  FrenetFrames frames,
                  int material,
                  int extrudeMaterial,
                  WorldUVGenerator uvGenerator}) 
      : super() {
    if (shapes == null) {
      shapes = [];
      return;
    }

    shapebb = shapes.last.getBoundingBox();
    
    var args = {#amount: amount,
                #bevelThickness: bevelThickness,
                #bevelSize: bevelSize != null ? bevelSize : bevelThickness - 2.0,
                #bevelSegments: bevelSegments,
                #bevelEnabled: bevelEnabled,
                #curveSegments: curveSegments,
                #steps: steps,
                #bendPath: bendPath,
                #extrudePath: extrudePath,
                #frames: frames,
                #material: material,
                #extrudeMaterial: extrudeMaterial,
                #uvGenerator: uvGenerator};

    shapes.forEach((shape) => 
        Function.apply(addShape, [shape], args));

    computeCentroids();
    computeFaceNormals();
  }

  void addShape(Shape shape, {int amount, double bevelThickness, double bevelSize, int bevelSegments, 
                bool bevelEnabled,int curveSegments, steps, Curve bendPath, Curve extrudePath, 
                FrenetFrames frames, int material, int extrudeMaterial, WorldUVGenerator uvGenerator}) {
    var extrudePts, extrudeByPath = false;
    
    var uvgen = uvGenerator != null ? uvGenerator : new ExtrudeGeometryWorldUVGenerator();
    
    var splineTube, binormal, normal, position2;
    
    if (extrudePath != null) {
      extrudePts = extrudePath.getSpacedPoints(steps);

      extrudeByPath = true;
      bevelEnabled = false; // bevels not supported for path extrusion

      // SETUP TNB variables
      
      splineTube = frames != null ? frames : new FrenetFrames(extrudePath, steps, false);
    }

    // Safeguards if bevels are not enabled
    if (!bevelEnabled) {
      bevelSegments = 0;
      bevelThickness = 0.0;
      bevelSize = 0.0;
    }

    // Variables initalization

    var bevelPoints = [];

    var shapesOffset = vertices.length;

    var shapePoints = shape.extractPoints(curveSegments);

    List _vertices = shapePoints["shape"];
    List<List<Vector2>> holes = shapePoints["holes"];

    var reverse = !ShapeUtils.isClockWise(_vertices);

    if (reverse) {
      _vertices = _vertices.reversed.toList();

      holes.forEach((ahole) {
        if (ShapeUtils.isClockWise(ahole)) {
          ahole = ahole.reversed.toList();
        }
      });

      reverse = false; 
    }


    var _faces = ShapeUtils.triangulateShape(_vertices, holes);

    /* Vertices */

    var contour = _vertices; // vertices has all points but contour has only points of circumference

    holes.forEach((ahole) => _vertices.addAll(ahole));
    
    var vlen = _vertices.length,
        flen = _faces.length,
        clen = contour.length;


    // Find directions for point movement
      
    var contourMovements = new List(clen);
  
    for (var i = 0, j = clen - 1, k = i + 1; i < clen; i++, j++, k++) {
      if (j == clen) j = 0;
      if (k == clen) k = 0;
  
      var pt_i = contour[i];
      var pt_j = contour[j];
      var pt_k = contour[k];
  
      contourMovements[i] = _getBevelVec(contour[i], contour[j], contour[k]);
    }
  
    var holesMovements = [], oneHoleMovements, verticesMovements = contourMovements.toList();
  
    holes.forEach((ahole) {
      oneHoleMovements = new List(ahole.length);
  
      for (var i = 0, il = ahole.length, j = il - 1, k = i + 1; i < il; i++, j++, k++) {
        if (j == il) j = 0;
        if (k == il) k = 0;
  
        oneHoleMovements[i] = _getBevelVec(ahole[i], ahole[j], ahole[k]);
      }
  
      holesMovements.add(oneHoleMovements);
      verticesMovements.addAll(oneHoleMovements);
    });

    for (var b = 0; b < bevelSegments; b++) {
      var t = b / bevelSegments;
      var z = bevelThickness * (1 - t);
  
      var bs = bevelSize * (Math.sin (t * Math.PI / 2));
  
      for (var i = 0; i < contour.length; i++) {
        var vert = _scalePt2(contour[i], contourMovements[i], bs);
        vertices.add(new Vector3(vert.x, vert.y, -z));
      }
  
      for (var h = 0; h < holes.length; h++) {
        var ahole = holes[h];
        oneHoleMovements = holesMovements[h];
  
        for (var i = 0; i < ahole.length; i++) {
          var vert = _scalePt2(ahole[i], oneHoleMovements[i], bs);
          vertices.add(new Vector3(vert.x, vert.y, -z));
        }
      }
    }

    var bs = bevelSize;
  
    for (var i = 0; i < vlen; i++) {
      var vert = bevelEnabled ? _scalePt2(_vertices[i], verticesMovements[i], bs) : _vertices[i];
  
      if (!extrudeByPath) {
        vertices.add(new Vector3(vert.x, vert.y, 0.0));
      } else {
        normal = new Vector3.copy(splineTube.normals[0])..scale(vert.x);
        binormal = new Vector3.copy(splineTube.binormals[0])..scale(vert.y);
  
        position2 = new Vector3.copy(extrudePts[0])..add(normal + binormal);
  
        vertices.add(position2);
      }
    }

    for (var s = 1; s <= steps; s++) {
      for (var i = 0; i < vlen; i++) {
        var vert = bevelEnabled ? _scalePt2(_vertices[i], verticesMovements[i], bs) : _vertices[i];
        
        if (!extrudeByPath) {
          vertices.add(new Vector3(vert.x, vert.y, amount / steps * s));
        } else {  
          normal = new Vector3.copy(splineTube.normals[s])..scale(vert.x);
          binormal = new Vector3.copy(splineTube.binormals[s])..scale(vert.y);
  
          position2 = new Vector3.copy(extrudePts[s]).add(normal + binormal);
  
          vertices.add(position2);
        }
      }
    }

    for (var b = bevelSegments - 1; b >= 0; b--) {
      var t = b / bevelSegments;
      var z = bevelThickness * (1 - t);
      bs = bevelSize * Math.sin (t * Math.PI/2);
  
      // contract shape
      for (var i = 0; i < clen; i++) {
        var vert = _scalePt2(contour[i], contourMovements[i], bs);
        vertices.add(new Vector3(vert.x, vert.y,  amount + z));
      }
  
      // expand holes
      for (var h = 0; h < holes.length; h++) {
        var ahole = holes[h];
        oneHoleMovements = holesMovements[h];

        for (var i = 0; i < ahole.length; i++) {
          var vert = _scalePt2(ahole[i], oneHoleMovements[i], bs);
  
          if (!extrudeByPath) {
            vertices.add(new Vector3(vert.x, vert.y,  amount + z));
          } else {
            vertices.add(new Vector3(vert.x, vert.y + extrudePts[steps - 1].y, extrudePts[steps - 1].x + z));
          }
        }
      }
    }
    
    /*
     * Internal functions.
     */
  
    f3(int a, int b, int c, bool isBottom) {
      a += shapesOffset;
      b += shapesOffset;
      c += shapesOffset;

      // normal, color, material
      faces.add(new Face3(a, b, c, null, null, material));

      var uvs = isBottom ? uvgen.generateBottomUV(this, a, b, c) : uvgen.generateTopUV(this, a, b, c);

      faceVertexUvs[0].add(uvs);
    }

    f4(int a, int b, int c, int d) {
      a += shapesOffset;
      b += shapesOffset;
      c += shapesOffset;
      d += shapesOffset;

      faces.add(new Face3(a, b, d, null, null, extrudeMaterial));
      faces.add(new Face3(b, c, d, null, null, extrudeMaterial));

      var uvs = uvgen.generateSideWallUV(this, a, b, c, d);

      faceVertexUvs[0].add([uvs[0], uvs[1], uvs[3]]);
      faceVertexUvs[0].add([uvs[1], uvs[2], uvs[3]]);
    }

    sidewalls(List<Vector2> contour, int layeroffset) {
      var j, k, i = contour.length;

      while (--i >= 0) {
        j = i;
        k = i - 1;
        if ( k < 0 ) k = contour.length - 1;
        
        var sl = steps + bevelSegments * 2;

        for (var s = 0; s < sl; s++) {
          var slen1 = vlen * s;
          var slen2 = vlen * (s + 1);

          var a = layeroffset + j + slen1,
              b = layeroffset + k + slen1,
              c = layeroffset + k + slen2,
              d = layeroffset + j + slen2;

          f4(a, b, c, d);
        }
      }
    }
    
    /*
     * Faces
     */
  
    // Top and bottom faces
    
    if (bevelEnabled) {
      var layer = 0 ; 
      var offset = vlen * layer;

      // Bottom faces
      _faces.forEach((face) => f3(face[2]+ offset, face[1]+ offset, face[0] + offset, true));

      layer = steps + bevelSegments * 2;
      offset = vlen * layer;

      // Top faces
      _faces.forEach((face) => f3(face[0] + offset, face[1] + offset, face[2] + offset, false));
    } else {
      // Bottom faces
      _faces.forEach((face) => f3(face[2], face[1], face[0], true));
    }
    
    // Top faces
    _faces.forEach((face) => f3( face[0] + vlen * steps, face[1] + vlen * steps, face[2] + vlen * steps, false));
  
    // Sides faces
    var layeroffset = 0;
    sidewalls(contour, layeroffset);
    layeroffset += contour.length;

    holes.forEach((ahole) {
      sidewalls(ahole, layeroffset);
      layeroffset += ahole.length;
    });
  }
  
  Vector2 _scalePt2(Vector2 pt, Vector2 vec, double size) => vec * size + pt;

  Vector2 _getBevelVec2(Vector2 pt_i, Vector2 pt_j, Vector2 pt_k) {
    var a = ExtrudeGeometry.__v1,
        b = ExtrudeGeometry.__v2,
        v_hat = ExtrudeGeometry.__v3,
        w_hat = ExtrudeGeometry.__v4,
        p = ExtrudeGeometry.__v5,
        q = ExtrudeGeometry.__v6;
    
    // define a as vector j->i
    // define b as vectot k->i
    a.setValues(pt_i.x - pt_j.x, pt_i.y - pt_j.y);
    b.setValues(pt_i.x - pt_k.x, pt_i.y - pt_k.y);

    // get unit vectors
    var v = a.normalize();
    var w = b.normalize();

    // normals from pt i
    v_hat.setValues(-v.y, v.x);
    w_hat.setValues(w.y, -w.x);

    // pts from i
    p.setFrom(pt_i + v_hat);
    q.setFrom(pt_i + w_hat);

    if (p == q) return w_hat.clone();

    // Points from j, k. helps prevents points cross overover most of the time

    p.setFrom(pt_j + v_hat);
    q.setFrom(pt_k + w_hat);

    var v_dot_w_hat = v.dot(w_hat);
    var q_sub_p_dot_w_hat = (q - p).dot(w_hat);

    // We should not reach these conditions

    if (v_dot_w_hat == 0) {
      print("Either infinite or no solutions!");
      if (q_sub_p_dot_w_hat == 0) {
        print("Its finite solutions.");
      } else {
        print("Too bad, no solutions.");
      }
    }

    var s = q_sub_p_dot_w_hat / v_dot_w_hat;

    if (s < 0) {
      return _getBevelVec1(pt_i, pt_j, pt_k);
    }

    var intersection = v * s + p;

    return intersection - pt_i ;
  }

  Vector2 _getBevelVec(Vector2 pt_i, Vector2 pt_j, Vector2 pt_k) => _getBevelVec2(pt_i, pt_j, pt_k);

  Vector2 _getBevelVec1(Vector2 pt_i, Vector2 pt_j, Vector2 pt_k) {
    var anglea = Math.atan2(pt_j.y - pt_i.y, pt_j.x - pt_i.x);
    var angleb = Math.atan2(pt_k.y - pt_i.y, pt_k.x - pt_i.x);

    if (anglea > angleb) {
      angleb += Math.PI * 2;
    }

    var anglec = (anglea + angleb) / 2;

    var x = -Math.cos(anglec);
    var y = -Math.sin(anglec);
    
    return new Vector2(x, y); 
  }
 
  static Vector2 __v1 = new Vector2.zero();
  static Vector2 __v2 = new Vector2.zero();
  static Vector2 __v3 = new Vector2.zero(); 
  static Vector2 __v4 = new Vector2.zero();
  static Vector2 __v5 = new Vector2.zero();
  static Vector2 __v6 = new Vector2.zero();
}

abstract class WorldUVGenerator {
  List<Vector2> generateTopUV(Geometry geometry, int indexA, int indexB, int indexC);
  List<Vector2> generateBottomUV(Geometry geometry, int indexA, int indexB, int indexC);
  List<Vector2> generateSideWallUV(Geometry geometry, int indexA, int indexB, int indexC, int indexD);
}

class ExtrudeGeometryWorldUVGenerator implements WorldUVGenerator {
  List<Vector2> generateTopUV(Geometry geometry, int indexA, int indexB, int indexC) {
    var ax = geometry.vertices[indexA].x,
        ay = geometry.vertices[indexA].y,

        bx = geometry.vertices[indexB].x,
        by = geometry.vertices[indexB].y,

        cx = geometry.vertices[indexC].x,
        cy = geometry.vertices[indexC].y;

    return [new Vector2(ax, 1.0 - ay),
            new Vector2(bx, 1.0 - by),
            new Vector2(cx, 1.0 - cy)];
  }

  List<Vector2> generateBottomUV(Geometry geometry, int indexA, int indexB, int indexC) =>
      generateTopUV(geometry, indexA, indexB, indexC);

  List<Vector2> generateSideWallUV(Geometry geometry, int indexA, int indexB, int indexC, int indexD) {
    var ax = geometry.vertices[indexA].x,
        ay = geometry.vertices[indexA].y,
        az = geometry.vertices[indexA].z,

        bx = geometry.vertices[indexB].x,
        by = geometry.vertices[indexB].y,
        bz = geometry.vertices[indexB].z,

        cx = geometry.vertices[indexC].x,
        cy = geometry.vertices[indexC].y,
        cz = geometry.vertices[indexC].z,

        dx = geometry.vertices[indexD].x,
        dy = geometry.vertices[indexD].y,
        dz = geometry.vertices[indexD].z;

    if ((ay - by).abs() < 0.01) {
      return [new Vector2(ax, 1.0 - az),
              new Vector2(bx, 1.0 - bz),
              new Vector2(cx, 1.0 - cz),
              new Vector2(dx, 1.0 - dz)];
    } else {
      return [new Vector2(ay, 1.0 - az),
              new Vector2(by, 1.0 - bz),
              new Vector2(cy, 1.0 - cz),
              new Vector2(dy, 1.0 - dz)];
    }
  }
}