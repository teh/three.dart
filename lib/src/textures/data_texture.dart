/*
 * @author alteredq / http://alteredqualia.com/
 */

part of three;

class DataTexture extends Texture {
  factory DataTexture(data,
                      int width,
                      int height,
                      int format,
                     {int type,
                      mapping,
                      int wrapS,
                      int wrapT,
                      int magFilter,
                      int minFilter,
                      int anisotropy}) {
    return new Texture(new ImageElement(src: data, width: width, height: height), 
                       mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
  }
}