part of three;

class XHRLoader {
  var manager;
  
  XHRLoader([manager]) : this.manager = manager != null ? manager : DefaultLoadingManager;
  
  void load(String url, {Function onLoad, Function onProgress, Function onError}) {
    var request = new HttpRequest();
    
    if (onLoad != null) {
      request.onLoad.listen((_) {
        onLoad(request.responseText);
        manager.itemEnd(url);
      });
    }
      
    if (onProgress != null) {
      request.onProgress.listen(onProgress);
    }
    
    if (onError != null) {
      request.onError.listen(onError);
    }
        
    request.open('GET', url, async: true);
    request.send();
    
    manager.itemStart(url);
  }
}