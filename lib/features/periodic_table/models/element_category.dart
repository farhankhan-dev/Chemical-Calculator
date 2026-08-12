import 'package:flutter/material.dart';

enum ElementCategory {
  alkaliMetal('Alkali Metal', Color(0xFFFF6B6B)),
  alkalineEarthMetal('Alkaline Earth Metal', Color(0xFFFF9F43)),
  transitionMetal('Transition Metal', Color(0xFFFECA57)),
  postTransitionMetal('Post-Transition Metal', Color(0xFF54A0FF)),
  metalloid('Metalloid', Color(0xFF1DD1A1)),
  reactiveNonmetal('Reactive Nonmetal', Color(0xFF5f27cd)),
  halogen('Halogen', Color(0xFF00D2D3)),
  nobleGas('Noble Gas', Color(0xFFFF9FF3)),
  lanthanide('Lanthanide', Color(0xFF48DBFB)),
  actinide('Actinide', Color(0xFFFF6B81)),
  unknown('Unknown', Color(0xFF8395A7));

  final String displayName;
  final Color color;

  const ElementCategory(this.displayName, this.color);

  /// Returns light background tint for cards/chips
  Color get bgTint => color.withValues(alpha: 0.18);
  
  /// Returns border color
  Color get borderColor => color.withValues(alpha: 0.6);
}
