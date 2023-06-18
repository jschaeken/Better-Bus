import 'package:better_bus_dublin/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

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
                            Constants
                                .assetRoutesMap[AssetImages.clusterMarkerIcon]!,
                            filterQuality: FilterQuality.high,
                            isAntiAlias: true,
                          ),
                        ),
                      ),
                    ),
                    BoldTileText(stopNumber),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    busStopNickname,
                    textAlign: TextAlign.start,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ),
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
    this.color,
    this.textAlign = TextAlign.start,
    this.height = 1.2,
  });

  final String text;
  // final double fontSize;
  final Color? color;
  final TextAlign textAlign;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: GoogleFonts.inter(
        color: color ?? Theme.of(context).colorScheme.onPrimary,
        fontSize: Constants.headerFontSize,
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
    required this.isRouteSearch,
    required this.onSearchTap,
    required this.controller,
    required this.onSearchChanged,
    required this.onTileTap,
    this.isSearchLoading = false,
    required this.focusNode,
    this.searchResults = const [],
    required this.isLoadingRoute,
  });

  final bool isRouteSearch;
  final VoidCallback onSearchTap;
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final List<dynamic> searchResults;
  final Function(dynamic, int) onTileTap;
  final bool isSearchLoading;
  final FocusNode focusNode;
  final int isLoadingRoute;

  @override
  Widget build(BuildContext context) {
    if (searchResults.isEmpty &&
        !isSearchLoading &&
        controller.text.isNotEmpty) {
      HapticFeedback.selectionClick();
    }
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
            if (isRouteSearch)
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            if (!isRouteSearch) FilteringTextInputFormatter.digitsOnly,
          ],
          onTapOutside: (event) {
            final FocusScopeNode currentScope = FocusScope.of(context);
            if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          focusNode: focusNode,
          keyboardType:
              isRouteSearch ? TextInputType.text : TextInputType.number,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: Constants.headerFontSize,
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
                    icon: const Icon(CupertinoIcons.clear),
                    onPressed: () {
                      controller.clear();
                      onSearchChanged('');
                      FocusScope.of(context).requestFocus(focusNode);
                    },
                  )
                : const SizedBox(),
            hintText: isRouteSearch ? 'Search Routes' : 'Search Stops',
            hintStyle: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(.5),
              fontSize: Constants.headerFontSize,
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
                        'No ${isRouteSearch ? 'routes' : 'stops'} found',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: Constants.bodyFontSize,
                        ),
                      ).animate().shakeX(),
                    ),
                  )
                : isSearchLoading
                    ? const CircularProgressIndicator()
                    : Container()
            : Container(
                alignment: Alignment.topCenter,
                height: 260,
                width: double.infinity,
                child: ListView.builder(
                  padding: const EdgeInsets.all(0),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    return InformationTile(
                      onTileTap: () => onTileTap(searchResults[index], index),
                      titleText: isRouteSearch
                          ? searchResults[index].routeShortName
                          : searchResults[index].stopCode,
                      subtitleText: isRouteSearch
                          ? '${searchResults[index].routeLongName}'
                          : searchResults[index].stopName,
                      isLoadingRoute: isLoadingRoute == index,
                      index: index,
                    );
                  },
                ),
              ),
      ],
    );
  }
}

class InformationTile extends StatelessWidget {
  const InformationTile({
    super.key,
    required this.onTileTap,
    required this.titleText,
    required this.subtitleText,
    required this.isLoadingRoute,
    required this.index,
  });

  final VoidCallback onTileTap;
  final String titleText;
  final String subtitleText;
  final bool isLoadingRoute;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: index == 0
          ? const EdgeInsets.only(top: 12, bottom: 3)
          : const EdgeInsets.symmetric(vertical: 3),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: Theme.of(context).colorScheme.secondary,
          onTap: () {
            onTileTap();
          },
          title: Text(
            titleText,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: Constants.headerFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            subtitleText,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSecondary,
              fontSize: Constants.bodyFontSize,
            ),
          ),
          trailing: PressableIcon(
            backgroundColor:
                Theme.of(context).colorScheme.tertiary.withOpacity(.4),
            isLoading: isLoadingRoute,
            onPressed: () {
              onTileTap();
            },
            child: const Icon(CupertinoIcons.chevron_right),
          ),
        ),
      ),
    );
  }
}

class PressableIcon extends StatelessWidget {
  const PressableIcon({
    super.key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
    this.isLoading = false,
  });

  final Widget child;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () {
          onPressed();
        },
        child: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.transparent,
          child: isLoading
              ? CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.onPrimary,
                )
              : child,
        ),
      ),
    );
  }
}
