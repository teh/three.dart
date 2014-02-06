part of three;

class LoadingManager extends EventEmitter {
  int loaded = 0;
  int total = 0;
  
  Function onLoad, onProgress, onError;
  
  LoadingManager({this.onLoad, this.onProgress, this.onError});
  
  int itemStart(String url) => total++;
  
  void itemEnd(String url) {
    loaded++;
    
    if (onProgress != null) {
      onProgress(url, loaded, total);
    }
    
    if (loaded == total && onLoad != null) {
      onLoad();
    }
  }
}

final DefaultLoadingManager = new LoadingManager();