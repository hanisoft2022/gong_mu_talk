# Comment Count Fix - Deployment Guide

## 🎯 Summary

Fixed critical comment count discrepancy bug where displayed counts didn't match actual comment counts (e.g., showing 5 when only 4 comments exist).

### Root Cause
- **Double counting**: Both app Transaction and Firebase Functions were incrementing commentCount
- **Race condition**: Timing-dependent inconsistencies between client and server
- **Soft delete not detected**: Functions only detected hard deletes, missing `deleted: true` state changes

### Solution
- **Single source of truth**: Firebase Functions now exclusively manage commentCount
- **Atomic operations**: Using `FieldValue.increment()` to prevent race conditions
- **Soft delete detection**: Functions detect `deleted: false → true` changes
- **Undo functionality**: 3-second window to restore deleted comments

---

## 📋 Changes Made

### 1. Firebase Functions (`functions/src/index.ts`)
- ✅ Added soft delete detection (`deleted: false → true`)
- ✅ Added restore detection (`deleted: true → false`)
- ✅ Switched to atomic `FieldValue.increment()` operations
- ✅ Made Functions the single source of truth for commentCount

### 2. Comment Repository (`lib/features/community/data/repositories/comment_repository.dart`)
- ✅ Removed commentCount updates from `createComment` Transaction
- ✅ Removed commentCount updates from `deleteComment` Transaction
- ✅ Added `undoDeleteComment` method for restore functionality
- ✅ Cleaned up unused counter shard fields

### 3. PostCard Cubit (`lib/features/community/presentation/cubit/post_card_cubit.dart`)
- ✅ Added `deleteComment` method with optimistic UI updates
- ✅ Added `undoDeleteComment` method with rollback logic
- ✅ Implemented error handling and state management

### 4. UI Components
**CommentTile** (`lib/features/community/presentation/widgets/post/comment_tile.dart`):
- ✅ Added deleted state rendering
- ✅ Added delete button (visible only to comment author)
- ✅ Display "[삭제된 댓글입니다]" for deleted comments

**PostCard** (`lib/features/community/presentation/widgets/post_card.dart`):
- ✅ Added delete undo timer (3-second window)
- ✅ Added SnackBar with "실행 취소" button
- ✅ Proper cleanup in dispose

### 5. Verification Script (`scripts/verify_comment_counts.dart`)
- ✅ Created data correction script
- ✅ Counts actual non-deleted comments
- ✅ Fixes existing comment count mismatches

---

## 🚀 Deployment Steps

### Step 1: Verify Code Quality ✅
```bash
flutter analyze
# Expected: Only info-level "avoid_print" warnings in scripts (acceptable)
```

### Step 2: Run Data Verification Script
This will fix existing comment count mismatches in production data:

```bash
dart run scripts/verify_comment_counts.dart
```

**Expected Output**:
```
🔍 Starting comment count verification...
✅ Firebase initialized
📥 Fetching all posts...
📊 Found X posts

❌ Mismatch found:
   Post ID: abc123
   Stored count: 5
   Actual count: 4
   Difference: 1
   ✅ Fixed!

============================================================
📋 Verification Summary:
============================================================
Total posts checked: X
Mismatches found: Y
Successfully fixed: Y
Failed to fix: 0
============================================================

✅ All mismatches have been fixed!
```

**Important**: Run this script BEFORE deploying new Functions to fix historical data.

### Step 3: Deploy Firebase Functions
```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

**Expected Output**:
```
✔  functions: Finished running predeploy script.
✔  Deploy complete!

Functions deployed:
- onCommentWrite (updated)
```

### Step 4: Test App
```bash
# Run tests
flutter test

# Build debug APK
flutter build apk --debug

# Manual Testing Checklist:
# 1. Create new comment → Check count increments by 1
# 2. Delete comment → Check count decrements by 1
# 3. Undo delete within 3 seconds → Check count increments back
# 4. Let delete timer expire → Check comment stays deleted
# 5. Verify "[삭제된 댓글입니다]" displays for deleted comments
```

### Step 5: Production Deployment
```bash
# Build release APK
flutter build apk --release

