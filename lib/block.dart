import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'dart:async';
import 'dart:math';

enum BlockType {
  Oka,
  Da,
  DaKana,
}

enum BlockStatus {
  Moving,
  Fixed,
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

  double left() => this.x - this.width / 2;
  double right() => this.x + this.width / 2;
  double top() => this.y - this.height / 2;
  double bottom() => this.y + this.height / 2;
  Offset get center => Offset(this.x, this.y);
}

class Block extends RectEntity {
  BlockType blockType;
  BlockStatus blockStatus = BlockStatus.Moving;
  Animation<double> animation;
  RectEntity Function(Block) pipeAnimation;
  double radiusRate = 0.8;

  double get radius => this.width * this.radiusRate;

  Block.init({double x, double y, this.blockType}) : super.init(x, y);

  RectEntity animatedEntity() => this.pipeAnimation(this);

  bool testHit(Offset p) {
    var center = this.animatedEntity().center;
    return (p - center).distance < this.radius;
  }

  void fix() {
    this.blockStatus = BlockStatus.Fixed;
    this.radiusRate = 2;
    var fixed = this.animatedEntity();
    this.pipeAnimation = (Block _) => fixed;
  }
}

class MotionGenerator {
  Size field;
  double itemInterval;
  int count;
  Random random = Random();

  MotionGenerator(this.field, this.itemInterval, this.count);

  double margin() => 2 * this.itemInterval;

  MotionData generate(int index) {
    return this.toBottom(this.random.nextDouble(), index);
  }

  MotionData toBottom(double rate, int index) {
    var delay = (index + 1) * this.margin();
    var d = this.field.height + this.margin() * this.count;
    var rotateDirection = this.getRotateDirection();
    return MotionData(
        Offset(
            this.itemInterval + rate * (this.field.width - 2 * this.itemInterval),
            0),
        (block) => block.clone()
          ..y = block.animation.value * d - delay
          ..rotation = autoRotation(block, rotateDirection));
  }

  double autoRotation(Block block, int direction) {
    return 6 * pi * block.animation.value * direction;
  }

  int getRotateDirection() {
    return 1 - 2 * this.random.nextInt(2);
  }
}

class MotionData {
  Offset from;
  RectEntity Function(Block) transform;

  MotionData(this.from, this.transform);
}
