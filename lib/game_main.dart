import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/painting.dart' show decodeImageFromList;
import 'game_field.dart';
import 'block.dart';

class GameMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    return GameApp(
        gameField: GameField(
            Size(500, 800), Size(screenSize.width, screenSize.height - 220)));
  }
}

class GameApp extends StatefulWidget {
  final GameField gameField;

  GameApp({Key key, this.gameField}) : super(key: key);

  @override
  _GameAppState createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  List<Block> blocks;

  @override
  void initState() {
    this._animationController =
        AnimationController(duration: const Duration(seconds: 15), vsync: this)
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
    var motionGenerator =
        MotionGenerator(this.widget.gameField.fieldSize, 80, length);
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
    var p = this.widget.gameField.inverseOffset(localPosition);
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
    this.widget.gameField.screenSize =
        Size(screenSize.width, screenSize.height - 220);

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
                        painter: _BlockListPainter(
                            this.blocks, this.widget.gameField),
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

  List<Block> blocks;
  GameField gameField;
  final Paint blockStrokePaint = Paint()
    ..color = Colors.blue
    ..strokeWidth = 4
    ..style = PaintingStyle.stroke;
  final Paint blockFillPaint = Paint()
    ..color = Colors.grey
    ..style = PaintingStyle.fill;

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
    canvas.clipRect(this.gameField.convertedRect);
    canvas.drawRect(
        this.gameField.convertedRect,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);

    this.paintBlockList(
        canvas,
        this
            .blocks
            .where((block) => block.blockStatus == BlockStatus.Moving)
            .toList());
    this.paintBlockList(
        canvas,
        this
            .blocks
            .where((block) => block.blockStatus != BlockStatus.Moving)
            .toList());
  }

  void paintBlockList(Canvas canvas, List<Block> _blocks) {
    this.paintBlockOutline(canvas, _blocks);

    this.paintBlockImage(
        canvas,
        imageOka,
        _blocks
            .where((block) => block.blockType == BlockType.Oka)
            .map((block) => block.animatedEntity())
            .toList());
    this.paintBlockImage(
        canvas,
        imageDa,
        _blocks
            .where((block) => block.blockType == BlockType.Da)
            .map((block) => block.animatedEntity())
            .toList());
    this.paintBlockImage(
        canvas,
        imageDaKana,
        _blocks
            .where((block) => block.blockType == BlockType.DaKana)
            .map((block) => block.animatedEntity())
            .toList());
  }

  void paintBlockImage(
      Canvas canvas, ui.Image image, List<RectEntity> entities) {
    if (image == null) return;

    Rect rect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.drawAtlas(
        image,
        entities.map((RectEntity entity) {
          var convertedCenter =
              this.gameField.convertOffset(Offset(entity.x, entity.y));
          return RSTransform.fromComponents(
            rotation: entity.rotation,
            scale: this.gameField.convertDouble(entity.width) / rect.width,
            anchorX: rect.width / 2,
            anchorY: rect.height / 2,
            translateX: convertedCenter.dx,
            translateY: convertedCenter.dy,
          );
        }).toList(),
        entities.map((_) => rect).toList(),
        [],
        BlendMode.src,
        null,
        Paint());
  }

  void paintBlockOutline(Canvas canvas, List<Block> blocks) {
    blocks.forEach((block) {
      var entity = block.animatedEntity();
      var convertedCenter =
          this.gameField.convertOffset(Offset(entity.x, entity.y));
      canvas.drawCircle(
          convertedCenter,
          this.gameField.convertDouble(block.radius),
          (block.blockStatus == BlockStatus.Moving
              ? (this.blockStrokePaint)
              : (this.blockFillPaint)));
    });
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
