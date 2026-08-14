import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  CacheEntry(this.data, this.timestamp);

  bool isValid(Duration ttl) {
    return DateTime.now().difference(timestamp) < ttl;
  }
}

class RepositoryCache<T> {
  final String cachePrefix;
  final T Function(dynamic json)? fromJson;
  final dynamic Function(T data)? toJson;

  final Map<String, CacheEntry<T>> _cache = {};
  final Map<String, Future<T>> _inFlightRequests = {};

  RepositoryCache({
    this.cachePrefix = 'repo_cache_',
    this.fromJson,
    this.toJson,
  });

  /// Retrieves data from memory cache, then disk cache, otherwise executes the [fetcher].
  Future<T> get(
    String key,
    Future<T> Function() fetcher, {
    required Duration ttl,
    bool forceRefresh = false,
  }) async {
    final fullKey = '$cachePrefix$key';

    if (forceRefresh) {
      await invalidate(key);
    } else {
      // 1. Check Memory Cache
      final memoryEntry = _cache[key];
      if (memoryEntry != null && memoryEntry.isValid(ttl)) {
        return memoryEntry.data;
      }

      // 2. Check Disk Cache (if serialization provided)
      if (fromJson != null) {
        final prefs = await SharedPreferences.getInstance();
        final diskData = prefs.getString(fullKey);
        final diskTimeStr = prefs.getString('${fullKey}_time');

        if (diskData != null && diskTimeStr != null) {
          final diskTime = DateTime.tryParse(diskTimeStr);
          if (diskTime != null && DateTime.now().difference(diskTime) < ttl) {
            try {
              final parsed = fromJson!(jsonDecode(diskData));
              _cache[key] = CacheEntry(parsed, diskTime);
              return parsed;
            } catch (e) {
              // Ignore disk read errors
            }
          }
        }
      }
    }

    // 3. Network Fetch
    if (_inFlightRequests.containsKey(key)) {
      return _inFlightRequests[key]!;
    }

    final future = fetcher()
        .then((data) async {
          final now = DateTime.now();
          _cache[key] = CacheEntry(data, now);

          // Save to disk
          if (toJson != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(fullKey, jsonEncode(toJson!(data)));
            await prefs.setString('${fullKey}_time', now.toIso8601String());
          }

          _inFlightRequests.remove(key);
          return data;
        })
        .catchError((error) {
          _inFlightRequests.remove(key);
          throw error;
        });

    _inFlightRequests[key] = future;
    return future;
  }

  /// Manually clears a specific cache entry (e.g., after a mutation).
  Future<void> invalidate(String key) async {
    _cache.remove(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$cachePrefix$key');
    await prefs.remove('${cachePrefix}${key}_time');
  }

  /// Clears the entire memory cache.
  void clear() {
    _cache.clear();
  }
}
