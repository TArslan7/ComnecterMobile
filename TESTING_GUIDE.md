# 🧪 Testing Guide - Discover Feed Feature

## Test Coverage Summary

### ✅ **Currently Implemented**

#### **Unit Tests** (13 tests) ✓
- **Location:** `test/features/discover/all_feed_test.dart`
- **Status:** ✅ All passing
- **Coverage:**
  - FeedItem serialization/deserialization
  - UserCard, CommunityCard, EventCard models
  - Repository pagination logic
  - Boosted item ordering
  - Distance formatting
  - Event logic (isFull, isHappeningSoon)
  - Member count formatting

#### **Widget Tests** (8 tests) ✓
- **Location:** `test/features/discover/feed_card_widgets_test.dart`
- **Status:** ✅ All passing
- **Coverage:**
  - UserFeedCard display and interactions
  - CommunityFeedCard display and state changes
  - EventFeedCard display and capacity logic
  - Boosted badge rendering
  - Button callbacks

**Total: 21 automated tests ✅**

---

## 🎯 Manual Testing Checklist

### Prerequisites

1. Run the app:
```bash
cd /Users/tolgaarslan/ComnecterMobile
flutter run
```

2. Navigate to the Discover Feed:
   - Option A: Go to `/discover/all` route
   - Option B: Add a test button to navigate there

---

### Test Plan

#### **1. Initial Load** 🔄

| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| Open feed screen | Shows shimmer loading placeholders | ☐ |
| Wait for data load | Cards appear after ~800ms | ☐ |
| Check card types | Mix of users, communities, events | ☐ |
| Check boosted items | Boosted items appear first | ☐ |
| Check distances | Shows "Xm away" or "X.Xkm away" | ☐ |

---

#### **2. Scrolling Behavior** 📱

| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| Scroll down slowly | Smooth animation, no jank | ☐ |
| Scroll down quickly | Cards snap into place | ☐ |
| Scroll to bottom | Shows loading indicator | ☐ |
| Wait for pagination | More cards load automatically | ☐ |
| Scroll through 50+ items | No memory issues or slowdown | ☐ |
| Scroll to end of feed | Shows all available items | ☐ |

---

#### **3. Pull-to-Refresh** 🔄

| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| Pull down from top | Refresh indicator appears | ☐ |
| Release to refresh | Loading animation plays | ☐ |
| Wait for completion | Feed reloads with fresh data | ☐ |
| Check scroll position | Resets to top of feed | ☐ |

---

#### **4. User Cards** 👤

| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| View user card | Shows name, avatar, bio | ☐ |
| Check online status | Green border for online users | ☐ |
| Check interests | Shows up to 3 interest tags | ☐ |
| Check mutual friends | Shows count if > 0 | ☐ |
| Tap card | Navigation or placeholder message | ☐ |
| Tap "Connect" button | Shows success snackbar | ☐ |
| Check boosted badge | Lightning bolt for boosted users | ☐ |

---

#### **5. Community Cards** 🏘️

| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| View community card | Shows name, description, avatar | ☐ |
| Check member count | Formatted correctly (500, 1.5K, 1.5M) | ☐ |
| Check verified badge | Blue checkmark for verified | ☐ |
| Check tags | Shows community tags | ☐ |
| Tap card | Navigation or placeholder message | ☐ |
| Tap "Join Community" | Button changes to "Joined" | ☐ |
| Check boosted badge | Lightning bolt for boosted | ☐ |

---

#### **6. Event Cards** 📅

| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| View event card | Shows title, description, location | ☐ |
| Check date/time | Displays correctly formatted | ☐ |
| Check attendee count | Shows "X/Y attending" or "X attending" | ☐ |
| Check organizer | Shows "by [OrgName]" | ☐ |
| Check happening soon | Orange badge if within 24h | ☐ |
| Tap card | Navigation or placeholder message | ☐ |
| Tap "RSVP" button | Changes to "Attending" | ☐ |
| Check full event | Shows "Event Full" (disabled) | ☐ |
| Check boosted badge | Lightning bolt for boosted | ☐ |

---

#### **7. Premium Features** 💎

| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| Check toggle visibility | "Hide Boosted" toggle in app bar | ☐ |
| Check lock icon | Shows for non-premium users | ☐ |
| Tap toggle (free user) | Opens premium paywall modal | ☐ |
| View paywall | Shows premium icon and benefits | ☐ |
| Tap "Upgrade to Premium" | Navigates to subscription screen | ☐ |
| Tap "Maybe Later" | Closes modal | ☐ |

