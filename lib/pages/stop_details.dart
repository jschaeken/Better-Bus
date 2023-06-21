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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    refreshBusTimes();
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

  Future<void> refreshBusTimes({bool isRefresh = false}) async {
    Provider.of<ApiInterface>(context, listen: false).getStopTimesByStopId(
      widget.stop.stopId,
      (e) {
        handleGetTripUpdateErrorCallback(e);
      },
      isRefesh: isRefresh,
    );
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
                  HapticFeedback.lightImpact();
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
              HorizPaddingConstant(
                child: Row(
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
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) =>
                                FullMapView(stop: widget.stop),
                          ),
                        );
                      },
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
              const HorizPaddingConstant(
                child: SizedBox(
                  height: 20,
                ),
              ),
              HorizPaddingConstant(
                child: AnimatedSwitcher(
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
                child: HorizPaddingConstant(
                  child:
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            Animate(
                              controller: animController,
                              effects: const [RotateEffect()],
                              child: IconButton(
                                onPressed: () async {
                                  refreshBusTimes(isRefresh: true);
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
                                            onRefresh: () => refreshBusTimes(
                                                isRefresh: true),
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
                                                      bool showRelativeTime =
                                                          false;
                                                      if ((value
                                                                      .busRtpiList[
                                                                          index]
                                                                      .departureMins ??
                                                                  0) >
                                                              60 ||
                                                          value
                                                                  .busRtpiList[
                                                                      index]
                                                                  .departureMins ==
                                                              null) {
                                                        showRelativeTime =
                                                            false;
                                                      } else {
                                                        showRelativeTime = true;
                                                      }
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
                                                        trailingText: showRelativeTime
                                                            ? '${value.busRtpiList[index].departureMins} ${value.busRtpiList[index].departureMins == 1 ? 'min' : 'mins'}'
                                                            : '${value.busRtpiList[index].arrivalTime.hour}:${value.busRtpiList[index].arrivalTime.minute}',
                                                        accentButtonOnPressed:
                                                            () {},
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

  int dateTimeToRelative(DateTime arrivalTime) {
    log('arrival time: $arrivalTime');
    return (arrivalTime.difference(DateTime.now())).inMinutes;
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
}

class BusRtpiTile extends StatefulWidget {
  const BusRtpiTile({
    super.key,
    required this.buttonText,
    this.accentButtonOnPressed,
    required this.titleText,
    this.subtitleText,
    this.trailingText,
    this.servingAgencyLogoPath,
  });

  final String buttonText;
  final VoidCallback? accentButtonOnPressed;
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
            controller: controller,
            leading: widget.servingAgencyLogoPath == null
                ? null
                : ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.asset(widget.servingAgencyLogoPath!,
                        width: 37, height: 37)),
            title: Row(
              children: [
                widget.buttonText.isEmpty
                    ? const SizedBox()
                    : ElevatedButton(
                        onPressed: () {},
                        child: Text(
                          widget.buttonText,
                          style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onPrimary,
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
        )).animate().fadeIn();
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

class HorizPaddingConstant extends StatelessWidget {
  const HorizPaddingConstant({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
      child: child,
    );
  }
}
