import 'package:flutter/material.dart';

import '../data/database.dart';
import '../services/services.dart';
import 'add_food_sheet.dart';

/// Opens the add-food sheet for [day] (or to edit [existing]) and offers Undo
/// for whatever it logged.
Future<void> openFoodEditor(
  BuildContext context, {
  required AppDatabase database,
  required AppServices services,
  required DateTime day,
  FoodEntry? existing,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final logged = await showModalBottomSheet<LoggedResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => AddFoodSheet(
      database: database,
      services: services,
      day: day,
      existing: existing,
    ),
  );
  if (logged == null) return;
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text('Logged ${logged.label}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => database.deleteEntries(logged.ids),
        ),
      ),
    );
}

/// Today at midnight.
DateTime today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}
