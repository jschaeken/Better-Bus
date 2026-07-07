# Better Bus Dublin

A project to replace the TFI Live app because it's terrible.

A Flutter app for real-time Dublin bus information — live vehicle positions, stop departures, route browsing, and saved stops, with a map-first interface built for day-to-day commuting.

## Features

- **Live map** — See buses moving across Dublin with clustered stop markers and tap-to-inspect stop info
- **Stop departures** — View upcoming arrivals for any stop, with pull-to-refresh and service notices
- **Route explorer** — Browse routes by direction and see the stops served along each line
- **Saved stops** — Pin favourite stops locally for quick access from the home screen
- **Search** — Find stops and routes without digging through menus
- **Light & dark mode** — Follows system theme preferences

## How it works

The app bundles static GTFS data (stops, routes, calendar) for offline reference and pulls live trip updates via GTFS Realtime. A custom AWS Lambda backend supplements the NTA data with route-to-stop lookups and trip details. Local state (saved stops, settings) is persisted with Hive.

## Tech stack

| Layer | Tools |
| --- | --- |
| Framework | Flutter (Dart 3+) |
| State | Provider |
| Maps | platform_maps_flutter |
| Local storage | Hive |
| Live data | GTFS Realtime, NTA API |
| Backend | AWS API Gateway + Lambda |

## Setup

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0+)
- Xcode (iOS) or Android Studio (Android) for device builds
- API keys for the services listed below

### Install

1. Clone the repo and install dependencies:

   ```bash
   git clone https://github.com/jschaeken/Better-Bus.git
   cd Better-Bus
   flutter pub get
   ```

2. Copy the example env file and fill in your API keys:

   ```bash
   cp .env.example .env
   ```

   | Variable | Description |
   | --- | --- |
   | `NTA_API_KEY` | National Transport Authority API key |
   | `NTA_API_KEY_BACKUP` | Backup NTA API key |
   | `GOOGLE_MAPS_API_KEY` | Google Maps API key (required for Android maps) |
   | `AWS_LAMBDA_KEY` | AWS API Gateway key for the backend |
   | `STAGE` | Backend stage (`dev` or `prod`) |

3. Run the app:

   ```bash
   flutter run
   ```

## Project structure

```
lib/
├── components/     # Shared UI (map view, etc.)
├── pages/        # Screens (home, stop details, routes, saved stops)
└── utils/        # API layer, models, providers, constants
assets/
└── gtfs_data/    # Bundled static transit data
```
