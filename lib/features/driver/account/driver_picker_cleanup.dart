import 'dart:io';

Future<void> removeImportedDriverImage(String path) async {
  // The pinned Android and iOS file selector implementations return copies.
  // Desktop pickers return the original path.
  if (Platform.isAndroid || Platform.isIOS) {
    final copy = File(path);
    if (await copy.exists()) await copy.delete();
  }
}
