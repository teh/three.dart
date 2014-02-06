/*
 * @author mr.doob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 * @author szimek / https://github.com/szimek/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 */

part of three;

class ImageList {
  int loadCount;
  List<ImageElement> _images;
  Map<String, dynamic> props = {};
  List<TextureMipmap> mipmaps = [];

  ImageList(int size) : _images = new List<ImageElement>(size);

  ImageElement operator [](int index) => _images[index];
  operator []=(int index, ImageElement img) => _images[index] = img;
  
  int get length => _images.length;
  List<ImageElement> getRange(int start, int length) => _images.getRange(start, length);

}

class Texture {
  int id = TextureIdCount++;
  String uuid = MathUtils.generateUUID();
  
  String name = '';
  
  var image;
  List<TextureMipmap> mipmaps = [];
  
  var mapping; //??

  int wrapS;
  int wrapT;
  
  int magFilter;
  int minFilter;
  
  int anisotropy;
  
  int format;
  int type;
  
  Vector2 offset = new Vector2.zero();
  Vector2 repeat = new Vector2.one();
  
  bool generateMipmaps = true;
  bool premultiplyAlpha = false;
  bool flipY = true;
  int unpackAlignment = 4; // valid values: 1, 2, 4, 8 (see http://www.khronos.org/opengles/sdk/docs/man/xhtml/glPixelStorei.xml)

  bool needsUpdate = false;
  Function onUpdate;
  
  String sourceFile;

  Texture([this.image,
           var mapping,
           this.wrapS = CLAMP_TO_EDGE_WRAPPING,
           this.wrapT = CLAMP_TO_EDGE_WRAPPING,
           this.magFilter = LINEAR_FILTER,
           this.minFilter = LINEAR_MIPMAP_LINEAR_FILTER,
           this.format = RGBA_FORMAT,
           this.type = UNSIGNED_BYTE_TYPE,
           this.anisotropy = 1])
      : this.mapping = mapping != null ? mapping : new UVMapping();

  Texture clone([Texture texture]) {
    if (texture == null) texture = new Texture();
 
    return texture
    ..image = image
    ..mipmaps = mipmaps.toList()
    
    ..mapping = mapping
    
    ..wrapS = wrapS
    ..wrapT = wrapT
    
    ..magFilter = magFilter
    ..minFilter = minFilter
    
    ..anisotropy = anisotropy
    
    ..format = format
    ..type = type
    
    ..offset.setFrom(offset)
    ..repeat.setFrom(repeat)
    
    ..generateMipmaps = generateMipmaps
    ..premultiplyAlpha = premultiplyAlpha
    ..flipY = flipY
    ..unpackAlignment;
  }

  // Quick hack to allow setting new properties (used by the renderer)
  Map __data = {};
  operator [](String k) => __data[k];
  operator []= (String k, Object v) => __data[k] = v;
}

class TextureMipmap {
  Uint8List data;
  int width;
  int height;
  
  TextureMipmap(this.data, this.width, this.height);
}

class DDSTexture {
  List<TextureMipmap> mipmaps = [];
  int width = 0, height = 0;
  var format;
  int mipmapCount = 1;
  bool isCubemap;
}
