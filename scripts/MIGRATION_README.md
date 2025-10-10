# Firestore Migration Script: Remove Unused Fields

## Overview

This script removes unused gamification and premium feature fields from the Firestore database that are no longer supported by the application.

## Fields Removed

### Users Collection (`users/{uid}`)
- `points` - User engagement points
- `level` - User level based on points
- `supporterLevel` - Supporter tier level
- `premiumTier` - Premium subscription tier
- `supporterBadgeVisible` - Visibility toggle for supporter badge
- `badges` - Array of earned badges

### Posts Collection (`posts/{postId}`)
- `authorSupporterLevel` - Post author's supporter level
- `authorIsSupporter` - Boolean indicating if author is a supporter

### Comments Subcollection (`posts/{postId}/comments/{commentId}`)
- `authorSupporterLevel` - Comment author's supporter level
- `authorIsSupporter` - Boolean indicating if author is a supporter

## Why Remove These Fields?

1. **Cost Optimization**: These fields were being written on every post/comment creation, consuming unnecessary Firestore write operations
2. **Code Cleanup**: Features were never implemented in the UI, making them "ghost features"
3. **Future Planning**: Team decided not to implement these features for at least 1 year
4. **Database Hygiene**: Removing unused data reduces storage costs and improves query performance

## Prerequisites

1. Firebase Admin SDK credentials (`functions/serviceAccountKey.json`)
2. Node.js installed
3. `firebase-admin` npm package installed (already in `functions/package.json`)

## Usage

### 1. Dry-Run Mode (Recommended First)

Run this first to see what would be deleted WITHOUT making any changes:

```bash
cd /path/to/gong_mu_talk
node scripts/remove_unused_fields.js --dry-run
```

This will output:
- Number of users, posts, and comments that would be affected
- Specific document IDs and fields that would be removed
- No actual database changes

### 2. Live Mode (Actual Deletion)

⚠️ **WARNING**: This permanently deletes data from Firestore!

```bash
node scripts/remove_unused_fields.js
```

The script will:
1. Give you 5 seconds to cancel (Ctrl+C)
2. Process users collection
3. Process posts collection
4. Process all comments subcollections
5. Show progress and completion summary

## Safety Features

- **Batch Processing**: Uses Firebase batches (500 operations max) for atomic operations
- **5-Second Delay**: Gives you time to cancel before starting
- **Dry-Run Mode**: Test first without making changes
- **Progress Reporting**: Shows detailed progress for each step
- **Error Handling**: Rolls back batches on error

## Expected Output

### Dry-Run Example:
```
╔════════════════════════════════════════════════════════════╗
║   Firestore Field Removal Script                          ║
║   Removing: points, level, supporter, premium, badges      ║
╚════════════════════════════════════════════════════════════╝

⚠️  DRY-RUN MODE: No changes will be made

📋 Step 1: Removing fields from users collection...

📊 Found 1234 users

   User abc123 has fields: points, level, badges
   User def456 has fields: supporterLevel, premiumTier

✅ 1234 users would be updated

📋 Step 2: Removing fields from posts collection...
...
```

### Live Mode Example:
```
⚠️  LIVE MODE: This will permanently delete data!
   Press Ctrl+C within 5 seconds to cancel...

📋 Step 1: Removing fields from users collection...
🔧 Committing 3 batch(es)...
   ✅ Batch 1/3 committed
   ✅ Batch 2/3 committed
   ✅ Batch 3/3 committed

✅ 1234 users were updated
...
```

## Performance

- **Small database** (<1000 docs): ~10-30 seconds
- **Medium database** (1000-10000 docs): ~1-5 minutes
- **Large database** (>10000 docs): ~5-15 minutes

Processing time depends on:
- Number of documents
- Number of comments per post
- Network speed
- Firestore region

## Troubleshooting

### Error: "Cannot find module 'firebase-admin'"
```bash
cd functions
npm install
cd ..
```

### Error: "serviceAccountKey.json not found"
1. Download service account key from Firebase Console
2. Place it in `functions/serviceAccountKey.json`
3. Ensure it's in `.gitignore` (it should be)

### Error: "Permission denied"
```bash
chmod +x scripts/remove_unused_fields.js
```

### Error: "Quota exceeded"
If you have a very large database, run the script during off-peak hours or contact Firebase support to temporarily increase quotas.

## Post-Migration Verification

After running the migration, verify the changes:

1. **Check Firestore Console**:
   - Open Firebase Console → Firestore Database
   - Random sample a few user/post/comment documents
   - Verify the fields no longer exist

2. **Check App Behavior**:
   - Deploy latest code to production
   - Test creating posts/comments
   - Verify no errors related to missing fields

3. **Monitor Firestore Usage**:
   - Firebase Console → Usage tab
   - Compare write operations before/after
   - Should see reduction in writes (no more point updates)

## Rollback

⚠️ **There is NO automatic rollback** for this script!

If you need to restore data:
1. Contact Firebase Support for point-in-time restore (available for Blaze plan)
2. Use Firestore backup/export if you created one beforehand

**Recommended**: Export Firestore data before running:
```bash
gcloud firestore export gs://your-bucket/backup-before-field-removal
```

## Related Code Changes

This migration script should be run AFTER deploying the code changes that removed:
- `lib/core/constants/engagement_points.dart`
- Point awarding logic in repositories
- `incrementPoints()` and `assignBadge()` methods
- All UI references to points/levels/badges

See git commit: `[commit hash]` for full code changes.

## Contact

For questions or issues:
- Email: hanisoft2022@gmail.com
- Check logs in console output
- Review Firebase Console for error details
