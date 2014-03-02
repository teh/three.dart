// r58
// TODO - dispatch events
part of three;

class Chunk {
  int start, count, index;
  Chunk({this.start, this.count, this.index});
}

class BufferGeometry implements IGeometry {
	int id = GeometryIdCount++;
	String uuid = MathUtils.generateUUID();

	// Attributes
	Map<String, GeometryAttribute> attributes = {};
	
	// Attributes typed arrays are kept only if dynamic flag is set  
  bool dynamic = false;

  // Offsets for chunks when using indexed elements
	List<Chunk> offsets = [];

	// Boundings
	Box3 boundingBox;
	Sphere boundingSphere;

	bool hasTangents = false;

	// For compatibility
	List morphTargets = [];
	
	 /*
	  *  Default attributes
	  */
  GeometryAttribute<Float32List> get aPosition => attributes[GeometryAttribute.POSITION];
  set aPosition(GeometryAttribute a) => attributes[GeometryAttribute.POSITION] = a;

  GeometryAttribute<Float32List> get aNormal => attributes[GeometryAttribute.NORMAL];
  set aNormal(GeometryAttribute a) => attributes[GeometryAttribute.NORMAL] = a; 

  GeometryAttribute<Int16List> get aIndex => attributes[GeometryAttribute.INDEX];
  set aIndex(GeometryAttribute a) => attributes[GeometryAttribute.INDEX] = a; 

  GeometryAttribute<Float32List> get aUV => attributes[GeometryAttribute.UV];
  set aUV(GeometryAttribute a) => attributes[GeometryAttribute.UV] = a; 

  GeometryAttribute<Float32List> get aTangent => attributes[GeometryAttribute.TANGENT];
  set aTangent(GeometryAttribute a) => attributes[GeometryAttribute.TANGENT] = a; 

  GeometryAttribute<Float32List> get aColor => attributes[GeometryAttribute.COLOR];
  set aColor(GeometryAttribute a) => attributes[GeometryAttribute.COLOR] = a; 
	
	void applyMatrix (Matrix4 matrix) {
		if (aPosition != null) {
		  matrix.multiplyDoubleArray(aPosition.array);
			this["verticesNeedUpdate"] = true;
		}

		if (aNormal != null) {
		  var normalMatrix = matrix.getNormalMatrix();
		  normalMatrix.multiplyDoubleArray(aNormal.array);
			this["normalsNeedUpdate"] = true;
		}
	}

	void computeBoundingBox () {
	  var positions = aPosition.array != null ? aPosition.array : [];
	  
	  boundingBox = new Box3.fromPoints(
	      new List.generate(positions.length, (i) =>
	          new Vector3.array(positions, i * 3)));


		if (positions.isEmpty) {
		  boundingBox.min.setValues(0.0, 0.0, 0.0);
			boundingBox.max.setValues(0.0, 0.0, 0.0);
		}
	}

	void computeBoundingSphere() {
	  var positions = aPosition.array != null ? aPosition.array : [];
	  
	  boundingSphere = new Sphere.fromPoints(
	      new List.generate(positions.length, (i) =>
	          new Vector3.array(positions, (i/3).toInt()))); 
	}

	void computeVertexNormals() {
		if (aPosition != null) {
		  if (aNormal == null) {
	      aNormal = new GeometryAttribute.float32(aPosition.numItems, 3);
	    } else {
	      // Reset existing normals to zero
	      aNormal.array.map((_) => 0.0);
	    }
			
		  // Indexed elements
		  if (aIndex != null) {
  			for (var j = 0; j < offsets.length; j++) {
  				var start = offsets[j].start;
  				var count = offsets[j].count;
  				var index = offsets[j].index;
  
  				for (var i = start; i < start + count; i += 3) {
  					var vA = index + aIndex.array[i];
  					var vB = index + aIndex.array[i + 1];
  					var vC = index + aIndex.array[i + 2];
  					var x, y, z;
  
  					x = aPosition.array[vA * 3];
  					y = aPosition.array[vA * 3 + 1];
  					z = aPosition.array[vA * 3 + 2];
  					var pA = new Vector3(x, y, z);
  
  					x = aPosition.array[vB * 3];
  					y = aPosition.array[vB * 3 + 1];
  					z = aPosition.array[vB * 3 + 2];
  					var pB = new Vector3(x, y, z);
  
  					x = aPosition.array[vC * 3];
  					y = aPosition.array[vC * 3 + 1];
  					z = aPosition.array[vC * 3 + 2];
  					var pC = new Vector3(x, y, z);
  
  					var cb = (pC - pB).cross(pA - pB);
  
  					aNormal.array[vA * 3]     += cb.x;
  					aNormal.array[vA * 3 + 1] += cb.y;
  					aNormal.array[vA * 3 + 2] += cb.z;
  
  					aNormal.array[vB * 3]     += cb.x;
  					aNormal.array[vB * 3 + 1] += cb.y;
  					aNormal.array[vB * 3 + 2] += cb.z;
  
  					aNormal.array[vC * 3]     += cb.x;
  					aNormal.array[vC * 3 + 1] += cb.y;
  					aNormal.array[vC * 3 + 2] += cb.z;
  				}
  			}
  	  // Non-indexed elements (unconnected triangle soup)
		  } else {
		    for (var i = 0; i < aPosition.array.length; i += 9 ) {
		      var x, y, z;
		      
          x = aPosition.array[i];
          y = aPosition.array[i + 1];
          z = aPosition.array[i + 2];
          var pA = new Vector3(x, y, z);

          x = aPosition.array[i + 3];
          y = aPosition.array[i + 4];
          z = aPosition.array[i + 5];
          var pB = new Vector3(x, y, z);

          x = aPosition.array[i + 6];
          y = aPosition.array[i + 7];
          z = aPosition.array[i + 8];
          var pC = new Vector3(x, y, z);

          var cb = (pC - pB).cross(pA - pB);

          aNormal.array[i]     = cb.x;
          aNormal.array[i + 1] = cb.y;
          aNormal.array[i + 2] = cb.z;

          aNormal.array[i + 3] = cb.x;
          aNormal.array[i + 4] = cb.y;
          aNormal.array[i + 5] = cb.z;

          aNormal.array[i + 6] = cb.x;
          aNormal.array[i + 7] = cb.y;
          aNormal.array[i + 8] = cb.z;
        }
		  }
		  
		  normalizeNormals();
			this["normalsNeedUpdate"] = true;
		}
	}
	
