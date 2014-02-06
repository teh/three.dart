part of three;

/**
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 *
 * Ported to Dart from JS by:
 * @author nelson silva / http://www.inevo.pt/
 *
 * based on r62 
 */

class JSONLoader extends Loader {
  
  bool withCredentials = false;
  
  JSONLoader({bool showStatus: false}) : super(showStatus);

  load(String url, LoadedCallback callback, {String texturePath: null}) {

    if (texturePath == null) {
      texturePath = Loader._extractUrlBase(url);
    }

    onLoadStart();
    
    _loadAjaxJSON(url, callback, texturePath);
  }

  _loadAjaxJSON(String url, LoadedCallback callback, String texturePath, {LoadProgressCallback callbackProgress: null}) {
    HttpRequest xhr = new HttpRequest();

    var length = 0;

    xhr.onReadyStateChange.listen((Event e) {
      if (xhr.readyState == HttpRequest.DONE) {
        if (xhr.status == 200 || xhr.status == 0) {
          if (!xhr.responseText.isEmpty)  {
            var json = JSON.decode(xhr.responseText);
            var result = _parse(json, texturePath);
            
            callback(result["geometry"], result["materials"]);
          } else {
            print("JSONLoader: [$url] seems to be unreachable or file there is empty");
          }

          // in context of more complex asset initialization
          // do not block on single failed file
          // maybe should go even one more level up
          
          onLoadComplete();
        } else {
          print("JSONLoader: Couldn't load [$url] [${xhr.status}]");
        }
      } else if (xhr.readyState == HttpRequest.LOADING) {
        if (callbackProgress != null) {
          if (length == 0) {
            length = xhr.getResponseHeader("Content-Length");
          }

          callbackProgress({ "total": length, "loaded": xhr.responseText.length });
        }
      } else if (xhr.readyState == HttpRequest.HEADERS_RECEIVED) {
        length = xhr.getResponseHeader("Content-Length");
      }
    });

    xhr.open("GET", url);
    xhr.withCredentials = withCredentials;
    xhr.send(null);
  }

  bool _isBitSet(value, position) => (value & (1 << position)) > 0;
  
  _parse(Map json, String texturePath) {
    var geometry = new Geometry(),
        scale = (json.containsKey("scale")) ? 1.0 / json["scale"] : 1.0;

    _parseModel(json, geometry, scale);
    
    _parseSkin(json, geometry);
    _parseMorphing(json, geometry, scale);
  
    geometry.computeCentroids();
    geometry.computeFaceNormals();
    geometry.computeBoundingSphere(); 
    
    if (!json.containsKey("materials")) {
      return { "geometry" : geometry };

    } else {
      var materials = _initMaterials(json["materials"], texturePath);
      if (_needsTangents(materials)) {
        geometry.computeTangents();
      }
      
      return { "geometry" : geometry, "materials" : materials};
    }
  }
  
