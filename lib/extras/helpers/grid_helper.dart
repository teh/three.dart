part of three;

class GridHelper extends Line {
  Color color1 = new Color(0x444444);
  Color color2 = new Color(0x888888);
  
  factory GridHelper(int size, int step)  {
    for (var i = size; i <= size; i += step) {
      var size_ = size.toDouble();
      var i_ = i.toDouble();
      geometry.vertices
      ..add(new Vector3(-size_, 0.0, i_))
      ..add(new Vector3(size_ , 0.0, i_))
      ..add(new Vector3(i_,     0.0, -size_))
      ..add(new Vector3(i_,     0.0, size_));

      var color = i == 0 ? color1 : color2;
      geometry.colors = new List.filled(4, color);
    }
    
    return new Line(new Geometry(), new LineBasicMaterial(vertexColors: VERTEX_COLORS), LINE_PIECES);
  }
  
  void setColors(int colorCenterLine, int colorGrid) {
    color1.setFrom(colorCenterLine);
    color2.setFrom(colorGrid);

    geometry.colorsNeedUpdate = true;
  }
}