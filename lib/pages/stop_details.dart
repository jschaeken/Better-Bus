import 'dart:developer';
import 'package:better_bus_dublin/pages/full_map_view.dart';
import 'package:better_bus_dublin/utils/api_interface.dart';
import 'package:better_bus_dublin/utils/components.dart';
import 'package:better_bus_dublin/utils/constants.dart';
import 'package:better_bus_dublin/utils/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

class StopDetailsPage extends StatefulWidget {
  const StopDetailsPage({Key? key, required this.stop}) : super(key: key);

  final Stop stop;

  @override
  _StopDetailsPageState createState() => _StopDetailsPageState();
}

class _StopDetailsPageState extends State<StopDetailsPage>
    with SingleTickerProviderStateMixin {
  bool isInitialLoad = true;
  Widget noticeWidget = const SizedBox();

  //Refresh animation controller
  late AnimationController animController;

  int hoursToShow = 1;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadBusTimes();
    log(widget.stop.stopId.toString());
    animController = AnimationController(
      vsync: this,
      duration: 300.ms,
    );
    if (widget.stop.notice != null) {
      noticeWidget = NoticeBox(
        widget.stop.notice!,
        () {
          setState(() {
            noticeWidget = const SizedBox();
          });
        },
      );
    } else {
      noticeWidget = const SizedBox();
    }
  }

  Future<void> loadBusTimes(
      {bool isRefresh = false, int? minutesIntoFuture}) async {
    Provider.of<ApiInterface>(context, listen: false).getStopTimesByStopId(
      widget.stop.stopId,
      (e) {
        handleGetTripUpdateErrorCallback(e);
      },
      isRefesh: isRefresh,
      minsIntoFuture: minutesIntoFuture,
    );
    lightTouchImpact();
  }

  Future<void> loadVehicleLocation(BusRtpi busRtpi) async {
    log('loading vehicle location for trip id: ${busRtpi.tripInfo?.tripId}');
    var busLoc = await Provider.of<ApiInterface>(context, listen: false)
        .getVehicleLocation(busRtpi);
    lightTouchImpact();
  }

  @override
  Widget build(BuildContext context) {
    Animate.restartOnHotReload = true;
    DateTime updateTime = DateTime.now();
    return Scaffold(
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
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: BoldTileText('Stop ${widget.stop.stopCode}'),
        elevation: 6,
        actions: [
          //bookmark
          ValueListenableBuilder(
            valueListenable: Hive.box<Stop>('savedStops').listenable(),
            builder: (context, value, child) {
              return IconButton(
                onPressed: () {
                  isInitialLoad = false;
                  lightTouchImpact();
                  if (value.containsKey(widget.stop.stopCode)) {
                    log('removing stop ${widget.stop.stopCode} from savedStops');
                    value.delete(widget.stop.stopCode);
                  } else {
                    log('adding stop ${widget.stop.stopCode} to savedStops');
                    value.put(widget.stop.stopCode, widget.stop);
                  }
                },
                icon: SizedBox(
                  child: value.containsKey(widget.stop.stopCode)
                      ? Icon(
                          Icons.bookmark,
                          color: Theme.of(context).colorScheme.tertiary,
                          size: 28,
                        )
                      : Icon(
                          Icons.bookmark_outline,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 28,
                        ),
                )
                    .animate(
                      target: value.containsKey(widget.stop.stopCode) &&
                              !isInitialLoad
                          ? 1
                          : 0,
                    )
                    .shimmer(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        left: false,
        right: false,
        child: Padding(
          // padding: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 10,
              ),
              Constants.horizPadding(
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BoldTileText(widget.stop.stopName),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        lightTouchImpact();
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) =>
                                FullMapView(stop: widget.stop),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.tertiary,
                      ),
                      child: Row(children: [
                        Text(
                          'Show on map',
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Icon(
                          CupertinoIcons.map_pin_ellipse,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
              Constants.horizPadding(
                const SizedBox(
                  height: 20,
                ),
              ),
              Constants.horizPadding(
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: noticeWidget,
                  transitionBuilder: (child, animation) {
                    return SizeTransition(
                      sizeFactor: animation,
                      child: child,
                    );
                  },
                ),
              ),
              //Times
              Flexible(
                flex: 7,
                child: Constants.horizPadding(
                  Consumer<ApiInterface>(builder: (context, value, child) {
                    if (!value.isLoadingInfo) {
                      updateTime = DateTime.now();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const BoldTileText('Times'),
                                  StatefulBuilder(builder: (context, fresh) {
                                    //refresh every second
                                    Future.delayed(const Duration(seconds: 5),
                                        () {
                                      if (context.mounted) {
                                        fresh(() {});
                                      }
                                    });
                                    return Text(
                                        value.isLoadingInfo
                                            ? ''
                                            : 'Real Time Data Updated: ${DateTime.now().difference(updateTime).inMinutes < 1 ? 'Just now' : '${DateTime.now().difference(updateTime).inMinutes} minute${DateTime.now().difference(updateTime).inMinutes == 1 ? '' : 's'} ago'}',
                                        style: GoogleFonts.inter(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondary,
                                          fontSize: Constants.bodyFontSize,
                                        ));
                                  })
                                ],
                              ),
                            ),
                            Animate(
                              controller: animController,
                              effects: const [RotateEffect()],
                              child: IconButton(
                                onPressed: () async {
                                  loadBusTimes(
                                      isRefresh: true,
                                      minutesIntoFuture: hoursToShow * 60);
                                  value.isLoadingInfo = true;
                                  await animController.animateTo(1);
                                  animController.value = 0;
                                },
                                icon: const Icon(
                                  CupertinoIcons.refresh_circled,
                                ),
                                iconSize: 35,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            )
                          ],
                        ),
                        ValueListenableBuilder(
                            valueListenable:
                                Hive.box<bool>('settings').listenable(),
                            builder: (context, Box<bool> box, child) {
                              return box.get('showHoursSlider') ?? false
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'For debugging purposes only',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: DevSlider(
                                                    min: 1,
                                                    max: 8,
                                                    divisions: 7,
                                                    label: 'Hours to show',
                                                    onChanged: (val) {
                                                      setState(() {
                                                        hoursToShow =
                                                            val.toInt();
                                                      });
                                                    },
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 10),
                                                  child: Text(
                                                    'Showing ${hoursToShow == 1 ? '1 hour' : '$hoursToShow hours'}',
                                                    style: GoogleFonts.inter(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSecondary,
                                                      fontSize: Constants
                                                          .bodyFontSize,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Container();
                            }),
                        Flexible(
                          flex: 5,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(
                                  width: 1,
                                  color:
                                      Theme.of(context).colorScheme.secondary),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: value.isLoadingInfo
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    )
                                  : Flex(
                                      direction: Axis.vertical,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Expanded(
                                          child: RefreshIndicator(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .tertiary,
                                            onRefresh: () => loadBusTimes(
                                                isRefresh: true,
                                                minutesIntoFuture:
                                                    hoursToShow * 60),
                                            child: value.busRtpiList.isEmpty
                                                ? Flex(
                                                    direction: Axis.vertical,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceAround,
                                                    children: [
                                                      Flexible(
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            const SizedBox(
                                                              width: double
                                                                  .infinity,
                                                            ),
                                                            Text(
                                                              'No buses found',
                                                              style: GoogleFonts
                                                                  .inter(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .onPrimary,
                                                                fontSize: Constants
                                                                    .bodyFontSize,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 5,
                                                            ),
                                                            //cloud
                                                            Icon(
                                                              CupertinoIcons
                                                                  .cloud,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onPrimary,
                                                              size: 30,
                                                            )
                                                                .animate(
                                                                  onPlay: (controller) =>
                                                                      controller.repeat(
                                                                          reverse:
                                                                              true),
                                                                )
                                                                .slideX(
                                                                  begin: -1,
                                                                  end: 1,
                                                                  duration:
                                                                      5000.ms,
                                                                  curve: Curves
                                                                      .easeInOut,
                                                                ),
                                                          ],
                                                        ).animate().fadeIn(),
                                                      ),
                                                    ],
                                                  )
                                                : ListView.builder(
                                                    shrinkWrap: false,
                                                    itemCount: value
                                                        .busRtpiList.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      return BusRtpiTile(
                                                        servingAgencyLogoPath:
                                                            getLogoPathForAgency(
                                                                value
                                                                    .busRtpiList[
                                                                        index]
                                                                    .tripInfo
                                                                    ?.agency),
                                                        buttonText: value
                                                                .busRtpiList[
                                                                    index]
                                                                .tripInfo
                                                                ?.routeShortName ??
                                                            '',
                                                        titleText: value
                                                                .busRtpiList[
                                                                    index]
                                                                .tripInfo
                                                                ?.tripHeadsign ??
                                                            '',
                                                        trailingText: showTime(
                                                            value
                                                                .busRtpiList[
                                                                    index]
                                                                .arrivalTime),
                                                        accentButtonOnPressed:
                                                            () {},
                                                        tileOnPressed: () {
                                                          loadVehicleLocation(
                                                            value.busRtpiList[
                                                                index],
                                                          );
                                                        },
                                                      );
                                                    }),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void handleGetTripUpdateErrorCallback(String error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.inter()),
        ),
      );
    }
  }

  String? getLogoPathForAgency(Agency? servingAgenci) {
    switch (servingAgenci) {
      case Agency.dublinBus:
        return Constants.assetRoutesMap[AssetImages.dublinBusLogo]!;
      case Agency.goAhead:
        return Constants.assetRoutesMap[AssetImages.goAheadLogo]!;
      case Agency.busEireann:
        return Constants.assetRoutesMap[AssetImages.busEireannLogo]!;
      default:
        return null;
    }
  }

  String showTime(DateTime arrivalTime) {
    //if time is less than 60 minutes away, show relative time
    int relativeTime = arrivalTime.difference(DateTime.now()).inMinutes;

    if (relativeTime < 60) {
      return relativeTime == 0
          ? 'Due'
          : '${arrivalTime.difference(DateTime.now()).inMinutes} mins';
    } else {
      String hour = arrivalTime.hour < 10
          ? '0${arrivalTime.hour}'
          : arrivalTime.hour.toString();
      String minute = arrivalTime.minute < 10
          ? '0${arrivalTime.minute}'
          : arrivalTime.minute.toString();
      return '$hour:$minute';
    }
  }

  void lightTouchImpact() {
    HapticFeedback.lightImpact();
  }

  void mediumTouchImpact() {
    HapticFeedback.mediumImpact();
  }

  void heavyTouchImpact() {
    HapticFeedback.heavyImpact();
  }
}

class DevSlider extends StatefulWidget {
  const DevSlider({
    super.key,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
  });

  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  State<DevSlider> createState() => _DevSliderState();
}

class _DevSliderState extends State<DevSlider> {
  var currentVal = 1;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: currentVal.toDouble(),
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      label: widget.label,
      activeColor: Theme.of(context).colorScheme.secondary,
      thumbColor: Theme.of(context).colorScheme.secondary,
      onChanged: (value) {
        setState(() {
          currentVal = value.toInt();
        });
      },
      onChangeEnd: (value) => widget.onChanged(value),
    );
  }
}

class BusRtpiTile extends StatefulWidget {
  const BusRtpiTile({
    super.key,
    required this.buttonText,
    this.accentButtonOnPressed,
    required this.tileOnPressed,
    required this.titleText,
    this.subtitleText,
    this.trailingText,
    this.servingAgencyLogoPath,
  });

  final String buttonText;
  final VoidCallback? accentButtonOnPressed;
  final VoidCallback tileOnPressed;
  final String titleText;
  final String? subtitleText;
  final String? trailingText;
  final String? servingAgencyLogoPath;

  @override
  State<BusRtpiTile> createState() => _BusRtpiTileState();
}

class _BusRtpiTileState extends State<BusRtpiTile> {
  final ExpansionTileController controller = ExpansionTileController();

  @override
  Widget build(BuildContext context) {
    return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 0,
            ),
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              color: Theme.of(context).colorScheme.secondary,
              elevation: 0,
              child: ExpansionTile(
                onExpansionChanged: (value) {
                  if (value) {
                    widget.tileOnPressed();
                  } else {}
                },
                controller: controller,
                title: Row(
                  children: [
                    widget.buttonText.isEmpty
                        ? const SizedBox()
                        : ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.tertiary,
                            ),
                            child: Text(
                              widget.buttonText,
                              style: GoogleFonts.inter(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: Constants.bodyFontSize),
                            ),
                          ),
                    const SizedBox(
                      width: 10,
                    ),
                    Flexible(
                      child: Text(
                        widget.titleText,
                        style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: Constants.bodyFontSize),
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.trailingText == null
                        ? const SizedBox()
                        : Text(
                            widget.trailingText!,
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: Constants.bodyFontSize,
                            ),
                          ),
                  ],
                ),
              ),
            )).animate().fadeIn(
          duration: const Duration(milliseconds: 100),
        );
  }
}

class NoticeBox extends StatelessWidget {
  const NoticeBox(this.notice, this.closeCallback, {super.key});

  final String notice;
  final Function closeCallback;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.error.withOpacity(.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              //iocn
              Icon(
                Icons.warning_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 30,
              ),
              const SizedBox(
                width: 5,
              ),
              BoldTileText(
                'Notice',
                color: Theme.of(context).colorScheme.error,
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  closeCallback();
                },
                icon: Icon(
                  CupertinoIcons.xmark,
                  color: Theme.of(context).colorScheme.onError.withOpacity(.5),
                ),
              )
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            notice,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onError,
              fontSize: Constants.bodyFontSize,
            ),
          )
        ],
      ),
    );
  }
}
