import 'dart:io';

import 'package:better_bus_dublin/components/map_view.dart';
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
  final List<double> snapSizes = [.20, .82];
  final double initialChildSize = 0.20;
  final double minChildSize = 0.20;
  final double maxChildSize = .82;
  late final GlobalKey<ScaffoldState> scaffoldKey;
  final isMobile = Platform.isIOS || Platform.isAndroid;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    scaffoldKey = GlobalKey();
    initialStopsLoad();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      drawer: const HomePageDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Stack(
              children: [
                isMobile
                    ? const MapView()
                    : Image.asset(
                        'assets/images/appleMap.jpg',
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
                                  icon: CupertinoIcons.line_horizontal_3,
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
                      physics: const NeverScrollableScrollPhysics(),
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
  final TextEditingController busStopSearchController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    busStopSearchController.addListener(() {
      if (busStopSearchController.text.isNotEmpty) {
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
                'Search Stop Number',
              ),
              const SizedBox(
                height: 10,
              ),
              Consumer<SearchProvider>(
                builder: (context, searchProvider, child) => ModalSearchBar(
                  onSearchTap: widget.searchTapped,
                  controller: busStopSearchController,
                  searchResults: searchProvider.searchResults,
                  isSearchLoading: searchProvider.isSearching,
                  onSearchChanged: (String value) {
                    searchProvider.startSearchLoading();
                    searchBusStopsByStopNumber(value.trim());
                    searchProvider.stopSeatchLoading();
                  },
                  focusNode: focusNode,
                  onTileTap: (stop) {
                    handleStopTileTap(stop);
                  },
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
                  : SizedBox(
                      height: 130,
                      width: MediaQuery.of(context).size.width,
                      child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: box.length,
                          itemBuilder: (context, index) {
                            return box.getAt(index) == null
                                ? const SizedBox()
                                : Padding(
                                    padding: EdgeInsets.only(
                                      left: index == 0 ? 16 : 0,
                                      right: index == box.length - 1 ? 16 : 0,
                                      top: 15,
                                      bottom: 15,
                                    ),
                                    child: SavedStopTile(
                                      stopNumber: box.getAt(index)!.stopCode,
                                      busCompany: BusCompany.dublinBus,
                                      busStopNickname:
                                          box.getAt(index)!.stopName,
                                      onTapped: () {
                                        handleStopTileTap(box.getAt(index)!);
                                      },
                                    ),
                                  );
                          },
                          separatorBuilder: (context, index) => const SizedBox(
                                width: 15,
                              )),
                    ),
              const SizedBox(
                height: 400,
              )
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

  void handleStopTileTap(Stop stop) {
    Navigator.push(context,
        CupertinoPageRoute(builder: (context) => StopDetailsPage(stop: stop)));
  }
}

class HomePageDrawer extends StatefulWidget {
  const HomePageDrawer({super.key});

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
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const BoldTileText(
                        'Dark Mode',
                      ),
                      Consumer<GlobalState>(
                        builder: (context, value, child) => Switch(
                          activeTrackColor:
                              Theme.of(context).colorScheme.tertiary,
                          value: value.isDarkMode,
                          onChanged: (_) {
                            value.toggleDarkMode();
                          },
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlobalState extends ChangeNotifier {
  bool isDarkMode = ThemeMode.system == ThemeMode.dark;

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}
