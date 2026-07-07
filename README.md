# Better Bus Dublin

A project to replace the TFI Live app because it's terrible.

## Setup

1. Clone the repo and install Flutter dependencies:

   ```bash
   flutter pub get
   ```

2. Copy the example env file and fill in your API keys:

   ```bash
   cp .env.example .env
   ```

   Required variables:

   | Variable | Description |
   | --- | --- |
   | `NTA_API_KEY` | National Transport Authority API key |
   | `NTA_API_KEY_BACKUP` | Backup NTA API key |
   | `GOOGLE_MAPS_API_KEY` | Google Maps API key (Android) |
   | `AWS_LAMBDA_KEY` | AWS API Gateway key for the backend |
   | `STAGE` | Backend stage (`dev` or `prod`) |

3. Run the app:

   ```bash
   flutter run
   ```