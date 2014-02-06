/*
 * @author mrdoob / http://mrdoob.com/
 * @author bhouston / http://exocortex.com/
 * @author stephomi / http://stephaneginier.com/
 */

part of three; 

class RayCaster {
  /// The Ray used for the raycasting.
  Ray ray;
  
  /// The near factor of the raycaster. This value indicates which objects can 
  /// be discarded based on the distance.This value shouldn't be negative 
  /// and should be smaller than the far property.
  double near;
  
  /// The far factor of the raycaster. This value indicates which objects can 
  /// be discarded based on the distance. This value shouldn't be negative 
  /// and should be larger than the near property.
  double far;
  
  /// The precision factor of the raycaster.
  double precision = 0.0001;
  
  double linePrecision = 1.0;
  
  Sphere sphere = new Sphere();
  Ray localRay = new Ray();
  Plane facePlane = new Plane();
  Vector3 intersectPoint = new Vector3.zero();
  Vector3 matrixPosition = new Vector3.zero();
  
  Matrix4 inverseMatrix = new Matrix4.identity();
  
  /// This class makes raycasting easier. Raycasting is used for picking and more.
  RayCaster(Vector3 origin, Vector3 direction, [this.near = 0.0, this.far = double.INFINITY])
      : ray = new Ray.originDirection(origin, direction);
  
