import 'package:better_bus_dublin/components/map_view.dart';
import 'package:better_bus_dublin/pages/saved_page.dart';
import 'package:better_bus_dublin/pages/stop_details.dart';
import 'package:better_bus_dublin/utils/api_interface.dart';
import 'package:better_bus_dublin/utils/components.dart';
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

  final Duration animationDuration = const Duration(milliseconds: 150);
  final double modalSearchHeight = .8;
  final Curve animationCurve = Curves.fastOutSlowIn;
  final List<double> snapSizes = [.20, .7];
  final double initialChildSize = 0.20;
  final double minChildSize = 0.20;
  final double maxChildSize = .90;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Provider.of<ApiInterface>(context, listen: false).loadStops();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Stack(
            children: [
              const MapView(),
              SafeArea(
                child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          PressableIcon(
                            icon: CupertinoIcons.location_fill,
                            onPressed: () {},
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          PressableIcon(
                            icon: CupertinoIcons.settings,
                            onPressed: () {},
                          )
                        ],
                      ),
                    )),
              ),
              Center(
                  child: Container(
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 7,
                    offset: const Offset(0, 4), // changes position of shadow
                  ),
                ]),
                child: GestureDetector(
                  onTap: () {
                    showFullModal();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Show Modal',
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  ),
                ),
              )),
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
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 5), // changes position of shadow
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
                    child: Container(
                      color: Theme.of(context).colorScheme.background,
                      child: MainModalSheet(
                        searchTapped: () => showFullModal(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                                            fontSize: 17,
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
                              color: Theme.of(context).colorScheme.onSecondary,
                              fontSize: 17,
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
                      )))
                  : SizedBox(
                      height: 250,
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
                                        right: index == box.length ? 16 : 0,
                                        top: 15,
                                        bottom: 15),
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
            ],
          ),
        ),
        const SizedBox(
          height: 800,
        )
      ],
    );
  }

  void searchBusStopsByStopNumber(String trim) async {
    Provider.of<SearchProvider>(context, listen: false).searchResults =
        await Provider.of<ApiInterface>(context, listen: false)
            .searchByStopCode(trim);
  }

  void handleShowListTap(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => SavedStopsPage(),
      ),
    );
  }

  void handleStopTileTap(Stop stop) {
    busStopSearchController.text = stop.stopCode;
    Navigator.push(context,
        CupertinoPageRoute(builder: (context) => StopDetailsPage(stop: stop)));
  }
}
