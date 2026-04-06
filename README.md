# Fair Attendance Tracker

A Flutter app for location-based fair participation check-ins. Users can refresh their current location, see the nearest fair on a map, join when inside the fair radius, and track earned points in history.

## Features

- Detects current GPS location and reverse-geocoded address
- Finds nearest fair and shows distance + allowed check-in radius
- Displays map view with fair marker, user marker, and fair radius circle
- Adds participation records with timestamp and points
- Shows total points and full participation history
- Allows clearing history and resetting points

## Tech Stack

- Flutter
- geolocator, geocoding
- flutter_map + OpenStreetMap tiles
- shared_preferences
- intl

## Run Locally

1. Install Flutter SDK.
2. In this project folder, run:

```bash
flutter pub get
flutter run
```

## Notes

- Location permission is required for core features.
- Fair locations are predefined in `lib/services/location_service.dart`.
