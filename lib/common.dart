import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DrawingSegment extends Equatable {
  const DrawingSegment(
    this.pts,
    this.color,
  );
  final List<Offset> pts;
  final DrawingColor color;

  @override
  List<Object?> get props => [pts, color];
}

enum DrawingColor {
  black(Colors.black),
  red(Colors.red),
  blue(Colors.blue),
  green(Colors.green),
  white(Colors.white),
  transparent(Colors.transparent);

  const DrawingColor(this._value);

  final Color _value;
  Color get value => _value;
}

enum DrawingMode {
  drawing,
  rewind,
}

// brush color
final brushColorProvider =
    StateProvider<DrawingColor>((ref) => DrawingColor.black);

// current drawing mode :  drawing or rewind
final drawingModeProvider =
    StateProvider<DrawingMode>((ref) => DrawingMode.drawing);

// 
final drawingProvider = StateProvider<List<DrawingSegment>>((ref) => []);
