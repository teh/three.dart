part of three;

class GeometryLoader {
  var manager;
  
  GeometryLoader(manager) 
      : this.manager = manager != null ? manager : DefaultLoadingManager;
  
  void load(String url, Function onLoad) {
    var loader = new XHRLoader()
    .load(url, onLoad: (text) => onLoad(parse(JSON.decode(text))));
  }
  
  Geometry parse(Map json) {} 
}