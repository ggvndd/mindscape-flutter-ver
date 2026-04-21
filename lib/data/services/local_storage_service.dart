/// Local storage service using Hive for offline-first approach
class LocalStorageService {
  static bool _initialized = false;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    _initialized = true;
  }

  static Future<void> clearAll() async {
    // No-op until local persistence is reintroduced.
  }
}