part of three;

class WebGLImageList { // implements ImageList
  ImageList _imageList;
  var webglTextureCube;

  WebGLImageList._internal(ImageList imageList) : _imageList = imageList;

  factory WebGLImageList(ImageList imageList) {
    if (imageList.props["__webglImageList"] == null) {
      imageList.props["__webglImageList"] = new WebGLImageList._internal(imageList);
    }

    return imageList.props["__webglImageList"];
  }

  ImageElement operator [](int index) => _imageList[index];
  void operator []=(int index, ImageElement img) { _imageList[index] = img; }
  int get length => _imageList.length;
}