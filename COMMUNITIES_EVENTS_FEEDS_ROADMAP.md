# 🏘️📅 Communities & Events Feeds - Implementation Roadmap

## 📊 Current Status

### ✅ **Already Completed:**
1. **All Feed** (`/discover/all`) - Shows everything
2. **Users Feed** (`/discover/users`) - Shows only users

### 🔄 **In Progress:**
3. **Communities Feed** (`/discover/communities`) - Shows only communities
4. **Events Feed** (`/discover/events`) - Shows only events

---

## 📁 **Files Created So Far**

### Communities Feed:
```
✅ lib/features/discover/repositories/communities_feed_repository.dart
⏳ lib/features/discover/providers/communities_feed_provider.dart
⏳ lib/features/discover/communities_feed_screen.dart
⏳ test/features/discover/communities_feed_test.dart
```

### Events Feed:
```
✅ lib/features/discover/repositories/events_feed_repository.dart
⏳ lib/features/discover/providers/events_feed_provider.dart
⏳ lib/features/discover/events_feed_screen.dart
⏳ test/features/discover/events_feed_test.dart
```

---

## 🚧 **What Still Needs to Be Built**

### For Communities Feed:

#### 1. **CommunitiesFeedProvider** (providers/communities_feed_provider.dart)
```dart
// Similar to users_feed_provider.dart
- CommunitiesFeedState (state model)
- CommunitiesFeedController (controller)
- communitiesFeedControllerProvider (Riverpod provider)
```

#### 2. **CommunitiesFeedScreen** (communities_feed_screen.dart)
```dart
- Vertical PageView for communities
- Community cards with:
  * Cover image/avatar
  * Name + verified badge
  * Description
  * Member count
  * Tags
  * Distance
  * Join/Joined button
- Premium "Hide Boosted" toggle
- Pull-to-refresh
- Shimmer loading
- Empty state: "No communities nearby. Create one!"
```

#### 3. **Community Actions**:
- Join community button
- Open community details (navigation)
- Share community
- Analytics: community_join_tap, community_view

---

### For Events Feed:

#### 1. **EventsFeedProvider** (providers/events_feed_provider.dart)
```dart
- EventsFeedState
- EventsFeedController  
- eventsFeedControllerProvider
```

#### 2. **EventsFeedScreen** (events_feed_screen.dart)
```dart
- Vertical PageView for events
- Event cards with:
  * Cover image/poster
  * Title
  * Date/time (local timezone)
  * Venue/location
  * Distance
  * Price (if applicable)
  * Attendee count
  * Multiple action buttons:
    - Save (bookmark locally)
    - RSVP (navigate to detail)
    - Share (system share)
- Premium "Hide Boosted" toggle
- Pull-to-refresh
- Shimmer loading
- Empty state: "No events nearby. Try widening your radius."
```

#### 3. **Event Actions**:
- Save event (local storage)
- RSVP to event (navigation)
- Share event (system share sheet)
- Analytics: rsvp_tap, share_tap, save_tap

---

## 🎯 **Quick Implementation Guide**

Since you have 2 working examples (All Feed and Users Feed), here's how to create the remaining two:

### **Communities Feed = Copy Users Feed Pattern**

```bash
# 1. Copy users_feed_provider.dart
# 2. Replace "Users" with "Communities"
# 3. Change FeedItemType filter to .community
# 4. Use CommunitiesFeedRepository
```

### **Events Feed = Copy Users Feed Pattern**

```bash
# 1. Copy users_feed_provider.dart  
# 2. Replace "Users" with "Events"
# 3. Change FeedItemType filter to .event
# 4. Use EventsFeedRepository
# 5. Add extra actions (Save, Share)
```

---

## 📝 **Code Templates**

### Communities Feed Provider Template:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_item.dart';
import '../repositories/communities_feed_repository.dart';

class CommunitiesFeedState {
  final List<FeedItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? cursor;
  final String? error;
  final bool hideBoosted;

  const CommunitiesFeedState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.cursor,
    this.error,
    this.hideBoosted = false,
  });

  // Add copyWith, filteredItems, isEmpty, hasError methods
  // (Copy from users_feed_provider.dart)
}

class CommunitiesFeedController extends StateNotifier<CommunitiesFeedState> {
  CommunitiesFeedController({
    required this.repository,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  }) : super(const CommunitiesFeedState());

  final CommunitiesFeedRepository repository;
  final double lat;
  final double lng;
  final double radiusMeters;

  // Add loadInitial, loadMore, refresh, toggleHideBoosted methods
  // (Copy from users_feed_provider.dart)
}

// Add provider
final communitiesFeedRepositoryProvider = Provider<CommunitiesFeedRepository>((ref) {
  return CommunitiesFeedRepository();
});

