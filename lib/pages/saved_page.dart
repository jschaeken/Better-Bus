import 'package:better_bus_dublin/pages/stop_details.dart';
import 'package:better_bus_dublin/utils/api_interface.dart';
import 'package:better_bus_dublin/utils/components.dart';
import 'package:better_bus_dublin/utils/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SavedStopsPage extends StatelessWidget {
  SavedStopsPage({super.key});

  final ApiInterface apiInterface = ApiInterface();

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
        title: const BoldTileText('Saved Stops'),
        elevation: 6,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            ValueListenableBuilder(
                valueListenable: Hive.box<Stop>('savedStops').listenable(),
                builder: (context, value, child) {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: Hive.box<Stop>('savedStops').length,
                    itemBuilder: (context, index) {
                      final Stop? stop = value.getAt(index);
                      return stop == null
                          ? const SizedBox()
                          : Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              elevation: 6,
                              color: Theme.of(context).colorScheme.secondary,
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                leading: Icon(
                                  CupertinoIcons.arrow_up_right_square,
                                  size: 35,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                                title: BoldTileText(stop.stopCode),
                                subtitle: Text(
                                  stop.stopName,
                                  style: GoogleFonts.inter(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondary,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon:
                                      const Icon(Icons.bookmark_remove_rounded),
                                  color: Theme.of(context).colorScheme.error,
                                  onPressed: () {
                                    Hive.box<Stop>('savedStops')
                                        .deleteAt(index);
                                  },
                                  iconSize: 30,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => StopDetailsPage(
                                        stop: stop,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                    },
                  );
                }),
            const SizedBox(
              height: 100,
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(width: 1),
              ),
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      // border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(200),
                    ),
                    height: 300,
                    width: 300,
                    child: SizedBox(
                      width: 90,
                      height: double.infinity,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned(
                            top: 32,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              height: 90,
                              width: 90,
                            ),
                          ),
                          Positioned(
                            top: 112,
                            child: Container(
                              height: 160,
                              width: 15,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
