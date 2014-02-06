/*
 * @author mr.doob / http://mrdoob.com/
 * @author supereggbert / http://www.paulbrunt.co.uk/
 * @author julianwa / https://github.com/julianwa
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 * @author nelson silva / http://www.inevo.pt
 *
 * based on r65
 */

part of three;

class Projector {
  RenderableObject _object;
  RenderableVertex _vertex;
  RenderableFace3 _face;
  RenderableLine _line;
  RenderableSprite _sprite;
  
  int _objectCount;
  int _vertexCount;  
  int _face3Count;  
  int _lineCount;
  int _spriteCount;
    
  List<RenderableObject> _objectPool = [];
  List<RenderableVertex> _vertexPool = [];
  List<RenderableFace3> _face3Pool = [];
  List<RenderableLine> _linePool = [];
  List<RenderableSprite> _spritePool = [];
   
  int _objectPoolLength = 0;
  int _vertexPoolLength = 0;  
  int _face3PoolLength = 0; 
  int _linePoolLength = 0;
  int _spritePoolLength = 0;
  
  ProjectorRenderData _renderData = new ProjectorRenderData();

  Vector3 _vector3 = new Vector3.zero();
  Vector4 _vector4 = new Vector4.identity();
  
  Box3 _clipBox = new Box3(new Vector3.minusOne(), new Vector3.one());
  Box3 _boundingBox = new Box3();
  List<Vector3> _points3 = new List<Vector3>(3);
  List<Vector3> _points4 = new List<Vector3>(4);
  
  Matrix4 _viewMatrix = new Matrix4.identity();
  Matrix4 _viewProjectionMatrix = new Matrix4.identity();
  
  Matrix4 _modelMatrix;
  Matrix4 _modelViewProjectionMatrix = new Matrix4.identity();
  
  Matrix3 _normalMatrix = new Matrix3.identity();
  Matrix3 _normalViewMatrix = new Matrix3.identity();
  
  Vector3 _centroid = new Vector3.zero();
  
  Frustum _frustum = new Frustum();

  Vector4 _clippedVertex1PositionScreen = new Vector4.identity();
  Vector4 _clippedVertex2PositionScreen = new Vector4.identity();

  /// Projects [vector] from object space into screen space.
  Vector3 projectVector(Vector3 vector, Camera camera) {
    camera.matrixWorldInverse.copyInverse(camera.matrixWorld);
    _viewProjectionMatrix = camera.projectionMatrix * camera.matrixWorldInverse;
    return vector.applyProjection(_viewProjectionMatrix);
  }

  /// Converts [vector] from a screen space into world space.
  Vector3 unprojectVector(Vector3 vector, Camera camera) {
    camera.projectionMatrixInverse.copyInverse(camera.projectionMatrix);
    _viewProjectionMatrix = camera.matrixWorld * camera.projectionMatrixInverse;
    return vector.applyProjection(_viewProjectionMatrix);
  }

  /// Translates [vector] from NDC (Normalized Device Coordinates) 
  /// to a [Raycaster] that can be used for picking. 
  /// NDC range from [-1.0 .. 1.0] in x (left to right) and [1.0 .. -1.0] in y (top to bottom).
  RayCaster pickingRay(Vector3 vector, Camera camera) {
    // set two vectors with opposing z values
    vector.z = -1.0;
    var end = new Vector3(vector.x, vector.y, 1.0);

    unprojectVector(vector, camera);
    unprojectVector(end, camera);

    // find direction from vector to end
    end.sub(vector).normalize();

    return new RayCaster(vector, end);
  }
  
  RenderableObject _getObject(Object3D object) {
    _object = getNextObjectInPool();
    _object.id = object.id;
    _object.object = object;

    if (object.renderDepth != null) {
      _object.z = object.renderDepth;
    } else {
      _vector3 = object.matrixWorld.getTranslation();
      _vector3.applyProjection(_viewProjectionMatrix);
      _object.z = _vector3.z;
    }

    return _object;
  }
  
  void _projectVertex(RenderableVertex vertex) {
    var position = vertex.position;
    var positionWorld = vertex.positionWorld;
    var positionScreen = vertex.positionScreen;
   
    positionWorld = new Vector3.copy(position)..applyMatrix4(_modelMatrix);
    positionScreen = new Vector4.copy(positionWorld)..applyMatrix4(_viewProjectionMatrix);
    
    var invW = 1 / positionScreen.w;
    
    positionScreen.x *= invW;
    positionScreen.y *= invW;
    positionScreen.z *= invW;
    
    vertex.visible = positionScreen.x >= -1 && positionScreen.x <= 1 &&
    positionScreen.y >= -1 && positionScreen.y <= 1 &&
    positionScreen.z >= -1 && positionScreen.z <= 1;
  }