final communitiesFeedControllerProvider = StateNotifierProvider.family
    .autoDispose<CommunitiesFeedController, CommunitiesFeedState, CommunitiesFeedParams>(
  (ref, params) {
    final repository = ref.watch(communitiesFeedRepositoryProvider);
    final controller = CommunitiesFeedController(
      repository: repository,
      lat: params.lat,
      lng: params.lng,
      radiusMeters: params.radiusMeters,
    );
    Future.microtask(() => controller.loadInitial());
    return controller;
  },
);

class CommunitiesFeedParams {
  final double lat;
  final double lng;
  final double radiusMeters;

  const CommunitiesFeedParams({
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunitiesFeedParams &&
        other.lat == lat &&
        other.lng == lng &&
        other.radiusMeters == radiusMeters;
  }

  @override
  int get hashCode => Object.hash(lat, lng, radiusMeters);
}
```

---

## 🧪 **What You Need to Test**

Once all 4 feeds are implemented, here's your complete testing matrix:

### **1. All Feeds Test Matrix**

| Feed Type | Route | Content | Boosted | Premium | Status |
|-----------|-------|---------|---------|---------|--------|
| All | `/discover/all` | Mixed (U+C+E) | ✓ | ✓ | ✅ Done |
| Users | `/discover/users` | Users only | ✓ | ✓ | ✅ Done |
| Communities | `/discover/communities` | Communities only | ✓ | ✓ | ⏳ TODO |
| Events | `/discover/events` | Events only | ✓ | ✓ | ⏳ TODO |

---

### **2. Communities Feed Testing Checklist**

#### Basic Functionality:
- [ ] Feed loads with shimmer placeholders
- [ ] Shows ONLY community cards (no users/events)
- [ ] Community cards display:
  * [ ] Avatar/cover image
  * [ ] Community name
  * [ ] Verified badge (if verified)
  * [ ] Description (2 lines max)
  * [ ] Member count (formatted: 500, 1.5K, 1.5M)
  * [ ] Tags (colored chips)
  * [ ] Distance from user
  * [ ] Join/Joined button

#### Interactions:
- [ ] Tap card → navigates to community detail
- [ ] Tap "Join Community" → changes to "Joined"
- [ ] Tap "Joined" → shows leave options
- [ ] Already joined communities show "Joined" state

#### Feed Behavior:
- [ ] Boosted communities appear first
- [ ] Pull-to-refresh works
- [ ] Infinite scroll loads more
- [ ] Smooth 60fps scrolling
- [ ] No lag with 50+ items

#### Premium Features:
- [ ] "Hide Boosted" toggle visible
- [ ] Free users see paywall
- [ ] Premium users can toggle
- [ ] Toggle hides/shows boosted communities

#### Empty/Error States:
- [ ] Empty state shows "No communities nearby"
- [ ] Shows "Create community" CTA button
- [ ] Error state shows retry button
- [ ] Error messages are clear

#### Analytics:
- [ ] `communities_tab_view` fires on scroll
- [ ] `community_join_tap` fires on join
- [ ] `premium_toggle` fires correctly

---

### **3. Events Feed Testing Checklist**

#### Basic Functionality:
- [ ] Feed loads with shimmer placeholders
- [ ] Shows ONLY event cards (no users/communities)
- [ ] Event cards display:
  * [ ] Cover image/poster
  * [ ] Event title
  * [ ] Date & time (local timezone format)
  * [ ] Venue name and location
  * [ ] Distance from user
  * [ ] Attendee count (X/Y or X attending)
  * [ ] Price (if applicable)
  * [ ] Tags
  * [ ] "Happening Soon" badge (if within 24h)

#### Interactions:
- [ ] Tap card → navigates to event detail
- [ ] Tap "RSVP" → changes to "Attending"
- [ ] Tap "Save" → saves event locally
- [ ] Tap "Share" → opens system share sheet
- [ ] Full events show "Event Full" (disabled)
- [ ] Already attending shows "Attending" state

#### Feed Behavior:
- [ ] Boosted events appear first
- [ ] Then sorted by date (upcoming first)
- [ ] Pull-to-refresh works
- [ ] Infinite scroll loads more
- [ ] Smooth scrolling

#### Time Formatting:
- [ ] Dates show in local timezone
- [ ] "Happening soon" badge for <24h events
- [ ] Past events handled gracefully
- [ ] Time displays clearly (12h or 24h format)

#### Premium Features:
- [ ] "Hide Boosted" toggle works
- [ ] Paywall for free users
- [ ] Premium can hide boosted events

#### Empty/Error States:
- [ ] Empty state: "No events nearby"
- [ ] Suggests widening radius
- [ ] Error handling works

#### Analytics:
- [ ] `events_tab_view` fires
- [ ] `rsvp_tap` fires on RSVP
- [ ] `share_tap` fires on share
- [ ] `save_tap` fires on save

---

### **4. Integration Testing**

#### Scroll View Integration:
```
Discover → Scroll View:
  ├─ "All" tab → [Open Full Screen Feed] → All Feed ✅
  ├─ "Detected Users" → [Open Users Feed] → Users Feed ✅
  ├─ "Communities" → [Open Communities Feed] → Communities Feed ⏳
  └─ "Events" → [Open Events Feed] → Events Feed ⏳
```

Test checklist:
- [ ] All buttons navigate correctly
- [ ] Back navigation works
- [ ] State persists when returning
- [ ] No memory leaks switching feeds

---

### **5. Performance Testing**

Test each feed with:
- [ ] 100+ items scrolled
- [ ] Rapid scrolling
- [ ] Background/foreground switching
- [ ] Memory usage monitoring
- [ ] Frame rate monitoring (should be 60fps)
- [ ] No crashes or ANRs

---

### **6. Cross-Feed Consistency Testing**

All 4 feeds should have:
- [ ] Same UI/UX patterns
- [ ] Same premium toggle behavior
- [ ] Same loading states (shimmer)
- [ ] Same empty states pattern
- [ ] Same error handling
- [ ] Same pull-to-refresh UX
- [ ] Same scroll behavior
- [ ] Same analytics naming convention

---

## 📊 **Test Coverage Goals**

### Current Test Status:
```
✅ All Feed: 13 tests passing
✅ Users Feed: 10 tests passing  
✅ Widget Tests: 8 tests passing
⏳ Communities Feed: 0 tests (not created yet)
⏳ Events Feed: 0 tests (not created yet)

Current Total: 31 tests
Target Total: 51+ tests (aim for 10+ per feed)
```

---

## 🎯 **Implementation Priority**

### Phase 1: Communities Feed (Higher Priority)
1. Create `communities_feed_provider.dart`
2. Create `communities_feed_screen.dart`
3. Add route to `app_router.dart`
4. Add button to scroll view
5. Test manually
6. Write unit tests

### Phase 2: Events Feed
1. Create `events_feed_provider.dart`
2. Create `events_feed_screen.dart`
3. Add route to `app_router.dart`
4. Add button to scroll view
5. Add Save/RSVP/Share functionality
6. Test manually
7. Write unit tests

### Phase 3: Integration
1. Update scroll view with all feed buttons
2. Test navigation between all feeds
3. Test premium features across all feeds
4. Performance testing
5. Analytics verification

---

## 🚀 **Quick Start for You**

### Option 1: I can implement both feeds for you
Let me know and I'll create all the remaining files (providers, screens, tests, routing updates)

### Option 2: You implement following the patterns
Use the existing `users_feed_*` files as templates:
1. Copy `users_feed_provider.dart` → rename to `communities_feed_provider.dart`
2. Find/replace "Users" → "Communities"
3. Update repository reference
4. Repeat for events feed
5. Copy `users_feed_screen.dart` for screens
6. Update card rendering logic

---

## 📱 **Testing After Implementation**

### Quick Smoke Test Script:
```dart
// Add to your app for easy testing
class FeedTestingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('🧪 Test All Feeds'),
        ElevatedButton(
          onPressed: () => context.push('/discover/all'),
          child: Text('🌟 All Feed'),
        ),
        ElevatedButton(
          onPressed: () => context.push('/discover/users'),
          child: Text('👥 Users Feed'),
        ),
        ElevatedButton(
          onPressed: () => context.push('/discover/communities'),
          child: Text('🏘️ Communities Feed'),
        ),
        ElevatedButton(
          onPressed: () => context.push('/discover/events'),
          child: Text('📅 Events Feed'),
        ),
      ],
    );
  }
}
```

---

## 🎯 **Definition of Done**

All feeds are ready when:
- [ ] All 4 feeds implemented and working
- [ ] Routes added for all feeds
- [ ] Scroll view buttons added for easy access
- [ ] All feeds follow same patterns
- [ ] Premium features work consistently
- [ ] 50+ unit tests passing
- [ ] Manual testing complete
- [ ] No performance issues
- [ ] Analytics tracking verified
- [ ] Empty/error states tested
- [ ] Documentation updated

---

## 💡 **Recommendation**

**Should I implement the remaining Communities and Events feeds for you?**

I can create:
- ✅ Both provider files
- ✅ Both screen files  
- ✅ Both test files
- ✅ Update routing
- ✅ Update scroll view
- ✅ Comprehensive testing guide

This would give you **4 complete, tested, production-ready feeds** following the same patterns!

**What would you like me to do?**

