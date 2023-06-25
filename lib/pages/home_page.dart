import 'dart:developer';
import 'dart:io';

import 'package:better_bus_dublin/components/map_view.dart';
import 'package:better_bus_dublin/pages/route_detail_page.dart';
import 'package:better_bus_dublin/pages/saved_page.dart';
import 'package:better_bus_dublin/pages/stop_details.dart';
import 'package:better_bus_dublin/utils/api_interface.dart';
import 'package:better_bus_dublin/utils/components.dart';
import 'package:better_bus_dublin/utils/constants.dart';
import 'package:better_bus_dublin/utils/models.dart';
import 'package:better_bus_dublin/utils/providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  DraggableScrollableController draggableScrollController =
      DraggableScrollableController();

  final Duration animationDuration = const Duration(milliseconds: 120);
  final double modalSearchHeight = .8;
  final Curve animationCurve = Curves.easeInSine;
  final List<double> snapSizes = [.26, .82];
  final double minChildSize = 0.26;
  final double maxChildSize = .82;
  final double initialChildSize = 0.26;
  late final GlobalKey<ScaffoldState> scaffoldKey;
  final isMobile = Platform.isIOS || Platform.isAndroid;
  late final BitmapDescriptor clusterImage;
  late final PlatformMapController mapController;
  bool continousUpdate = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    scaffoldKey = GlobalKey();
    initialCalendarLoad();
    initialStopsLoad();
    initialRoutesLoad();
    loadClusterMarkerImage();
  }

  loadClusterMarkerImage() async {
    clusterImage = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(),
        Constants.assetRoutesMap[AssetImages.clusterMarkerIcon]!);
  }

  initialStopsLoad() async {
    await Provider.of<ApiInterface>(context, listen: false).loadStops(
        callback: (errorString) {
      if (errorString.isNotEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorString)));
      }
    });
  }

  initialCalendarLoad() async {
    await Provider.of<ApiInterface>(context, listen: false)
        .loadServiceAvailability();
  }

  markerWindowTapped(String stopId) {
    Stop? stop = Provider.of<ApiInterface>(context, listen: false)
        .searchByStopId(stopId, (e) => genericDebugErrorHandler(e));
    if (stop != null) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => StopDetailsPage(stop: stop),
        ),
      );
    }
  }

  mapCreatedHandler(PlatformMapController controller) async {
    mapController = controller;
    refreshMapClusters();
    setState(() {});
    Provider.of<ApiInterface>(context, listen: false)
        .initFluster(1, 20, clusterImage, (stopId) {
      markerWindowTapped(stopId);
    });
  }

  handleCameraMove(CameraPosition camPos) {
    Provider.of<ApiInterface>(context, listen: false).currentCamPos = camPos;
    if (continousUpdate) {
      refreshMapClusters();
    }
  }

  refreshMapClusters() async {
    final visibleRegion = await mapController.getVisibleRegion();
    Provider.of<ApiInterface>(context, listen: false)
        .updateClustersForCamPos(visibleRegion);
  }

  initialRoutesLoad() async {
    await Provider.of<ApiInterface>(context, listen: false).loadRoutes(
        callback: (errorString) {
      if (errorString.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorString),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      drawerEnableOpenDragGesture: false,
      drawer: HomePageDrawer(
          continousUpdate: continousUpdate,
          continousUpdateChanged: (val) {
            setState(() {
              continousUpdate = val;
            });
          }),
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Stack(
              fit: StackFit.expand,
              children: [
                isMobile
                    ? Consumer<ApiInterface>(builder: (context, value, child) {
                        return MapView(
                          onMapCreated: (mapController) {
                            mapCreatedHandler(mapController);
                          },
                          cameraIdleCallback: () => refreshMapClusters(),
                          onCameraMove: (camPos) => handleCameraMove(camPos),
                          markers: value.currentClusters
                              .map((marker) => marker.toMarker())
                              .toSet(),
                        );
                      })
                    : Image.asset(
                        Constants.assetRoutesMap[AssetImages.appleMap]!,
                        fit: BoxFit.cover,
                      ),
                SafeArea(
                  child: Column(
                    children: [
                      Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                PressableIcon(
                                  child: const Icon(
                                      CupertinoIcons.line_horizontal_3),
                                  onPressed: () {
                                    handleOpenDrawer(context, scaffoldKey);
                                  },
                                )
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
            DraggableScrollableSheet(
              snap: true,
              expand: false,
              snapAnimationDuration: animationDuration,
              controller: draggableScrollController,
              snapSizes: snapSizes,
              initialChildSize: initialChildSize,
              minChildSize: minChildSize,
              maxChildSize: maxChildSize,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset:
                            const Offset(0, 5), // changes position of shadow
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const ClampingScrollPhysics(),
                      child: Container(
                        color: Theme.of(context).colorScheme.background,
                        child: MainModalSheet(
                          searchTapped: () {
                            if (draggableScrollController.size <
                                modalSearchHeight) {
                              showFullModal();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            //banner ad
            // Container(
            //   height: 50,
            //   decoration: BoxDecoration(
            //     gradient: const LinearGradient(
            //       colors: [
            //         Colors.red,
            //         Colors.purple,
            //       ],
            //       begin: Alignment.topLeft,
            //       end: Alignment.bottomRight,
            //     ),
            //     border: Border.all(
            //       color: Colors.white,
            //       strokeAlign: BorderSide.strokeAlignInside,
            //       width: 2,
            //     ),
            //   ),
            //   child: const Center(
            //     child: Text(
            //       'Banner Ad would go here',
            //       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            //     ),
            //   )
            //       .animate(
            //         onPlay: (controller) => controller.repeat(reverse: true),
            //       )
            //       .slideX(
            //         begin: -.2,
            //         end: .2,
            //         duration: const Duration(seconds: 10),
            //       ),
            // )
          ],
        ),
      ),
    );
  }

  void showFullModal({double? height, Duration? duration, Curve? curve}) {
    draggableScrollController.animateTo(
      height ?? modalSearchHeight,
      duration: duration ?? animationDuration,
      curve: curve ?? animationCurve,
    );
  }

  void handleOpenDrawer(
      BuildContext context, GlobalKey<ScaffoldState> scaffoldKey) {
    //unfocus
    scaffoldKey.currentState!.openDrawer();
    FocusScope.of(context).unfocus();
  }

  genericDebugErrorHandler(String e) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
  }
}

class MainModalSheet extends StatefulWidget {
  const MainModalSheet({
    super.key,
    required this.searchTapped,
  });

  final VoidCallback searchTapped;

  @override
  State<MainModalSheet> createState() => _MainModalSheetState();
}

class _MainModalSheetState extends State<MainModalSheet> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  int selectedSearchIndex = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    searchController.addListener(() {
      if (searchController.text.isNotEmpty) {
        widget.searchTapped();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: double.infinity,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DraggableIndicatorBar(),
              const SizedBox(
                height: 20,
              ),
              const BoldTileText(
                'Search',
              ),
              const SizedBox(
                height: 10,
              ),
              //Stop or Route selection
              Consumer<SearchProvider>(
                builder: (context, searchProvider, child) => Column(
                  children: [
                    Container(
                      height: 50,
                      margin: const EdgeInsets.only(
                        bottom: 10,
                        top: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              AnimatedAlign(
                                duration: const Duration(milliseconds: 120),
                                alignment: selectedSearchIndex == 0
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                curve: Curves.easeIn,
                                child: FractionallySizedBox(
                                  widthFactor: .5,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    height: 50,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SearchToggleSwitch(
                                    isSelected: selectedSearchIndex == 0,
                                    onTapped: () => setState(() {
                                      widget.searchTapped();
                                      selectedSearchIndex = 0;
                                      searchBusStopsByStopNumber(
                                          searchController.text.trim());
                                      refocusTextField(focusNode);
                                    }),
                                    text: 'By Stop Number',
                                  ),
                                  const SizedBox(
                                    width: 4,
                                  ),
                                  SearchToggleSwitch(
                                    isSelected: selectedSearchIndex == 1,
                                    onTapped: () => setState(() {
                                      widget.searchTapped();
                                      selectedSearchIndex = 1;
                                      searchBusStopsByRoute(
                                          searchController.text.trim());
                                      refocusTextField(focusNode);
                                    }),
                                    text: 'By Route',
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ModalSearchBar(
                      isRouteSearch: selectedSearchIndex == 1,
                      onSearchTap: widget.searchTapped,
                      controller: searchController,
                      searchResults: searchProvider.searchResults,
                      isSearchLoading: searchProvider.isSearching,
                      isLoadingRoute: searchProvider.isLoadingRoute,
                      onSearchChanged: (String value) async {
                        if (selectedSearchIndex == 0) {
                          searchBusStopsByStopNumber(value.trim());
                        } else {
                          searchBusStopsByRoute(value.trim());
                        }
                      },
                      focusNode: focusNode,
                      onTileTap: (tile, index) async {
                        if (selectedSearchIndex == 0) {
                          handleStopTileTap(tile);
                        } else {
                          searchProvider.isLoadingRoute = index;
                          final (busRoute1, busRoute2) =
                              await handleRouteTileTap(
                                  tile, (e) => handleErrorOnTap(e));
                          searchProvider.isLoadingRoute = -1;
                          pushRoutePage(busRoute1, busRoute2);
                        }
                      },
                    ),
                  ],
                ),
              ),
              //Saved Stops Text and Button Row
            ],
          ),
        ),
        const SizedBox(
          height: 30,
        ),
        ValueListenableBuilder(
          valueListenable: Hive.box<Stop>('savedStops').listenable(),
          builder: (context, box, child) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const BoldTileText(
                      'Saved Stops',
                    ),
                    box.isEmpty
                        ? const SizedBox()
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 7,
                                  offset: const Offset(
                                      0, 2), // changes position of shadow
                                ),
                              ],
                            ),
                            child: Material(
                              borderRadius: BorderRadius.circular(6),
                              color: Theme.of(context).colorScheme.secondary,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () {
                                  handleShowListTap(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 3),
                                  child: Row(
                                    children: [
                                      Text('Show List',
                                          style: GoogleFonts.inter(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .tertiary,
                                            fontSize: Constants.bodyFontSize,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      Icon(
                                        CupertinoIcons.chevron_right,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                        size: 20,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                  ],
                ),
              ),
              //Saved Stops
              box.isEmpty
                  ? Container(
                      alignment: Alignment.center,
                      height: 200,
                      width: double.infinity,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'No Saved Stops Yet',
                              style: GoogleFonts.inter(
                                color:
                                    Theme.of(context).colorScheme.onSecondary,
                                fontSize: Constants.bodyFontSize,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Icon(
                              Icons.heart_broken_rounded,
                              color: Theme.of(context).colorScheme.onSecondary,
                              size: 30,
                            )
                          ],
                        ),
                      ),
                    )
                  //Saved Stops List (Horizontal)
                  : Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: HorizPaddingConstant(
                        child: SizedBox(
                          width: double.infinity,
                          child: GridView(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.6,
                            ),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              for (int index = 0; index < box.length; index++)
                                SavedStopTile(
                                  stopNumber: box.getAt(index)!.stopCode,
                                  busCompany: BusCompany.dublinBus,
                                  busStopNickname: box.getAt(index)!.stopName,
                                  onTapped: () {
                                    handleStopTileTap(box.getAt(index)!);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
              const SizedBox(
                height: 50,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void searchBusStopsByStopNumber(String trim) async {
    Provider.of<SearchProvider>(context, listen: false).searchResults =
        await Provider.of<ApiInterface>(context, listen: false)
            .searchByStopCode(trim, (errorString) {
      if (errorString.isNotEmpty) {
        //cancel all snackbars
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorString)));
      }
    });
  }

  void handleShowListTap(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => SavedStopsPage(),
      ),
    );
  }

  void handleStopTileTap(Stop stop, {Function(String e)? errorCallback}) {
    Navigator.push(context,
        CupertinoPageRoute(builder: (context) => StopDetailsPage(stop: stop)));
  }

  Future<(BusRoute, BusRoute)> handleRouteTileTap(
      BusRoute route, Function(String e) errorCallback) async {
    var res = await Provider.of<ApiInterface>(context, listen: false)
        .getRouteDetail(route, errorCallback);
    BusRoute returnedRoute1 = res.$1;
    log('returned route 1 stops length: ${returnedRoute1.routeStops.length}',
        name: 'route_tile_tap');
    BusRoute returnedRoute2 = res.$2;
    log('returned route 2 stops length: ${returnedRoute2.routeStops.length}',
        name: 'route_tile_tap');
    return (returnedRoute1, returnedRoute2);
  }

  void pushRoutePage(BusRoute route1, BusRoute route2) {
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => RouteDetail(
                  route1: route1,
                  route2: route2,
                )));
  }

  void searchBusStopsByRoute(String trim) {
    Provider.of<SearchProvider>(context, listen: false).searchResults =
        Provider.of<ApiInterface>(context, listen: false)
            .searchByRouteName(trim, (errorString) {
      if (errorString.isNotEmpty) {
        //cancel all snackbars
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorString)));
      }
    });
  }

  handleErrorOnTap(String error) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  void refocusTextField(FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }
}

class SearchToggleSwitch extends StatelessWidget {
  const SearchToggleSwitch({
    super.key,
    required this.isSelected,
    required this.onTapped,
    required this.text,
  });

  final bool isSelected;
  final Function() onTapped;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            onTapped();
          },
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePageDrawer extends StatefulWidget {
  const HomePageDrawer(
      {super.key,
      this.continousUpdate = false,
      required this.continousUpdateChanged});

  final bool continousUpdate;
  final Function(bool) continousUpdateChanged;

  @override
  State<HomePageDrawer> createState() => _HomePageDrawerState();
}

class _HomePageDrawerState extends State<HomePageDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 30,
                    width: double.infinity,
                  ),
                  const BoldTileText(
                    'Better Bus Dublin',
                  ),
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  SwitchListTile(
                    value: widget.continousUpdate,
                    onChanged: (value) => widget.continousUpdateChanged(value),
                    title: const Text('Update Map continously on move (debug)'),
                    contentPadding: const EdgeInsets.all(0),
                  ),
                  ElevatedButton(
                      onPressed: () {
                        ApiInterface().getMinutesSinceDayStart(DateTime.now());
                      },
                      child: const Text('test'))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
