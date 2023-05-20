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
                                title: BoldTileText(stop.stopCode),
                                subtitle: Text(
                                  stop.stopName,
                                  style: GoogleFonts.inter(),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    Hive.box<Stop>('savedStops')
                                        .deleteAt(index);
                                  },
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
          ],
        ),
      ),
    );
  }
}
