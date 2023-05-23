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

class StopDetailsPage extends StatefulWidget {
  const StopDetailsPage({Key? key, required this.stop}) : super(key: key);

  final Stop stop;

  @override
  _StopDetailsPageState createState() => _StopDetailsPageState();
}

class _StopDetailsPageState extends State<StopDetailsPage> {
  bool isInitialLoad = true;
  Widget noticeWidget = const SizedBox();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
        backgroundColor:
            Theme.of(context).colorScheme.onSecondary.withOpacity(.3),
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
                  setState(() {});
                  HapticFeedback.lightImpact();
                  if (value.containsKey(widget.stop.stopCode)) {
                    log('removing stop ${widget.stop.stopCode} from savedStops');
                    Hive.box<Stop>('savedStops').delete(widget.stop.stopCode);
                  } else {
                    log('adding stop ${widget.stop.stopCode} to savedStops');
                    Hive.box<Stop>('savedStops')
                        .put(widget.stop.stopCode, widget.stop);
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
                          color: Theme.of(context).colorScheme.onSecondary,
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 10,
              ),
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
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (context) =>
                                  FullMapView(stop: widget.stop)));
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
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.asset(
                      'assets/images/dublinBusLogoSmall.png',
                      filterQuality: FilterQuality.none,
                      height: 50,
                      width: 50,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              //notice
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
              const SizedBox(
                height: 20,
              ),
              //Times
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BoldTileText('Times'),
                  Text('Real Time Data Updated: X mins ago',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontSize: Constants.bodyFontSize,
                      ))
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              FutureBuilder(
                  future:
                      ApiInterface().getTripUpdateByStopId(widget.stop.stopId),
                  builder: (context, listBuses) {
                    return !listBuses.hasData
                        ? const CircularProgressIndicator()
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: listBuses.data!.length,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              int time = dateTimeToRelative(
                                  listBuses.data![index].arrivalTime);

                              return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 0),
                                  child: Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    elevation: 0,
                                    child: ListTile(
                                      title: Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {},
                                            child: Text(
                                              listBuses.data![index].vehicleInfo
                                                  .routeShortName,
                                              style: GoogleFonts.inter(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize:
                                                      Constants.bodyFontSize),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Flexible(
                                            child: Text(
                                              listBuses.data![index].vehicleInfo
                                                  .tripHeadsign,
                                              style: GoogleFonts.inter(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize:
                                                      Constants.bodyFontSize),
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$time ${time == 1 ? 'min' : 'mins'}',
                                            style: GoogleFonts.inter(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: Constants.bodyFontSize,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ));
                            });
                  }),
            ],
          ),
        ),
      ),
    );
  }

  void handleGetTripUpdateErrorCallback(String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error, style: GoogleFonts.inter()),
    ));
  }

  int dateTimeToRelative(DateTime arrivalTime) {
    return (arrivalTime.difference(DateTime.now())).inMinutes;
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
