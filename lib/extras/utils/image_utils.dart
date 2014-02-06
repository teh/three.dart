library ImageUtils;

import "dart:html";
import "dart:math" as Math;
import "dart:typed_data";

import "package:three/three.dart";

String crossOrigin = 'anonymous';

Texture loadTexture(String url, {mapping, Function onLoad, Function onError}) {
  var loader = new ImageLoader()
  ..crossOrigin = crossOrigin;
  
  var texture = new Texture(null, mapping);
  
  loader.load(url, (image) {
    texture.needsUpdate = true;
    texture.image = image;
    
    if (onLoad != null) onLoad(texture);
  });
  
  texture.sourceFile = url;
  
  return texture;
}

CompressedTexture loadCompressedTexture(String url, {mapping, Function onLoad, Function onError}) {
  var texture = new CompressedTexture()
  ..mapping = mapping;

  var request = new HttpRequest();

  var buffer = request.response;
  var dds = parseDDS(buffer, true);

  texture
  ..format = dds.format
  
  ..mipmaps = dds.mipmaps
  ..image.width = dds.width
  ..image.height = dds.height

  // gl.generateMipmap fails for compressed textures
  // mipmaps must be embedded in the DDS file
  // or texture filters must not use mipmapping

  ..generateMipmaps = false
  ..needsUpdate = true;

  if (onLoad != null) onLoad(texture);

  request.onError.listen(onError);

  request.open('GET', url, async: true);
  request.responseType = "arraybuffer";
  request.send(null);

  return texture;
}

Texture loadTextureCube(List<String> array, {mapping, Function onLoad, Function onError}) {
  var images = new ImageList(1)
  ..loadCount = 0;

  var texture = new Texture()
  ..image = images;
  
  if (mapping != null) texture.mapping = mapping;

  // no flipping needed for cube textures

  texture.flipY = false;

  for (var i = 0; i < array.length; i++) {
    var cubeImage = new ImageElement();
    images[i] = cubeImage;

    cubeImage
    ..onLoad.listen((_) { 
      images.loadCount += 1;

      if (images.loadCount == 6) {
        texture.needsUpdate = true;
        if (onLoad != null) onLoad(texture);
      }
    })
    ..onError.listen(onError)
    ..crossOrigin = crossOrigin
    ..src = array[i];
  }

  return texture;
}

/* TODO 
CompressedTexture loadCompressedTextureCube(List<String> array, {mapping, onLoad, onError}) {}

CompressedTexture loadDDSTexture(String url, {mapping, onLoad, onError}) {}
*/

