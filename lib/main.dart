import 'package:better_bus_dublin/pages/home_page.dart';
import 'package:better_bus_dublin/utils/api_interface.dart';
import 'package:better_bus_dublin/utils/models.dart';
import 'package:better_bus_dublin/utils/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterConfig.loadEnvVariables();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('No .env file found: $e');
  }
  await Hive.initFlutter();
  Hive.registerAdapter(StopAdapter());
  await Hive.openBox<Stop>('savedStops');

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<SearchProvider>(
      create: (_) => SearchProvider(),
    ),
    ChangeNotifierProvider<ApiInterface>(
      create: (_) => ApiInterface(),
    ),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Better Bus',
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color.fromARGB(255, 238, 238, 238),
          onPrimary: Colors.black,
          secondary: Color.fromARGB(255, 235, 235, 235),
          onSecondary: Color.fromARGB(255, 62, 62, 62),
          error: Color.fromARGB(255, 243, 87, 87),
          onError: Color.fromARGB(255, 0, 0, 0),
          background: Color.fromARGB(255, 255, 255, 255),
          onBackground: Colors.black,
          surface: Color.fromARGB(255, 151, 209, 156),
          onSurface: Colors.black,
          tertiary: Color.fromARGB(255, 88, 198, 97),
        ),
        primaryColor: Colors.white,
        useMaterial3: true,
      ),
      scrollBehavior: const ScrollBehavior().copyWith(scrollbars: false),
      home: const HomePage(),
    );
  }
}

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StopAdapter extends TypeAdapter<Stop> {
  @override
  final int typeId = 0;

  @override
  Stop read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Stop(
      stopId: fields[0] as String,
      stopCode: fields[1] as String,
      stopName: fields[2] as String,
      stopDesc: fields[3] as String?,
      stopLat: fields[4] as double,
      stopLon: fields[5] as double,
      zoneId: fields[6] as String?,
      stopUrl: fields[7] as String?,
      locationType: fields[8] as String?,
      parentStation: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Stop obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.stopId)
      ..writeByte(1)
      ..write(obj.stopCode)
      ..writeByte(2)
      ..write(obj.stopName)
      ..writeByte(3)
      ..write(obj.stopDesc)
      ..writeByte(4)
      ..write(obj.stopLat)
      ..writeByte(5)
      ..write(obj.stopLon)
      ..writeByte(6)
      ..write(obj.zoneId)
      ..writeByte(7)
      ..write(obj.stopUrl)
      ..writeByte(8)
      ..write(obj.locationType)
      ..writeByte(9)
      ..write(obj.parentStation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StopAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
