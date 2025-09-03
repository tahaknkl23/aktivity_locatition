import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/real_map_location_picker.dart';
import '../dynamic_form_field_widget.dart';

class MapFieldWidget extends StatelessWidget {
  final FieldCommonProps props;

  const MapFieldWidget({
    super.key,
    required this.props,
  });

  @override
  Widget build(BuildContext context) {
    final currentLocation = _parseLocation();

    return InkWell(
      onTap: props.field.isEnabled ? () => _openMapSelector(context) : null,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(props.size.formFieldBorderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: currentLocation != null ? _buildSelectedLocationDisplay(currentLocation) : _buildEmptyLocationDisplay(),
      ),
    );
  }

  MapLocationData? _parseLocation() {
    if (props.currentValue == null || props.currentValue.toString().isEmpty) {
      return null;
    }

    try {
      final parts = props.currentValue.toString().split(',');
      if (parts.length == 2) {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return MapLocationData(
          latitude: lat,
          longitude: lng,
          address: 'Seçilen konum',
          coordinates: props.currentValue.toString(),
        );
      }
    } catch (e) {
      debugPrint('[MapField] Invalid location format: ${props.currentValue}');
    }

    return null;
  }

  Widget _buildSelectedLocationDisplay(MapLocationData location) {
    return Padding(
      padding: EdgeInsets.all(props.size.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: props.size.mediumIcon,
              ),
              SizedBox(width: props.size.smallSpacing),
              Expanded(
                child: Text(
                  'Konum Seçildi',
                  style: TextStyle(
                    fontSize: props.size.textSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (props.field.isEnabled)
                IconButton(
                  onPressed: () => props.onValueChanged(null),
                  icon: const Icon(
                    Icons.clear,
                    size: 20,
                    color: AppColors.error,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          SizedBox(height: props.size.tinySpacing),
          Flexible(
            child: Text(
              location.address,
              style: TextStyle(
                fontSize: props.size.smallText,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: props.size.tinySpacing),
          Text(
            location.coordinates,
            style: TextStyle(
              fontSize: props.size.smallText * 0.9,
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLocationDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map,
            size: 32,
            color: props.field.isEnabled ? AppColors.primary : AppColors.textTertiary,
          ),
          SizedBox(height: props.size.smallSpacing),
          Text(
            props.field.isEnabled ? 'Konum seçiniz' : 'Konum seçimi devre dışı',
            style: TextStyle(
              fontSize: props.size.textSize,
              color: props.field.isEnabled ? AppColors.textSecondary : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMapSelector(BuildContext context) async {
    try {
      final result = await showDialog<MapLocationData>(
        context: context,
        builder: (context) => RealMapLocationPicker(
          title: props.field.label,
          initialCoordinates: props.currentValue?.toString(),
        ),
      );

      if (result != null) {
        props.onValueChanged(result.coordinates);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Konum seçildi: ${result.address}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[MapField] Map selector error: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Konum seçiminde hata: ${e.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