  void _projectObject(Object3D object) {
    if (!object.visible) return;
    
    if (object is Light) {
      _renderData.lights.add(object);
    } else if (object is Mesh || object is Line) {
      if (!object.frustumCulled || _frustum.intersectsObject(object)) {
       _renderData.objects.add(_getObject(object)); 
      }
    } else if (object is Sprite) {
      _renderData.sprites.add(_getObject(object));
    }
    
    object.children.forEach((child) => _projectObject(child));
  }
  
  void _projectGraph(Object3D root, [bool sortObjects = false]) {
    _objectCount = 0;

    _renderData.objects = [];
    _renderData.sprites = [];
    _renderData.lights = [];

    _projectObject(root);

    if (sortObjects) {
      _renderData.objects.sort(_painterSort);
    }
  }

  /// Transforms a 3D scene object into 2D render data that can be 
  /// rendered in a screen with your renderer of choice, projecting 
  /// and clipping things out according to the used camera. 
  /// 
  /// If the scene were a real scene, this method would be the 
  /// equivalent of taking a picture with the camera (and developing 
  /// the film would be the next step, using a Renderer).
  ProjectorRenderData projectScene(Scene scene, Camera camera, {bool sortObjects: false, bool sortElements: false}) {
    var visible = false;
    
    _face3Count = 0;
    _lineCount = 0;
    _spriteCount = 0;
    
    _renderData.elements = [];
    
    if (scene.autoUpdate) scene.updateMatrixWorld();
    if (camera.parent == null) camera.updateMatrixWorld();
    
    _viewMatrix = camera.matrixWorldInverse..copyInverse(camera.matrixWorld);
    _viewProjectionMatrix = camera.projectionMatrix - _viewMatrix;

    _normalViewMatrix = _viewMatrix.getNormalMatrix();

    _frustum.setFromMatrix(_viewProjectionMatrix);

    _projectGraph(scene, sortObjects);
    
    _renderData.objects.forEach((object) {
      _modelMatrix = object.matrixWorld;
      
      _vertexCount = 0;
      
      if (object is Mesh) {
        var geometry = object.geometry;
        
        var vertices = geometry.vertices;
        var faces = geometry.faces;
        var faceVertexUvs = geometry.faceVertexUvs;
        
        _normalMatrix = _modelMatrix.getNormalMatrix();
        
        var isFaceMaterial = object.material is MeshFaceMaterial;
        var objectMaterials = isFaceMaterial ? object.material : null;
        
        vertices.forEach((vertex) {
          _vertex = getNextVertexInPool()
              ..position.setFrom(vertex);
          
          _projectVertex(_vertex);
        });
        
        for (var f = 0; f < faces.length; f++) {
          var face = faces[f];

          var material = isFaceMaterial ? objectMaterials.materials[face.materialIndex]
                                        : object.material;

          if (material == null) continue;

          var side = material.side;

          var v1 = _vertexPool[face.a];
          var v2 = _vertexPool[face.b];
          var v3 = _vertexPool[face.c];
          
          if (material.morphTargets == true) {
            var morphTargets = geometry.morphTargets;
            var morphInfluences = object.morphTargetInfluences;
            
            var v1p = v1.position;
            var v2p = v2.position;
            var v3p = v3.position;
            
            var vA = new Vector3.zero();
            var vB = new Vector3.zero();
            var vC = new Vector3.zero();
             
            for (var t = 0; t < morphTargets.length; t++) {
               var influence = morphInfluences[t];
 
               if (influence == 0) continue;
 
               var targets = morphTargets[t].vertices;
 
               vA.x += (targets[face.a].x - v1p.x) * influence;
               vA.y += (targets[face.a].y - v1p.y) * influence;
               vA.z += (targets[face.a].z - v1p.z) * influence;
 
               vB.x += (targets[face.b].x - v2p.x) * influence;
               vB.y += (targets[face.b].y - v2p.y) * influence;
               vB.z += (targets[face.b].z - v2p.z) * influence;
 
               vC.x += (targets[face.c].x - v3p.x) * influence;
               vC.y += (targets[face.c].y - v3p.y) * influence;
               vC.z += (targets[face.c].z - v3p.z) * influence;
             }
             
            v1.position.add(vA);
            v2.position.add(vB);
            v3.position.add(vC);

            _projectVertex(v1);
            _projectVertex(v2);
            _projectVertex(v3);
          }
          
          _points3[0] = v1.positionScreen;
          _points3[1] = v2.positionScreen;
          _points3[2] = v3.positionScreen;

          if (v1.visible || v2.visible || v3.visible ||
              _clipBox.intersectsWithBox3(_boundingBox..setFromPoints(_points3))) {

            visible = ((v3.positionScreen.x - v1.positionScreen.x) *
                       (v2.positionScreen.y - v1.positionScreen.y) -
                       (v3.positionScreen.y - v1.positionScreen.y) *
                       (v2.positionScreen.x - v1.positionScreen.x)) < 0;

            if (side == DOUBLE_SIDE || side == FRONT_SIDE) {
              _face = getNextFace3InPool();

              _face.id = object.id;
              _face.v1.copy(v1);
              _face.v2.copy(v2);
              _face.v3.copy(v3);

            } else {
              continue;
            }
          } else {
            continue;
          }

          _face.normalModel.setFrom(face.normal);

          if (!visible && (side == BACK_SIDE || side == DOUBLE_SIDE)) {
            _face.normalModel.negate();
          }
          
          _normalMatrix.transform(_face.normalModel..normalize());
          _normalViewMatrix.transform(_face.normalModelView..setFrom(_face.normalModel));
          _modelMatrix.transform3(_face.centroidModel..setFrom(face.centroid));
          
          for (var n = 0; n < Math.min(face.vertexNormals.length, 3); n++) {
            var normalModel = _face.vertexNormalsModel[n];
            normalModel.setFrom(face.vertexNormals[n]);

            if (!visible && (side == BACK_SIDE || side == DOUBLE_SIDE)) {
              normalModel.negate();
            }
            
            _normalMatrix.transform(normalModel..normalize());

            var normalModelView = _face.vertexNormalsModelView[n];
            _normalViewMatrix.transform(normalModelView..setFrom(normalModel));

          }

          _face.vertexNormalsLength = face.vertexNormals.length;

          for (var c = 0; c < Math.min(faceVertexUvs.length, 3); c++) {
            var uvs = faceVertexUvs[c][f];

            if (uvs == null) continue;

            for (var u = 0; u < uvs.length; u++) {
              _face.uvs[c][u] = uvs[u];
            }
          }

          _face.color = face.color;
          _face.material = material;

          _centroid.setFrom(_face.centroidModel)..applyProjection(_viewProjectionMatrix);

          _face.z = _centroid.z;

          _renderData.elements.add(_face);
        }
      } else if (object is Line) {
        _modelViewProjectionMatrix =_viewProjectionMatrix *_modelMatrix;

        var vertices = object.geometry.vertices;

        var v1 = getNextVertexInPool();
        v1.positionScreen.setFrom(_modelViewProjectionMatrix.transform3(vertices[0]));

        // Handle LineStrip and LinePieces
        var step = object.type == LINE_PIECES ? 2 : 1;

        for (var v = 1; v < vertices.length; v++) {

          var v1 = getNextVertexInPool();
          v1.positionScreen.setFrom(_modelViewProjectionMatrix.transform3(vertices[v]));

          if ((v + 1) % step > 0) continue;

          var v2 = _vertexPool[_vertexCount - 2];

          _clippedVertex1PositionScreen.setFrom(v1.positionScreen);
          _clippedVertex2PositionScreen.setFrom(v2.positionScreen);

          if (clipLine(_clippedVertex1PositionScreen, _clippedVertex2PositionScreen)) {
            // Perform the perspective divide
            _clippedVertex1PositionScreen.scale(1 / _clippedVertex1PositionScreen.w);
            _clippedVertex2PositionScreen.scale(1 / _clippedVertex2PositionScreen.w);

            _line = getNextLineInPool();

            _line.id = object.id;
            _line.v1.positionScreen.setFrom( _clippedVertex1PositionScreen );
            _line.v2.positionScreen.setFrom( _clippedVertex2PositionScreen );

            _line.z = Math.max(_clippedVertex1PositionScreen.z, _clippedVertex2PositionScreen.z);

            _line.material = object.material;

            if (object.material.vertexColors == VERTEX_COLORS) {

              _line.vertexColors[0].setFrom(object.geometry.colors[v]);
              _line.vertexColors[1].setFrom(object.geometry.colors[v - 1]);
            }

            _renderData.elements.add(_line);
          }
        }
      }
    });
    
    _renderData.sprites.forEach((object) {
      _modelMatrix = object.matrixWorld;

      _vector4.setValues(_modelMatrix[12], _modelMatrix[13], _modelMatrix[14], 1.0);
      _vector4.applyMatrix4(_viewProjectionMatrix);

      var invW = 1 / _vector4.w;

      _vector4.z *= invW;

      if (_vector4.z >= -1 && _vector4.z <= 1) {
        _sprite = getNextSpriteInPool()
            ..id = object.id
            ..x = _vector4.x * invW
            ..y = _vector4.y * invW
            ..z = _vector4.z
            ..object = object

            ..rotation = object.rotation

            ..scale.x = object.scale.x * (_sprite.x - (_vector4.x + camera.projectionMatrix[0]) / (_vector4.w + camera.projectionMatrix[12])).abs()
            ..scale.y = object.scale.y * (_sprite.y - (_vector4.y + camera.projectionMatrix[5]) / ( _vector4.w + camera.projectionMatrix[13])).abs()

            ..material = object.material;

        _renderData.elements.add(_sprite);
      }
    });

    if (sortElements) _renderData.elements.sort(_painterSort);
    return _renderData;
  }
  

