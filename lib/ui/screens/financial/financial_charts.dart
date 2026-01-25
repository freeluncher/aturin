import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../domain/models/invoice.dart';
import '../../../domain/logic/financial_stats.dart';

class FinancialCharts extends StatefulWidget {
  final List<Invoice> invoices;

  const FinancialCharts({super.key, required this.invoices});

  @override
  State<FinancialCharts> createState() => _FinancialChartsState();
}

class _FinancialChartsState extends State<FinancialCharts> {
  // 0 = Monthly, 1 = Yearly
  int _viewMode = 0;

  // Selections
  late int _selectedYear;
  late int _selectedMonth; // 1-12

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMonthly = _viewMode == 0;

    // Aggregate Data
    Map<int, double> chartData;
    double maxY = 0;

    if (isMonthly) {
      chartData = FinancialStats.getMonthlyStats(
        widget.invoices,
        _selectedYear,
        _selectedMonth,
      );
    } else {
      chartData = FinancialStats.getYearlyStats(widget.invoices, _selectedYear);
    }

    if (chartData.isNotEmpty) {
      maxY = chartData.values.reduce((a, b) => a > b ? a : b);
      // Add buffer to top
      maxY = maxY * 1.2;
      if (maxY == 0) maxY = 100000; // Default scale if empty
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Controls
            // Controls
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // View Mode Toggle
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('Monthly'),
                        icon: Icon(LucideIcons.calendarDays, size: 16),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('Yearly'),
                        icon: Icon(LucideIcons.calendarRange, size: 16),
                      ),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() {
                        _viewMode = newSelection.first;
                      });
                    },
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: MaterialStateProperty.all(EdgeInsets.zero),
                    ),
                  ),

                  const SizedBox(
                    width: 16,
                  ), // Replaced Spacer with fixed spacing
                  // Dropdowns based on mode
                  if (isMonthly) ...[
                    // Month Dropdown
                    DropdownButton<int>(
                      value: _selectedMonth,
                      underline: const SizedBox(),
                      items: List.generate(12, (index) {
                        return DropdownMenuItem(
                          value: index + 1,
                          child: Text(
                            DateFormat(
                              'MMMM',
                            ).format(DateTime(2022, index + 1)),
                          ),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMonth = val);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Year Dropdown (Last 5 years)
                  DropdownButton<int>(
                    value: _selectedYear,
                    underline: const SizedBox(),
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedYear = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Chart
            AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          NumberFormat.compactCurrency(
                            symbol: 'Rp',
                            decimalDigits: 0,
                          ).format(rod.toY),
                          TextStyle(
                            color: theme.colorScheme.onInverseSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final index = val.toInt();
                          if (!chartData.containsKey(index))
                            return const SizedBox();

                          // Clean up labels to avoid crowding
                          if (isMonthly) {
                            // Show ever 5th day and first/last
                            if (index == 1 ||
                                index == 15 ||
                                index == 30 ||
                                index % 5 == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  index.toString(),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          } else {
                            // Yearly: Show Month Initial (J, F, M...)
                            // Or short name (Jan, Feb)
                            final date = DateTime(2022, index);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('MMM').format(date),
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (val, meta) {
                          if (val == 0) return const SizedBox();
                          return Text(
                            NumberFormat.compact(
                              locale: 'en_US',
                            ).format(val), // Compact: 1K, 1M
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                      strokeWidth: 1,
                    ),
                  ),
                  barGroups: chartData.entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: theme.colorScheme.primary,
                          width: isMonthly ? 6 : 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
