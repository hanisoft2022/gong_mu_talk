/// Extracted from teacher_salary_insight_page.dart for better file organization
/// This widget displays the annual salary projection table

library;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/annual_salary.dart';

class SalaryProjectionTable extends StatelessWidget {
  const SalaryProjectionTable({
    required this.data,
    super.key,
  });

  final List<AnnualSalary> data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '연도별 연봉 예측',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (data.isEmpty)
              Text(
                '예측 데이터를 계산할 수 없습니다. 입력값을 확인해주세요.',
                style: theme.textTheme.bodyMedium,
              )
            else
              SizedBox(
                height: min(360, 56.0 * data.length + 56),
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const <DataColumn>[
                        DataColumn(label: Text('Year')),
                        DataColumn(label: Text('세전 연봉')),
                        DataColumn(label: Text('세후 연봉')),
                      ],
                      rows: data
                          .map(
                            (AnnualSalary entry) => DataRow(
                              cells: <DataCell>[
                                DataCell(Text('${entry.year}년')),
                                DataCell(
                                  Text(currencyFormat.format(entry.gross.round())),
                                ),
                                DataCell(
                                  Text(currencyFormat.format(entry.net.round())),
                                ),
                              ],
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
