class FileTransfer {
  final String transferId;
  final String status;
  final String? codePhrase;
  final String? fileName;
  final int? fileSize;
  final DateTime createdAt;

  FileTransfer({
    required this.transferId,
    required this.status,
    this.codePhrase,
    this.fileName,
    this.fileSize,
    required this.createdAt,
  });

  factory FileTransfer.fromJson(Map<String, dynamic> json) {
    return FileTransfer(
      transferId: json['transfer_id'] ?? '',
      status: json['status'] ?? 'unknown',
      codePhrase: json['code_phrase'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
