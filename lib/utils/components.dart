import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models.dart';

enum BusCompany {
  dublinBus,
  goAhead,
  busEireann,
  airCoach,
  cityLink,
}

class SavedStopTile extends StatelessWidget {
  const SavedStopTile({
    super.key,
    required this.stopNumber,
    required this.busCompany,
    required this.busStopNickname,
    required this.onTapped,
  });

  final String stopNumber;
  final BusCompany busCompany;
  final String busStopNickname;
  final VoidCallback onTapped;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.secondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 11,
            offset: const Offset(0, 4), // changes position of shadow
          ),
        ],
      ),
      width: 155,
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onTapped(),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LimitedBox(
                          maxHeight: 40,
                          maxWidth: 40,
                          child: Image.asset(
                            'assets/images/dublinBusLogoSmall.png',
                            filterQuality: FilterQuality.none,
                            isAntiAlias: true,
                          ),
                        ),
                      ),
                    ),
                    BoldTileText(stopNumber, fontSize: 25),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: BoldTileText(
                    busStopNickname,
                    textAlign: TextAlign.start,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
                const Spacer(),
                //Live Bus Times
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //Live icon
                    Icon(
                      CupertinoIcons.dot_radiowaves_left_right,
                      color: Theme.of(context).colorScheme.tertiary,
                      size: 25,
                    )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .fade()
                        .then(delay: 1000.ms),
                    BoldTileText(
                      'Live',
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BoldTileText(
                          '47',
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        BoldTileText(
                          '1 min',
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSecondary,
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BoldTileText(
                            '46a',
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                          BoldTileText(
                            '8 mins',
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSecondary,
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BoldTileText(
                          '118',
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        BoldTileText(
                          '10 mins',
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSecondary,
                          textAlign: TextAlign.end,
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BoldTileText extends StatelessWidget {
  const BoldTileText(
    this.text, {
    super.key,
    this.fontSize = 25,
    this.color = Colors.black,
    this.textAlign = TextAlign.start,
    this.height = 1.2,
    this.expand = false,
  });

  final String text;
  final double fontSize;
  final Color color;
  final TextAlign textAlign;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: GoogleFonts.inter(
        color: color,
        fontSize: expand ? null : fontSize,
        height: height,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class DraggableIndicatorBar extends StatelessWidget {
  const DraggableIndicatorBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 15),
        height: 5,
        width: 54,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSecondary.withOpacity(.5),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class ModalSearchBar extends StatelessWidget {
  const ModalSearchBar({
    super.key,
    required this.onSearchTap,
    required this.controller,
    required this.onSearchChanged,
    required this.onTileTap,
    this.isSearchLoading = false,
    this.searchResults = const [],
  });

  final VoidCallback onSearchTap;
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final List<Stop> searchResults;
  final ValueChanged<Stop> onTileTap;
  final bool isSearchLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          cursorColor: Theme.of(context).colorScheme.onPrimary,
          cursorOpacityAnimates: true,
          textAlignVertical: TextAlignVertical.center,
          onTap: () => onSearchTap(),
          onChanged: (s) => onSearchChanged(s),
          controller: controller,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onTapOutside: (event) => FocusScope.of(context).unfocus(),
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.onPrimary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor:
                Theme.of(context).colorScheme.onSecondary.withOpacity(.1),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      onSearchChanged('');
                    },
                  )
                : const SizedBox(),
            hintText: '7415',
            hintStyle: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(.5),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        //Search results
        searchResults.isEmpty
            ? controller.text.isNotEmpty
                ? SizedBox(
                    height: 90,
                    child: Center(
                      child: Text(
                        'No Stops Found',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 17,
                        ),
                      ).animate().shakeX(),
                    ),
                  )
                : isSearchLoading
                    ? const CircularProgressIndicator()
                    : Container()
            : SizedBox(
                height:
                    searchResults.length > 3 ? 260 : searchResults.length * 90,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                          child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              tileColor:
                                  Theme.of(context).colorScheme.secondary,
                              onTap: () {
                                onTileTap(searchResults[index]);
                              },
                              title: Text(
                                searchResults[index].stopCode,
                                style: GoogleFonts.inter(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                searchResults[index].stopName,
                                style: GoogleFonts.inter(
                                  color:
                                      Theme.of(context).colorScheme.onSecondary,
                                  fontSize: 15,
                                ),
                              ),
                              trailing: const CircleAvatar(
                                  foregroundImage: AssetImage(
                                'assets/images/dublinBusLogo.jpg',
                              ))),
                        ),
                      );
                    },
                  ),
                ),
              ),
      ],
    );
  }
}

class PressableIcon extends StatelessWidget {
  const PressableIcon({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () {
          onPressed();
        },
        child: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.transparent,
          child: Icon(
            icon,
            color: Colors.black,
            size: 25,
          ),
        ),
      ),
    );
  }
}
