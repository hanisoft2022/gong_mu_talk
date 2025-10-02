# Profile Page Refactoring Plan

## Overview
**Target File**: `lib/features/profile/presentation/views/profile_page.dart`
**Current Size**: 3,131 lines (RED ZONE - 800+ lines over limit)
**Target Size**: ≤300 lines (GREEN ZONE)
**Estimated Token Count**: ~31,000 tokens → ~3,000 tokens (90% reduction)

## File Structure Analysis

### Current Components (30+ classes/widgets)
1. **ProfilePage** (lines 30-65) - Main coordinator
2. **_ProfileLoggedOut** (lines 67-102) - Logged out view
3. **_ProfileLoggedInScaffold** (lines 104-172) - Logged in scaffold
4. **_ProfileOverviewTab** (lines 174-231) - Overview tab
5. **_TimelineSection** (lines 233-353) - Timeline display
6. **_TimelinePostTile** (lines 355-414) - Post tile
7. **_TimelineStat** (lines 416-432) - Stat widget
8. **_ProfileHeader** (lines 434-892) - **HUGE** 458 lines with test career selector
9. **_StatCard** (lines 895-947) - Follower/following card
10. **_BioCard** (lines 949-1036) - Bio display with expand/collapse
11. **_VerificationStatusRow** (lines 1038-1072) - Verification status
12. **_PaystubStatusRow** (lines 1074-1169) - Paystub status
13. **_ProfileAvatar** (lines 1171-1200) - Avatar widget
14. **_ProfileSettingsTab** (lines 1202-1789) - **HUGE** 587 lines settings
15. **_SettingsSection** (lines 1791-1809) - Settings section wrapper
16. **_showRelationsSheet** (lines 1811-1950) - Relations bottom sheet
17. **_FollowButton** (lines 1956-2112) - Follow/unfollow button
18. **Helper functions** (lines 2114-2140) - _formatDate, _getMaskedNickname
19. **_SponsorshipBanner** (lines 2142-2151) - Sponsorship widget
20. **ProfileEditPage** (lines 2154-2343) - Edit page (189 lines)
21. **_ProfileEditSection** (lines 2346-2366) - Edit section wrapper
22. **_ProfileImageSection** (lines 2368-2468) - Image picker
23. **_PaystubVerificationCard** (lines 2472-2598) - Paystub card
24. **_GovernmentEmailVerificationCard** (lines 2600-2757) - Email verification
25. **_ThemeSettingsSection** (lines 2759-2860) - Theme picker
26. **_ThemeOptionTile** (lines 2862-2902) - Theme option
27. **_CustomLicensePage** (lines 2904-3130) - License page (226 lines)

## Proposed File Structure

```
lib/features/profile/presentation/
├── views/
│   ├── profile_page.dart (200-300 lines) ✓ MAIN COORDINATOR
│   ├── profile_edit_page.dart (300-400 lines)
│   ├── profile_logged_out_page.dart (50-100 lines)
│   └── license_page.dart (200-250 lines)
│
├── widgets/
│   ├── profile_common/
│   │   ├── profile_avatar.dart (30-50 lines) ✓ CREATED
│   │   ├── stat_card.dart (50-70 lines) ✓ CREATED
│   │   ├── bio_card.dart (80-100 lines) ✓ CREATED
│   │   └── follow_button.dart (150-180 lines) ✓ CREATED
│   │
│   ├── profile_overview/
│   │   ├── profile_overview_tab.dart (50-80 lines)
│   │   ├── profile_header.dart (300-400 lines) [includes test career selector]
│   │   ├── profile_stats_section.dart (50-80 lines)
│   │   └── sponsorship_banner.dart (20-30 lines) ✓ CREATED
│   │
│   ├── profile_timeline/
│   │   ├── timeline_section.dart (120-150 lines) ✓ CREATED
│   │   ├── timeline_post_tile.dart (60-80 lines) ✓ CREATED
│   │   └── timeline_stat.dart (20-30 lines) ✓ CREATED
│   │
│   ├── profile_settings/
│   │   ├── profile_settings_tab.dart (400-500 lines)
│   │   ├── settings_section.dart (20-30 lines)
│   │   ├── theme_settings_section.dart (80-120 lines)
│   │   ├── theme_option_tile.dart (40-60 lines)
│   │   ├── notification_settings_section.dart (150-200 lines)
│   │   ├── password_change_section.dart (120-150 lines)
│   │   └── account_management_section.dart (100-150 lines)
│   │
│   ├── profile_verification/
│   │   ├── verification_status_row.dart (30-50 lines) ✓ CREATED
│   │   ├── paystub_status_row.dart (80-120 lines)
│   │   ├── paystub_verification_card.dart (120-150 lines)
│   │   └── government_email_verification_card.dart (150-180 lines)
│   │
│   ├── profile_edit/
│   │   ├── profile_edit_section.dart (20-30 lines)
│   │   └── profile_image_section.dart (80-120 lines)
│   │
│   └── profile_relations/
│       └── relations_sheet.dart (120-160 lines)
│
└── utils/
    └── profile_helpers.dart (40-60 lines) ✓ CREATED
```

## Files Created (Progress)

