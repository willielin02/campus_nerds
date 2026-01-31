import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/city.dart';

/// Bottom sheet for selecting a city
class CitySelectorBottomSheet extends StatelessWidget {
  const CitySelectorBottomSheet({
    super.key,
    required this.cities,
    required this.selectedCity,
    required this.onCitySelected,
    required this.onAllCitiesSelected,
  });

  final List<City> cities;
  final City? selectedCity;
  final ValueChanged<City> onCitySelected;
  final VoidCallback onAllCitiesSelected;

  /// Show the city selector bottom sheet
  static Future<void> show({
    required BuildContext context,
    required List<City> cities,
    required City? selectedCity,
    required ValueChanged<City> onCitySelected,
    required VoidCallback onAllCitiesSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CitySelectorBottomSheet(
        cities: cities,
        selectedCity: selectedCity,
        onCitySelected: onCitySelected,
        onAllCitiesSelected: onAllCitiesSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: colors.tertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              '選擇地區',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Divider
          Divider(color: colors.tertiary, height: 1),

          // All cities option
          _CityOption(
            label: '全部地區',
            isSelected: selectedCity == null,
            onTap: () {
              Navigator.pop(context);
              onAllCitiesSelected();
            },
            colors: colors,
            textTheme: textTheme,
          ),

          // City list
          ...cities.map((city) => _CityOption(
                label: city.name,
                isSelected: selectedCity?.id == city.id,
                onTap: () {
                  Navigator.pop(context);
                  onCitySelected(city);
                },
                colors: colors,
                textTheme: textTheme,
              )),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _CityOption extends StatelessWidget {
  const _CityOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.textTheme,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColorsTheme colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyLarge?.copyWith(
                  color: isSelected ? colors.primary : colors.primaryText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
