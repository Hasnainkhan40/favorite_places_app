import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favorite_places/models/place.dart';
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';

Future<Database> _getDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  final db = await sql.openDatabase(
    path.join(dbPath, 'plces.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE user_places(id TEXT PRIMARY KEY, title TEXT, image TEXT, lat REAL, lng REAL, address TEXT)',
      );
    },
    version: 1,
  );
  return db;
}

class UserPlacesNotifier extends StateNotifier<List<Place>> {
  UserPlacesNotifier() : super(const []);

  Future<void> loadPlaces() async {
    final db = await _getDatabase();
    final data = await db.query('user_places');
    final places =
        data
            .map(
              (row) => Place(
                id: row['id'] as String,
                titel: row['title'] as String,
                image: File(row['image'] as String),
                location: PlaceLocation(
                  latitude: row['lat'] as double,
                  longitude: row['lng'] as double,
                  address: row['address'] as String,
                ),
              ),
            )
            .toList();
    state = places;
  }

  void addPlace(String titel, File image, PlaceLocation location) async {
    final appDir = await syspaths.getApplicationSupportDirectory();
    final filename = path.basename(image.path);
    final copidImage = await image.copy('${appDir.path}/$filename');

    final newPlace = Place(titel: titel, image: copidImage, location: location);
    state = [newPlace, ...state];
    final db = await _getDatabase();
    db.insert('user_places', {
      'id': newPlace.id,
      'title': newPlace.titel,
      'image': newPlace.image.path,
      'lat': newPlace.location.latitude,
      'lng': newPlace.location.longitude,
      'address': newPlace.location.address,
    });
  }
}

final userPlacesProvider =
    StateNotifierProvider<UserPlacesNotifier, List<Place>>(
      (ref) => UserPlacesNotifier(),
    );
