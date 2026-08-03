import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/trip.dart';
import '../models/checklist_item.dart';
import '../models/flight.dart';
import '../models/expense.dart';
import '../models/accommodation.dart';
import '../models/note.dart';
import '../models/note_checklist_item.dart';
import '../models/itinerary_place.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('trip_planner.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // On web, the ffi factory expects a plain database name (no filesystem path).
    final path = kIsWeb ? filePath : join(await getDatabasesPath(), filePath);

    return await openDatabase(
      path,
      version: 11,
      onCreate: _createDB,
      onConfigure: _onConfigure,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        main_destination TEXT NOT NULL,
        is_public INTEGER NOT NULL DEFAULT 0,
        share_token TEXT,
        destination_lat REAL,
        destination_lng REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE checklist_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        local_file_path TEXT,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    await _createFlightsTable(db);
    await _createExpensesTable(db);
    await _createAccomsTable(db);
    await _createNotesTable(db);
    await _createNoteChecklistItemsTable(db);
    await _createSettlementStatusTable(db);
    await _createItineraryPlacesTable(db);
  }

  Future _createFlightsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS flights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        flight_code TEXT NOT NULL,
        departure_airport TEXT NOT NULL,
        arrival_airport TEXT NOT NULL,
        departure_time TEXT NOT NULL,
        arrival_time TEXT NOT NULL,
        flight_date TEXT NOT NULL,
        confirmation_no TEXT NOT NULL,
        boarding_time TEXT NOT NULL,
        gate TEXT NOT NULL,
        terminal TEXT NOT NULL,
        seat_number TEXT NOT NULL,
        passenger_names TEXT NOT NULL,
        airline_name TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createExpensesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        paid_by TEXT NOT NULL DEFAULT 'Me',
        split_between TEXT NOT NULL DEFAULT 'Me',
        date TEXT NOT NULL DEFAULT '',
        payment_method TEXT NOT NULL DEFAULT 'Cash',
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createAccomsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS accommodations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        hotel_name TEXT NOT NULL,
        check_in TEXT NOT NULL,
        check_out TEXT NOT NULL,
        confirmation_no TEXT NOT NULL,
        local_file_path TEXT,
        price REAL NOT NULL DEFAULT 0.0,
        lat REAL,
        lng REAL,
        address TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createNotesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createNoteChecklistItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS note_checklist_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        note_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createSettlementStatusTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settlement_status (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        person_name TEXT NOT NULL,
        is_settled INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createFlightsTable(db);
    }
    if (oldVersion < 3) {
      await _createExpensesTable(db);
      await _createAccomsTable(db);
    }
    if (oldVersion < 4) {
      await _createNotesTable(db);
      await _createNoteChecklistItemsTable(db);
    }
    if (oldVersion < 5) {
      try { await db.execute('ALTER TABLE flights ADD COLUMN price REAL NOT NULL DEFAULT 0.0'); } catch (_) {}
      try { await db.execute('ALTER TABLE accommodations ADD COLUMN price REAL NOT NULL DEFAULT 0.0'); } catch (_) {}
      try { await db.execute("ALTER TABLE expenses ADD COLUMN paid_by TEXT NOT NULL DEFAULT 'Me'"); } catch (_) {}
      try { await db.execute("ALTER TABLE expenses ADD COLUMN split_between TEXT NOT NULL DEFAULT 'Me'"); } catch (_) {}
    }
    if (oldVersion < 6) {
      try { await db.execute("ALTER TABLE expenses ADD COLUMN date TEXT NOT NULL DEFAULT ''"); } catch (_) {}
      try { await db.execute("ALTER TABLE expenses ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'Cash'"); } catch (_) {}
    }
    if (oldVersion < 7) {
      await _createSettlementStatusTable(db);
    }
    if (oldVersion < 8) {
      await _createItineraryPlacesTable(db);
    }
    if (oldVersion < 9) {
      try { await db.execute('ALTER TABLE itinerary_places ADD COLUMN lat REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE itinerary_places ADD COLUMN lng REAL'); } catch (_) {}
    }
    if (oldVersion < 10) {
      try { await db.execute('ALTER TABLE itinerary_places ADD COLUMN cost REAL NOT NULL DEFAULT 0.0'); } catch (_) {}
    }
    if (oldVersion < 11) {
      try { await db.execute('ALTER TABLE trips ADD COLUMN is_public INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE trips ADD COLUMN share_token TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE trips ADD COLUMN destination_lat REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE trips ADD COLUMN destination_lng REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE accommodations ADD COLUMN lat REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE accommodations ADD COLUMN lng REAL'); } catch (_) {}
      try { await db.execute("ALTER TABLE accommodations ADD COLUMN address TEXT NOT NULL DEFAULT ''"); } catch (_) {}
    }
  }

  // --- TRIPS CRUD ---
  Future<Trip> createTrip(Trip trip) async {
    final db = await instance.database;
    final id = await db.insert('trips', trip.toMap());
    
    // Auto-generate default checklist items as per FEATURE 1
    await createChecklistItem(ChecklistItem(tripId: id, title: 'Visa Preparation'));
    await createChecklistItem(ChecklistItem(tripId: id, title: 'Flight Tickets'));
    await createChecklistItem(ChecklistItem(tripId: id, title: 'Travel Insurance'));
    await createChecklistItem(ChecklistItem(tripId: id, title: 'Hotel Booking Confirmed'));

    // Auto-generate default helpful notes with internal checklists as per user query
    final visaNoteId = await createNote(Note(
      tripId: id,
      title: 'Giấy tờ chuẩn bị Visa',
      content: 'Chuẩn bị đầy đủ hồ sơ trước ngày khởi hành ít nhất 2 tuần.',
    ));
    await createNoteChecklistItem(NoteChecklistItem(noteId: visaNoteId, title: 'Hộ chiếu còn hạn trên 6 tháng'));
    await createNoteChecklistItem(NoteChecklistItem(noteId: visaNoteId, title: 'Ảnh 4x6 nền trắng mới chụp'));
    await createNoteChecklistItem(NoteChecklistItem(noteId: visaNoteId, title: 'Tờ khai xin cấp Visa đã điền đủ'));
    await createNoteChecklistItem(NoteChecklistItem(noteId: visaNoteId, title: 'Xác nhận đặt phòng khách sạn & vé bay'));

    final suitcaseNoteId = await createNote(Note(
      tripId: id,
      title: 'Chuẩn bị Vali hành lý',
      content: 'Xếp đồ gọn gàng, tránh mang quá cân quy định của hãng bay.',
    ));
    await createNoteChecklistItem(NoteChecklistItem(noteId: suitcaseNoteId, title: 'Quần áo đi biển / dạo phố'));
    await createNoteChecklistItem(NoteChecklistItem(noteId: suitcaseNoteId, title: 'Sạc điện thoại, sạc dự phòng'));
    await createNoteChecklistItem(NoteChecklistItem(noteId: suitcaseNoteId, title: 'Bàn chải & kem đánh răng cá nhân'));
    await createNoteChecklistItem(NoteChecklistItem(noteId: suitcaseNoteId, title: 'Thuốc chống muỗi & thuốc cảm cúm'));

    return Trip(
      id: id,
      title: trip.title,
      startDate: trip.startDate,
      endDate: trip.endDate,
      mainDestination: trip.mainDestination,
      isPublic: trip.isPublic,
      shareToken: trip.shareToken,
      destinationLat: trip.destinationLat,
      destinationLng: trip.destinationLng,
    );
  }

  Future<Trip?> readTripById(int id) async {
    final db = await instance.database;
    final result = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Trip.fromMap(result.first);
  }

  Future<Trip?> readTripByShareToken(String token) async {
    final db = await instance.database;
    final result = await db.query(
      'trips',
      where: 'share_token = ? AND is_public = 1',
      whereArgs: [token],
    );
    if (result.isEmpty) return null;
    return Trip.fromMap(result.first);
  }

  Future<List<Trip>> readPublicTrips({int? excludeTripId}) async {
    final db = await instance.database;
    final result = excludeTripId != null
        ? await db.query(
            'trips',
            where: 'is_public = 1 AND id != ?',
            whereArgs: [excludeTripId],
            orderBy: 'start_date DESC',
          )
        : await db.query(
            'trips',
            where: 'is_public = 1',
            orderBy: 'start_date DESC',
          );
    return result.map((json) => Trip.fromMap(json)).toList();
  }

  Future<Trip> updateTrip(Trip trip) async {
    final db = await instance.database;
    await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
    return trip;
  }

  Future<Trip> setTripSharing(int tripId, {required bool isPublic, String? shareToken}) async {
    final existing = await readTripById(tripId);
    if (existing == null) throw StateError('Trip not found');
    final updated = existing.copyWith(
      isPublic: isPublic,
      shareToken: isPublic ? shareToken : existing.shareToken,
    );
    return updateTrip(updated);
  }

  Future<Trip> cloneTrip(int sourceTripId) async {
    final source = await readTripById(sourceTripId);
    if (source == null) throw StateError('Trip not found');

    final cloned = await createTrip(Trip(
      title: '${source.title} (Copy)',
      startDate: source.startDate,
      endDate: source.endDate,
      mainDestination: source.mainDestination,
      destinationLat: source.destinationLat,
      destinationLng: source.destinationLng,
    ));

    final tripId = cloned.id!;

    final checklist = await readChecklistForTrip(sourceTripId);
    for (final item in checklist) {
      await createChecklistItem(ChecklistItem(
        tripId: tripId,
        title: item.title,
        isCompleted: false,
        localFilePath: item.localFilePath,
      ));
    }

    final flights = await readFlightsForTrip(sourceTripId);
    for (final flight in flights) {
      await createFlight(Flight(
        tripId: tripId,
        flightCode: flight.flightCode,
        departureAirport: flight.departureAirport,
        arrivalAirport: flight.arrivalAirport,
        departureTime: flight.departureTime,
        arrivalTime: flight.arrivalTime,
        flightDate: flight.flightDate,
        confirmationNo: flight.confirmationNo,
        boardingTime: flight.boardingTime,
        gate: flight.gate,
        terminal: flight.terminal,
        seatNumber: flight.seatNumber,
        passengerNames: flight.passengerNames,
        airlineName: flight.airlineName,
        price: flight.price,
      ));
    }

    final accoms = await readAccommodationsForTrip(sourceTripId);
    for (final accom in accoms) {
      await createAccommodation(Accommodation(
        tripId: tripId,
        hotelName: accom.hotelName,
        checkIn: accom.checkIn,
        checkOut: accom.checkOut,
        confirmationNo: accom.confirmationNo,
        localFilePath: accom.localFilePath,
        price: accom.price,
        lat: accom.lat,
        lng: accom.lng,
        address: accom.address,
      ));
    }

    final notes = await readNotesForTrip(sourceTripId);
    for (final note in notes) {
      final noteId = await createNote(Note(
        tripId: tripId,
        title: note.title,
        content: note.content,
      ));
      final noteItems = await readChecklistForNote(note.id!);
      for (final ni in noteItems) {
        await createNoteChecklistItem(NoteChecklistItem(
          noteId: noteId,
          title: ni.title,
          isCompleted: false,
        ));
      }
    }

    final places = await readItineraryPlacesForTrip(sourceTripId);
    for (final place in places) {
      await createItineraryPlace(ItineraryPlace(
        tripId: tripId,
        date: place.date,
        title: place.title,
        startTime: place.startTime,
        endTime: place.endTime,
        location: place.location,
        kind: place.kind,
        sortOrder: place.sortOrder,
        lat: place.lat,
        lng: place.lng,
        cost: place.cost,
      ));
    }

    final expenses = await readExpensesForTrip(sourceTripId);
    for (final expense in expenses) {
      await createExpense(Expense(
        tripId: tripId,
        title: expense.title,
        amount: expense.amount,
        category: expense.category,
        paidBy: expense.paidBy,
        splitBetween: expense.splitBetween,
        date: expense.date,
        paymentMethod: expense.paymentMethod,
      ));
    }

    return (await readTripById(tripId))!;
  }

  Future<List<Trip>> readAllTrips() async {
    final db = await instance.database;
    final result = await db.query('trips', orderBy: 'start_date ASC');
    return result.map((json) => Trip.fromMap(json)).toList();
  }

  Future<int> deleteTrip(int id) async {
    final db = await instance.database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  // --- CHECKLIST CRUD ---
  Future<ChecklistItem> createChecklistItem(ChecklistItem item) async {
    final db = await instance.database;
    final id = await db.insert('checklist_items', item.toMap());
    return item.copyWith(id: id);
  }

  Future<List<ChecklistItem>> readChecklistForTrip(int tripId) async {
    final db = await instance.database;
    final result = await db.query(
      'checklist_items',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
    return result.map((json) => ChecklistItem.fromMap(json)).toList();
  }

  Future<int> updateChecklistItem(ChecklistItem item) async {
    final db = await instance.database;
    return await db.update(
      'checklist_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteChecklistItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'checklist_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- FLIGHTS CRUD ---
  Future<Flight> createFlight(Flight flight) async {
    final db = await instance.database;
    final id = await db.insert('flights', flight.toMap());
    
    // Auto-save flight price into expenses table so user doesn't type it again!
    if (flight.price > 0) {
      await createExpense(Expense(
        tripId: flight.tripId,
        title: 'Flight (${flight.flightCode})',
        amount: flight.price,
        category: 'Flights',
        paidBy: 'Me',
        splitBetween: flight.passengerNames,
        date: flight.flightDate, // store the actual flight date
        paymentMethod: 'Card',
      ));
    }
    
    return flight.copyWith(id: id);
  }

  Future<int> updateFlight(Flight flight) async {
    final db = await instance.database;
    return await db.update(
      'flights',
      flight.toMap(),
      where: 'id = ?',
      whereArgs: [flight.id],
    );
  }

  Future<List<Flight>> readFlightsForTrip(int tripId) async {
    final db = await instance.database;
    final result = await db.query(
      'flights',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
    return result.map((json) => Flight.fromMap(json)).toList();
  }

  Future<int> deleteFlight(int id) async {
    final db = await instance.database;
    // Fetch the flight first so we can find and delete its auto-created expense
    final rows = await db.query('flights', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final flight = Flight.fromMap(rows.first);
      await db.delete(
        'expenses',
        where: 'trip_id = ? AND title = ? AND category = ?',
        whereArgs: [flight.tripId, 'Flight (${flight.flightCode})', 'Flights'],
      );
    }
    return await db.delete('flights', where: 'id = ?', whereArgs: [id]);
  }

  // --- EXPENSES CRUD ---
  Future<Expense> createExpense(Expense expense) async {
    final db = await instance.database;
    final id = await db.insert('expenses', expense.toMap());
    return expense.copyWith(id: id);
  }

  Future<List<Expense>> readExpensesForTrip(int tripId) async {
    final db = await instance.database;
    final result = await db.query(
      'expenses',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await instance.database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- ACCOMODATIONS CRUD ---
  Future<Accommodation> createAccommodation(Accommodation accom) async {
    final db = await instance.database;
    final id = await db.insert('accommodations', accom.toMap());

    // Auto-save stay price into expenses table so user doesn't type it again!
    if (accom.price > 0) {
      await createExpense(Expense(
        tripId: accom.tripId,
        title: 'Stay: ${accom.hotelName}',
        amount: accom.price,
        category: 'Accomms',
        paidBy: 'Me',
        // Split evenly across all group members by default
        splitBetween: 'Me, Claire, Celeste, Jessica',
        date: accom.checkIn,
        paymentMethod: 'Card',
      ));
    }

    return accom.copyWith(id: id);
  }

  Future<List<Accommodation>> readAccommodationsForTrip(int tripId) async {
    final db = await instance.database;
    final result = await db.query(
      'accommodations',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
    return result.map((json) => Accommodation.fromMap(json)).toList();
  }

  Future<int> updateAccommodation(Accommodation accom) async {
    final db = await instance.database;
    return await db.update(
      'accommodations',
      accom.toMap(),
      where: 'id = ?',
      whereArgs: [accom.id],
    );
  }

  Future<int> deleteAccommodation(int id) async {
    final db = await instance.database;
    // Fetch the accom first so we can find and delete its auto-created expense
    final rows = await db.query('accommodations', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final accom = Accommodation.fromMap(rows.first);
      await db.delete(
        'expenses',
        where: 'trip_id = ? AND title = ? AND category = ?',
        whereArgs: [accom.tripId, 'Stay: ${accom.hotelName}', 'Accomms'],
      );
    }
    return await db.delete('accommodations', where: 'id = ?', whereArgs: [id]);
  }

  // --- NOTES CRUD ---
  Future<int> createNote(Note note) async {
    final db = await instance.database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> readNotesForTrip(int tripId) async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // --- NOTE CHECKLIST ITEMS CRUD ---
  Future<NoteChecklistItem> createNoteChecklistItem(NoteChecklistItem item) async {
    final db = await instance.database;
    final id = await db.insert('note_checklist_items', item.toMap());
    return item.copyWith(id: id);
  }

  Future<List<NoteChecklistItem>> readChecklistForNote(int noteId) async {
    final db = await instance.database;
    final result = await db.query(
      'note_checklist_items',
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
    return result.map((json) => NoteChecklistItem.fromMap(json)).toList();
  }

  Future<int> updateNoteChecklistItem(NoteChecklistItem item) async {
    final db = await instance.database;
    return await db.update(
      'note_checklist_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteNoteChecklistItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'note_checklist_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- SETTLEMENT STATUS CRUD ---

  /// Returns a set of person names that have been marked as settled for this trip.
  Future<Set<String>> readSettledPersons(int tripId) async {
    final db = await instance.database;
    final result = await db.query(
      'settlement_status',
      where: 'trip_id = ? AND is_settled = 1',
      whereArgs: [tripId],
    );
    return result.map((row) => row['person_name'] as String).toSet();
  }

  /// Marks (or unmarks) a person as settled for this trip.
  Future<void> setSettled(int tripId, String personName, {required bool settled}) async {
    final db = await instance.database;
    // Upsert: delete existing row then insert fresh
    await db.delete(
      'settlement_status',
      where: 'trip_id = ? AND person_name = ?',
      whereArgs: [tripId, personName],
    );
    await db.insert('settlement_status', {
      'trip_id': tripId,
      'person_name': personName,
      'is_settled': settled ? 1 : 0,
    });
  }

  // --- ITINERARY PLACES ---

  Future _createItineraryPlacesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS itinerary_places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        title TEXT NOT NULL,
        start_time TEXT NOT NULL DEFAULT '',
        end_time TEXT NOT NULL DEFAULT '',
        location TEXT NOT NULL DEFAULT '',
        kind TEXT NOT NULL DEFAULT 'place',
        sort_order INTEGER NOT NULL DEFAULT 0,
        lat REAL,
        lng REAL,
        cost REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<ItineraryPlace> createItineraryPlace(ItineraryPlace place) async {
    final db = await instance.database;
    final id = await db.insert('itinerary_places', place.toMap());

    if (place.cost > 0) {
      await createExpense(Expense(
        tripId: place.tripId,
        title: place.expenseTitle,
        amount: place.cost,
        category: place.expenseCategory,
        paidBy: 'Me',
        splitBetween: 'Me',
        date: place.date,
        paymentMethod: 'Cash',
      ));
    }

    return place.copyWith(id: id);
  }

  Future<List<ItineraryPlace>> readItineraryPlacesForTrip(int tripId) async {
    final db = await instance.database;
    final result = await db.query(
      'itinerary_places',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'date ASC, sort_order ASC, start_time ASC',
    );
    return result.map((json) => ItineraryPlace.fromMap(json)).toList();
  }

  Future<void> updateItineraryPlace(ItineraryPlace place) async {
    final db = await instance.database;
    // Delete the old auto-created expense (using old title/category)
    final oldRows = await db.query('itinerary_places', where: 'id = ?', whereArgs: [place.id]);
    if (oldRows.isNotEmpty) {
      final old = ItineraryPlace.fromMap(oldRows.first);
      await db.delete(
        'expenses',
        where: 'trip_id = ? AND title = ? AND category = ?',
        whereArgs: [old.tripId, old.expenseTitle, old.expenseCategory],
      );
    }
    await db.update('itinerary_places', place.toMap(), where: 'id = ?', whereArgs: [place.id]);
    if (place.cost > 0) {
      await createExpense(Expense(
        tripId: place.tripId,
        title: place.expenseTitle,
        amount: place.cost,
        category: place.expenseCategory,
        paidBy: 'Me',
        splitBetween: 'Me',
        date: place.date,
        paymentMethod: 'Cash',
      ));
    }
  }

  Future<int> deleteItineraryPlace(int id) async {
    final db = await instance.database;
    final rows = await db.query('itinerary_places', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final place = ItineraryPlace.fromMap(rows.first);
      await db.delete(
        'expenses',
        where: 'trip_id = ? AND title = ? AND category = ?',
        whereArgs: [place.tripId, place.expenseTitle, place.expenseCategory],
      );
    }
    return await db.delete('itinerary_places', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorderItineraryPlaces(List<int> placeIdsInOrder) async {
    final db = await instance.database;
    for (var i = 0; i < placeIdsInOrder.length; i++) {
      await db.update(
        'itinerary_places',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [placeIdsInOrder[i]],
      );
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
