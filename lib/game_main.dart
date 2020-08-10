import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/animation.dart';

class GameMain extends StatefulWidget {
  @override
  _GameMainState createState() => _GameMainState();
}

class _GameMainState extends State<GameMain>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;

  List<Block> blocks;

  @override
  void initState() {
    _animationController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this)
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _animationController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              _animationController.forward();
            }
          });
    this.initGameState();
    super.initState();
  }

  void initGameState() {
    this.blocks = List.generate(5, (i) {
      var block = Block.init(x: i * 50.0, y: 0, blockType: BlockType.Oka)
        ..animation =
            Tween(begin: 0.0, end: 100.0).animate(_animationController);
      return block;
    });
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
                  color: Colors.white,
                  child: ClipRect(
                    child: GestureDetector(
                      onTapDown: (details) {
                        print("${details.localPosition.dx}");
                        print("${details.localPosition.dx}");
                      },
                      child: CustomPaint(
                        painter: _BlockListPainter(this.blocks),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 10),
                          ),
                        ),
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
  List<Block> blocks;

  _BlockListPainter(this.blocks);

  @override
  void paint(Canvas canvas, Size size) {
    this.blocks.forEach((block) => this.paintBlock(canvas, size, block));
  }

  void paintBlock(Canvas canvas, Size size, Block block) {
    var paint = Paint()
      ..isAntiAlias = true
      ..color = Colors.blue
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(block.x, block.y + block.animation.value),
            width: block.width,
            height: block.height),
        paint);
  }

  // void tmppaint(Canvas canvas, Size size) {
  //   final TextStyle style = TextStyle(
  //     color: Colors.black,
  //     backgroundColor: Colors.green[100],
  //     decorationColor: Colors.green,
  //   );
  //   final ui.ParagraphBuilder paragraphBuilder =
  //       ui.ParagraphBuilder(ui.ParagraphStyle(
  //     fontSize: 50,
  //     fontWeight: FontWeight.w600,
  //     textAlign: TextAlign.center,
  //   ))
  //         ..pushStyle(style.getTextStyle())
  //         ..addText('岡');
  //   final ui.Paragraph paragraph = paragraphBuilder.build()
  //     ..layout(ui.ParagraphConstraints(width: 0));

  //   final rate = this.radius / 100.0;
  //   canvas.save();
  //   canvas.translate(0, 100);
  //   canvas.rotate(2 * pi * rate);
  //   canvas.scale(rate);
  //   canvas.drawParagraph(paragraph, Offset(0, -50 * rate));
  //   canvas.restore();
  // }

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
  Animation<double> animation;

  RectEntity.init(this.x, this.y)
      : this.width = 30,
        this.height = 30,
        this.rotation = 0,
        this.scale = 0;

  left() => this.x - this.width / 2;
  right() => this.x + this.width / 2;
  top() => this.y - this.height / 2;
  bottom() => this.y + this.height / 2;
}

class Block extends RectEntity {
  BlockType blockType;

  Block.init({double x, double y, this.blockType}) : super.init(x, y);
}