	void normalizeNormals() {
	  for (var i = 0; i < aNormal.array.length; i += 3) {
      var x, y, z;
      
      x = aNormal.array[i];
      y = aNormal.array[i + 1];
      z = aNormal.array[i + 2];

      var n = 1.0 / Math.sqrt(x * x + y * y + z * z);

      aNormal.array[i]     *= n;
      aNormal.array[i + 1] *= n;
      aNormal.array[i + 2] *= n;
    }
	}

	void computeTangents() {
		// based on http://www.terathon.com/code/tangent.html
		// (per vertex tangents)
	  
		if (aIndex == null || aPosition == null || aNormal == null || aUV == null) {
			print("Missing required attributes (index, position, normal or uv) in BufferGeometry.computeTangents()");
			return;
		}

		var nVertices = aPosition.numItems ~/ 3;

		if (aTangent == null) {
			aTangent = new GeometryAttribute.float32(nVertices, 4);
		}
		
		var tan1 = new List.filled(nVertices, new Vector3.zero()), 
		    tan2 = new List.filled(nVertices, new Vector3.zero());

		var sdir = new Vector3.zero(),
		    tdir = new Vector3.zero();

		var handleTriangle = (int a, int b, int c) {
			var xA = aPosition.array[a * 3];
			var yA = aPosition.array[a * 3 + 1];
			var zA = aPosition.array[a * 3 + 2];

			var xB = aPosition.array[b * 3];
			var yB = aPosition.array[b * 3 + 1];
			var zB = aPosition.array[b * 3 + 2];

			var xC = aPosition.array[c * 3];
			var yC = aPosition.array[c * 3 + 1];
			var zC = aPosition.array[c * 3 + 2];

			var uA = aUV.array[a * 2];
			var vA = aUV.array[a * 2 + 1];

			var uB = aUV.array[b * 2];
			var vB = aUV.array[b * 2 + 1];

			var uC = aUV.array[c * 2];
			var vC = aUV.array[c * 2 + 1];

			var x1 = xB - xA;
			var x2 = xC - xA;
			
			var y1 = yB - yA;
			var y2 = yC - yA;

			var z1 = zB - zA;
			var z2 = zC - zA;

			var s1 = uB - uA;
			var s2 = uC - uA;

			var t1 = vB - vA;
			var t2 = vC - vA;

			var r = 1.0 / (s1 * t2 - s2 * t1);

			var sdir = new Vector3((t2 * x1 - t1 * x2) * r,
			                       (t2 * y1 - t1 * y2) * r,
			                       (t2 * z1 - t1 * z2) * r);

			var tdir = new Vector3((s1 * x2 - s2 * x1) * r,
			                       (s1 * y2 - s2 * y1) * r,
			                       (s1 * z2 - s2 * z1) * r);
			
			tan1[a].add(sdir);
			tan1[b].add(sdir);
			tan1[c].add(sdir);

			tan2[a].add(tdir);
			tan2[b].add(tdir);
			tan2[c].add(tdir);
		};

		for (var j = 0; j < offsets.length; ++ j) {
			var start = offsets[j].start;
			var count = offsets[j].count;
			var index = offsets[j].index;

			for (var i = start; i < start + count; i += 3) {
				var iA = index + aIndex.array[i];
				var iB = index + aIndex.array[i + 1];
				var iC = index + aIndex.array[i + 2];

				handleTriangle(iA, iB, iC);
			}
		}

		var handleVertex = (v) {
		  var n = new Vector3(aNormal.array[v * 3],
		                      aNormal.array[v * 3 + 1],
		                      aNormal.array[v * 3 + 2]);
		  
			// Gram-Schmidt orthogonalize
			var tmp = new Vector3.copy(tan1[v]);
			tmp.sub(n.scaled(n.dot(tan1[v]))).normalize();

			// Calculate handedness
			var test = n.cross(tan1[v]).dot(tan2[v]);
			var w = (test < 0.0) ? -1.0 : 1.0;

			aTangent.array[v * 4] 	  = tmp.x;
			aTangent.array[v * 4 + 1] = tmp.y;
			aTangent.array[v * 4 + 2] = tmp.z;
			aTangent.array[v * 4 + 3] = w;
		};

		for (var j = 0; j < offsets.length; ++ j) {
			var start = offsets[j].start;
			var count = offsets[j].count;
			var index = offsets[j].index;

			for (var i = start; i < start + count; i += 3) {
				var iA = index + aIndex.array[i];
				var iB = index + aIndex.array[i + 1];
				var iC = index + aIndex.array[i + 2];

				handleVertex(iA);
				handleVertex(iB);
				handleVertex(iC);
			}
		}

		hasTangents = true;
		this["tangentsNeedUpdate"] = true;
	}
	
	//TODO Add clone.
	
  noSuchMethod(Invocation invocation) {
    throw new Exception('Unimplemented ${invocation.memberName}');
  }

	// Quick hack to allow setting new properties (used by the renderer)
  Map __data = {};
  operator [](String key) => __data[key];
  operator []=(String key, value) => __data[key] = value;
}






