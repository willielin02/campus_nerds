import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/city.dart';

/// Category type for city selector (affects event counts and opacity)
enum CitySelectorCategory {
  focusedStudy,
  englishGames,
}

/// Fixed city order matching FlutterFlow
const _cityOrder = [
  '2e7c8bc4-232b-4423-9526-002fc27ed1d3', // 臺北
  '2e3dfbb9-8c2a-4098-8c09-9213f55de6fc', // 桃園
  '3d221404-0590-4cca-b553-1ab890f31267', // 新竹
  '3bc5798e-933e-4d46-a819-05f3fa060077', // 臺中
  'c3e02d08-970d-4fcf-82c5-69a86f69e872', // 嘉義
  '33a466b3-6d0b-4cd6-b197-9eaba2101853', // 臺南
  '72cbb430-f015-41b1-970a-86297bf3c904', // 高雄
];

/// Bottom sheet for selecting a city (FlutterFlow grid design)
class CitySelectorBottomSheet extends StatelessWidget {
  const CitySelectorBottomSheet({
    super.key,
    required this.cities,
    required this.selectedCity,
    required this.onCitySelected,
    required this.category,
    required this.eventCountsByCity,
  });

  final List<City> cities;
  final City? selectedCity;
  final ValueChanged<City> onCitySelected;
  final CitySelectorCategory category;

  /// Event counts per city (cityId -> count) for opacity control
  final Map<String, int> eventCountsByCity;

  /// Show the city selector bottom sheet
  static Future<void> show({
    required BuildContext context,
    required List<City> cities,
    required City? selectedCity,
    required ValueChanged<City> onCitySelected,
    required CitySelectorCategory category,
    required Map<String, int> eventCountsByCity,
  }) {
    // Filter cities to only show those with images (the 7 supported cities)
    // and sort them in the fixed order
    final filteredCities =
        cities.where((city) => city.imageAsset != null).toList();

    // Sort by fixed order
    filteredCities.sort((a, b) {
      final indexA = _cityOrder.indexOf(a.id);
      final indexB = _cityOrder.indexOf(b.id);
      // If not found in order list, put at end
      final orderA = indexA == -1 ? 999 : indexA;
      final orderB = indexB == -1 ? 999 : indexB;
      return orderA.compareTo(orderB);
    });

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: false,
      useRootNavigator: true,
      builder: (context) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CitySelectorBottomSheet(
          cities: filteredCities,
          selectedCity: selectedCity,
          onCitySelected: onCitySelected,
          category: category,
          eventCountsByCity: eventCountsByCity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Padding(
      // Outer padding: 16 left/right (matches FlutterFlow)
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.primaryBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Padding(
          // Inner column padding: left 32, top 48, right 32, bottom 32
          padding: const EdgeInsetsDirectional.fromSTEB(32, 48, 32, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title in Row (left-aligned)
              Row(
                children: [
                  Text(
                    '想認識哪裡的書呆子呢？',
                    style: textTheme.titleMedium?.copyWith(
                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                    ),
                  ),
                ],
              ),

              // Grid of city cards with top padding
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: cities.length,
                    itemBuilder: (context, index) {
                      final city = cities[index];
                      final eventCount = eventCountsByCity[city.id] ?? 0;
                      final isDisabled = eventCount == 0;

                      return _CityCard(
                        city: city,
                        isDisabled: isDisabled,
                        onTap: isDisabled
                            ? null
                            : () {
                                Navigator.pop(context);
                                onCitySelected(city);
                              },
                      );
                    },
                  ),
                ),
              ),

              // Bottom safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

/// City card widget with image background and text overlay
class _CityCard extends StatelessWidget {
  const _CityCard({
    required this.city,
    required this.isDisabled,
    this.onTap,
  });

  final City city;
  final bool isDisabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Opacity(
      opacity: isDisabled ? 0.22 : 1.0,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: colors.secondaryBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors.tertiary,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Image background
              if (city.imageAsset != null)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      city.imageAsset!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),

              // City name overlay
              Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          city.name,
                          style: textTheme.labelLarge?.copyWith(
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                            shadows: [
                              Shadow(
                                color: colors.primary,
                                offset: const Offset(2, 2),
                                blurRadius: 2,
                              ),
                              Shadow(
                                color: colors.primary,
                                offset: const Offset(-2, -2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
