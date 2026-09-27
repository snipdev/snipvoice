import '../models/voice_entry.dart';
import 'library_service.dart';
import 'storage_service.dart';

/// Collects the image-attach flow for an entry in one place:
/// pick file -> copy into the media folder -> add to list/persistence.
///
/// Return value: true if at least one image was added (for UI feedback).
Future<bool> attachImagesToEntry({
  required LibraryService library,
  required StorageService storage,
  required VoiceEntry entry,
  required String dialogTitle,
}) async {
  final picked = await storage.importImages(entry.id, dialogTitle);
  if (picked.isEmpty) return false;
  await library.addImages(entry.id, picked);
  return true;
}
