import 'dart:developer';
import 'dart:io';
import 'package:better_bus_dublin/pages/stop_details.dart';
import 'package:better_bus_dublin/utils/components.dart';
import 'package:better_bus_dublin/utils/constants.dart';
import 'package:better_bus_dublin/utils/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class RouteDetail extends StatefulWidget {
  const RouteDetail({super.key, required this.route1, required this.route2});

  final BusRoute route1;
  final BusRoute route2;

  @override
  State<RouteDetail> createState() => _RouteDetailState();
}

class _RouteDetailState extends State<RouteDetail> {
  final isMobile = Platform.isIOS || Platform.isAndroid;

  late BusRoute currentRoute;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    currentRoute = widget.route1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        automaticallyImplyLeading: true,
        leading: IconButton(
          color: Theme.of(context).colorScheme.onPrimary,
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentRoute.routeLongName ?? '',
                      style: TextStyle(
                        fontSize: Constants.headerFontSize,
                        fontWeight: Constants.headerFontWeight,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().scaleY(),
        ),

        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: BoldTileText(currentRoute.routeShortName),
        //make app bar height react to title text length

        elevation: 6,
        actions: [
          //flip route direction
          ElevatedButton(
            onPressed: () {
              setState(() {
                currentRoute = currentRoute == widget.route1
                    ? widget.route2
                    : widget.route1;
              });
            },
            child: Row(
              children: [
                Text(
                  'Switch Direction',
                  style: TextStyle(
                      fontSize: Constants.subHeaderFontSize,
                      fontWeight: Constants.subHeaderFontWeight,
                      color: Theme.of(context).colorScheme.onPrimary),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          isMobile
              ? FractionallySizedBox(
                  heightFactor: .65,
                  child: PlatformMap(
                    initialCameraPosition: CameraPosition(
                      target: getLatLngBoundsCenter(currentRoute.routeStops),
                      zoom: 12,
                    ),
                    markers: placeMarkers(currentRoute.routeStops),
                  ),
                )
              : FractionallySizedBox(
                  heightFactor: .65,
                  child: Image.asset(
                    Constants.assetRoutesMap[AssetImages.appleMap]!,
                    fit: BoxFit.cover,
                  ),
                ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: .35,
              alignment: Alignment.bottomCenter,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(0),
                      itemCount: currentRoute.routeStops.length,
                      itemBuilder: (context, index) {
                        return InformationTile(
                          onTileTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => StopDetailsPage(
                                  stop: currentRoute.routeStops[index],
                                ),
                              ),
                            );
                          },
                          titleText: currentRoute.routeStops[index].stopName,
                          subtitleText:
                              'Stop ${currentRoute.routeStops[index].stopCode}',
                          isLoadingRoute: false,
                          index: index,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  getLatLngBoundsCenter(List<Stop> routeStops) {
    double minLat = 90;
    double maxLat = -90;
    double minLng = 180;
    double maxLng = -180;
    for (var stop in routeStops) {
      if (stop.stopLat < minLat) {
        minLat = stop.stopLat;
      }
      if (stop.stopLat > maxLat) {
        maxLat = stop.stopLat;
      }
      if (stop.stopLon < minLng) {
        minLng = stop.stopLon;
      }
      if (stop.stopLon > maxLng) {
        maxLng = stop.stopLon;
      }
    }
    log('center is ${LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2)}',
        name: 'center');
    return LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );
  }

  Set<Marker> placeMarkers(List<Stop> routeStops) {
    Set<Marker> markers = {};
    for (var stop in routeStops) {
      markers.add(
        Marker(
          infoWindow: InfoWindow(
            title: stop.stopCode,
            onTap: () => handleMarkerTap(stop),
          ),
          markerId: MarkerId(stop.stopId),
          position: LatLng(stop.stopLat, stop.stopLon),
          consumeTapEvents: true,
          onTap: () {
            log('tapped marker ${stop.stopId}');
          },
        ),
      );
    }
    return markers;
  }

  handleMarkerTap(Stop stop) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => StopDetailsPage(stop: stop),
      ),
    );
  }
}
