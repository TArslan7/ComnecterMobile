import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'radar_widget.dart';

class RadarScreen extends HookWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final points = useState<List<Offset>>(_generatePoints());
    final refreshController = useMemoized(() => RefreshController());

    // Auto-refresh timer
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 3), (_) {
        points.value = _generatePoints();
      });
      return timer.cancel;
    }, []);

    return Scaffold(
      appBar: AppBar(title: const Text('Radar')),
      body: SmartRefresher(
        controller: refreshController,
        enablePullDown: true,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          points.value = _generatePoints();
          refreshController.refreshCompleted();
        },
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: RadarWidget(points: points.value),
          ),
        ),
      ),
    );
  }

  List<Offset> _generatePoints() {
    final random = math.Random();
    final count = random.nextInt(5) + 1; // up to 5 users
    return List.generate(count, (_) {
      final r = random.nextDouble();
      final theta = random.nextDouble() * 2 * math.pi;
      return Offset(r * math.cos(theta), r * math.sin(theta));
    });
  }
}
