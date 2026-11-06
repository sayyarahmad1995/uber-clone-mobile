import 'dart:io';

Future<void> removeImportedDriverImage(String path) async {
  // The iOS file selector imports a copy.
  // Desktop pickers return the original path.
  if (Platform.isIOS) {
    final copy = File(path);
    if (await copy.exists()) await copy.delete();
  }
}

Future<void> removeCapturedDriverSelfie(String path) async {
  try {
    await File(path).delete();
  } on FileSystemException {
    // Camera files live in the operating system's temporary cache.
  }
}