  /*
   *  Pools
   */
  
  RenderableObject getNextObjectInPool() {
    if (_objectCount == _objectPoolLength) {
      var object = new RenderableObject();
      _objectPool.add(object);
      _objectPoolLength++;
      _objectCount++;
      return object;
    }

    return _objectPool[_objectCount++];
  }

  RenderableVertex getNextVertexInPool() {
    if (_vertexCount == _vertexPoolLength) {
      var vertex = new RenderableVertex();
      _vertexPool.add(vertex);
      _vertexPoolLength++;
      _vertexCount++;
      return vertex;
    }

    return _vertexPool[ _vertexCount++];
  }

  RenderableFace3 getNextFace3InPool() {
    if (_face3Count == _face3PoolLength) {
      var face = new RenderableFace3();
      _face3Pool.add(face);
      _face3PoolLength++;
      _face3Count++;
      return face;
    }
    
    return _face3Pool[_face3Count++];
  }


  RenderableLine getNextLineInPool() {
    if (_lineCount == _linePoolLength) {
      var line = new RenderableLine();
      _linePool.add(line);
      _linePoolLength++;
      _lineCount++;
      return line;
    }
    
    return _linePool[_lineCount++];
  }

  RenderableSprite getNextSpriteInPool() {
    if (_spriteCount == _spritePoolLength) {
      var sprite = new RenderableSprite();
      _spritePool.add(sprite);
      _spritePoolLength++;
      _spriteCount++;
      return sprite;
    }

    return _spritePool[_spriteCount++];
  }

