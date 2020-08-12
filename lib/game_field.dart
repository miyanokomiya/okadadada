import 'package:flutter/material.dart';

class GameField {
  Size fieldSize;
  Size screenSize;
  double fieldRate;
  double screenRate;
  double scale;
  Size scaledField;
  double dx;
  double dy;
  Offset dOffset;
  Rect convertedRect;

  GameField(this.fieldSize, this.screenSize) {
    fieldRate = fieldSize.width / fieldSize.height;
    screenRate = screenSize.width / screenSize.height;
    scale = (fieldRate > screenRate
        ? screenSize.width / fieldSize.width
        : screenSize.height / fieldSize.height);
    scaledField = fieldSize * scale;
    dx = scaledField.width < screenSize.width
        ? (screenSize.width - scaledField.width) / 2
        : 0;
    dy = 5;
    dOffset = Offset(dx, dy);
    convertedRect = Rect.fromLTWH(
        dOffset.dx, dOffset.dy, scaledField.width, scaledField.height);
  }

  double convertDouble(double org) => org * scale;
  Offset convertOffset(Offset org) => org * scale + dOffset;
  Size convertSize(Size org) => org * scale;
  Offset inverseOffset(Offset org) => (org - dOffset) / scale;
}
