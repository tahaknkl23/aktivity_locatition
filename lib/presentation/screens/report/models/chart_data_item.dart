// lib/presentation/widgets/report/models/chart_data_item.dart
class ChartDataItem {
  final String label;
  final double value;

  ChartDataItem({
    required this.label,
    required this.value,
  });

  @override
  String toString() {
    return 'ChartDataItem(label: $label, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChartDataItem && other.label == label && other.value == value;
  }

  @override
  int get hashCode => label.hashCode ^ value.hashCode;
}
