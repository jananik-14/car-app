import 'package:idb_shim/idb_browser.dart';
import 'package:flutter/foundation.dart';

class BlobStorage {
  static final BlobStorage _instance = BlobStorage._internal();
  factory BlobStorage() => _instance;
  BlobStorage._internal();

  Database? _db;
  final String _dbName = 'wheels2drive_blob_db';
  final String _storeName = 'blobs';
  final Map<String, Uint8List> _memoryFallback = {};
  bool _useMemoryFallback = false;

  Future<void> _init() async {
    if (_db != null || _useMemoryFallback) return;

    try {
      final idbFactory = kIsWeb ? getIdbFactory() : idbFactoryMemory;
      if (idbFactory == null) {
        _useMemoryFallback = true;
        return;
      }
      
      _db = await idbFactory.open(
        _dbName,
        version: 1,
        onUpgradeNeeded: (VersionChangeEvent event) {
          Database db = event.database;
          db.createObjectStore(_storeName);
        },
      );
    } catch (e) {
      _useMemoryFallback = true;
    }
  }

  Future<void> put(String key, Uint8List bytes) async {
    await _init();
    if (_useMemoryFallback) {
      _memoryFallback[key] = bytes;
      return;
    }
    
    final txn = _db!.transaction(_storeName, idbModeReadWrite);
    final store = txn.objectStore(_storeName);
    await store.put(bytes, key);
    await txn.completed;
  }

  Future<Uint8List?> get(String key) async {
    await _init();
    if (_useMemoryFallback) {
      return _memoryFallback[key];
    }

    final txn = _db!.transaction(_storeName, idbModeReadOnly);
    final store = txn.objectStore(_storeName);
    final value = await store.getObject(key);
    
    if (value is Uint8List) {
      return value;
    } else if (value != null) {
      return Uint8List.fromList((value as List).cast<int>());
    }
    return null;
  }

  Future<void> delete(String key) async {
    await _init();
    if (_useMemoryFallback) {
      _memoryFallback.remove(key);
      return;
    }

    final txn = _db!.transaction(_storeName, idbModeReadWrite);
    final store = txn.objectStore(_storeName);
    await store.delete(key);
    await txn.completed;
  }

  Future<void> deleteByPrefix(String prefix) async {
    await _init();
    if (_useMemoryFallback) {
      _memoryFallback.removeWhere((key, value) => key.startsWith(prefix));
      return;
    }

    final txn = _db!.transaction(_storeName, idbModeReadWrite);
    final store = txn.objectStore(_storeName);
    
    final keys = await store.getAllKeys(null);
    for (var key in keys) {
      if (key is String && key.startsWith(prefix)) {
        await store.delete(key);
      }
    }
    await txn.completed;
  }
}
