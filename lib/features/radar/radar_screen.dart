import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:async';

class RadarScreen extends HookWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usersNearby = useState<int>(0);
    final refreshController = useMemoized(() => RefreshController());

    // Auto-refresh timer
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 3), (_) {
        usersNearby.value = _generateRandomUsers();
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
          usersNearby.value = _generateRandomUsers();
          refreshController.refreshCompleted();
        },
        child: Center(
          child: Text(
            '${usersNearby.value} gebruiker(s) in jouw buurt',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }

  int _generateRandomUsers() => DateTime.now().second % 6;
}
