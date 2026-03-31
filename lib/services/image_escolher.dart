import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

class ImageEscolher {
  // Função para selecionar a foto
  Future<String?> escolherFoto(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      // 2. Abre o editor de corte (Crop)
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Força ser quadrado
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ajustar Foto',
            toolbarColor: Colors.pink,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true, // Impede o usuário de desalinhar o quadrado
          ),
          IOSUiSettings(
            title: 'Ajustar Foto',
            aspectRatioLockEnabled: true,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 450, height: 450),
            translations: const WebTranslations(
              title: 'Ajustar Foto',
              rotateLeftTooltip: 'Girar Esquerda',
              rotateRightTooltip: 'Girar Direita',
              cropButton: 'Confirmar',
              cancelButton: 'Cancelar',
            ),
          ),
        ],
      );
      
      if (croppedFile != null) {
        if (kIsWeb) {
          // CONVERSÃO PARA BASE64 NO WEB
          final bytes = await croppedFile.readAsBytes();
          final base64Image = base64Encode(bytes);
          return 'base64:$base64Image';
        } else {
          return croppedFile.path;
        }
      }
    }
    
    return null;
  }
}