  _parseModel(Map json, Geometry geometry, num scale) {
    var i, j, fi,

        offset, zLength,
    
        colorIndex, normalIndex, uvIndex, materialIndex,
    
        type,
        isQuad,
        hasMaterial,
        hasFaceVertexUv,
        hasFaceNormal, hasFaceVertexNormal,
        hasFaceColor, hasFaceVertexColor,
    
        vertex, face, faceA, faceB, color, hex, normal,
    
        uvLayer, uv, u, v,
    
        faces = json["faces"],
        vertices = json["vertices"],
        normals = json["normals"],
        colors = json["colors"],
    
        nUvLayers = 0;

    if (json.containsKey("uvs")) {
      // disregard empty arrays
      for (i = 0; i < json["uvs"].length; i++) {
        if (json["uvs"][i].isNotEmpty) {
          nUvLayers ++;
        }
      }

      for (i = 0; i < nUvLayers; i++) {
        geometry.faceVertexUvs[i] = new List(faces.length);
      }
    }

    offset = 0;
    zLength = vertices.length;

    while (offset < zLength) {
      vertex = new Vector3.zero();

      vertex.x = vertices[offset++] * scale;
      vertex.y = vertices[offset++] * scale;
      vertex.z = vertices[offset++] * scale;

      geometry.vertices.add(vertex);
    }

    offset = 0;
    zLength = faces.length;

    while (offset < zLength) {

      type = faces[offset++];

      isQuad              = _isBitSet(type, 0);
      hasMaterial         = _isBitSet(type, 1);
      hasFaceVertexUv     = _isBitSet(type, 3);
      hasFaceNormal       = _isBitSet(type, 4);
      hasFaceVertexNormal = _isBitSet(type, 5);
      hasFaceColor        = _isBitSet(type, 6);
      hasFaceVertexColor  = _isBitSet(type, 7);

      //print("\"type\", [$type], \"bits\", [$isQuad], [$hasMaterial], [$hasFaceVertexUv], [$hasFaceNormal], [$hasFaceVertexNormal], [$hasFaceColor], [$hasFaceVertexColor]");

      if (isQuad) {
        faceA = new Face3();
        faceA.a = faces[offset];
        faceA.b = faces[offset + 1];
        faceA.c = faces[offset + 3];

        faceB = new Face3();
        faceB.a = faces[offset + 1];
        faceB.b = faces[offset + 2];
        faceB.c = faces[offset + 3];

        offset += 4;

        if (hasMaterial) {

          materialIndex = faces[offset++];
          faceA.materialIndex = materialIndex;
          faceB.materialIndex = materialIndex;
        }

        // to get face <=> uv index correspondence

        fi = geometry.faces.length;
        if (hasFaceVertexUv) {
          for (i = 0; i < nUvLayers; i++) {
            uvLayer = json["uvs"][i];
            
            geometry.faceVertexUvs[i][fi] = [];
            geometry.faceVertexUvs[i][fi + 1] = [];

            for (j = 0; j < 4; j ++) {
              uvIndex = faces[offset++];

              u = uvLayer[uvIndex * 2];
              v = uvLayer[uvIndex * 2 + 1];

              uv = new Vector2(u, v);

              if (j != 2) geometry.faceVertexUvs[i][fi].add(uv);
              if (j != 0) geometry.faceVertexUvs[i][fi + 1].add(uv);
            }
          }
        }

        if (hasFaceNormal) {

          normalIndex = faces[offset++] * 3;

          faceA.normal.setValues(
              normals[normalIndex++],
              normals[normalIndex++],
              normals[normalIndex]
         );

          faceB.normal = faceA.normal;
        }

        if (hasFaceVertexNormal) {

          for (i = 0; i < 4; i++) {
            normalIndex = faces[offset++] * 3;

            normal = new Vector3(
                normals[normalIndex++],
                normals[normalIndex++],
                normals[normalIndex]
           );


            if (i != 2) faceA.vertexNormals.add(normal);
            if (i != 0) faceB.vertexNormals.add(normal);
          }
        }

        if (hasFaceColor) {
          colorIndex = faces[offset++];
          hex = colors[colorIndex];

          faceA.color.setHex(hex);
          faceB.color.setHex(hex);
        }

        if (hasFaceVertexColor) {
          for (i = 0; i < 4; i++) {
            colorIndex = faces[offset++];
            hex = colors[colorIndex];

            if (i != 2) faceA.vertexColors.add(new Color(hex));
            if (i != 0) faceB.vertexColors.add(new Color(hex));
          }
        }

        geometry.faces.add(faceA);
        geometry.faces.add(faceB);

      } else {
        face = new Face3();
        face.a = faces[offset++];
        face.b = faces[offset++];
        face.c = faces[offset++];

        if (hasMaterial) {
          materialIndex = faces[offset++];
          face.materialIndex = materialIndex;
        }

        // to get face <=> uv index correspondence
        
        fi = geometry.faces.length;

        if (hasFaceVertexUv) {
          for (i = 0; i < nUvLayers; i++) {
            uvLayer = json["uvs"][i];

            geometry.faceVertexUvs[i][fi] = [];

            for (j = 0; j < 3; j++) {
              uvIndex = faces[offset ++];

              u = uvLayer[uvIndex * 2];
              v = uvLayer[uvIndex * 2 + 1];

              uv = new Vector2(u, v);

              geometry.faceVertexUvs[i][fi].add(uv);
            }
          }
        }

        if (hasFaceNormal) {
          normalIndex = faces[offset++] * 3;

          face.normal.setValues(
              normals[normalIndex++],
              normals[normalIndex++],
              normals[normalIndex]);
        }

        if (hasFaceVertexNormal) {
          for (i = 0; i < 3; i++) {
            normalIndex = faces[offset++] * 3;

            normal = new Vector3(
                normals[normalIndex++],
                normals[normalIndex++],
                normals[normalIndex]);
            
            face.vertexNormals.add(normal);
          }
        }

        if (hasFaceColor) {
          colorIndex = faces[offset ++];
          face.color.setHex(colors[colorIndex]);
        }

        if (hasFaceVertexColor) {
          for (i = 0; i < 3; i++) {
            colorIndex = faces[offset ++];
            face.vertexColors.add(new Color(colors[colorIndex]));
          }
      
          geometry.faces.add(face);
        }
      }  
    }
  }
  
