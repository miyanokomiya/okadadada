import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
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

class BlockEntity {
  double x;
  double y;
  double width = 50;
  double height = 50;
  double rotation = 0;
  double scale = 0;
  double radiusRate = 1;

  BlockEntity.init(this.x, this.y);

  BlockEntity clone() => BlockEntity.init(this.x, this.y)
    ..width = this.width
    ..height = this.height
    ..rotation = this.rotation
    ..scale = this.scale
    ..radiusRate = this.radiusRate;

  double left() => this.x - this.width / 2;
  double right() => this.x + this.width / 2;
  double top() => this.y - this.height / 2;
  double bottom() => this.y + this.height / 2;
  Offset get center => Offset(this.x, this.y);
  double get radius => this.width * this.radiusRate;
}

class Block extends BlockEntity {
  BlockType blockType;
  BlockStatus blockStatus = BlockStatus.Moving;
  Animation<double> animation;
  BlockEntity Function(Block) pipeAnimation;
  double fixedAnimationValue = 0;

  Block.init({double x, double y, this.blockType}) : super.init(x, y);

  double get animatedValueFromFixed {
    var val = this.animation.value - this.fixedAnimationValue;
    return val >= 0 ? val : val + 1;
  }

  BlockEntity animatedEntity() => this.pipeAnimation(this);

  bool testHit(Offset p) {
    var center = this.animatedEntity().center;
    return (p - center).distance < this.radius;
  }

  void fix() {
    this.blockStatus = BlockStatus.Fixed;
    var fixed = this.animatedEntity();
    this.fixedAnimationValue = this.animation.value;
    this.pipeAnimation = (Block b) {
      var ret = fixed.clone();
      ret.radiusRate = 2.0 * max(1.0 - b.animatedValueFromFixed, 0.5);
      return ret;
    };
  }
}

class MotionGenerator {
  Size field;
  double itemInterval;
  int count;
  Random random = Random();

  MotionGenerator(this.field, this.itemInterval, this.count);

  double get margin => 2 * this.itemInterval;

  MotionData generate(int index) {
    return this.toBottom(this.random.nextDouble(), index);
  }

  MotionData toBottom(double rate, int index) {
    var delay = (index + 1) * this.margin;
    var d = this.field.height + this.margin * (this.count + 1);
    var rotateDirection = this.getRotateDirection();
    return MotionData(
        Offset(
            this.itemInterval +
                rate * (this.field.width - 2 * this.itemInterval),
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
  BlockEntity Function(Block) transform;

  MotionData(this.from, this.transform);
}
