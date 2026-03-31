import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class ImageProviderService {
  ImageProvider? buildImageProvider(String path) {
    if (path.startsWith('data:image')) {
      // Data URI — extrair o base64 após a vírgula
      final base64Str = path.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    } else if (path.startsWith('base64:')) {
      return MemoryImage(base64Decode(path.substring(7)));
    } else if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      // Caminho local (só funciona em mobile)
      return FileImage(File(path));
    }
  }
}