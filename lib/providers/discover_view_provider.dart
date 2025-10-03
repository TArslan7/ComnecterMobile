import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DiscoverViewType {
  radar,
  map,
  scroll,
}

class DiscoverViewNotifier extends StateNotifier<DiscoverViewType> {
  DiscoverViewNotifier() : super(DiscoverViewType.radar);
  
  void setView(DiscoverViewType view) {
    state = view;
  }
  
  String getViewTitle(DiscoverViewType viewType) {
    switch (viewType) {
      case DiscoverViewType.radar:
        return 'Radar';
      case DiscoverViewType.map:
        return 'Map';
      case DiscoverViewType.scroll:
        return 'Discover';
    }
  }

  IconData getViewIcon(DiscoverViewType viewType) {
    switch (viewType) {
      case DiscoverViewType.radar:
        return Icons.radar;
      case DiscoverViewType.map:
        return Icons.map;
      case DiscoverViewType.scroll:
        return Icons.list;
    }
  }

  String getViewDescription(DiscoverViewType viewType) {
    switch (viewType) {
      case DiscoverViewType.radar:
        return 'Pulse radar detection for nearby users';
      case DiscoverViewType.map:
        return 'Real-time map with users and events';
      case DiscoverViewType.scroll:
        return 'Browse detected users, friends, and communities';
    }
  }
}

final discoverViewProvider = StateNotifierProvider<DiscoverViewNotifier, DiscoverViewType>((ref) {
  return DiscoverViewNotifier();
});
