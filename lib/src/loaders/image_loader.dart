part of three;

class ImageLoader {
	var manager;
	String crossOrigin;

	ImageLoader([manager]) 
	    : manager = manager != null ? manager : DefaultLoadingManager;

	void load(String url, Function onLoad, {Function onError}) {
	  var image = new ImageElement()
	  ..src = url;
	  
	  if (onLoad != null) {
	    image.onLoad.listen((_) {
	      manager.itemEnd(url);
	      onLoad(image);
	    });
	  }
	  
	  // on progress?
	 
	  if (onError != null) {
      image.onError.listen((_) => manager.itemEnd(url));
      onLoad(this);
    }

		if (crossOrigin != null) image.crossOrigin = crossOrigin;
		
		manager.itemStart(url);
	}
}