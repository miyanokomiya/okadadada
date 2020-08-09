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
  Animation<double> _animation;
  AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _animation = Tween(begin: 0.0, end: 100.0).animate(_animationController)
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
        title: Text('岡田ダダダ - Play -'),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20.0),
              child: RaisedButton(
                child: Text('Start/Stop'),
                onPressed: () {
                  if (_animationController.isAnimating) {
                    _animationController.reset();
                  } else {
                    _animationController.repeat();
                  }
                },
              ),
            ),
            Opacity(
              opacity: _animationController.isAnimating ? 1.0 : 0.00,
              child: CustomPaint(
                painter: _CirclePainter(_animation.value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  double radius;

  _CirclePainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final TextStyle style = TextStyle(
      color: Colors.black,
      backgroundColor: Colors.green[100],
      decorationColor: Colors.green,
    );
    final ui.ParagraphBuilder paragraphBuilder =
        ui.ParagraphBuilder(ui.ParagraphStyle(
      fontSize: 50,
      fontWeight: FontWeight.w600,
      textAlign: TextAlign.center,
    ))
          ..pushStyle(style.getTextStyle())
          ..addText('岡');
    final ui.Paragraph paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: 0));

    final rate = this.radius / 100.0;
    canvas.save();
    canvas.translate(0, 100);
    canvas.rotate(2 * pi * rate);
    canvas.scale(rate);
    canvas.drawParagraph(paragraph, Offset(0, -50 * rate));
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