DDSTexture parseDDS(ByteBuffer buffer, bool loadMipmaps) {
  var dds = new DDSTexture();

  // Adapted from @toji's DDS utils
  //        https://github.com/toji/webgl-texture-utils/blob/master/texture-util/dds.js

  // All values and structures referenced from:
  // http://msdn.microsoft.com/en-us/library/bb943991.aspx/

  var DDS_MAGIC = 0x20534444;

  var DDSD_CAPS = 0x1,
      DDSD_HEIGHT = 0x2,
      DDSD_WIDTH = 0x4,
      DDSD_PITCH = 0x8,
      DDSD_PIXELFORMAT = 0x1000,
      DDSD_MIPMAPCOUNT = 0x20000,
      DDSD_LINEARSIZE = 0x80000,
      DDSD_DEPTH = 0x800000;

  var DDSCAPS_COMPLEX = 0x8,
      DDSCAPS_MIPMAP = 0x400000,
      DDSCAPS_TEXTURE = 0x1000;

  var DDSCAPS2_CUBEMAP = 0x200,
      DDSCAPS2_CUBEMAP_POSITIVEX = 0x400,
      DDSCAPS2_CUBEMAP_NEGATIVEX = 0x800,
      DDSCAPS2_CUBEMAP_POSITIVEY = 0x1000,
      DDSCAPS2_CUBEMAP_NEGATIVEY = 0x2000,
      DDSCAPS2_CUBEMAP_POSITIVEZ = 0x4000,
      DDSCAPS2_CUBEMAP_NEGATIVEZ = 0x8000,
      DDSCAPS2_VOLUME = 0x200000;

  var DDPF_ALPHAPIXELS = 0x1,
      DDPF_ALPHA = 0x2,
      DDPF_FOURCC = 0x4,
      DDPF_RGB = 0x40,
      DDPF_YUV = 0x200,
      DDPF_LUMINANCE = 0x20000;

  int fourCCToInt32(String value) =>
      value.codeUnitAt(0) +
     (value.codeUnitAt(1) << 8) +
     (value.codeUnitAt(2) << 16) +
     (value.codeUnitAt(3) << 24);

  String int32ToFourCC(int value) =>
      new String.fromCharCodes([value & 0xff,
                               (value >> 8) & 0xff,
                               (value >> 16) & 0xff,
                               (value >> 24) & 0xff]);

  Uint8List loadARGBMip(ByteBuffer buffer, int dataOffset, int width, int height) {
    var dataLength = width * height * 4;
    var srcBuffer = new Uint8List.view(buffer, dataOffset, dataLength);
    var byteArray = new Uint8List(dataLength);
    var dst = 0;
    var src = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        var b = srcBuffer[src]; src++;
        var g = srcBuffer[src]; src++;
        var r = srcBuffer[src]; src++;
        var a = srcBuffer[src]; src++;
        byteArray[dst] = r; dst++;
        byteArray[dst] = g; dst++;
        byteArray[dst] = b; dst++;
        byteArray[dst] = a; dst++;
      }
    }
    
    return byteArray;
  }

  var FOURCC_DXT1 = fourCCToInt32("DXT1");
  var FOURCC_DXT3 = fourCCToInt32("DXT3");
  var FOURCC_DXT5 = fourCCToInt32("DXT5");

  var headerLengthInt = 31; // The header length in 32 bit ints

  // Offsets into the header array

  var off_magic = 0;

  var off_size = 1;
  var off_flags = 2;
  var off_height = 3;
  var off_width = 4;

  var off_mipmapCount = 7;

  var off_pfFlags = 20;
  var off_pfFourCC = 21;
  var off_RGBBitCount = 22;
  var off_RBitMask = 23;
  var off_GBitMask = 24;
  var off_BBitMask = 25;
  var off_ABitMask = 26;

  var off_caps = 27;
  var off_caps2 = 28;
  var off_caps3 = 29;
  var off_caps4 = 30;

  // Parse header
  var header = new Int32List.view(buffer, 0, headerLengthInt);

  if (header[off_magic] != DDS_MAGIC) {
    print("ImageUtils.parseDDS(): Invalid magic number in DDS header");
    return dds;

  }

  if ((header[off_pfFlags] & DDPF_FOURCC) == 0) {
    print("ImageUtils.parseDDS(): Unsupported format, must contain a FourCC code");
    return dds;
  }

  var blockBytes;

  var fourCC = header[off_pfFourCC];

  var isRGBAUncompressed = false;
  
  if (fourCC == FOURCC_DXT1) {
    blockBytes = 8;
    dds.format = RGB_S3TC_DXT1_FORMAT;
  } else if (fourCC == FOURCC_DXT3) {
    blockBytes = 16;
    dds.format = RGBA_S3TC_DXT3_FORMAT;
  } else if (fourCC == FOURCC_DXT5) {
    blockBytes = 16;
    dds.format = RGBA_S3TC_DXT5_FORMAT;
  } else {
    if(header[off_RGBBitCount] == 32 
    && header[off_RBitMask] & 0xff0000
    && header[off_GBitMask] & 0xff00 
    && header[off_BBitMask] & 0xff
    && header[off_ABitMask] & 0xff000000) {
      isRGBAUncompressed = true;
      blockBytes = 64;
      dds.format = RGBA_FORMAT;
    } else {
      print("ImageUtils.parseDDS(): Unsupported FourCC code: ${int32ToFourCC(fourCC)}");
      return dds;
    }
  }

  dds.mipmapCount = 1;

  if ((header[off_flags] & DDSD_MIPMAPCOUNT != 0) && loadMipmaps) {
    dds.mipmapCount = Math.max(1, header[off_mipmapCount]);
  }
  
  dds.isCubemap = (header[off_caps2] & DDSCAPS2_CUBEMAP) != 0 ? true : false;

  dds.width = header[off_width];
  dds.height = header[off_height];

  var dataOffset = header[off_size] + 4;

  // Extract mipmaps buffers

  var width = dds.width;
  var height = dds.height;

  var faces = dds.isCubemap ? 6 : 1;

  for (var face = 0; face < faces; face++) {
    for (var i = 0; i < dds.mipmapCount; i++) {
      var byteArray, dataLength;

      if(isRGBAUncompressed) {
        byteArray = loadARGBMip(buffer, dataOffset, width, height);
        dataLength = byteArray.length;
      } else {
        dataLength = Math.max(4, width) / 4 * Math.max(4, height) / 4 * blockBytes;
        byteArray = new Uint8List.view(buffer, dataOffset, dataLength);
      }
      
      var mipmap = new TextureMipmap(byteArray, width, height);
      dds.mipmaps.add(mipmap);

      dataOffset += dataLength;

      width = Math.max(width * 0.5, 1);
      height = Math.max(height * 0.5, 1);
    }

    width = dds.width;
    height = dds.height;
  }

  return dds;
}

