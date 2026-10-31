class PatientDocument {
  final int? id;
  final int patientId;
  final String title;
  final String filePath;
  final String fileType; // 'image', 'pdf', 'document'
  final String fileSize;
  final String uploadedAt;

  PatientDocument({
    this.id,
    required this.patientId,
    required this.title,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'patientId': patientId,
      'title': title,
      'filePath': filePath,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt,
    };
  }

  factory PatientDocument.fromMap(Map<String, dynamic> map) {
    return PatientDocument(
      id: map['id'] as int?,
      patientId: (map['patientId'] as num).toInt(),
      title: map['title'] ?? '',
      filePath: map['filePath'] ?? '',
      fileType: map['fileType'] ?? 'document',
      fileSize: map['fileSize'] ?? '0 KB',
      uploadedAt: map['uploadedAt'] ?? '',
    );
  }
}
