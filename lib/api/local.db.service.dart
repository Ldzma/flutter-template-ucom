import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocalDBService {
  // Almacenamiento en memoria para Windows y Web
  static final Map<String, List<Map<String, dynamic>>> _memoryStorage = {};
  
  // Variable estática para almacenar el modo de almacenamiento
  static bool _useMemoryStorage = false;
  
  // Inicialización del servicio
  static Future<void> initialize() async {
    if (kIsWeb) {
      _useMemoryStorage = true;
    } else {
      try {
        // Intentar acceder al directorio de documentos
        final dir = await getApplicationDocumentsDirectory();
        _useMemoryStorage = false;
      } catch (e) {
        print("Error al inicializar el almacenamiento: $e");
        _useMemoryStorage = true;
      }
    }
  }

  Future<String> _getFilePath(String filename) async {
    if (_useMemoryStorage) {
      return filename;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}/$filename';
    } catch (e) {
      print("Error al obtener el directorio de documentos: $e");
      _useMemoryStorage = true;
      return filename;
    }
  }

  Future<File> _getFile(String filename, {bool forceUpdate = false}) async {
    if (_useMemoryStorage) {
      if (!_memoryStorage.containsKey(filename) || forceUpdate) {
        try {
          final data = await rootBundle.loadString('assets/data/$filename');
          _memoryStorage[filename] = List<Map<String, dynamic>>.from(jsonDecode(data));
        } catch (e) {
          print("Error al cargar datos del bundle: $e");
          rethrow;
        }
      }
      return File.fromRawPath(utf8.encode(jsonEncode(_memoryStorage[filename])));
    }

    try {
      final path = await _getFilePath(filename);
      final file = File(path);

      if (forceUpdate || !await file.exists()) {
        try {
          final data = await rootBundle.loadString('assets/data/$filename');
          await file.writeAsString(data);
        } catch (e) {
          print("Error al cargar datos del bundle: $e");
          rethrow;
        }
      }

      return file;
    } catch (e) {
      print("Error al obtener el archivo: $e");
      _useMemoryStorage = true;
      try {
        final data = await rootBundle.loadString('assets/data/$filename');
        _memoryStorage[filename] = List<Map<String, dynamic>>.from(jsonDecode(data));
        return File.fromRawPath(utf8.encode(data));
      } catch (e) {
        print("Error al cargar datos del bundle como fallback: $e");
        rethrow;
      }
    }
  }

  Future<List<Map<String, dynamic>>> getAll(String filename, {bool forceUpdate = false}) async {
    if (_useMemoryStorage) {
      if (!_memoryStorage.containsKey(filename) || forceUpdate) {
        try {
          final data = await rootBundle.loadString('assets/data/$filename');
          _memoryStorage[filename] = List<Map<String, dynamic>>.from(jsonDecode(data));
        } catch (e) {
          print("Error al cargar datos del bundle: $e");
          rethrow;
        }
      }
      return _memoryStorage[filename]!;
    }

    try {
      final file = await _getFile(filename, forceUpdate: forceUpdate);
      final contents = await file.readAsString();
      return List<Map<String, dynamic>>.from(jsonDecode(contents));
    } catch (e) {
      print("Error al obtener datos: $e");
      _useMemoryStorage = true;
      try {
        final data = await rootBundle.loadString('assets/data/$filename');
        _memoryStorage[filename] = List<Map<String, dynamic>>.from(jsonDecode(data));
        return _memoryStorage[filename]!;
      } catch (e) {
        print("Error al cargar datos del bundle como fallback: $e");
        rethrow;
      }
    }
  }

  Future<void> saveAll(String filename, List<Map<String, dynamic>> data) async {
    if (_useMemoryStorage) {
      _memoryStorage[filename] = data;
      return;
    }

    try {
      final file = await _getFile(filename);
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print("Error al guardar datos: $e");
      _useMemoryStorage = true;
      _memoryStorage[filename] = data;
    }
  }

  Future<void> add(String filename, Map<String, dynamic> newItem) async {
    try {
      final list = await getAll(filename);
      list.add(newItem);
      await saveAll(filename, list);
    } catch (e) {
      print("Error al agregar item: $e");
      rethrow;
    }
  }

  Future<void> update(String filename, String key, String value, Map<String, dynamic> updatedItem) async {
    try {
      final list = await getAll(filename);
      final index = list.indexWhere((e) => e[key] == value);
      if (index != -1) {
        list[index] = updatedItem;
        await saveAll(filename, list);
      }
    } catch (e) {
      print("Error al actualizar item: $e");
      rethrow;
    }
  }

  Future<void> delete(String filename, String key, String value) async {
    try {
      final list = await getAll(filename);
      list.removeWhere((e) => e[key] == value);
      await saveAll(filename, list);
    } catch (e) {
      print("Error al eliminar item: $e");
      rethrow;
    }
  }
}
