import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'common.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CanvasPanel(),
      ),
    );
  }
}

class CanvasPanel extends StatelessWidget {
  const CanvasPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        const Expanded(flex: 1, child: InfoBoard()),
        const Divider(height: 8.0, thickness: 1),
        Expanded(
          flex: 6,
          child: Stack(
            fit: StackFit.expand,
            children: [
              BackgroundArea(size: size * 0.95),
              RepaintBoundary(child: DrawingArea(size: size * 0.95)),
            ],
          ),
        ),
        const Divider(height: 8.0, thickness: 1),
        const Expanded(
          flex: 1,
          child: RepaintBoundary(
            child: ToolsSelector(),
          ),
        ),
      ],
    );
  }
}

class InfoBoard extends ConsumerWidget {
  const InfoBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segments = ref.watch(drawingProvider);

    return Container(
      width: double.maxFinite,
      //decoration:
      // BoxDecoration(border: Border.all(color: Colors.red, width: 5)),
      child: Text('segments : ${segments.length}'),
    );
  }
}

class BackgroundArea extends ConsumerWidget {
  const BackgroundArea({super.key, required this.size});
  final Size size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segments = ref.watch(drawingProvider);

    return CustomPaint(
      painter: BackgroundPainter(segments: segments),
      size: size,
    );
  }
}

class DrawingArea extends HookConsumerWidget {
  const DrawingArea({super.key, required this.size});
  final Size size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingMode = ref.watch(drawingModeProvider);
    final drawingNotifier = useValueNotifier<DrawingSegment?>(null);

    // rewind면 최근에 DrawingArea에 그렸던 내용을 clear 합니다.
    if (drawingMode == DrawingMode.rewind) {
      drawingNotifier.value =
          const DrawingSegment([], DrawingColor.transparent);
    }

    return Listener(
      onPointerDown: (event) {
        drawingNotifier.value = DrawingSegment(
          [event.localPosition],
          ref.read(brushColorProvider),
        );
        ref.read(drawingModeProvider.notifier).state = DrawingMode.drawing;
      },
      onPointerMove: (event) {
        drawingNotifier.value = DrawingSegment(
          [...drawingNotifier.value!.pts, event.localDelta],
          ref.read(brushColorProvider),
        );
      },
      onPointerUp: (event) {
        if (drawingNotifier.value == null ||
            drawingNotifier.value?.pts.length == 1) return;

        ref.watch(drawingProvider.notifier).state = [
          ...ref.read(drawingProvider),
          drawingNotifier.value!, // 최종으로 만들어진 Segment를 추가
        ];
      },
      child: CustomPaint(
        painter: DrawingPainter(
          notifier: drawingNotifier,
        ),
        child: Container(
          width: size.width,
          height: size.height,
          alignment: Alignment.center,
          transform: Matrix4.identity()..rotateZ(-pi / 5),
          transformAlignment: Alignment.center,
          child: Text(
            'mode : ${ref.read(drawingModeProvider).toString()}',
            style: TextStyle(
              color: Colors.grey.shade500.withAlpha(100),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  const BackgroundPainter({
    required this.segments,
  });
  //  {
  //   debugPrint('backgroundPainter created with segments ${segments.length}');
  // }

  final List<DrawingSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint painter = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    final path = Path();

    // debugPrint(
    //     'background drawing segments : ${segments.length}, size: ${size.toString()}');

    if (segments.isNotEmpty) {
      // prohibit to go out boundary
      canvas.clipRect(Offset.zero & size);
      for (var segment in segments) {
        final pts = segment.pts;

        path.moveTo(pts[0].dx, pts[0].dy);
        painter.color = segment.color.value;

        for (int i = 1; i < pts.length; i++) {
          path.relativeLineTo(pts[i].dx, pts[i].dy);
        }

        canvas.drawPath(path, painter);

        path.reset();
      }
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
    return segments.length != oldDelegate.segments.length;
  }
}

class DrawingPainter extends CustomPainter {
  const DrawingPainter({
    required this.notifier,
  }) : super(repaint: notifier);
  //  {
  //   debugPrint('DrawingPainter created pts : ${notifier.value?.pts.length}');
  // }

  final ValueNotifier<DrawingSegment?> notifier;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint painter = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    if (notifier.value == null) return;

    final List<Offset> pts = notifier.value!.pts;
    final Color color = notifier.value!.color.value;

    // debugPrint(
    //     'DrawingPainter paint pts : ${pts.length} size: ${size.toString()}');

    if (pts.isEmpty) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.transparent);
      return;
    }

    final offsets = pts;
    final path = Path()..moveTo(offsets[0].dx, offsets[0].dy);
    painter.color = color;
    for (int i = 1; i < offsets.length; i++) {
      path.relativeLineTo(offsets[i].dx, offsets[i].dy);
    }

    // prohibit to go out boundary
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(path, painter);
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return notifier.value != oldDelegate.notifier.value;
  }
}

class ToolsSelector extends ConsumerWidget {
  const ToolsSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(brushColorProvider);

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Spacer(flex: 1),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Radio(
                  value: DrawingColor.black,
                  fillColor: MaterialStateProperty.resolveWith((states) {
                    return Colors.black;
                  }),
                  activeColor: DrawingColor.black.value,
                  groupValue: color,
                  onChanged: (DrawingColor? value) {
                    ref.watch(brushColorProvider.notifier).state = value!;
                  },
                ),
                Radio(
                  value: DrawingColor.red,
                  fillColor: MaterialStateProperty.resolveWith((states) {
                    return Colors.red;
                  }),
                  // focusColor: Colors.purple,
                  activeColor: DrawingColor.red.value,
                  groupValue: color,
                  onChanged: (DrawingColor? value) {
                    ref.watch(brushColorProvider.notifier).state = value!;
                  },
                ),
                Radio(
                  value: DrawingColor.blue,
                  fillColor: MaterialStateProperty.resolveWith((states) {
                    return Colors.blue;
                  }),
                  activeColor: DrawingColor.blue.value,
                  groupValue: color,
                  onChanged: (DrawingColor? value) {
                    ref.watch(brushColorProvider.notifier).state = value!;
                  },
                ),
                Radio(
                  value: DrawingColor.green,
                  fillColor: MaterialStateProperty.resolveWith((states) {
                    return Colors.green;
                  }),
                  activeColor: DrawingColor.green.value,
                  groupValue: color,
                  onChanged: (DrawingColor? value) {
                    ref.watch(brushColorProvider.notifier).state = value!;
                  },
                ),
              ],
            ),
          ),
          Flexible(
            flex: 3,
            child: ElevatedButton(
              child: const Icon(
                Icons.change_circle_outlined,
              ),
              onPressed: () {
                final currentSegments = ref.read(drawingProvider);
                if (currentSegments.isEmpty) return;

                // remove the last line, which has been drown
                ref.watch(drawingModeProvider.notifier).state =
                    DrawingMode.rewind;
                ref.watch(drawingProvider.notifier).state = [...currentSegments]
                  ..removeLast();
              },
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}