  List<RayIntersection> _intersectObject(Object3D object, RayCaster raycaster, List<RayIntersection> intersects) {
    if (object is Sprite) {
      matrixPosition = object.matrixWorld.getTranslation();
      var distance = raycaster.ray.distanceToPoint(matrixPosition);

      if (distance > object.scale.x) {
        return intersects;
      }
      
      intersects.add(new RayIntersection(distance: distance,
                                         point: object.position,
                                         object: object));
    } else if (object is LOD) {
      matrixPosition = object.matrixWorld.getTranslation();
      var distance = raycaster.ray.origin.distanceTo(matrixPosition);
      _intersectObject(object.getObjectForDistance(distance), raycaster, intersects);

    } else if (object is Mesh) {
      var geometry = object.geometry;

      // Checking boundingSphere distance to ray
      if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

      sphere.copyFrom(geometry.boundingSphere);
      object.matrixWorld.transformSphere(sphere);

      if (raycaster.ray.intersectsWithSphere(sphere) != null) {
        return intersects;
      }

      // Check boundingBox before continuing
      inverseMatrix.copyInverse(object.matrixWorld);  
      inverseMatrix.transformRay(localRay..copyFrom(raycaster.ray));

      if (geometry.boundingBox != null) {
        if (localRay.intersectsWithBox3(geometry.boundingBox) != null)  {
          return intersects;
        }
      } 

      if (geometry is BufferGeometry) {
        var material = object.material;

        if (material == null) return intersects;
        if (!geometry.dynamic) return intersects;

        if (geometry.aIndex != null) {
          geometry.offsets.forEach((offset) {
            var start = offset.start;
            var count = offset.count;
            var index = offset.index;
            
            for (var i = start; i < start + count; i += 3) {

              var a = index + geometry.aIndex.array[i];
              var b = index + geometry.aIndex.array[i + 1]; 
              var c = index + geometry.aIndex.array[i + 2];

              var vA = new Vector3(geometry.aPosition.array[a * 3],
                                   geometry.aPosition.array[a * 3 + 1],
                                   geometry.aPosition.array[a * 3 + 2]);
              
              var vB = new Vector3(geometry.aPosition.array[b * 3],
                                   geometry.aPosition.array[b * 3 + 1],
                                   geometry.aPosition.array[b * 3 + 2]);
              
              var vC = new Vector3(geometry.aPosition.array[c * 3],
                                   geometry.aPosition.array[c * 3 + 1],
                                   geometry.aPosition.array[c * 3 + 2]);

              var intersectionPoint = material.side == BACK_SIDE
                  ? localRay.intersectsWithTriangle(
                      new Triangle(vC, vB, vA), true) 
                  : localRay.intersectsWithTriangle(
                      new Triangle(vA, vB, vC), material.side != DOUBLE_SIDE);


              if (intersectionPoint == null) continue;
              
              object.matrixWorld.transform3(intersectionPoint);

              var distance = raycaster.ray.origin.distanceTo(intersectionPoint);

              if (distance < raycaster.precision || 
                  distance < raycaster.near || 
                  distance > raycaster.far) continue;

              intersects.add(new RayIntersection(distance: distance,
                                                 point: intersectionPoint,
                                                 object: object));
            }   
          });
        } else {
          for (var i = 0; i < geometry.aPosition.array.length; i += 3) {
            var a = i;
            var b = i + 1;
            var c = i + 2;

            var vA = new Vector3(
                geometry.aPosition.array[a * 3],
                geometry.aPosition.array[a * 3 + 1],
                geometry.aPosition.array[a * 3 + 2]
            );
            var vB = new Vector3(
                geometry.aPosition.array[b * 3],
                geometry.aPosition.array[b * 3 + 1],
                geometry.aPosition.array[b * 3 + 2]
            );
            var vC = new Vector3(
                geometry.aPosition.array[c * 3],
                geometry.aPosition.array[c * 3 + 1],
                geometry.aPosition.array[c * 3 + 2]
            );
            
            var intersectionPoint = material.side == BACK_SIDE
                ? localRay.intersectsWithTriangle(new Triangle(vC, vB, vA), true) 
                : localRay.intersectsWithTriangle(new Triangle(vA, vB, vC), material.side != DOUBLE_SIDE);

            if (intersectionPoint == null) continue;

            object.matrixWorld.transform3(intersectionPoint);

            var distance = raycaster.ray.origin.distanceTo(intersectionPoint);

            if (distance < raycaster.precision || 
                distance < raycaster.near || 
                distance > raycaster.far) continue;

            intersects.add(new RayIntersection(distance: distance,
                                               point: intersectionPoint,
                                               object: object));
          }
        }
      } else if (geometry is Geometry) {
        var isFaceMaterial = object.material is MeshFaceMaterial;
        var objectMaterials = isFaceMaterial ? (object.material as MeshFaceMaterial).materials : null;
        
        var vertices = geometry.vertices;

        for (var f = 0; f < geometry.faces.length; f++) {
          var face = geometry.faces[f];

          var material = isFaceMaterial ? objectMaterials[face.materialIndex] : object.material;

          if (material == null) continue;

          var a = vertices[face.a];
          var b = vertices[face.b];
          var c = vertices[face.c];
          
          if (material.morphTargets) {
            var morphTargets = geometry.morphTargets;
            var morphInfluences = object.morphTargetInfluences;
            
            var vA = new Vector3.zero();
            var vB = new Vector3.zero();
            var vC = new Vector3.zero();

            for (var t = 0; t < morphTargets.length; t++) {
              var influence = morphInfluences[t];

              if (influence == 0) continue;

              var targets = morphTargets[t].vertices;

              vA.x += (targets[face.a].x - a.x) * influence;
              vA.y += (targets[face.a].y - a.y) * influence;
              vA.z += (targets[face.a].z - a.z) * influence;

              vB.x += (targets[face.b].x - b.x) * influence;
              vB.y += (targets[face.b].y - b.y) * influence;
              vB.z += (targets[face.b].z - b.z) * influence;

              vC.x += (targets[face.c].x - c.x) * influence;
              vC.y += (targets[face.c].y - c.y) * influence;
              vC.z += (targets[face.c].z - c.z) * influence;
            }

            vA.add(a);
            vB.add(b);
            vC.add(c);

            a = vA;
            b = vB;
            c = vC;
          }
          
          var intersectionPoint = material.side == BACK_SIDE 
              ? localRay.intersectsWithTriangle(new Triangle(c, b, a), true)
              : localRay.intersectsWithTriangle(new Triangle(a, b, c), material.side != DOUBLE_SIDE);
               
          if (intersectionPoint == null) continue;

          object.matrixWorld.transform3(intersectionPoint);

          var distance = raycaster.ray.origin.distanceTo(intersectionPoint);

          if (distance < raycaster.precision || 
              distance < raycaster.near || 
              distance > raycaster.far) continue;

          intersects.add(new RayIntersection(distance: distance,
                                             point: intersectionPoint,
                                             object: object,
                                             face: face,
                                             faceIndex: f));
        }
      }
    } else if (object is Line) {
      var precision = raycaster.linePrecision;
      var precisionSq = raycaster.precision * raycaster.precision;

      var geometry = object.geometry;

      if (geometry.boundingSphere == null) { 
        geometry.computeBoundingSphere();
      }

      // Checking boundingSphere distance to ray
      sphere.copyFrom(geometry.boundingSphere);
      object.matrixWorld.transformSphere(sphere);
      
      if (raycaster.ray.intersectsWithSphere(sphere) == null) {
        return intersects;
      }
      
      inverseMatrix.copyInverse(object.matrixWorld);
      inverseMatrix.transformRay(localRay..copyFrom(raycaster.ray));

      if (geometry is Geometry) {
        var interSegment, interRay;
        var step = object.type == LINE_STRIP ? 1 : 2;

        for (var i = 0; i < geometry.vertices.length - 1; i += step) {
          var distSq = localRay.distanceToSegmentSquared(geometry.vertices[i], 
                                                         geometry.vertices[i + 1], 
                                                         interRay, 
                                                         interSegment);
          if (distSq > precisionSq) continue;

          var distance = localRay.origin.distanceTo(interRay);

          if (distance < raycaster.near || 
              distance > raycaster.far) continue;

          intersects.add(new RayIntersection(distance: distance,
                                             // What do we want? intersection point on the ray or on the segment??
                                             // point: raycaster.ray.at(distance),
                                             point: object.matrixWorld.transform3(interSegment.clone()),
                                             object: object));
        }
      }
    }
  }
  
  void _intersectDescendants(Object3D object, RayCaster raycaster, List<RayIntersection> intersects) =>
      object.getDescendants().forEach((descendant) => _intersectObject(descendant, raycaster, intersects));
  
  /// Updates the ray with a new origin and direction.
  void copyOriginDirection(Vector3 origin, Vector3 direction) {
    ray.copyOriginDirection(origin, direction);
  }
  
  _descSort(a, b) => b.distance.compareTo(a.distance);
  
  /// Checks all intersections between the ray and the object with or without the descendants.
  List<RayIntersection> intersectObject(Object3D object, [bool recursive = false]) {
    var intersects = [];

    if (recursive) {
      _intersectDescendants(object, this, intersects);
    }

    _intersectObject(object, this, intersects);

    intersects.sort(_descSort);
    return intersects;
  }
  
  /// Checks all intersections between the ray and the objects with or without the descendants.
  List<RayIntersection> intersectObjects(List<Object3D> objects, [bool recursive = false]) {
    var intersects = [];
    
    objects.forEach((object) {
      _intersectObject(object, this, intersects);
      
      if (recursive) {
        _intersectDescendants(object, this, intersects);
      }
    });

    intersects.sort(_descSort);
    return intersects;
  }
}