class CacheManager {
  static final Map<String, dynamic> _cache = {};

  static void store(String key, dynamic value) {
    _cache[key] = value;
  }

  static dynamic retrieve(String key) {
    return _cache[key];
  }

  static void invalidate(String key) {
    _cache.remove(key);
  }

  static void invalidateAll() {
    _cache.clear();
  }
}
