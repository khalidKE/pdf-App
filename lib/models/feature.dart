import 'package:flutter/material.dart';

class Feature {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget screen;
  final String category;
  final bool isPro;
  final bool isNew;
  final bool isBeta;
  final List<String> tags;
  
  const Feature({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.screen,
    required this.category,
    this.isPro = false,
    this.isNew = false,
    this.isBeta = false,
    this.tags = const [],
  });
  
  bool get hasTags => tags.isNotEmpty;
  
  bool matchesSearch(String query) {
    final searchTerms = query.toLowerCase().split(' ');
    final searchableText = '${title.toLowerCase()} ${description.toLowerCase()} ${category.toLowerCase()} ${tags.join(' ').toLowerCase()}';
    
    return searchTerms.every((term) => searchableText.contains(term));
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Feature &&
      other.title == title &&
      other.description == description &&
      other.icon == icon &&
      other.color == color &&
      other.category == category &&
      other.isPro == isPro &&
      other.isNew == isNew &&
      other.isBeta == isBeta &&
      other.tags.length == tags.length &&
      other.tags.every((tag) => tags.contains(tag));
  }
  
  @override
  int get hashCode {
    return Object.hash(
      title,
      description,
      icon,
      color,
      category,
      isPro,
      isNew,
      isBeta,
      Object.hashAll(tags),
    );
  }
}
