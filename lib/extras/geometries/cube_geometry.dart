/*
 * @author mr.doob / http://mrdoob.com/
 * based on http://papervision3d.googlecode.com/svn/trunk/as3/trunk/src/org/papervision3d/objects/primitives/Cube.as
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 * 
 * based on r63
 */

part of three;

/// CubeGeometry is the quadrilateral primitive geometry class. It is typically used 
/// for creating a cube or irregular quadrilateral of the dimensions provided with 
/// the 'width', 'height', and 'depth' constructor arguments.
class CubeGeometry extends Geometry {
  final double width;
  final double height;
  final double depth;
  final int widthSegments;
  final int heightSegments;
  final int depthSegments;
  
  /// ##Parameters
  /// * [width]: Width of the sides on the X axis.
  /// * [height]: Height of the sides on the Y axis.
  /// * [depth]: Depth of the sides on the Z axis.
  /// * [widthSegments]: Number of segmented faces along the width of the sides. Default is 1.
  /// * [heightSegments]: Number of segmented faces along the height of the sides. Default is 1.
  /// * [depthSegments]: Number of segmented faces along the depth of the sides. Default is 1.
  CubeGeometry(this.width, 
               this.height, 
               this.depth, 
              [this.widthSegments = 1, 
               this.heightSegments = 1, 
               this.depthSegments = 1]) : super() {
    var width_half = width / 2;
    var height_half = height / 2;
    var depth_half = depth / 2;
    
    _buildPlane('z', 'y', -1, -1, depth, height,  width_half,  0); // px
    _buildPlane('z', 'y',  1, -1, depth, height, -width_half,  1); // nx
    _buildPlane('x', 'z',  1,  1, width, depth,   height_half, 2); // py
    _buildPlane('x', 'z',  1, -1, width, depth,  -height_half, 3); // ny
    _buildPlane('x', 'y',  1, -1, width, height,  depth_half,  4); // pz
    _buildPlane('x', 'y', -1, -1, width, height, -depth_half,  5); // nz
    
    computeCentroids();
    mergeVertices();
  }
  
  void _buildPlane(String u, String v, int udir, int vdir, double width, double height, double depth, int materialIndex) {
    var w,
        gridX = widthSegments,
        gridY = heightSegments,
        width_half = width / 2,
        height_half = height / 2,
        offset = vertices.length;
    
    var m = {"x": 0, "y": 1, "z": 2};

    if ((u == 'x' && v == 'y') || (u == 'y' && v == 'x')) {
      w = 'z';
    } else if ((u == 'x' && v == 'z') || (u == 'z' && v == 'x')) {
      w = 'y';
      gridY = depthSegments;
    } else if ((u == 'z' && v == 'y') || (u == 'y' && v == 'z')) {
      w = 'x';
      gridX = depthSegments;
    }

    var gridX1 = gridX + 1,
        gridY1 = gridY + 1,
        segment_width = width / gridX,
        segment_height = height / gridY;
        
    var normal = new Vector3.zero();
    normal[m[w]] = depth > 0 ? 1.0 : - 1.0;

    for (var iy = 0; iy < gridY1; iy ++) {
      for (var ix = 0; ix < gridX1; ix ++) {
        var vector = new Vector3.zero();
        vector[m[u]] = (ix * segment_width - width_half) * udir;
        vector[m[v]] = (iy * segment_height - height_half) * vdir;
        vector[m[w]] = depth;

        vertices.add(vector);
      }
    }

    for (var iy = 0; iy < gridY; iy++) {
      for (var ix = 0; ix < gridX; ix++) {
        var a = ix + gridX1 * iy;
        var b = ix + gridX1 * (iy + 1);
        var c = (ix + 1) + gridX1 * (iy + 1);
        var d = (ix + 1) + gridX1 * iy;

        var uva = new Vector2(ix / gridX, 1 - iy / gridY);
        var uvb = new Vector2(ix / gridX, 1 - (iy + 1) / gridY);
        var uvc = new Vector2((ix + 1) / gridX, 1 - (iy + 1) / gridY);
        var uvd = new Vector2((ix + 1) / gridX, 1 - iy / gridY);

        var face = new Face3(a + offset, b + offset, d + offset, new List.filled(3, normal.clone()), null, materialIndex)
        ..normal.setFrom(normal);
        faces.add(face);
        faceVertexUvs[0].add([uva, uvb, uvd]);

        face = new Face3(b + offset, c + offset, d + offset, new List.filled(3, normal.clone()), null, materialIndex)
        ..normal.setFrom(normal);
        faces.add(face);
        faceVertexUvs[0].add([uvb.clone(), uvc, uvd.clone()]);
      }
    }
  }
}