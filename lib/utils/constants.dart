import 'package:flutter/widgets.dart';

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

  static const assetRoutesMap = <AssetId, String>{
    AssetId.dublinBusLogoSmall: 'assets/images/dublinBusLogoSmall.png',
    AssetId.dublinBusLogo: 'assets/images/dublinBusLogo.jpg',
    AssetId.goAheadLogo: 'assets/images/goAheadLogo.png',
    AssetId.clusterMarkerIcon: 'assets/images/clusterMarkerIcon.png',
    AssetId.appleMap: 'assets/images/appleMap.jpg',
    AssetId.busEireannLogo: 'assets/images/busEireannLogo.jpg',
    AssetId.markerIconMaterial: 'assets/images/markerIcon.png',
  };

  static Widget horizPadding(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
        child: child,
      );
}

enum AssetId {
  dublinBusLogoSmall,
  dublinBusLogo,
  goAheadLogo,
  clusterMarkerIcon,
  markerIconMaterial,
  appleMap,
  busEireannLogo,
}
