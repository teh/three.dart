/*
 * @author clockworkgeek / https://github.com/clockworkgeek
 * @author timothypratley / https://github.com/timothypratley
 * @author WestLangley / http://github.com/WestLangley
 * 
 * based on r63
*/

part of three;

class PolyhedronGeometry extends Geometry {

  List _midpoints;

  // nelsonsilva - We're using a PolyhedronGeometryVertex decorator to allow adding index and uv properties
  List<PolyhedronGeometryVertex> _p = [];

  PolyhedronGeometry(List<List<num>> lvertices, List<List<num>> lfaces, [double radius = 1.0, num detail = 0]) : super() {

    _midpoints = [];

    lvertices.forEach( (vertex) {
      _prepare( new PolyhedronGeometryVertex(vertex[ 0 ].toDouble(), vertex[ 1 ].toDouble(), vertex[ 2 ].toDouble()));
    });

    lfaces.forEach((face) => _make( _p[ face[ 0 ] ], _p[ face[ 1 ] ], _p[ face[ 2 ] ], detail ));

    // TODO No need to unwrap ? (now unwrapp and add the original Vector3 to the vertices)
    _p.forEach((v) => this.vertices.add(v));

    mergeVertices();

    // Apply radius

    this.vertices.forEach((Vector3 vertex) => vertex.scale( radius ));

    computeCentroids();

    boundingSphere = new Sphere(new Vector3.zero(), radius);

  }

  // Project vector onto sphere's surface
  PolyhedronGeometryVertex _prepare( PolyhedronGeometryVertex vertex) {

    vertex.normalize();
    _p.add( vertex );
    vertex.index = _p.length - 1;

    // Texture coords are equivalent to map coords, calculate angle and convert to fraction of a circle.

    var u = _azimuth( vertex ) / 2 / Math.PI + 0.5;
    var v = _inclination( vertex ) / Math.PI + 0.5;
    vertex.uv = new Vector2( u, 1 - v );

    return vertex;

  }


  // Approximate a curved face with recursively sub-divided triangles.

  _make( PolyhedronGeometryVertex v1, PolyhedronGeometryVertex v2, PolyhedronGeometryVertex v3, detail ) {

    if ( detail < 1 ) {

      var face = new Face3( v1.index, v2.index, v3.index, [ v1.clone(), v2.clone(), v3.clone() ] );
      face.centroid.add( v1 ).add( v2 ).add( v3 ).scale( 1.0 / 3.0 );
      face.normal.setFrom(face.centroid.clone().normalize());
      this.faces.add( face );

      var azi = _azimuth( face.centroid );
      this.faceVertexUvs[ 0 ].add( [
                                     _correctUV( v1.uv, v1, azi ),
                                     _correctUV( v2.uv, v2, azi ),
                                     _correctUV( v3.uv, v3, azi )
                                     ] );

    } else {

      detail -= 1;

      // split triangle into 4 smaller triangles

      _make( v1, _midpoint( v1, v2 ), _midpoint( v1, v3 ), detail ); // top quadrant
      _make( _midpoint( v1, v2 ), v2, _midpoint( v2, v3 ), detail ); // left quadrant
      _make( _midpoint( v1, v3 ), _midpoint( v2, v3 ), v3, detail ); // right quadrant
      _make( _midpoint( v1, v2 ), _midpoint( v2, v3 ), _midpoint( v1, v3 ), detail ); // center quadrant

    }

  }

  _midpoint( v1, v2 ) {

    // TODO - nelsonsilva - refactor this code
    // arrays don't "automagically" grow in Dart!
    if ( _midpoints.length < v1.index + 1) {
      _midpoints.length = v1.index + 1;
      _midpoints[ v1.index ] = [];
    }
    if ( _midpoints.length < v2.index + 1) {
      _midpoints.length = v2.index + 1;
      _midpoints[ v2.index ] = [];
    }

    // prepare _midpoints[ v1.index ][ v2.index ]
    if (_midpoints[ v1.index ] == null ) {
      _midpoints[ v1.index ] = [];
    }

    if (_midpoints[ v1.index ].length < v2.index + 1) {
      _midpoints[ v1.index ].length = v2.index + 1;
    }

    // prepare _midpoints[ v2.index ][ v1.index ]
    if (_midpoints[ v2.index ] == null ) {
      _midpoints[ v2.index ] = [];
    }

    if (_midpoints[ v2.index ].length < v1.index + 1) {
      _midpoints[ v2.index ].length = v1.index + 1;
    }

    var mid = _midpoints[ v1.index ][ v2.index ];

    if ( mid == null ) {

      // generate mean point and project to surface with prepare()
      mid = _prepare(
          new PolyhedronGeometryVertex.fromVector3( (v1 + v2).scale(0.5) )
      );
      _midpoints[ v1.index ][ v2.index ] = mid;
      _midpoints[ v2.index ][ v1.index ] = mid;
    }

    return mid;

  }


  /// Angle around the Y axis, counter-clockwise when looking from above.
  _azimuth( vector ) => Math.atan2( vector.z, -vector.x );


  /// Angle above the XZ plane.
  _inclination( vector ) => Math.atan2( -vector.y, Math.sqrt( ( vector.x * vector.x ) + ( vector.z * vector.z ) ) );

  /// Texture fixing helper. Spheres have some odd behaviours.
  _correctUV( uv, vector, azimuth ) {
    if ( ( azimuth < 0 ) && ( uv.x == 1 ) ) uv = new Vector2( uv.x - 1, uv.y );
    if ( ( vector.x == 0 ) && ( vector.z == 0 ) ) uv = new Vector2( azimuth / 2 / Math.PI + 0.5, uv.y );
    return uv;

  }
}

