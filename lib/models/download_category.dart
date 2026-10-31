class DownloadCategory {
  final int? id;
  final String name;
  final String directory;

  DownloadCategory({
    this.id,
    required this.name,
    required this.directory,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'directory': directory,
    };
  }

  factory DownloadCategory.fromMap(Map<String, dynamic> map) {
    return DownloadCategory(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Other',
      directory: map['directory'] as String? ?? '',
    );
  }
}
