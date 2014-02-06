part of three;

class Bone extends Object3D {
  SkinnedMesh skin;
  Matrix4 skinMatrix = new Matrix4.identity();

  Bone(SkinnedMesh belongsToSkin) : skin = belongsToSkin, super();

  void update([Matrix4 parentSkinMatrix, bool forceUpdate = false]) {
    // update local
    if (matrixAutoUpdate) {
      if (forceUpdate) updateMatrix();
    }

    // update skin matrix
    if (forceUpdate || matrixWorldNeedsUpdate) {
      if(parentSkinMatrix != null) {
        skinMatrix = parentSkinMatrix * matrix;
      } else {
        skinMatrix = matrix.clone();
      }
      
      matrixWorldNeedsUpdate = false;
      forceUpdate = true;
    }

    // update children
    children.forEach((c) => c.update(skinMatrix, forceUpdate));
  }
}
