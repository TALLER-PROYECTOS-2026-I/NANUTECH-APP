import 'dart:io';

import 'package:image_picker/image_picker.dart';

class FuelReceiptService {
  final ImagePicker picker = ImagePicker();

  static const int maxSizeBytes = 5 * 1024 * 1024;

  Future<XFile?> pickFromGallery() async {
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (file == null) return null;

    await validateImage(file);
    return file;
  }

  Future<XFile?> pickFromCamera() async {
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (file == null) return null;

    await validateImage(file);
    return file;
  }

  Future<void> validateImage(XFile file) async {
    final lower = file.path.toLowerCase();

    final validFormat = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');

    if (!validFormat) {
      throw Exception('Solo se permiten archivos PNG o JPG.');
    }

    final size = await File(file.path).length();

    if (size > maxSizeBytes) {
      throw Exception('La foto del comprobante no debe superar los 5MB.');
    }
  }
}