  int _painterSort(a, b) => a.z.compareTo(b.z) != 0 ? a.z.compareTo(b.z) : b.id.compareTo(a.id);
  
  bool clipLine(Vector4 s1, Vector4 s2) {
    var alpha1 = 0, alpha2 = 1,

    // Calculate the boundary coordinate of each vertex for the near and far clip planes,
    // Z = -1 and Z = +1, respectively.
    bc1near =  s1.z + s1.w,
    bc2near =  s2.z + s2.w,
    bc1far =  -s1.z + s1.w,
    bc2far =  -s2.z + s2.w;

    if (bc1near >= 0 && bc2near >= 0 && bc1far >= 0 && bc2far >= 0) {
      // Both vertices lie entirely within all clip planes.
      return true;
    } else if ((bc1near < 0 && bc2near < 0) || (bc1far < 0 && bc2far < 0)) {
      // Both vertices lie entirely outside one of the clip planes.
      return false;
    } else {
      // The line segment spans at least one clip plane.
      if (bc1near < 0) {
        // v1 lies outside the near plane, v2 inside
        alpha1 = Math.max(alpha1, bc1near / (bc1near - bc2near));
      } else if (bc2near < 0) {
        // v2 lies outside the near plane, v1 inside
        alpha2 = Math.min(alpha2, bc1near / (bc1near - bc2near));
      }

      if (bc1far < 0) {
        // v1 lies outside the far plane, v2 inside
        alpha1 = Math.max(alpha1, bc1far / (bc1far - bc2far));
      } else if (bc2far < 0) {
        // v2 lies outside the far plane, v2 inside
        alpha2 = Math.min(alpha2, bc1far / ( bc1far - bc2far));
      }

      if (alpha2 < alpha1) {
        // The line segment spans two boundaries, but is outside both of them.
        // (This can't happen when we're only clipping against just near/far but good
        //  to leave the check here for future usage if other clip planes are added.)
        return false;

      } else {
        // Update the s1 and s2 vertices to match the clipped line segment.
        s1.lerp(s2, alpha1);
        s2.lerp(s1, 1 - alpha2);
        return true;
      }
    }
  }
}

class ProjectorRenderData {
  List objects = [];
  List sprites = [];
  List lights = [];
  List elements = [];
}






