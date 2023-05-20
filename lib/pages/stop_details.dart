import 'dart:developer';
import 'package:better_bus_dublin/utils/api_interface.dart';
import 'package:better_bus_dublin/utils/components.dart';
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
  @override
  Widget build(BuildContext context) {
    log('stop details page - stopId: ${widget.stop.stopId}');
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
                icon: Icon(
                  value.containsKey(widget.stop.stopCode)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: Theme.of(context).colorScheme.onSecondary,
                  size: 28,
                )
                    .animate(
                      target: value.containsKey(widget.stop.stopCode) &&
                              !isInitialLoad
                          ? 1
                          : 0,
                    )
                    .scaleXY(end: 1.5)
                    .shimmer()
                    .then()
                    .scaleXY(end: 1 / 1.5),
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
                        BoldTileText(
                          'Stop Id: ${widget.stop.stopId}',
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 15,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    style: ButtonStyle(
                      shadowColor: MaterialStateProperty.all<Color>(
                          Theme.of(context).colorScheme.onPrimary),
                      foregroundColor: MaterialStateProperty.all<Color>(
                          Theme.of(context).colorScheme.tertiary),
                      backgroundColor: MaterialStateProperty.all<Color>(
                          Theme.of(context).colorScheme.secondary),
                      elevation: MaterialStateProperty.all<double>(6),
                      surfaceTintColor: MaterialStateProperty.all<Color>(
                          Theme.of(context).colorScheme.secondary),
                    ),
                    onPressed: () {},
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
                      const Icon(CupertinoIcons.map_pin_ellipse),
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
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              const NoticeBox(
                'Due to roadworks, stop 1234 will be closed from 12:00 to 14:00 on 12/12/2021',
              ),
              const SizedBox(
                height: 20,
              ),
              //Times
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BoldTileText('Times'),
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
                                      title: BoldTileText(
                                        '${listBuses.data![index].vehicleInfo.routeShortName} to ${listBuses.data![index].vehicleInfo.tripHeadsign}',
                                        fontSize: 16,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          BoldTileText(
                                            '$time ${time == 1 ? 'min' : 'mins'}',
                                            fontSize: 18,
                                          ),
                                          listBuses.data![index].scheduleType !=
                                                  ScheduleType.live
                                              ? Container()
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const SizedBox(
                                                      width: 10,
                                                    ),
                                                    Container(
                                                      width: 10,
                                                      height: 10,
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .tertiary,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          100,
                                                        ),
                                                      ),
                                                    )
                                                        .animate(
                                                            onPlay: (controller) =>
                                                                controller.repeat(
                                                                    reverse:
                                                                        true))
                                                        .fade(
                                                            duration: 1000.ms),
                                                    const SizedBox(
                                                      width: 5,
                                                    ),
                                                    Text(
                                                      'LIVE',
                                                      style: GoogleFonts.inter(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .tertiary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    )
                                                  ],
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
  const NoticeBox(this.notice, {super.key});

  final String notice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.error.withOpacity(.2),
      ),
      child: Text(
        notice,
        style: GoogleFonts.inter(
          color: Theme.of(context).colorScheme.onError,
          fontSize: 15,
        ),
      ),
    );
  }
}

class BusTimeTile extends StatelessWidget {
  const BusTimeTile({
    super.key,
    required this.index,
  });

  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: Theme.of(context).colorScheme.secondary,
      child: ListTile(
        title: BoldTileText(
          'Bus ${index + 1}',
          fontSize: 18,
        ),
        subtitle: Text(
          'Towards: [HeadSign]',
          style: GoogleFonts.inter(),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const BoldTileText(
              '5 mins',
              fontSize: 18,
            ),
            index % 2 == 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LIVE',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Icon(
                        Icons.circle,
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 12,
                      )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .fade()
                          .then(delay: 1000.ms)
                    ],
                  )
                : Text('SCHEDULED', style: GoogleFonts.inter()),
          ],
        ),
      ),
    );
  }
}
