import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'dart:async';
import 'dart:math';

enum BlockType {
  Oka,
  Da,
  DaKana,
}

class RectEntity {
  double x;
  double y;
  double width;
  double height;
  double rotation;
  double scale;

  RectEntity.init(this.x, this.y)
      : this.width = 50,
        this.height = 50,
        this.rotation = 0,
        this.scale = 0;

  RectEntity clone() => RectEntity.init(this.x, this.y)
    ..width = this.width
    ..height = this.height
    ..rotation = this.rotation
    ..scale = this.scale;

  left() => this.x - this.width / 2;
  right() => this.x + this.width / 2;
  top() => this.y - this.height / 2;
  bottom() => this.y + this.height / 2;
}

class Block extends RectEntity {
  BlockType blockType;
  Animation<double> animation;
  RectEntity Function(Block) pipeAnimation;

  Block.init({double x, double y, this.blockType}) : super.init(x, y);

  RectEntity animatedEntity() => this.pipeAnimation(this);

  // bool testHit(Offset p) {
  //   var center = this.animatedOffset();
  // }
}

class MotionGenerator {
  Size field;
  double blockRadius;
  int count;
  Random random = Random();

  MotionGenerator(this.field, this.blockRadius, this.count);

  double margin() => 2 * this.blockRadius;

  MotionData generate(int index) {
    return this.toBottom(this.random.nextDouble(), index);
  }

  MotionData toBottom(double rate, int index) {
    var delay = (index + 1) * this.margin();
    var d = this.field.height + this.margin() * this.count;
    return MotionData(
        Offset(
            this.blockRadius + rate * (this.field.width - 2 * this.blockRadius),
            0),
        (block) => block.clone()
          ..y = block.animation.value * d - delay
          ..rotation = autoRotation(block));
  }

  double autoRotation(Block block) {
    return 2 * pi * block.animation.value * getRotateDirection(block.blockType);
  }

  int getRotateDirection(BlockType blockType) {
    if (blockType == BlockType.Oka) return 1;
    if (blockType == BlockType.Da) return -1;
    return 0;
  }
}

class MotionData {
  Offset from;
  RectEntity Function(Block) transform;

  MotionData(this.from, this.transform);
}
