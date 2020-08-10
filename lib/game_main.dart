import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/painting.dart' show decodeImageFromList;
import 'game_field.dart';

class GameMain extends StatefulWidget {
  @override
  _GameMainState createState() => _GameMainState();
}

class _GameMainState extends State<GameMain>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;

  GameField gameField;
  List<Block> blocks;

  @override
  void initState() {
    this.gameField = GameField(Size(500, 800));
    this._animationController =
        AnimationController(duration: const Duration(seconds: 5), vsync: this)
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              this._animationController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              this._animationController.forward();
            }
          });
    this.initGameState();
    super.initState();
  }

  void initGameState() {
    var length = 5;
    this.blocks = List.generate(length, (i) {
      return List.generate(length, (j) {
        var block = Block.init(
            x: i * 80.0 +
                this.gameField.fieldSize.width / 2 -
                80 * (length - 1) / 2,
            y: j * 80.0 +
                this.gameField.fieldSize.height / 2 -
                80 * (length - 1) / 2,
            blockType: (i + j) % 2 == 0 ? BlockType.Oka : BlockType.Da)
          ..animation =
              Tween(begin: 0.0, end: 1.0).animate(_animationController)
          ..pipeAnimation = (block) => block.clone()
            ..rotation = 2 *
                pi *
                block.animation.value *
                (block.blockType == BlockType.Oka ? 1 : -1);

        return block;
      });
    }).expand((v) => v).toList();
    _animationController.reset();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    this.gameField.screenSize = Size(screenSize.width, screenSize.height - 220);

    return Scaffold(
      appBar: AppBar(
        title: Text('岡田ダダ - Play -'),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
                padding: EdgeInsets.all(20.0),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  RaisedButton(
                    child: Text('Reset'),
                    onPressed: () {
                      this.initGameState();
                    },
                  ),
                  Container(width: 20),
                  RaisedButton(
                    child: Text('Start/Stop'),
                    onPressed: () {
                      if (_animationController.isAnimating) {
                        _animationController.reset();
                      } else {
                        _animationController.repeat();
                      }
                    },
                  ),
                ])),
            Expanded(
                child: OverflowBox(
              child: Container(
                  color: Colors.black,
                  child: ClipRect(
                    child: GestureDetector(
                      onTapDown: (details) {
                        var p =
                            this.gameField.convertOffset(details.localPosition);
                        print("${p.dx}");
                        print("${p.dy}");
                      },
                      child: CustomPaint(
                        painter: _BlockListPainter(this.blocks, this.gameField),
                        child: Container(),
                      ),
                    ),
                  )),
            ))
          ],
        ),
      ),
    );
  }
}

class _BlockListPainter extends CustomPainter {
  static ui.Image imageOka;
  static ui.Image imageDa;
  static bool imageLoaded = false;

  static Future<Null> initImage() async {
    if (imageLoaded) return;
    imageOka = await loadImageAsset('assets/images/oka.png');
    imageDa = await loadImageAsset('assets/images/da.png');
    imageLoaded = true;
  }

  GameField gameField;
  List<Block> blocks;

  _BlockListPainter(this.blocks, this.gameField) {
    initImage();
  }

  ui.Image getBlockImage(Block block) {
    return block.blockType == BlockType.Oka ? imageOka : imageDa;
  }

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..isAntiAlias = true
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.clipRect(this.gameField.convertedRect());
    canvas.drawRect(this.gameField.convertedRect(), paint);
    this.blocks.forEach((block) => this.paintBlock(canvas, block));
  }

  void paintBlock(Canvas canvas, Block block) {
    var entity = block.animatedEntity();
    var convertedCenter =
        this.gameField.convertOffset(Offset(entity.x, entity.y));
    var rect = Rect.fromCenter(
        center: convertedCenter,
        width: this.gameField.convertDouble(block.width),
        height: this.gameField.convertDouble(block.height));

    canvas.save();
    canvas.translate(convertedCenter.dx, convertedCenter.dy);
    canvas.rotate(entity.rotation);
    canvas.translate(-convertedCenter.dx, -convertedCenter.dy);
    if (imageLoaded) {
      var image = this.getBlockImage(block);
      canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          rect,
          Paint());
    } else {
      canvas.drawRect(
          rect,
          Paint()
            ..isAntiAlias = true
            ..color = Colors.blue
            ..style = PaintingStyle.fill);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

enum BlockType {
  Oka,
  Da,
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

Future<ui.Image> loadImageAsset(String assetName) async {
  final data = await rootBundle.load(assetName);
  return decodeImageFromList(data.buffer.asUint8List());
}
