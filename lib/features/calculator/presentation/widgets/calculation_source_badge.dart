import 'package:flutter/material.dart';

/// 계산 출처 신뢰 배지
///
/// 정부 공식 데이터 기반임을 표시하여 신뢰성 강화
class CalculationSourceBadge extends StatelessWidget {
  final String source;
  final String? year;
  final VoidCallback? onTap;

  const CalculationSourceBadge({
    super.key,
    required this.source,
    this.year,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = year != null ? '$year $source 기준' : '$source 기준';
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap ?? () => _showSourceInfo(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              displayText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.info_outline, size: 14, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  void _showSourceInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SourceInfoSheet(source: source, year: year),
    );
  }
}

/// 출처 정보 시트
class _SourceInfoSheet extends StatelessWidget {
  final String source;
  final String? year;

  const _SourceInfoSheet({required this.source, this.year});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '신뢰할 수 있는 계산',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 출처 정보
          _buildInfoRow(
            context,
            '📋 적용 기준',
            year != null ? '$year년 $source' : source,
          ),

          const SizedBox(height: 12),

          _buildInfoRow(context, '🏛️ 법적 근거', _getLegalBasis(source)),

          const SizedBox(height: 12),

          _buildInfoRow(context, '📊 데이터 출처', _getDataSource(source)),

          const SizedBox(height: 12),

          _buildInfoRow(context, '🔄 마지막 업데이트', year ?? '2025'),

          const SizedBox(height: 24),

          // 안내 메시지
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '공무원 보수규정 및 관련 법령에 따라 정확하게 계산됩니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.primary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 닫기 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _getLegalBasis(String source) {
    if (source.contains('공무원 보수규정')) {
      return '공무원 보수규정\n(대통령령 제33149호)';
    } else if (source.contains('공무원연금법')) {
      return '공무원연금법\n(법률 제19234호)';
    } else if (source.contains('퇴직급여')) {
      return '공무원 보수규정 제35조\n(퇴직급여)';
    }
    return source;
  }

  String _getDataSource(String source) {
    if (source.contains('보수') || source.contains('급여')) {
      return '인사혁신처\n공무원 보수·수당 고시';
    } else if (source.contains('연금')) {
      return '공무원연금공단\n연금 산정 기준';
    }
    return '정부 공식 데이터';
  }
}
