import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:uuid/uuid.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();
  
  // Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }
  
  // Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }
  
  // Pick multiple images from gallery
  static Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
      );
      
      return pickedFiles.map((file) => File(file.path)).toList();
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }
  
  // Show image picker dialog
  static Future<File?> showImagePickerDialog(BuildContext context) async {
    File? image;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                image = await pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                image = await pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
    
    return image;
  }
  
  // Compress image
  static Future<File?> compressImage(File file) async {
    try {
      final dir = await path_provider.getTemporaryDirectory();
      final targetPath = path.join(dir.path, '${const Uuid().v4()}.jpg');
      
      // Use image_compression package or similar to compress
      // For now, we'll just return the original file
      return file;
    } catch (e) {
      print('Error compressing image: $e');
      return file;
    }
  }
}

