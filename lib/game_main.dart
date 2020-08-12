import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'dart:async';
import 'dart:ui' as ui;
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
    var length = 15;
    var typeIndexList = List.generate(length, (i) => i)..shuffle();
    var motionGenerator = MotionGenerator(this.gameField.fieldSize, 80, length);
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

  void tapField(Offset localPosition) {
    var p = this.gameField.inverseOffset(localPosition);
    var target = this
        .blocks
        .reversed
        .firstWhere((b) => b.testHit(p), orElse: () => null);
    if (target != null) {
      target.fix();
      setState(() {
        this.blocks.sort((a, b) => a.blockStatus == BlockStatus.Fixed &&
                b.blockStatus == BlockStatus.Moving
            ? 1
            : -1);
      });
    }
  }

  int get _fixedBlockCount =>
      this.blocks.where((b) => b.blockStatus == BlockStatus.Fixed).length;

  Widget _buildAppBar() {
    const text = Text('岡田ダダ - Play -');
    return AppBar(title: text);
  }

  Widget _buildHeader() {
    return Container(
        padding: const EdgeInsets.all(20.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('${this._fixedBlockCount} / ${this.blocks.length}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          Container(width: 20),
          RaisedButton(
            child: Text('Reset'),
            onPressed: () {
              this.initGameState();
            },
          ),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    // FIXME: should setState?
    this.gameField.screenSize = Size(screenSize.width, screenSize.height - 220);

    return Scaffold(
      appBar: _buildAppBar(),
      body: Center(
        child: Column(
          children: [
            this._buildHeader(),
            Expanded(
                child: OverflowBox(
              child: Container(
                  color: Colors.black,
                  child: ClipRect(
                    child: GestureDetector(
                      onTapDown: (details) =>
                          this.tapField(details.localPosition),
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
  static bool imageLoadStarted = false;

  static Future<Null> initImage() async {
    if (imageLoadStarted) return;
    imageLoadStarted = true;
    imageOka = await loadImageAsset('assets/images/oka.png');
    imageDa = await loadImageAsset('assets/images/da.png');
    imageDaKana = await loadImageAsset('assets/images/da_kana.png');
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
    canvas.clipRect(this.gameField.convertedRect());
    canvas.drawRect(
        this.gameField.convertedRect(),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);
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
    canvas.drawCircle(
        rect.center,
        this.gameField.convertDouble(block.radius),
        (block.blockStatus == BlockStatus.Moving
            ? (Paint()
              ..color = Colors.blue
              ..strokeWidth = 4
              ..style = PaintingStyle.stroke)
            : (Paint()
              ..color = Colors.grey
              ..style = PaintingStyle.fill)));

    var image = this.getBlockImage(block);
    if (image != null) {
      canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          rect,
          Paint());
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
