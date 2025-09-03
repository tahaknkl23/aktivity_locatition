// lib/core/widgets/dynamic_form/utils/date_picker_helper.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'date_formatter.dart';

/// Date picker helper utility
class DatePickerHelper {
  /// Date picker açar ve sonucu döndürür
  static Future<String?> selectDate({
    required BuildContext context,
    required dynamic currentValue,
    required bool hasTime,
  }) async {
    // Initial values
    DateTime initialDate = DateTime.now();
    TimeOfDay initialTime = TimeOfDay.now();

    // Parse current value
    final parsedDate = DateFormatter.parseDate(currentValue?.toString());
    if (parsedDate != null) {
      initialDate = parsedDate;
      initialTime = TimeOfDay.fromDateTime(parsedDate);
    }

    // Show date picker
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !context.mounted) return null;

    if (hasTime) {
      // Show time picker
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.primary,
                  ),
            ),
            child: child!,
          );
        },
      );

      if (selectedTime == null || !context.mounted) return null;

      // Format as "dd.MM.yyyy HH:mm"
      final dateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      return DateFormatter.format(dateTime);
    } else {
      // Format as "dd.MM.yyyy"
      return DateFormatter.formatDateOnly(selectedDate);
    }
  }
}
