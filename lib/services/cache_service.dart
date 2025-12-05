import 'dart:async';

/// Simple in-memory cache service for performance optimization
/// Caches frequently accessed data to reduce Firebase reads
class CacheService {
  // Singleton pattern
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, _CacheEntry> _cache = {};
  final Map<String, Timer> _timers = {};

  /// Default cache duration (5 minutes)
  static const Duration defaultDuration = Duration(minutes: 5);

  /// Get value from cache
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (entry.isExpired) {
      remove(key);
      return null;
    }
    
    return entry.value as T?;
  }

  /// Set value in cache with optional TTL
  void set<T>(String key, T value, {Duration? ttl}) {
    final duration = ttl ?? defaultDuration;
    
    // Cancel existing timer if any
    _timers[key]?.cancel();
    
    // Store entry
    _cache[key] = _CacheEntry(
      value: value,
      expiry: DateTime.now().add(duration),
    );
    
    // Set up auto-removal timer
    _timers[key] = Timer(duration, () => remove(key));
  }

  /// Remove value from cache
  void remove(String key) {
    _cache.remove(key);
    _timers[key]?.cancel();
    _timers.remove(key);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// Check if key exists and is not expired
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    if (entry.isExpired) {
      remove(key);
      return false;
    }
    
    return true;
  }

  /// Get or fetch pattern - get from cache or fetch using provider
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? ttl,
  }) async {
    // Try cache first
    final cached = get<T>(key);
    if (cached != null) return cached;
    
    // Fetch and cache
    final value = await fetcher();
    set(key, value, ttl: ttl);
    return value;
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiry;

  _CacheEntry({required this.value, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}
