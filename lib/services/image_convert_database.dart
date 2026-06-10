import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'dart:convert';

//SERVE PARA LER A IMAGEM TRAZENDO DO BANCO DE DADOS
class ImageProviderService {
  ImageProvider? buildImageProvider(String path) {
    if (path.isEmpty) return null;

    if (path.startsWith('data:image')) {
      try {
        final base64Str = path.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    } else if (path.startsWith('base64:')) {
      try {
        return MemoryImage(base64Decode(path.substring(7)));
      } catch (_) {
        return null;
      }
    } else if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      if (kIsWeb) {
        // No web, caminhos locais de arquivo não fazem sentido
        return null;
      }
      try {
        final file = io.File(path);
        if (file.existsSync()) {
          return FileImage(file);
        }
        return null;
      } catch (_) {
        return null;
      }
    }
  }
}