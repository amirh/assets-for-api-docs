// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show Image;

import 'package:diagram_capture/diagram_capture.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Image;

import 'diagram_step.dart';

Completer<Null> touch;
final GlobalKey key = new GlobalKey();

const String destinationImageName = 'assets/blend_mode_destination.jpeg';
const String sourceImageName = 'assets/blend_mode_source.png';
const String gridImageName = 'assets/blend_mode_grid.png';

Image destinationImage, sourceImage, gridImage;
int pageIndex = 0;

Future<Image> getImage(ImageProvider provider) {
  final Completer<Image> completer = new Completer<Image>();
  final ImageStream stream = provider.resolve(const ImageConfiguration());
  void listener(ImageInfo image, bool sync) {
    completer.complete(image.image);
    stream.removeListener(listener);
  }

  stream.addListener(listener);
  return completer.future;
}

class BlendModeDiagram extends StatelessWidget implements DiagramMetadata {
  const BlendModeDiagram(this.mode);

  final BlendMode mode;

  @override
  String get name => 'blend_mode_${describeEnum(mode)}';

  @override
  Widget build(BuildContext context) {
    return new ConstrainedBox(
      key: new UniqueKey(),
      constraints: new BoxConstraints.tight(const Size.square(400.0)),
      child: new DecoratedBox(
        decoration: new ShapeDecoration(
          shape: new Border.all(width: 1.0, color: Colors.white) + new Border.all(width: 1.0, color: Colors.black),
          image: const DecorationImage(
            image: const ExactAssetImage(gridImageName),
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: new AspectRatio(
          aspectRatio: 1.0,
          child: new CustomPaint(
            key: key,
            painter: new BlendModePainter(mode),
            child: new Stack(
              children: <Widget>[
                new Align(
                  alignment: Alignment.topLeft,
                  child: new Container(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 3.0),
                    color: Colors.white,
                    child: new Text(
                      '$mode',
                      style: const TextStyle(
                        inherit: false,
                        fontFamily: 'monospace',
                        color: Colors.black,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                new Align(
                  alignment: Alignment.bottomCenter,
                  child: new Container(
                    margin: const EdgeInsets.all(1.0),
                    padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
                    color: Colors.white,
                    child: const Text(
                      '⟵ destination ⟶',
                      style: const TextStyle(
                        inherit: false,
                        fontFamily: 'monospace',
                        color: Colors.black,
                        fontSize: 8.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                new RotatedBox(
                  quarterTurns: 3,
                  child: new Align(
                    alignment: Alignment.bottomCenter,
                    child: new Container(
                      margin: const EdgeInsets.all(1.0),
                      padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
                      color: Colors.white,
                      child: const Text(
                        '⟵ source ⟶',
                        style: const TextStyle(
                          inherit: false,
                          fontFamily: 'monospace',
                          color: Colors.black,
                          fontSize: 8.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BlendModePainter extends CustomPainter {
  const BlendModePainter(this.mode);

  final BlendMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    assert(size.shortestSide == size.longestSide);
    final Rect bounds = (Offset.zero & size).deflate(size.shortestSide * 0.025);
    canvas.saveLayer(bounds, new Paint()..blendMode = BlendMode.srcOver);
    assert(size.shortestSide == size.longestSide);
    paintTestImage(canvas, bounds, destinationImage);
    canvas.saveLayer(bounds, new Paint()..blendMode = mode);
    canvas.translate(0.0, size.height);
    canvas.rotate(-pi / 2.0);
    paintTestImage(canvas, bounds, sourceImage);
    canvas.restore();
    canvas.restore();
  }

  static const List<Color> bars = const <Color>[
    const Color(0xFFFF0000),
    const Color(0xC0FF0000),
    const Color(0x40FF0000),
    const Color(0xFF00FF00),
    const Color(0xC000FF00),
    const Color(0x4000FF00),
    const Color(0xFF0000FF),
    const Color(0xC00000FF),
    const Color(0x400000FF),
    const Color(0xFFFFFFFF),
    const Color(0xC0FFFFFF),
    const Color(0x40FFFFFF),
    const Color(0xFF000000),
    const Color(0x80000000),
    const Color(0x00000000),
  ];

  static const List<List<Color>> gradients = const <List<Color>>[
    const <Color>[
      const Color(0xFFFF0000),
      const Color(0xFF00FF00),
      const Color(0xFF0000FF),
      const Color(0xFFFF0000),
      const Color(0xFF00FF00),
      const Color(0xFF0000FF),
      const Color(0xFFFF0000),
      const Color(0xFF00FF00),
      const Color(0xFF0000FF),
    ],
    const <Color>[
      const Color(0x80FF0000),
      const Color(0x8000FF00),
      const Color(0x800000FF),
      const Color(0x80FF0000),
      const Color(0x8000FF00),
      const Color(0x800000FF),
      const Color(0x80FF0000),
      const Color(0x8000FF00),
      const Color(0x800000FF),
    ],
    const <Color>[
      const Color(0xFF000000),
      const Color(0x00000000),
      const Color(0xFF000000),
      const Color(0xFF000000),
      const Color(0x00000000),
      const Color(0xFF000000),
      const Color(0xFF000000),
      const Color(0x00000000),
      const Color(0xFF000000),
    ],
  ];

  void paintTestImage(Canvas canvas, Rect bounds, Image image) {
    final double barWidth = bounds.height / (bars.length * 3.0);
    double top = bounds.top + barWidth * 2.0;
    for (Color color in bars) {
      drawBar(canvas, new Rect.fromLTWH(bounds.left, top, bounds.width, barWidth), new Paint()..color = color);
      top += barWidth;
    }
    for (List<Color> colors in gradients) {
      final Rect rect = new Rect.fromLTWH(bounds.left, top, bounds.width, barWidth);
      top += barWidth;
      drawBar(canvas, rect, new Paint()..shader = new LinearGradient(colors: colors).createShader(rect));
    }
    top += barWidth * 2.0;
    final Rect rect = new Rect.fromLTRB(bounds.left, top, bounds.right, bounds.bottom);
    paintImage(canvas: canvas, rect: rect, image: image, fit: BoxFit.fill);
  }

  void drawBar(Canvas canvas, Rect rect, Paint paint) {
    canvas.drawRRect(
      new RRect.fromRectXY(rect, rect.shortestSide / 3.0, rect.shortestSide / 3.0),
      paint,
    );
  }

  @override
  bool shouldRepaint(BlendModePainter oldDelegate) {
    return mode != oldDelegate.mode;
  }
}

class BlendModeDiagramStep extends DiagramStep {
  BlendModeDiagramStep(DiagramController controller) : super(controller);

  @override
  final String category = 'dart-ui';

  List<BlendModeDiagram> _diagrams;
  @override
  Future<List<DiagramMetadata>> get diagrams async {
    if (_diagrams == null) {
      destinationImage ??= await getImage(const ExactAssetImage(destinationImageName));
      sourceImage ??= await getImage(const ExactAssetImage(sourceImageName));
      gridImage ??= await getImage(const ExactAssetImage(gridImageName));

      _diagrams = <BlendModeDiagram>[];
      for (BlendMode mode in BlendMode.values) {
        _diagrams.add(new BlendModeDiagram(mode));
      }
    }
    return _diagrams;
  }

  @override
  Future<File> generateDiagram(DiagramMetadata diagram) async {
    final BlendModeDiagram typedDiagram = diagram;
    controller.builder = (BuildContext context) => typedDiagram;
    return await controller.drawDiagramToFile(new File('${diagram.name}.png'));
  }
}
