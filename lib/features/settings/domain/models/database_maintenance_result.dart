/// Result of a database optimize (VACUUM + ANALYZE) operation.
class DatabaseMaintenanceResult {
  const DatabaseMaintenanceResult({
    required this.success,
    this.error,
    this.sizeBeforeBytes,
    this.sizeAfterBytes,
  });

  final bool success;
  final String? error;
  final int? sizeBeforeBytes;
  final int? sizeAfterBytes;

  int? get bytesReclaimed {
    if (sizeBeforeBytes == null || sizeAfterBytes == null) return null;
    return sizeBeforeBytes! - sizeAfterBytes!;
  }
}
