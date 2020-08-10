import 'package:flutter/material.dart';

class GameField {
  Size fieldSize;
  Size screenSize;

  GameField(this.fieldSize);

  double fieldRate() => fieldSize.width / fieldSize.height;
  double screenRate() => screenSize.width / screenSize.height;

  double scale() => (this.fieldRate() > this.screenRate()
      ? this.screenSize.width / this.fieldSize.width
      : this.screenSize.height / this.fieldSize.height);

  Size scaledField() => multiSize(this.fieldSize, this.scale());
  double dx() {
    var scaledWidth = this.scaledField().width;
    return scaledWidth < this.screenSize.width
        ? (this.screenSize.width - scaledWidth) / 2
        : 0;
  }

  double dy() {
    return 5;
  }

  Offset dOffset() => Offset(this.dx(), this.dy());

  Rect convertedRect() {
    var size = this.scaledField();
    var offset = this.dOffset();
    return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
  }

  double convertDouble(double org) => org * this.scale();
  Offset convertOffset(Offset org) =>
      addOffset(multiOffset(org, this.scale()), this.dOffset());
  Size convertSize(Size org) => multiSize(org, this.scale());

  Offset inverseOffset(Offset org) =>
      multiOffset(subOffset(org, this.dOffset()), 1 / this.scale());
}

Offset addOffset(Offset a, Offset b) {
  return Offset(a.dx + b.dx, a.dy + b.dy);
}

Offset subOffset(Offset a, Offset b) {
  return Offset(a.dx - b.dx, a.dy - b.dy);
}

Offset multiOffset(Offset org, double rate) {
  return Offset(org.dx * rate, org.dy * rate);
}

Size multiSize(Size org, double rate) {
  return Size(org.width * rate, org.height * rate);
}
