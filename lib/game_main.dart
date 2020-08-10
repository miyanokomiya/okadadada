import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/painting.dart' show decodeImageFromList;
import 'game_field.dart';
import 'block.dart';

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
        AnimationController(duration: const Duration(seconds: 10), vsync: this)
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              this._animationController.reset();
              this._animationController.forward();
            }
          });
    this.initGameState();
    super.initState();
  }

  void initGameState() {
    var length = 10;
    var typeIndexList = List.generate(length, (i) => i)..shuffle();
    var motionGenerator = MotionGenerator(this.gameField.fieldSize, 60, length);
    this.blocks = List.generate(length, (i) {
      var motion = motionGenerator.generate(i);
      return Block.init(
          blockType: getBlockType(length, typeIndexList[i]),
          x: motion.from.dx,
          y: motion.from.dy)
        ..animation = Tween(begin: 0.0, end: 1.0).animate(_animationController)
        ..pipeAnimation = motion.transform;
    });
    this._animationController.reset();
    this._animationController.forward();
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
                ])),
            Expanded(
                child: OverflowBox(
              child: Container(
                  color: Colors.black,
                  child: ClipRect(
                    child: GestureDetector(
                      onTapDown: (details) {
                        var p =
                            this.gameField.inverseOffset(details.localPosition);
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
  static ui.Image imageDaKana;
  static bool imageLoaded = false;

  static Future<Null> initImage() async {
    if (imageLoaded) return;
    imageOka = await loadImageAsset('assets/images/oka.png');
    imageDa = await loadImageAsset('assets/images/da.png');
    imageDaKana = await loadImageAsset('assets/images/da_kana.png');
    imageLoaded = true;
  }

  GameField gameField;
  List<Block> blocks;

  _BlockListPainter(this.blocks, this.gameField) {
    initImage();
  }

  ui.Image getBlockImage(Block block) {
    switch (block.blockType) {
      case BlockType.Oka:
        return imageOka;
      case BlockType.Da:
        return imageDa;
      default:
        return imageDaKana;
    }
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

Future<ui.Image> loadImageAsset(String assetName) async {
  final data = await rootBundle.load(assetName);
  return decodeImageFromList(data.buffer.asUint8List());
}

BlockType getBlockType(int length, int index) {
  if (index < (length * 0.2).ceil()) return BlockType.Oka;
  if (index > (length * 0.7).floor()) return BlockType.Da;
  return BlockType.DaKana;
}
