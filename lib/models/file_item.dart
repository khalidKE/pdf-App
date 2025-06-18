import 'package:flutter/material.dart';

enum FileType {
  pdf,
  image,
  excel,
  word,
  text,
  other,
}

class FileItem {
  final String name;
  final String path;
  final int size;
  final DateTime dateModified;
  final FileType type;
  
  FileItem({
    required this.name,
    required this.path,
    required this.size,
    required this.dateModified,
    required this.type,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'size': size,
      'dateModified': dateModified.toIso8601String(),
      'type': type.index,
    };
  }
  
  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'],
      path: json['path'],
      size: json['size'],
      dateModified: DateTime.parse(json['dateModified']),
      type: FileType.values[json['type']],
    );
  }
  
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  IconData get icon {
    switch (type) {
      case FileType.pdf:
        return Icons.picture_as_pdf;
      case FileType.image:
        return Icons.image;
      case FileType.excel:
        return Icons.table_chart;
      case FileType.word:
        return Icons.description;
      case FileType.text:
        return Icons.text_snippet;
      case FileType.other:
        return Icons.insert_drive_file;
    }
  }

  FileItem copyWith({
    String? name,
    String? path,
    int? size,
    DateTime? dateModified,
    FileType? type,
  }) {
    return FileItem(
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      dateModified: dateModified ?? this.dateModified,
      type: type ?? this.type,
    );
  }
}
