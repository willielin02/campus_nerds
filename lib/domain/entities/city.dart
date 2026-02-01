import 'package:equatable/equatable.dart';

/// City entity representing a location where events are held
class City extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? imageAsset;

  const City({
    required this.id,
    required this.name,
    required this.slug,
    this.imageAsset,
  });

  @override
  List<Object?> get props => [id, name, slug, imageAsset];
}

/// City image mapping based on FlutterFlow configuration
class CityImages {
  CityImages._();

  static const Map<String, String> _cityImages = {
    // Taipei
    '2e7c8bc4-232b-4423-9526-002fc27ed1d3':
        'assets/images/Gemini_Generated_Image_rywr7vrywr7vrywr.png',
    // Taoyuan
    '2e3dfbb9-8c2a-4098-8c09-9213f55de6fc':
        'assets/images/Gemini_Generated_Image_xen5gbxen5gbxen5.png',
    // Hsinchu
    '3d221404-0590-4cca-b553-1ab890f31267':
        'assets/images/Gemini_Generated_Image_6tyjmc6tyjmc6tyj.png',
    // Taichung
    '3bc5798e-933e-4d46-a819-05f3fa060077':
        'assets/images/Gemini_Generated_Image_s48qj2s48qj2s48q.png',
    // Chiayi
    'c3e02d08-970d-4fcf-82c5-69a86f69e872': 'assets/images/unnamed_(1).jpg',
    // Tainan
    '33a466b3-6d0b-4cd6-b197-9eaba2101853':
        'assets/images/Gemini_Generated_Image_mayt2wmayt2wmayt.png',
    // Kaohsiung
    '72cbb430-f015-41b1-970a-86297bf3c904':
        'assets/images/Gemini_Generated_Image_lq9w3olq9w3olq9w.png',
  };

  /// Get image asset path for a city by ID
  static String? getImageForCity(String cityId) => _cityImages[cityId];
}