**For Premium Users:**
| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| Tap toggle | Switches on (no paywall) | ☐ |
| Toggle ON | Feed reloads without boosted items | ☐ |
| Check feed | No BOOSTED badges visible | ☐ |
| Toggle OFF | Boosted items reappear | ☐ |

---

#### **8. Empty State** 📭

To test, modify repository to return empty list:

| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| No items detected | Shows empty state icon | ☐ |
| Check message | "Nothing detected nearby" | ☐ |
| Check button | "Refresh" button visible | ☐ |
| Tap refresh | Attempts to reload feed | ☐ |

---

#### **9. Error State** ⚠️

To test, modify repository to throw error:

| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| Network error | Shows error state icon | ☐ |
| Check message | "Oops! Something went wrong" | ☐ |
| Check error text | Shows actual error message | ☐ |
| Check button | "Try Again" button visible | ☐ |
| Tap try again | Attempts to reload feed | ☐ |

---

#### **10. Analytics Tracking** 📊

Check Firebase Analytics console after testing:

| Event | Parameters | Status |
|-------|-----------|--------|
| feed_scroll | page, total_items, timestamp | ☐ |
| boosted_impression | item_id, item_type, timestamp | ☐ |
| premium_toggle | is_premium, timestamp | ☐ |

---

## 🎭 Edge Cases to Test

#### **Performance**

| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| Rapid scrolling | No jank or dropped frames | ☐ |
| Long session | No memory leaks | ☐ |
| Background/foreground | State persists correctly | ☐ |
| Rotation (if supported) | Layout adjusts properly | ☐ |

#### **Network Conditions**

| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| Slow network | Shows loading, then data | ☐ |
| No network | Shows error state | ☐ |
| Network lost during scroll | Handles gracefully | ☐ |

#### **Boundary Conditions**

| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| Very long names | Text truncates properly | ☐ |
| Very long descriptions | Max 2 lines with ellipsis | ☐ |
| 0 mutual friends | Doesn't show mutual friends | ☐ |
| 0 attendees | Shows "0 attending" | ☐ |
| Very high numbers | Formats correctly (1M+) | ☐ |

---

## 🤖 Automated Test Commands

### Run All Tests
```bash
flutter test
```

### Run Unit Tests Only
```bash
flutter test test/features/discover/all_feed_test.dart
```

### Run Widget Tests Only
```bash
flutter test test/features/discover/feed_card_widgets_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run Tests in Watch Mode
```bash
flutter test --watch
```

---

## 📊 Expected Test Results

### Current Status
- ✅ Unit Tests: 13/13 passing
- ✅ Widget Tests: 8/8 passing
- ⏳ Manual Tests: To be completed
- ⏳ Integration Tests: Not yet implemented

### Coverage Goals
- ✅ Models: 100%
- ✅ Repository: 100%
- ✅ Providers: ~80% (UI testing covers rest)
- ✅ Widgets: ~90%
- ⏳ Screen: Manual testing required

---

## 🐛 Known Issues / Limitations

1. **Mock Data Only**
   - Currently using generated mock data
   - Real API integration needed for production

2. **No Real Location**
   - Using hardcoded San Francisco coordinates
   - Need to integrate device location services

3. **Premium Check**
   - Mock subscription service
   - Need real payment processor integration

4. **Analytics**
   - Firebase may not be initialized in all environments
   - Errors are caught and ignored

---

## 🚀 Integration Testing (Recommended)

For full E2E testing, create integration tests:

```bash
# Create integration test
mkdir -p integration_test
```

**Test scenarios:**
1. Complete user journey through feed
2. Premium upgrade flow
3. Pagination with real delays
4. Error recovery flows

---

## ✅ Definition of Done

Feature is fully tested when:

- [x] All unit tests passing (21/21) ✓
- [ ] All manual tests completed
- [ ] No critical bugs found
- [ ] Performance meets requirements (<8ms frame time)
- [ ] Analytics verified in Firebase console
- [ ] Premium features gated correctly
- [ ] Error states handled gracefully
- [ ] Empty states display correctly

---

## 📝 Testing Notes

**Add your testing notes here:**

- Date: _______
- Tester: _______
- Device: _______
- OS Version: _______
- Issues Found: _______

---

## 🔄 Regression Testing

When making changes, re-run:

1. All automated tests: `flutter test`
2. Core manual flows (1-7 above)
3. Performance verification

---

**Last Updated:** October 12, 2025

