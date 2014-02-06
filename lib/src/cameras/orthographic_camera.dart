/*
 * @author mr.doob / http://mrdoob.com/
 * @author greggman / http://games.greggman.com/
 * @author zz85 / http://www.lab4games.net/zz85/blog
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 * 
 * based on r63
 */

part of three;

class OrthographicCamera extends Camera {
	double left;
	double right;
	double top;
	double bottom;

	OrthographicCamera(this.left, this.right, this.top, this.bottom, [double near = 0.1, double far = 2000.0]) 
	    : super(near, far) {
		updateProjectionMatrix();
	}

	void updateProjectionMatrix() {
	  projectionMatrix = new Matrix4.orthographic(left, right, top, bottom, near, far);
	}
	
	OrthographicCamera clone([OrthographicCamera camera, bool recursive = false]) {
	  camera = new OrthographicCamera(left, right, top, bottom, near, far);
	  super.clone(camera, recursive);
	  return camera;
	}
}