# Or for iOS
flutter build ios --release
```

---

## 🧪 Testing Scenarios

### Scenario 1: Create Comment
**Steps**:
1. Open a post with 4 comments (count shows "4")
2. Add a new comment "Test comment"
3. Wait 2 seconds for Functions to process

**Expected**: Count updates to "5", new comment appears

### Scenario 2: Delete Comment
**Steps**:
1. Find your own comment
2. Tap delete icon (trash icon)
3. SnackBar appears: "댓글이 삭제되었습니다" with "실행 취소" button
4. Wait 3+ seconds

**Expected**:
- Comment text changes to "[삭제된 댓글입니다]"
- Count decrements by 1
- Comment marked as deleted

### Scenario 3: Undo Delete
**Steps**:
1. Delete your comment (see Scenario 2)
2. **Within 3 seconds**, tap "실행 취소" in SnackBar

**Expected**:
- Original comment text restored
- Count increments back to original
- Comment no longer marked as deleted

### Scenario 4: Verify Historical Data
**Steps**:
1. Check posts that had mismatched counts before deployment
2. Verify counts now match actual comment numbers

**Expected**: All counts accurate (script corrected historical data)

---

## 🔍 Monitoring & Verification

### Post-Deployment Checks

**1. Firebase Console Monitoring**:
```
1. Open Firebase Console → Functions
2. Check onCommentWrite function logs
3. Verify no errors in the last hour
4. Check execution count (should match comment activity)
```

**2. Firestore Data Inspection**:
```
1. Open Firestore console
2. Navigate to `posts` collection
3. Spot-check 5-10 posts:
   - Verify `commentCount` matches actual non-deleted comments
   - Check `topComment` is updated
   - Verify `hotScore` is recalculated
```

**3. App Testing**:
```bash
# Monitor logs during testing
adb logcat | grep -E "(Comment|PostCard|Cubit)"
```

### Expected Function Logs
```
Comment created: commentId=abc123, postId=xyz789
→ Incrementing commentCount by 1

Comment soft deleted: commentId=abc123, postId=xyz789
→ Decrementing commentCount by 1

Comment restored: commentId=abc123, postId=xyz789
→ Incrementing commentCount by 1
```

---

## ⚠️ Rollback Plan

If issues occur after deployment:

### Rollback Functions (Option 1)
```bash
firebase functions:rollback onCommentWrite
```

### Redeploy Previous Version (Option 2)
```bash
git checkout <previous-commit-hash>
cd functions
npm run build
firebase deploy --only functions
```

### Emergency Fix
If comment counts are completely broken:
```bash
# Re-run verification script to fix all counts
dart run scripts/verify_comment_counts.dart
```

---

## 📊 Success Metrics

**Day 1 Post-Deployment**:
- [ ] Zero comment count discrepancy reports
- [ ] Functions executing without errors
- [ ] Delete/undo functionality working smoothly

**Week 1 Post-Deployment**:
- [ ] Spot-check 50+ posts: All counts accurate
- [ ] No user complaints about missing comments
- [ ] Undo feature used successfully by users

---

## 📝 Known Limitations

### 1. Eventual Consistency
- **Issue**: UI shows optimistic count, Functions update asynchronously
- **Impact**: 1-2 second delay before count is finalized
- **Mitigation**: Optimistic updates provide instant feedback

### 2. Offline Behavior
- **Issue**: Deletes while offline may show incorrect count temporarily
- **Impact**: Count corrects when back online and Functions execute
- **Mitigation**: Firestore offline persistence handles edge cases

### 3. Script Performance
- **Issue**: Verification script may be slow for large datasets (10,000+ posts)
- **Impact**: Script may take 5-10 minutes to complete
- **Mitigation**: Run during low-traffic periods, add pagination if needed

---

## 🔗 Related Files

**Modified Files**:
- `functions/src/index.ts`
- `lib/features/community/data/repositories/comment_repository.dart`
- `lib/features/community/presentation/cubit/post_card_cubit.dart`
- `lib/features/community/presentation/widgets/post/comment_tile.dart`
- `lib/features/community/presentation/widgets/post_card.dart`

**New Files**:
- `scripts/verify_comment_counts.dart`
- `COMMENT_COUNT_FIX_DEPLOYMENT.md` (this file)

**Testing Files** (TODO - future work):
- `test/features/community/data/repositories/comment_repository_test.dart`
- `test/features/community/presentation/cubit/post_card_cubit_test.dart`

---

## ✅ Deployment Checklist

### Pre-Deployment
- [x] Code review completed
- [x] All compilation errors fixed
- [x] `flutter analyze` passes (only acceptable warnings)
- [ ] Backup production database (optional but recommended)

### Deployment
- [ ] Run data verification script (`dart run scripts/verify_comment_counts.dart`)
- [ ] Deploy Firebase Functions (`firebase deploy --only functions`)
- [ ] Verify Functions deployed successfully (check Firebase Console)
- [ ] Build and test debug app
- [ ] Manual testing: Create/delete/undo comments
- [ ] Verify comment counts are accurate

### Post-Deployment
- [ ] Monitor Firebase Functions logs for 1 hour
- [ ] Spot-check 10+ posts for accurate counts
- [ ] Test delete/undo functionality in production
- [ ] Verify no user reports of issues
- [ ] Update team on deployment status

### Optional
- [ ] Deploy app to Play Store / App Store
- [ ] Notify users of improved comment system (release notes)
- [ ] Add monitoring/alerting for comment count discrepancies

---

**Deployed by**: _____________
**Date**: _____________
**Environment**: [ ] Development [ ] Staging [ ] Production
**Status**: [ ] Success [ ] Rollback Required [ ] Issues Noted

**Notes**:
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
