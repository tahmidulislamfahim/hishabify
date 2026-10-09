class ReportFileItem {
  final String id;
  final String filePath;
  final String fileName;
  final String fileType; // 'pdf' or 'excel'
  final int fileSize;
  final DateTime createdAt;

  ReportFileItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReportFileItem.fromMap(Map<String, dynamic> map) {
    return ReportFileItem(
      id: map['id'] as String,
      filePath: map['file_path'] as String,
      fileName: map['file_name'] as String,
      fileType: map['file_type'] as String,
      fileSize: map['file_size'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
