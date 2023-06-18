import 'dart:ui';

class Constants {
  //fonts
  static const double headerFontSize = 22.0;
  static const double subHeaderFontSize = 18.0;
  static const double bodyFontSize = 16.0;
  static const subHeaderFontWeight = FontWeight.w600;

  //spacing
  static const double headerSpacing = 10.0;
  static const double subHeaderSpacing = 8.0;

  //padding
  static const double padding = 14.0;

  //api
  static const String baseUrl = 'https://example.com/';

  static const headerFontWeight = FontWeight.w600;

  static const assetRoutesMap = <AssetImages, String>{
    AssetImages.dublinBusLogoSmall: 'assets/images/dublinBusLogoSmall.png',
    AssetImages.dublinBusLogo: 'assets/images/dublinBusLogo.jpg',
    AssetImages.goAheadLogo: 'assets/images/goAheadLogo.png',
    AssetImages.clusterMarkerIcon: 'assets/images/clusterMarkerIcon.png',
    AssetImages.appleMap: 'assets/images/appleMap.jpg',
    AssetImages.busEireannLogo: 'assets/images/busEireannLogo.jpg',
  };
}

enum AssetImages {
  dublinBusLogoSmall,
  dublinBusLogo,
  goAheadLogo,
  clusterMarkerIcon,
  appleMap,
  busEireannLogo,
}