/**
 * [PolyhedronGeometryVertex] is a [Vector3] decorator to allow introducing [index] and [uv].
 * */
class PolyhedronGeometryVertex extends Vector3 {
  int index;
  Vector2 uv;
  PolyhedronGeometryVertex([num x = 0.0, num y = 0.0, num z = 0.0]) : super(x.toDouble(), y.toDouble(), z.toDouble());

  PolyhedronGeometryVertex.fromVector3(Vector3 other) : super.copy(other);
}

/*

// TODO find out why this doesn't work
class PolyhedronGeometry2 extends Geometry {
  PolyhedronGeometry2(List<List<double>> lvertices, List<List<int>> lfaces, [double radius = 1.0, int detail = 0]) {
    lvertices.forEach((verts) => _prepare(new Vector3.array(verts)));

    var lf = new List.generate(lfaces.length, (i) {
      var v1 = vertices[lfaces[i][0]];
      var v2 = vertices[lfaces[i][1]];
      var v3 = vertices[lfaces[i][2]];

      return new Face3(v1._index, v2._index, v3._index, [v1.clone(), v2.clone(), v3.clone()]);
    });
    
    lf.forEach((f) => _subdivide(f, detail));

    // Handle case when face straddles the seam
    faceVertexUvs[0].forEach((uvs) {
      var x0 = uvs[0].x;
      var x1 = uvs[1].x;
      var x2 = uvs[2].x;

      var max = Math.max(x0, Math.max(x1, x2));
      var min = Math.min(x0, Math.min(x1, x2));

      if (max > 0.9 && min < 0.1) { // 0.9 is somewhat arbitrary
        if (x0 < 0.2) uvs[0].x += 1;
        if (x1 < 0.2) uvs[1].x += 1;
        if (x2 < 0.2) uvs[2].x += 1;
      }
    });
    
    // Apply radius
    vertices.forEach((vertex) => vertex.scale(radius));

    // Merge vertices
    mergeVertices();
    computeCentroids();
    computeFaceNormals();
    
    boundingSphere = new Sphere(new Vector3.zero(), radius);
  }
  
  // Project vector onto sphere's surface
  Vector3 _prepare(Vector3 vector) {
    var vertex = vector.normalize().clone();
    vertices.add(vertex);
    
    vertex._index = vertices.length - 1;

    // Texture coords are equivalent to map coords, calculate angle and convert to fraction of a circle.
    var u = _azimuth(vector) / 2 / Math.PI + 0.5;
    var v = _inclination(vector) / Math.PI + 0.5;
    vertex._uv = new Vector2(u, 1 - v);

    return vertex;
  }
  

  // Approximate a curved face with recursively sub-divided triangles.
  void _make(Vector3 v1, Vector3 v2, Vector3 v3) {
    var face = new Face3(v1._index, v2._index, v3._index, [v1.clone(), v2.clone(), v3.clone()])
    ..centroid = (v1 + v2 + v3) / 3.0;
    faces.add(face);

    var azi = _azimuth(face.centroid);

    faceVertexUvs[0].add([_correctUV(v1._uv, v1, azi),
                          _correctUV(v2._uv, v2, azi),
                          _correctUV(v3._uv, v3, azi)]);
  }
  
  // Analytically subdivide a face to the required detail level.
  void _subdivide(Face3 face, int detail) {
    var cols = Math.pow(2, detail);
    var cells = Math.pow(4, detail);
    
    var a = _prepare(vertices[face.a]);
    var b = _prepare(vertices[face.b]);
    var c = _prepare(vertices[face.c]);
    
    var v = new List.filled(cols + 1, []);

    // Construct all of the vertices for this subdivision.
    for (var i = 0; i <= cols; i++) {
      var aj = _prepare(a.clone().lerp(c, i / cols));
      var bj = _prepare(b.clone().lerp(c, i / cols));
      var rows = cols - i;

      for (var j = 0; j <= rows; j++) {
        if (j == 0 && i == cols) {
          v[i].add(aj);
        } else {
          v[i].add(_prepare(aj.clone().lerp(bj, j / rows)));
        }
      }
    }

    // Construct all of the faces.
    for (var i = 0; i < cols; i ++) {
      for (var j = 0; j < 2 * (cols - i) - 1; j++) {
        var k = (j / 2).floor();

        if (j % 2 == 0) {
          _make(v[i][k + 1],
                v[i + 1][k],
                v[i][k]);

        } else {
          _make(v[i][k + 1],
                v[i + 1][k + 1],
                v[i + 1][k]);
        }
      }
    }
  }

  // Angle around the Y axis, counter-clockwise when looking from above.
  double _azimuth(Vector3 vector) => Math.atan2(vector.z, -vector.x);

  // Angle above the XZ plane.
  double _inclination(Vector3 vector) => Math.atan2(-vector.y, Math.sqrt((vector.x * vector.x) + (vector.z * vector.z)));

  // Texture fixing helper. Spheres have some odd behaviours.
  Vector2 _correctUV(Vector2 uv, Vector3 vector, double azimuth) {
    if ((azimuth < 0) && (uv.x == 1)) uv = new Vector2(uv.x - 1, uv.y);
    if ((vector.x == 0) && (vector.z == 0)) uv = new Vector2(azimuth / 2 / Math.PI + 0.5, uv.y);
    return uv.clone();
  }
}

*/
