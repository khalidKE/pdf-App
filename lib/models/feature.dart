import 'package:flutter/material.dart';

class Feature {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget screen;
  
  Feature({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.screen,
  });
}
