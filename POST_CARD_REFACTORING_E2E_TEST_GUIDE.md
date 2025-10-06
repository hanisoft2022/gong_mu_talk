# PostCard Refactoring E2E Test Guide

## 📋 Overview

This guide provides step-by-step manual testing procedures to verify that PostCard functionality remains intact after migrating from StatefulWidget to PostCardCubit.

**Critical**: All tests must pass before merging to main branch.

---

## 🎯 Test Scope

### Migrated to PostCardCubit
- ✅ Comment loading (featured + timeline)
- ✅ Comment submission
- ✅ Comment like toggle (with optimistic updates)
- ✅ Post reporting
- ✅ User blocking
- ✅ View count tracking

### Remaining in PostCard StatefulWidget
- ⏳ Image upload for comments (future: ImageUploadCubit)
- ⏳ UI animations (expand/collapse)
- ⏳ Menu overlay management

---

## 🧪 Test Cases

### 1. Comment Loading

#### 1.1 Basic Comment Loading
**Steps**:
1. Open Community Feed
2. Tap "댓글" button on any post with 3+ comments
3. Verify comments appear

**Expected**:
- Loading indicator appears briefly
- Featured comment shown (if likeCount ≥ 3 and total comments ≥ 3)
- Timeline comments displayed below
- No duplicate comments

**Failure Indicators**:
- ❌ Infinite loading
- ❌ No comments shown
- ❌ Duplicate comments
- ❌ Crash on load

#### 1.2 Featured Comment Criteria
**Steps**:
1. Find post with 2 comments → Tap "댓글"
2. Find post with 3+ comments but top comment has <3 likes → Tap "댓글"
3. Find post with 3+ comments and top comment has 3+ likes → Tap "댓글"

**Expected**:
- Case 1: No featured comment (< 3 total comments)
- Case 2: No featured comment (likeCount < 3)
- Case 3: Featured comment shown

**Failure Indicators**:
- ❌ Featured shown when criteria not met
- ❌ Featured not shown when criteria met

---

### 2. Comment Submission

#### 2.1 Text-Only Comment
**Steps**:
1. Tap "댓글" on any post
2. Enter text: "Test comment"
3. Tap submit button
4. Wait for submission

**Expected**:
- Submit button disabled during submission
- Comment appears in timeline after submit
- Comment count increments by 1
- Input field clears

**Failure Indicators**:
- ❌ Comment not submitted
- ❌ Comment count not updated
- ❌ Duplicate comments
- ❌ Input field not cleared

#### 2.2 Comment with Images
**Steps**:
1. Tap "댓글" on any post
2. Tap image picker icon
3. Select 1-3 images
4. Enter text (optional)
5. Tap submit

**Expected**:
- Image thumbnails shown
- Upload progress visible
- Comment submitted with images
- Images displayed in comment

**Failure Indicators**:
- ❌ Upload fails
- ❌ Images not attached
- ❌ Progress bar stuck

#### 2.3 Empty Comment Validation
**Steps**:
1. Tap "댓글" on any post
2. Leave input empty
3. Tap submit (should be disabled)
4. Enter only whitespace: "   \n  "
5. Tap submit

**Expected**:
- Submit button disabled when empty
- No comment submitted for whitespace-only

**Failure Indicators**:
- ❌ Empty comment submitted
- ❌ Whitespace comment submitted

---

### 3. Comment Like (Optimistic Update)

#### 3.1 Like Comment
**Steps**:
1. Open comments on any post
2. Tap like icon on any comment (currently unliked)
3. Observe immediate UI update
4. Wait 2 seconds for API call

**Expected**:
- Heart icon fills immediately
- Like count increments immediately (+1)
- No rollback (API succeeds)

**Failure Indicators**:
- ❌ Delayed UI update
- ❌ Like count wrong
- ❌ Rollback occurs (should not)

#### 3.2 Unlike Comment
**Steps**:
1. Find liked comment (red heart)
2. Tap heart icon
3. Observe immediate update

