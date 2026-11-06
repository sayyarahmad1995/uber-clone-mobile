import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart';

import '../../auth/auth_session.dart';
import 'driver_picker_cleanup_stub.dart'
    if (dart.library.io) 'driver_picker_cleanup.dart';

const identityDocumentMaxBytes = 1024 * 1024;
const vehicleDocumentMaxBytes = 2 * 1024 * 1024;

Future<Uint8List?> pickDriverDocument(int maxBytes) async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      return await const MethodChannel(
        'higo/driver_documents',
      ).invokeMethod<Uint8List>('pickImage', {'maxBytes': maxBytes});
    } on PlatformException catch (error) {
      throw AuthError(error.message ?? 'Unable to select an image.');
    }
  }
  const images = XTypeGroup(
    label: 'JPEG or PNG',
    extensions: ['jpg', 'jpeg', 'png'],
    mimeTypes: ['image/jpeg', 'image/png'],
    uniformTypeIdentifiers: ['public.jpeg', 'public.png'],
  );
  final file = await openFile(acceptedTypeGroups: [images]);
  if (file == null) return null;
  try {
    if (await file.length() > maxBytes) {
      throw AuthError('Choose an image up to ${maxBytes ~/ 1048576} MB.');
    }
    return await file.readAsBytes();
  } finally {
    await removeImportedDriverImage(file.path);
  }
}

Future<Uint8List> prepareDriverDocument(Uint8List bytes, int maxBytes) async {
  if (bytes.isEmpty || bytes.length > maxBytes) {
    throw AuthError('Choose a JPEG or PNG of up to ${maxBytes ~/ 1048576} MB.');
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  try {
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    try {
      final width = descriptor.width;
      final height = descriptor.height;
      if (width > 4096 || height > 4096 || width * height > 8000000) {
        throw const AuthError(
          'Choose an image no larger than 4096 pixels per side and 8 megapixels.',
        );
      }
      if (width <= 2048 && height <= 2048) return bytes;
      final codec = await descriptor.instantiateCodec(
        targetWidth: width >= height ? 2048 : null,
        targetHeight: height > width ? 2048 : null,
      );
      try {
        final image = (await codec.getNextFrame()).image;
        try {
          final resized = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))?.buffer.asUint8List();
          return resized != null && resized.length < bytes.length
              ? resized
              : bytes;
        } finally {
          image.dispose();
        }
      } finally {
        codec.dispose();
      }
    } finally {
      descriptor.dispose();
    }
  } on AuthError {
    rethrow;
  } catch (_) {
    throw const AuthError('Choose a readable JPEG or PNG.');
  } finally {
    buffer.dispose();
  }
}
