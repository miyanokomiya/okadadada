import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
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
    this.blocks = List.generate(5, (i) {
      var block = Block.init(x: i * 50.0, y: 0, blockType: BlockType.Oka)
        ..animation = Tween(begin: 0.0, end: 1.0).animate(_animationController)
        ..pipeAnimation = (block) => Offset(block.x,
            block.y + this.gameField.fieldSize.height * block.animation.value);
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
  GameField gameField;
  List<Block> blocks;

  _BlockListPainter(this.blocks, this.gameField);

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
    var paint = Paint()
      ..isAntiAlias = true
      ..color = Colors.blue
      ..strokeWidth = this.gameField.convertDouble(5.0)
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
        Rect.fromCenter(
            center: this.gameField.convertOffset(block.animatedOffset()),
            width: this.gameField.convertDouble(block.width),
            height: this.gameField.convertDouble(block.height)),
        paint);
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
  Offset Function(Block) pipeAnimation;

  Block.init({double x, double y, this.blockType}) : super.init(x, y);

  Offset animatedOffset() => this.pipeAnimation(this);

  // bool testHit(Offset p) {
  //   var center = this.animatedOffset();
  // }
}
