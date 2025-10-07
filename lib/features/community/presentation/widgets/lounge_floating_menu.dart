import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../../profile/domain/lounge_info.dart';
import '../../domain/services/lounge_access_service.dart';
import 'lounge_detail_sheet.dart';

class LoungeFloatingMenu extends StatefulWidget {
  const LoungeFloatingMenu({
    super.key,
    required this.lounges,
    required this.selectedLounge,
    required this.onLoungeSelected,
    required this.isVisible,
    this.hasCareerVerification = true,
    this.onVerifyCareer,
  });

  final List<LoungeInfo> lounges;
  final LoungeInfo? selectedLounge;
  final ValueChanged<LoungeInfo> onLoungeSelected;
  final bool isVisible;
  final bool hasCareerVerification;
  final VoidCallback? onVerifyCareer;

  @override
  State<LoungeFloatingMenu> createState() => _LoungeFloatingMenuState();
}

class _LoungeFloatingMenuState extends State<LoungeFloatingMenu>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  List<AnimationController> _itemControllers = [];
  List<Animation<Offset>> _itemSlideAnimations = [];
  List<Animation<double>> _itemFadeAnimations = [];

  @override
  void initState() {
    super.initState();

    // 메인 컨테이너 애니메이션
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // 각 메뉴 아이템 애니메이션 (Staggered) - 초기화
    _initializeItemAnimations();
  }

  void _initializeItemAnimations() {
    // 기존 컨트롤러들 정리 (안전한 dispose)
    try {
      if (_itemControllers.isNotEmpty) {
        for (final controller in _itemControllers) {
          if (controller.isAnimating) {
            controller.stop();
          }
          controller.dispose();
        }
      }
    } catch (e) {
      // 에러 발생 시 무시
    }

    // 새로운 컨트롤러들 생성
    final int loungeCount = widget.lounges.length;
    if (loungeCount == 0) {
      _itemControllers = [];
      _itemSlideAnimations = [];
      _itemFadeAnimations = [];
      return;
    }

    try {
      _itemControllers = List.generate(
        loungeCount,
        (index) => AnimationController(
          duration: Duration(milliseconds: 150 + (index * 50)),
          vsync: this,
        ),
      );

      _itemSlideAnimations = _itemControllers.map((controller) {
        return Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
        );
      }).toList();

      _itemFadeAnimations = _itemControllers.map((controller) {
        return Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
      }).toList();

      // 애니메이션 컨트롤러가 생성된 후 즉시 메뉴가 열려있으면 애니메이션 시작
      if (widget.isVisible && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.isVisible) {
            _showMenu();
          }
        });
      }
    } catch (e) {
      // 에러 발생 시 빈 목록으로 fallback
      _itemControllers = [];
      _itemSlideAnimations = [];
      _itemFadeAnimations = [];
    }
  }

  @override
  void didUpdateWidget(LoungeFloatingMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 라운지 목록이 변경되면 애니메이션 재초기화
    if (widget.lounges.length != oldWidget.lounges.length) {
      _initializeItemAnimations();
    }

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _showMenu();
      } else {
        _hideMenu();
      }
    }
  }

  void _showMenu() {
    if (!mounted) return;

    try {
      _controller.forward();

      // Staggered 애니메이션으로 각 아이템을 순차적으로 표시
      for (int i = 0; i < _itemControllers.length; i++) {
        Future.delayed(Duration(milliseconds: 50 + (i * 40)), () {
          if (mounted && widget.isVisible && i < _itemControllers.length) {
            try {
              _itemControllers[i].forward();
            } catch (e) {
              // 에러 발생 시 무시
            }
          }
        });
      }
    } catch (e) {
      // 에러 발생 시 무시
    }
  }

  void _hideMenu() {
    if (!mounted) return;

    try {
      _controller.reverse();
      for (int i = 0; i < _itemControllers.length; i++) {
        try {
          _itemControllers[i].reverse();
        } catch (e) {
          // 에러 발생 시 무시
        }
      }
    } catch (e) {
      // 에러 발생 시 무시
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    if (widget.lounges.isEmpty) {
      return _buildFallbackMenu(theme);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          alignment: Alignment.bottomRight, // FAB에서 시작하는 것처럼
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 헤더
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          border: Border(
                            bottom: BorderSide(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.forum_outlined,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const Gap(8),
                            Text(
                              '라운지 선택',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 메뉴 아이템들
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _buildMenuItems(theme),
                        ),
                      ),

                      // 급여명세서 인증 버튼 (미인증 시)
                      if (!widget.hasCareerVerification &&
                          widget.onVerifyCareer != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Divider(
                            height: 1,
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        _buildVerificationButton(theme),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildMenuItems(ThemeData theme) {
    // 애니메이션 컨트롤러가 라운지 수와 일치하지 않으면 빈 목록 반환
    if (_itemControllers.length != widget.lounges.length ||
        _itemSlideAnimations.length != widget.lounges.length ||
        _itemFadeAnimations.length != widget.lounges.length) {
      // 애니메이션 컨트롤러 재초기화 시도
      if (widget.lounges.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _initializeItemAnimations();
          }
        });
      }

      return [];
    }

    return widget.lounges.asMap().entries.map((entry) {
      final index = entry.key;
      final lounge = entry.value;
      final isSelected = lounge.id == widget.selectedLounge?.id;

      return AnimatedBuilder(
        animation: _itemControllers[index],
        builder: (context, child) {
          return SlideTransition(
            position: _itemSlideAnimations[index],
            child: FadeTransition(
              opacity: _itemFadeAnimations[index],
              child: _buildMenuItem(context, lounge, isSelected, theme),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildMenuItem(
    BuildContext context,
    LoungeInfo lounge,
    bool isSelected,
    ThemeData theme,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onLoungeSelected(lounge);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 라운지 이모지
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    lounge.emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const Gap(12),

              // 라운지 정보
              Expanded(
                child: Text(
                  lounge.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),

              // 통합 라운지 정보 아이콘
              if (_isUnifiedLounge(lounge)) ...[
                const Gap(4),
                InkWell(
                  onTap: () => _showLoungeDetailSheet(context, lounge),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],

              // 선택 표시
              if (isSelected) ...[
                const Gap(8),
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 통합 라운지 여부 확인
  bool _isUnifiedLounge(LoungeInfo lounge) {
    final requiredCareerIds = LoungeAccessService.getRequiredCareerIds(
      lounge.id,
    );
    return requiredCareerIds.length > 1;
  }

  /// 라운지 상세 정보 표시
  void _showLoungeDetailSheet(BuildContext context, LoungeInfo lounge) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LoungeDetailSheet(lounge: lounge),
    );
  }

  Widget _buildVerificationButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onVerifyCareer,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('🎓', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '직렬 인증하고 더 많은 라운지 이용하기',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        '급여명세서로 직렬을 인증하세요',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackMenu(ThemeData theme) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _controller.value,
          alignment: Alignment.bottomRight,
          child: Opacity(
            opacity: _controller.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '라운지 정보 로딩 중...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
