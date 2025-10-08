# Hot Score Algorithm Change

**Date**: 2025-01-XX
**Type**: Algorithm Enhancement
**Impact**: High - Changes ranking behavior for daily/weekly popular posts

---

## 📊 What Changed

### Before (Linear Scaling)
```typescript
baseScore = (likeCount × 2.0) + (commentCount × 3.0) + (viewCount × 0.1)
hotScore = baseScore × (0.8 ^ (hoursAgo / 24))
```

**Problem:**
- 100번째 좋아요 = 1번째 좋아요 (같은 가중치)
- 봇/어뷰징에 취약 (좋아요 1000개 = 즉시 1위)
- 댓글 없는 글이 과도하게 높은 순위

### After (Logarithmic Scaling)
```typescript
voteScore = log10(likeCount + 1) × 10.0
commentScore = commentCount × 3.0
viewScore = log10(viewCount + 1) × 0.5
baseScore = voteScore + commentScore + viewScore
hotScore = baseScore × (0.8 ^ (hoursAgo / 24))
```

**Benefits:**
- 초기 투표 가중치 높음 (Reddit/HackerNews 방식)
- 봇/어뷰징 방지 (로그 스케일)
- 댓글 많은 글이 더 높은 순위 (토론 중시)

---

## 🔢 Score Comparison Examples

### Example 1: Normal Post
```
Post A: 50 likes, 20 comments, 500 views, 3 hours ago

BEFORE:
  base = 50×2 + 20×3 + 500×0.1 = 210
  decay = 0.8^(3/24) = 0.974
  hotScore = 204.5

AFTER:
  voteScore = log10(51) × 10 = 17.1
  commentScore = 20 × 3 = 60
  viewScore = log10(501) × 0.5 = 1.35
  base = 78.45
  decay = 0.974
  hotScore = 76.4

Result: Score decreased, but relative ranking improved for discussion-heavy posts
```

### Example 2: Bot/Gaming Scenario
```
Post B (Bot): 1000 likes, 0 comments, 100 views, 1 hour ago
Post C (Real): 50 likes, 30 comments, 500 views, 1 hour ago

BEFORE:
  Post B: base = 1000×2 + 0 + 10 = 2010, hotScore = 1988 ← Winner
  Post C: base = 50×2 + 90 + 50 = 240, hotScore = 237 ← Loser

AFTER:
  Post B: voteScore = 30, commentScore = 0, viewScore = 1, base = 31, hotScore = 30.7
  Post C: voteScore = 17.1, commentScore = 90, viewScore = 1.35, base = 108.45, hotScore = 107.3 ← Winner

Result: Real discussion-heavy post now ranks higher! ✅
```

### Example 3: Vote Count Impact
```
Likes:     1    10    100   1000
Old Score: 2    20    200   2000
New Score: 0    10    20    30

Result: Logarithmic diminishing returns (anti-gaming)
```

---

## 📈 Expected Behavior Changes

### Daily Popular Tab (일간)
**Before:**
- 어제 글이 계속 상위 차지
- 좋아요만 많으면 무조건 상위
- 새 글이 올라오기 어려움

**After:**
- 최근 글이 더 자주 순환
- 댓글 많은 토론글이 상위
- 봇 글 자동 배제

### Weekly Popular Tab (주간)
**Before:**
- 초반에 인기 얻은 글이 계속 1위
- 중반 이후 글은 순위 진입 어려움

**After:**
- 댓글 많은 글이 역전 가능
- 토론 활발한 글이 지속적으로 상위 유지

---

## 🔧 Technical Details

### Weight Configuration
```typescript
const HOT_SCORE_WEIGHTS = {
  likeLogScale: 10.0,  // Multiplier for log10(likes + 1)
  comment: 3.0,        // Linear weight for comments (unchanged)
  viewLogScale: 0.5,   // Multiplier for log10(views + 1) - increased from 0.1
  timeDecayHours: 24,  // Unchanged
  decayFactor: 0.8,    // Unchanged (to be tuned later)
};
```

### Changed Files
1. `functions/src/index.ts` - Firebase Functions (calculateHotScore)
2. `lib/core/utils/hot_score.dart` - Flutter client (HotScoreCalculator)

### Database Impact
- **Firestore Indexes**: No change required (sorting order still works)
- **Existing hotScore values**: Will be recalculated by Firebase Functions
- **Migration**: Not required (automatic via Functions triggers)

---

## 🧪 Testing Recommendations

### Before Deployment
1. Test with existing production data:
   ```dart
   // Compare old vs new scores for top 100 posts
   final oldCalculator = HotScoreCalculator(
     likeWeight: 2, commentWeight: 3, viewWeight: 0.1,
   );
   final newCalculator = HotScoreCalculator(); // new defaults
   ```

2. Monitor for 1-2 weeks after deployment:
   - Daily popular ranking changes
   - User engagement metrics (CTR, time on page)
   - Bot/spam detection rates

### Red Flags to Watch
- ⚠️ Same posts stuck in top 10 for >3 days
- ⚠️ Zero-comment posts dominating rankings
- ⚠️ Sudden drop in user engagement

---

## 🔄 Rollback Plan

If issues occur, revert by changing constants back:

```typescript
// Rollback to linear scaling
const HOT_SCORE_WEIGHTS = {
  likeLogScale: 2.0,   // Effectively linear
  comment: 3.0,
  viewLogScale: 0.1,   // Effectively linear
  timeDecayHours: 24,
  decayFactor: 0.8,
};

// And remove log10 calculations in calculateHotScore
const voteScore = likeCount * HOT_SCORE_WEIGHTS.likeLogScale;
const viewScore = viewCount * HOT_SCORE_WEIGHTS.viewLogScale;
```

**Estimated rollback time**: 10 minutes (code change + deploy)

---

## 📚 References

- [Reddit's Hot Algorithm](https://medium.com/hacking-and-gonzo/how-reddit-ranking-algorithms-work-ef111e33d0d9)
- [HackerNews Ranking Formula](https://medium.com/hacking-and-gonzo/how-hacker-news-ranking-algorithm-works-1d9b0cf2c08d)
- [Deriving the Reddit Formula - Evan Miller](https://www.evanmiller.org/deriving-the-reddit-formula.html)

---

## 🎯 Future Improvements (Phase 2)

Consider after monitoring Phase 1:

1. **Faster time decay** (if old posts still dominate)
   ```typescript
   decayFactor: 0.5  // 0.8 → 0.5 (24h → 50% instead of 80%)
   ```

2. **Controversy score** (balance likes/dislikes)
   ```typescript
   const controversy = (likes + dislikes) / abs(likes - dislikes)
   ```

3. **Quality signals** (author reputation, report count)
   ```typescript
   const penalty = post.reportCount > 3 ? 0.5 : 1.0
   ```

4. **Dynamic weights** (per-lounge customization)
   ```typescript
   // Teacher lounge: higher comment weight
   // General lounge: balanced
   ```