**Expected**:
- Heart icon empties immediately
- Like count decrements (-1)
- No rollback

#### 3.3 Network Failure Rollback
**Steps**:
1. Enable airplane mode
2. Tap like on any comment
3. Observe immediate update
4. Wait 2 seconds

**Expected**:
- Like updates immediately (optimistic)
- After 2 seconds, reverts back (rollback)
- No error shown to user (silent fail for better UX)

**Failure Indicators**:
- ❌ No rollback on failure
- ❌ App crashes
- ❌ Error toast shown (should be silent)

---

### 4. Post Reporting

**Steps**:
1. Tap "..." menu on any post
2. Select "신고하기"
3. Choose reason: "스팸"
4. Confirm

**Expected**:
- Report dialog shows
- Report submitted successfully
- Success toast shown

**Failure Indicators**:
- ❌ Report not submitted
- ❌ Error toast shown
- ❌ Crash

---

### 5. User Blocking

**Steps**:
1. Tap author name on any post
2. Select "차단하기"
3. Confirm in dialog
4. Return to feed

**Expected**:
- Confirmation dialog shows
- Block request succeeds
- Success toast: "[닉네임]님을 차단했습니다"
- Posts from blocked user hidden (refresh feed to verify)

**Failure Indicators**:
- ❌ Block fails
- ❌ Posts still visible
- ❌ No confirmation toast

---

### 6. View Count Tracking

**Steps**:
1. Open Community Feed
2. Scroll to any post
3. Wait 1 second (view tracked)
4. Refresh feed
5. Find same post

**Expected**:
- View count incremented by 1
- Only tracked once per PostCard lifecycle

**Failure Indicators**:
- ❌ View count not incremented
- ❌ Multiple increments per view

---

### 7. Error Handling

#### 7.1 Comment Load Failure
**Steps**:
1. Enable airplane mode
2. Tap "댓글" on any post
3. Observe error state

**Expected**:
- Error message: "댓글을 불러오지 못했어요..."
- Retry option available

**Failure Indicators**:
- ❌ App crashes
- ❌ Infinite loading
- ❌ No error message

#### 7.2 Comment Submit Failure
**Steps**:
1. Enter comment text
2. Enable airplane mode
3. Tap submit
4. Wait for error

**Expected**:
- Error message: "댓글을 저장하지 못했어요..."
- Comment not added to list
- Input field preserves text

**Failure Indicators**:
- ❌ Comment added despite failure
- ❌ Input cleared

---

## 📊 Test Matrix

| Test Case | Before Refactoring | After Refactoring | Status |
|-----------|-------------------|-------------------|--------|
| Comment Loading (Basic) | ✅ | ⏳ | Pending |
| Comment Loading (Featured) | ✅ | ⏳ | Pending |
| Comment Submit (Text) | ✅ | ⏳ | Pending |
| Comment Submit (Images) | ✅ | ⏳ | Pending |
| Comment Like (Optimistic) | ✅ | ⏳ | Pending |
| Comment Unlike | ✅ | ⏳ | Pending |
| Network Failure Rollback | ✅ | ⏳ | Pending |
| Post Report | ✅ | ⏳ | Pending |
| User Block | ✅ | ⏳ | Pending |
| View Tracking | ✅ | ⏳ | Pending |
| Error: Load Failure | ✅ | ⏳ | Pending |
| Error: Submit Failure | ✅ | ⏳ | Pending |

---

## ✅ Sign-Off

**Tester Name**: ___________________  
**Date**: ___________________  
**All Tests Passed**: [ ] Yes  [ ] No

**Notes**:
_______________________________________
_______________________________________
_______________________________________

---

## 🚀 Next Steps After E2E Pass

1. ✅ Merge to main branch
2. Monitor Crashlytics for 24h
3. Check Firestore query costs
4. Phase 2: Extract ImageUploadCubit
5. Phase 3: Add more unit tests (target 70% coverage)

---

**Last Updated**: 2025-01-06  
**Version**: 1.0  
**Related PR**: [Link to PR]