getNormalMap(image, depth) {
  // Adapted from http://www.paulbrunt.co.uk/lab/heightnormal/
  var cross = (List a, List b) => 
      [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
  
  var subtract = (List a, List b) =>
      [a[0] - b[0], a[1] - b[1], a[2] - b[2]];


  var normalize = (List a) {
    var l = Math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]);
    return [a[0] / l, a[1] / l, a[2] / l];
  };

  depth = depth | 1;

  var width = image.width;
  var height = image.height;

  var canvas = new CanvasElement();
  canvas.width = width;
  canvas.height = height;

  var context = canvas.context2D;
  context.drawImage(image, 0, 0);

  var data = context.getImageData(0, 0, width, height).data;
  var imageData = context.createImageData(width, height);
  var output = imageData.data;

  for (var x = 0; x < width; x ++) {
    for (var y = 0; y < height; y ++) {
      var ly = y - 1 < 0 ? 0 : y - 1;
      var uy = y + 1 > height - 1 ? height - 1 : y + 1;
      var lx = x - 1 < 0 ? 0 : x - 1;
      var ux = x + 1 > width - 1 ? width - 1 : x + 1;

      var points = [];
      var origin = [0, 0, data[(y * width + x) * 4] / 255 * depth];
      points.addAll([
          [- 1, 0, data[(y * width + lx) * 4] / 255 * depth],
          [- 1, - 1, data[(ly * width + lx) * 4] / 255 * depth],
          [0, - 1, data[(ly * width + x) * 4] / 255 * depth],
          [1, - 1, data[(ly * width + ux) * 4] / 255 * depth],
          [1, 0, data[(y * width + ux) * 4] / 255 * depth],
          [1, 1, data[(uy * width + ux) * 4] / 255 * depth],
          [0, 1, data[(uy * width + x) * 4] / 255 * depth],
          [- 1, 1, data[(uy * width + lx) * 4] / 255 * depth]]);
      
      var normals = [];
      var num_points = points.length;

      for (var i = 0; i < num_points; i ++) {

        var v1 = points[i];
        var v2 = points[(i + 1) % num_points];
        v1 = subtract(v1, origin);
        v2 = subtract(v2, origin);
        normals.add(normalize(cross(v1, v2)));

      }

      var normal = [0, 0, 0];

      for (var i = 0; i < normals.length; i++) {
        normal[0] += normals[i][0];
        normal[1] += normals[i][1];
        normal[2] += normals[i][2];
      }

      normal[0] /= normals.length;
      normal[1] /= normals.length;
      normal[2] /= normals.length;

      var idx = (y * width + x) * 4;

      output[idx] = ((normal[0] + 1.0) / 2.0 * 255).toInt() | 0;
      output[idx + 1] = ((normal[1] + 1.0) / 2.0 * 255).toInt() | 0;
      output[idx + 2] = (normal[2] * 255).toInt() | 0;
      output[idx + 3] = 255;
    }
  }

  context.putImageData(imageData, 0, 0);
  return canvas;
}

DataTexture generateDataTexture(int width, int height, Color color) {
  var size = width * height;
  var data = new Uint8List(3 * size);

  var r = (color.r * 255).floor();
  var g = (color.g * 255).floor();
  var b = (color.b * 255).floor();

  for (var i = 0; i < size; i ++) {
    data[i * 3] = r;
    data[i * 3 + 1] = g;
    data[i * 3 + 2] = b;

  }

  var texture = new DataTexture(data, width, height, RGB_FORMAT)
  ..needsUpdate = true;

  return texture;
}