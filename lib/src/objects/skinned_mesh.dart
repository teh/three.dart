/*
 * @author mikael emtinger / http://gomo.se/
 * @author alteredq / http://alteredqualia.com/
 */

part of three;

class SkinnedMesh extends Mesh {
  bool useVertexTexture;
  
  List<Bone> bones;
  List boneMatrices;
  List boneInverses;
  
  Matrix4 identityMatrix = new Matrix4.identity();
  
  int boneTextureWidth, boneTextureHeight;
  DataTexture boneTexture;

  SkinnedMesh(Geometry geometry, Material material, {this.useVertexTexture: true}) 
      : super(geometry, material) {
    
    if (geometry.bones != null) {
      geometry.bones.forEach((gbone) {
        var p = gbone["pos"];
        var q = gbone["rotq"];
        var s = gbone["scl"];
        
        Bone bone = addBone();
        bone.name = gbone["name"];
        bone.position.copyFromArray(p);
        bone.quaternion.copyFromArray(q);
        
        if (s != null) {
          bone.scale.copyFromArray(s);
        } else {
          bone.scale = new Vector3.one();
        }
      });
      
      for (var b = 0; b < bones.length; b++) {
        var gbone = geometry.bones[b];
        var bone = bones[b];

        if (gbone["parent"] == -1) {
          add(bone);
        } else {
          bones[gbone["parent"]].add(bone);
        }
      }
      
      var nBones = bones.length;
      
      if (useVertexTexture) {
        
        // layout (1 matrix = 4 pixels)
        //        RGBA RGBA RGBA RGBA (=> column1, column2, column3, column4)
        //  with  8x8   pixel texture max   16 bones  (8 * 8  / 4)
        //        16x16 pixel texture max   64 bones (16 * 16 / 4)
        //        32x32 pixel texture max  256 bones (32 * 32 / 4)
        //        64x64 pixel texture max 1024 bones (64 * 64 / 4)

        var size;

        if (nBones > 256) {
          size = 64;
        } else if (nBones > 64) {
          size = 32;
        } else if (nBones > 16) {
          size = 16;
        } else {
          size = 8;
        }

        boneTextureWidth = size;
        boneTextureHeight = size;

        boneMatrices = new Float32List(boneTextureWidth * boneTextureHeight * 4); // 4 floats per RGBA pixel
        boneTexture = new DataTexture(boneMatrices, boneTextureWidth, boneTextureHeight, RGBA_FORMAT, type: FLOAT_TYPE);
        boneTexture.minFilter = NEAREST_FILTER;
        boneTexture.magFilter = NEAREST_FILTER;
        boneTexture.generateMipmaps = false;
        boneTexture.flipY = false;
      } else {
        boneMatrices = new Float32List(16 * nBones);
      }
      pose();
    }
  }
  
  Bone addBone([Bone bone]) {
    if (bone == null) {
      bone = new Bone(this);
    }
    
    bones.add(bone);
    return bone;
  }

  void updateMatrixWorld([force = false]) {
    var offsetMatrix = new Matrix4.identity();
    
    if (matrixAutoUpdate) updateMatrix();
    
    // update matrixWorld
    if (matrixWorldNeedsUpdate || force) {
      if (parent != null) {
        matrixWorld = parent.matrixWorld * matrix;
      } else {
        matrixWorld.setFrom(matrix);
      }
      
      matrixWorldNeedsUpdate = false; 
      force = true;
    }
    
    // update children
    children.forEach((child) {
      if (child is Bone) {
        child.update(identityMatrix, false);
      } else {
        child.updateMatrixWorld(true);
      }
    });
    
    // make a snapshot of the bones' rest position
    if (boneInverses == null) {
      boneInverses = [];
      
      bones.forEach((bone) => boneInverses.add(new Matrix4.identity()..copyInverse(bone.skinMatrix)));
    }
    
    // flatten bone matrices to array
    for (var b = 0; b < bones.length; b++) {
      // compute the offset between the current and the original transform;

      // TODO: we could get rid of this multiplication step if the skinMatrix
      // was already representing the offset; however, this requires some
      // major changes to the animation system

      offsetMatrix = bones[b].skinMatrix * boneInverses[b];
      offsetMatrix.copyIntoArray(boneMatrices, b * 16);
    }

    if (useVertexTexture) {
      boneTexture.needsUpdate = true;
    }
  }

  void pose() {
    updateMatrixWorld(true); 
    normalizeSkinWeights();
  }
  
  void normalizeSkinWeights() {
    if (geometry is Geometry) {
      geometry.skinIndices.forEach((sw) {
        var scale = 1.0 / sw.lengthManhattan();
        if (scale.isFinite) {
          sw.scale(scale);
        } else {
          sw = new Vector4.splat(1.0);
        }
      });
    } else {
      // skinning weights assumed to be normalized for BufferGeometry
    }
  }
}