### ✓ Completed (8 files)
1. `utils/profile_helpers.dart` (47 lines) - Helper functions
2. `widgets/profile_common/profile_avatar.dart` (44 lines) - Avatar widget
3. `widgets/profile_common/stat_card.dart` (66 lines) - Stat cards
4. `widgets/profile_common/bio_card.dart` (102 lines) - Bio display
5. `widgets/profile_common/follow_button.dart` (169 lines) - Follow button
6. `widgets/profile_timeline/timeline_stat.dart` (25 lines) - Timeline stat
7. `widgets/profile_timeline/timeline_post_tile.dart` (77 lines) - Post tiles
8. `widgets/profile_timeline/timeline_section.dart` (138 lines) - Timeline section
9. `widgets/profile_verification/verification_status_row.dart` (41 lines) - Status row
10. `widgets/profile_overview/sponsorship_banner.dart` (15 lines) - Sponsorship

**Total Created**: 724 lines across 10 files

### ⏳ Remaining (18-20 files)
- Profile overview widgets (header, tab, stats section)
- Settings widgets (main tab + 6 sections)
- Verification widgets (2 large cards, 1 status row)
- Edit page + widgets (main page + 2 sections)
- License page
- Logged out page
- Relations sheet

## Refactoring Strategy

### Phase 1: Extract Standalone Widgets ✓ DONE
- Helper functions → utils/
- Common widgets (avatar, stat card, bio, follow button)
- Timeline widgets
- Simple verification widgets

### Phase 2: Extract Large Complex Components (NEXT)
1. **ProfileEditPage** (189 lines) → `views/profile_edit_page.dart`
2. **_CustomLicensePage** (226 lines) → `views/license_page.dart`
3. **_ProfileLoggedOut** (35 lines) → `views/profile_logged_out_page.dart`

### Phase 3: Extract Massive Components (CRITICAL)
1. **_ProfileHeader** (458 lines) → Split into:
   - `widgets/profile_overview/profile_header.dart` (200-250 lines)
   - Test career selector can stay or move to separate file

2. **_ProfileSettingsTab** (587 lines) → Split into:
   - `widgets/profile_settings/profile_settings_tab.dart` (main, 150-200 lines)
   - `widgets/profile_settings/notification_settings_section.dart` (150 lines)
   - `widgets/profile_settings/password_change_section.dart` (120 lines)
   - `widgets/profile_settings/theme_settings_section.dart` (100 lines)
   - `widgets/profile_settings/account_management_section.dart` (100 lines)

### Phase 4: Create Coordinator
Refactor main `profile_page.dart` to:
- Import all extracted widgets
- Contain only: ProfilePage, _ProfileLoggedInScaffold, _ProfileOverviewTab
- Delegate to extracted components
- **Target**: 200-300 lines

## Token Savings Calculation

### Before
- **File Size**: 3,131 lines
- **Estimated Tokens**: ~31,000 tokens
- **Status**: RED ZONE (3.9x over limit)

### After
- **Main file**: 250 lines (~2,500 tokens)
- **Average extracted file**: 80 lines (~800 tokens each)
- **Total files**: ~30 files
- **Token savings per AI read**: ~28,500 tokens (92% reduction)

## Benefits

### 1. Code Organization
- Single Responsibility Principle enforced
- Easy to locate specific components
- Clear dependency structure

### 2. AI Efficiency
- Each file fits within AI context window
- 92% reduction in tokens for main file
- Parallel development possible

### 3. Maintenance
- Bug fixes isolated to specific files
- Testing individual components easier
- Reduced merge conflicts

### 4. Performance
- Better tree-shaking
- Faster hot reload
- Improved build times

## Implementation Checklist

- [x] Create directory structure
- [x] Extract helper functions (profile_helpers.dart)
- [x] Extract common widgets (4 files)
- [x] Extract timeline widgets (3 files)
- [x] Extract simple verification widgets (2 files)
- [ ] Extract ProfileEditPage
- [ ] Extract LicensePage
- [ ] Extract ProfileLoggedOutPage
- [ ] Extract profile header (massive 458 lines)
- [ ] Extract profile settings tab (massive 587 lines)
- [ ] Extract verification cards (2 large files)
- [ ] Extract profile overview tab
- [ ] Extract relations sheet
- [ ] Refactor main profile_page.dart
- [ ] Update all imports
- [ ] Run flutter pub run build_runner build
- [ ] Run flutter analyze
- [ ] Run flutter test
- [ ] Verify all functionality

## Completion Metrics

### Target Metrics
- **Main file**: ≤300 lines (GREEN ZONE)
- **All widget files**: ≤400 lines each (GREEN ZONE)
- **Compilation**: Success
- **Tests**: All passing
- **Functionality**: 100% preserved

### Current Progress
- **Files Created**: 10/30 (33%)
- **Lines Extracted**: 724 lines (23%)
- **Estimated Completion**: 75% more work needed

## Next Steps

1. Create ProfileEditPage extraction
2. Create LicensePage extraction
3. Extract ProfileHeader (the 458-line monster)
4. Extract ProfileSettingsTab (the 587-line monster)
5. Extract verification cards
6. Refactor main coordinator
7. Test and verify

## Notes

- Some components like _ProfileHeader contain test-only code (test career selector)
- Consider separating test utilities into a separate file
- The test career selector (136 career options) could be moved to a constants file
- Settings tab has multiple responsibilities that should be split
- License page is self-contained and easy to extract
