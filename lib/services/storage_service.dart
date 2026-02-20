import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final _supabase = Supabase.instance.client;
  final String _bucket = 'user_profiles';

  /// Upload a profile image and return the public URL
  Future<String> uploadProfileImage(String userId, File file) async {
    try {
      final fileExt = path.extension(file.path);
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}$fileExt';
      
      await _supabase.storage.from(_bucket).upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final publicUrl = _supabase.storage.from(_bucket).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete an image (optional utility)
  Future<void> deleteImage(String path) async {
    try {
        await _supabase.storage.from(_bucket).remove([path]);
    } catch (e) {
      // ignore
    }
  }
}