  _parseSkin(Map json, Geometry geometry) {
    var x, y, z, w, i, l, a, b, c, d;

    if (json.containsKey("skinWeights")) {
      l = json["skinWeights"].length;
      
      for (i = 0; i < l; i += 2) {
        x = json["skinWeights"][i    ].toDouble();
        y = json["skinWeights"][i + 1].toDouble();
        z = 0.0;
        w = 0.0;

        geometry.skinWeights.add(new Vector4(x, y, z, w));
      }
    }

    if (json.containsKey("skinIndices")) {

      l = json["skinIndices"].length;
      for (i = 0; i < l; i += 2) {
        a = json["skinIndices"][i    ].toDouble();
        b = json["skinIndices"][i + 1].toDouble();
        c = 0.0;
        d = 0.0;

        geometry.skinIndices.add(new Vector4(a, b, c, d));
      }
    }

    geometry.bones = json["bones"];
    //could change this to json["animations"][0] or remove completely
    geometry.animation = json["animation"];
    geometry.animations = json["animations"];
  }

  _parseMorphing(Map json, Geometry geometry, num scale) {
    if (json.containsKey("morphTargets")) {
      var i, l, v, vl, dstVertices, srcVertices;

      geometry.morphTargets = new List(json["morphTargets"].length);

      for (i = 0; i < geometry.morphTargets.length; i ++) {
        geometry.morphTargets[i] = new MorphTarget(json["morphTargets"][i]["name"], []);

        dstVertices = geometry.morphTargets[i].vertices;
        srcVertices = json["morphTargets"][i]["vertices"];

        vl = srcVertices.length;
        
        for(v = 0; v < vl; v += 3) {
          var vertex = new Vector3.zero();
          vertex.x = srcVertices[v] * scale;
          vertex.y = srcVertices[v + 1] * scale;
          vertex.z = srcVertices[v + 2] * scale;

          dstVertices.add(vertex);
        }
      }
    }

    if (json.containsKey("morphColors")) {
      var i, l, c, cl, dstColors, srcColors, color;

      geometry.morphColors = new List(json["morphColors"].length);

      for (i = 0; i < geometry.morphColors.length; i++) {
        dstColors = [];
        srcColors = json["morphColors"][i]["colors"];

        cl = srcColors.length;
        for (c = 0; c < cl; c += 3) {
          color = new Color(0xffaa00);
          color.setRGB(srcColors[c], srcColors[c + 1], srcColors[c + 2]);
          dstColors.add(color);
        }

        geometry.morphColors[i] = new MorphColor(json["morphColors"][i]["name"],
                                                 dstColors);
      } 
    }  
  }
}
