part of three;

class CompressedTexture extends Texture {
  bool generateMipmaps = false; // WebGL currently can't generate mipmaps for compressed textures, they must be embedded in DDS file
  
  CompressedTexture({List mipmaps, 
                     int width, 
                     int height, 
                     int format, 
                     int type, 
                     int mapping, 
                     int wrapS, 
                     int wrapT, 
                     int magFilter, 
                     int minFilter,
                     int anisotropy})
      : super(new ImageElement(width: width, height: height), 
              mapping, wrapS, wrapT, magFilter, minFilter, format, type) {
    this.mipmaps = mipmaps;
  }
}
