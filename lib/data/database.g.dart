// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FoodEntriesTable extends FoodEntries
    with TableInfo<$FoodEntriesTable, FoodEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MealType, int> mealType =
      GeneratedColumn<int>(
        'meal_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<MealType>($FoodEntriesTable.$convertermealType);
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
    'calories',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Portion?, int> portion =
      GeneratedColumn<int>(
        'portion',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Portion?>($FoodEntriesTable.$converterportionn);
  static const VerificationMeta _isEstimateMeta = const VerificationMeta(
    'isEstimate',
  );
  @override
  late final GeneratedColumn<bool> isEstimate = GeneratedColumn<bool>(
    'is_estimate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_estimate" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<int> protein = GeneratedColumn<int>(
    'protein',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<int> carbs = GeneratedColumn<int>(
    'carbs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<int> fat = GeneratedColumn<int>(
    'fat',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    mealType,
    calories,
    notes,
    loggedAt,
    portion,
    isEstimate,
    protein,
    carbs,
    fat,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('is_estimate')) {
      context.handle(
        _isEstimateMeta,
        isEstimate.isAcceptableOrUnknown(data['is_estimate']!, _isEstimateMeta),
      );
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    }
    if (data.containsKey('carbs')) {
      context.handle(
        _carbsMeta,
        carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta),
      );
    }
    if (data.containsKey('fat')) {
      context.handle(
        _fatMeta,
        fat.isAcceptableOrUnknown(data['fat']!, _fatMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      mealType: $FoodEntriesTable.$convertermealType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}meal_type'],
        )!,
      ),
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      portion: $FoodEntriesTable.$converterportionn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}portion'],
        ),
      ),
      isEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_estimate'],
      )!,
      protein: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protein'],
      ),
      carbs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carbs'],
      ),
      fat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fat'],
      ),
    );
  }

  @override
  $FoodEntriesTable createAlias(String alias) {
    return $FoodEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MealType, int, int> $convertermealType =
      const EnumIndexConverter<MealType>(MealType.values);
  static JsonTypeConverter2<Portion, int, int> $converterportion =
      const EnumIndexConverter<Portion>(Portion.values);
  static JsonTypeConverter2<Portion?, int?, int?> $converterportionn =
      JsonTypeConverter2.asNullable($converterportion);
}

class FoodEntry extends DataClass implements Insertable<FoodEntry> {
  final int id;
  final String name;
  final MealType mealType;
  final int? calories;
  final String? notes;
  final DateTime loggedAt;
  final Portion? portion;

  /// True when [calories] is a guess (portion size or AI), not a known value.
  final bool isEstimate;
  final int? protein;
  final int? carbs;
  final int? fat;
  const FoodEntry({
    required this.id,
    required this.name,
    required this.mealType,
    this.calories,
    this.notes,
    required this.loggedAt,
    this.portion,
    required this.isEstimate,
    this.protein,
    this.carbs,
    this.fat,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['meal_type'] = Variable<int>(
        $FoodEntriesTable.$convertermealType.toSql(mealType),
      );
    }
    if (!nullToAbsent || calories != null) {
      map['calories'] = Variable<int>(calories);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['logged_at'] = Variable<DateTime>(loggedAt);
    if (!nullToAbsent || portion != null) {
      map['portion'] = Variable<int>(
        $FoodEntriesTable.$converterportionn.toSql(portion),
      );
    }
    map['is_estimate'] = Variable<bool>(isEstimate);
    if (!nullToAbsent || protein != null) {
      map['protein'] = Variable<int>(protein);
    }
    if (!nullToAbsent || carbs != null) {
      map['carbs'] = Variable<int>(carbs);
    }
    if (!nullToAbsent || fat != null) {
      map['fat'] = Variable<int>(fat);
    }
    return map;
  }

  FoodEntriesCompanion toCompanion(bool nullToAbsent) {
    return FoodEntriesCompanion(
      id: Value(id),
      name: Value(name),
      mealType: Value(mealType),
      calories: calories == null && nullToAbsent
          ? const Value.absent()
          : Value(calories),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      loggedAt: Value(loggedAt),
      portion: portion == null && nullToAbsent
          ? const Value.absent()
          : Value(portion),
      isEstimate: Value(isEstimate),
      protein: protein == null && nullToAbsent
          ? const Value.absent()
          : Value(protein),
      carbs: carbs == null && nullToAbsent
          ? const Value.absent()
          : Value(carbs),
      fat: fat == null && nullToAbsent ? const Value.absent() : Value(fat),
    );
  }

  factory FoodEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodEntry(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      mealType: $FoodEntriesTable.$convertermealType.fromJson(
        serializer.fromJson<int>(json['mealType']),
      ),
      calories: serializer.fromJson<int?>(json['calories']),
      notes: serializer.fromJson<String?>(json['notes']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      portion: $FoodEntriesTable.$converterportionn.fromJson(
        serializer.fromJson<int?>(json['portion']),
      ),
      isEstimate: serializer.fromJson<bool>(json['isEstimate']),
      protein: serializer.fromJson<int?>(json['protein']),
      carbs: serializer.fromJson<int?>(json['carbs']),
      fat: serializer.fromJson<int?>(json['fat']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'mealType': serializer.toJson<int>(
        $FoodEntriesTable.$convertermealType.toJson(mealType),
      ),
      'calories': serializer.toJson<int?>(calories),
      'notes': serializer.toJson<String?>(notes),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'portion': serializer.toJson<int?>(
        $FoodEntriesTable.$converterportionn.toJson(portion),
      ),
      'isEstimate': serializer.toJson<bool>(isEstimate),
      'protein': serializer.toJson<int?>(protein),
      'carbs': serializer.toJson<int?>(carbs),
      'fat': serializer.toJson<int?>(fat),
    };
  }

  FoodEntry copyWith({
    int? id,
    String? name,
    MealType? mealType,
    Value<int?> calories = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? loggedAt,
    Value<Portion?> portion = const Value.absent(),
    bool? isEstimate,
    Value<int?> protein = const Value.absent(),
    Value<int?> carbs = const Value.absent(),
    Value<int?> fat = const Value.absent(),
  }) => FoodEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    mealType: mealType ?? this.mealType,
    calories: calories.present ? calories.value : this.calories,
    notes: notes.present ? notes.value : this.notes,
    loggedAt: loggedAt ?? this.loggedAt,
    portion: portion.present ? portion.value : this.portion,
    isEstimate: isEstimate ?? this.isEstimate,
    protein: protein.present ? protein.value : this.protein,
    carbs: carbs.present ? carbs.value : this.carbs,
    fat: fat.present ? fat.value : this.fat,
  );
  FoodEntry copyWithCompanion(FoodEntriesCompanion data) {
    return FoodEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      calories: data.calories.present ? data.calories.value : this.calories,
      notes: data.notes.present ? data.notes.value : this.notes,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      portion: data.portion.present ? data.portion.value : this.portion,
      isEstimate: data.isEstimate.present
          ? data.isEstimate.value
          : this.isEstimate,
      protein: data.protein.present ? data.protein.value : this.protein,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
      fat: data.fat.present ? data.fat.value : this.fat,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mealType: $mealType, ')
          ..write('calories: $calories, ')
          ..write('notes: $notes, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('portion: $portion, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    mealType,
    calories,
    notes,
    loggedAt,
    portion,
    isEstimate,
    protein,
    carbs,
    fat,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.mealType == this.mealType &&
          other.calories == this.calories &&
          other.notes == this.notes &&
          other.loggedAt == this.loggedAt &&
          other.portion == this.portion &&
          other.isEstimate == this.isEstimate &&
          other.protein == this.protein &&
          other.carbs == this.carbs &&
          other.fat == this.fat);
}

class FoodEntriesCompanion extends UpdateCompanion<FoodEntry> {
  final Value<int> id;
  final Value<String> name;
  final Value<MealType> mealType;
  final Value<int?> calories;
  final Value<String?> notes;
  final Value<DateTime> loggedAt;
  final Value<Portion?> portion;
  final Value<bool> isEstimate;
  final Value<int?> protein;
  final Value<int?> carbs;
  final Value<int?> fat;
  const FoodEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.mealType = const Value.absent(),
    this.calories = const Value.absent(),
    this.notes = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.portion = const Value.absent(),
    this.isEstimate = const Value.absent(),
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
  });
  FoodEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required MealType mealType,
    this.calories = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime loggedAt,
    this.portion = const Value.absent(),
    this.isEstimate = const Value.absent(),
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
  }) : name = Value(name),
       mealType = Value(mealType),
       loggedAt = Value(loggedAt);
  static Insertable<FoodEntry> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? mealType,
    Expression<int>? calories,
    Expression<String>? notes,
    Expression<DateTime>? loggedAt,
    Expression<int>? portion,
    Expression<bool>? isEstimate,
    Expression<int>? protein,
    Expression<int>? carbs,
    Expression<int>? fat,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (mealType != null) 'meal_type': mealType,
      if (calories != null) 'calories': calories,
      if (notes != null) 'notes': notes,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (portion != null) 'portion': portion,
      if (isEstimate != null) 'is_estimate': isEstimate,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fat != null) 'fat': fat,
    });
  }

  FoodEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<MealType>? mealType,
    Value<int?>? calories,
    Value<String?>? notes,
    Value<DateTime>? loggedAt,
    Value<Portion?>? portion,
    Value<bool>? isEstimate,
    Value<int?>? protein,
    Value<int?>? carbs,
    Value<int?>? fat,
  }) {
    return FoodEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      calories: calories ?? this.calories,
      notes: notes ?? this.notes,
      loggedAt: loggedAt ?? this.loggedAt,
      portion: portion ?? this.portion,
      isEstimate: isEstimate ?? this.isEstimate,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<int>(
        $FoodEntriesTable.$convertermealType.toSql(mealType.value),
      );
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (portion.present) {
      map['portion'] = Variable<int>(
        $FoodEntriesTable.$converterportionn.toSql(portion.value),
      );
    }
    if (isEstimate.present) {
      map['is_estimate'] = Variable<bool>(isEstimate.value);
    }
    if (protein.present) {
      map['protein'] = Variable<int>(protein.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<int>(carbs.value);
    }
    if (fat.present) {
      map['fat'] = Variable<int>(fat.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mealType: $mealType, ')
          ..write('calories: $calories, ')
          ..write('notes: $notes, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('portion: $portion, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat')
          ..write(')'))
        .toString();
  }
}

class $SavedFoodsTable extends SavedFoods
    with TableInfo<$SavedFoodsTable, SavedFood> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedFoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
    'calories',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEstimateMeta = const VerificationMeta(
    'isEstimate',
  );
  @override
  late final GeneratedColumn<bool> isEstimate = GeneratedColumn<bool>(
    'is_estimate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_estimate" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _portionLabelMeta = const VerificationMeta(
    'portionLabel',
  );
  @override
  late final GeneratedColumn<String> portionLabel = GeneratedColumn<String>(
    'portion_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _useCountMeta = const VerificationMeta(
    'useCount',
  );
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
    'use_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<int> protein = GeneratedColumn<int>(
    'protein',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<int> carbs = GeneratedColumn<int>(
    'carbs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<int> fat = GeneratedColumn<int>(
    'fat',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    calories,
    isEstimate,
    portionLabel,
    barcode,
    useCount,
    lastUsedAt,
    protein,
    carbs,
    fat,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedFood> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    }
    if (data.containsKey('is_estimate')) {
      context.handle(
        _isEstimateMeta,
        isEstimate.isAcceptableOrUnknown(data['is_estimate']!, _isEstimateMeta),
      );
    }
    if (data.containsKey('portion_label')) {
      context.handle(
        _portionLabelMeta,
        portionLabel.isAcceptableOrUnknown(
          data['portion_label']!,
          _portionLabelMeta,
        ),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('use_count')) {
      context.handle(
        _useCountMeta,
        useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    }
    if (data.containsKey('carbs')) {
      context.handle(
        _carbsMeta,
        carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta),
      );
    }
    if (data.containsKey('fat')) {
      context.handle(
        _fatMeta,
        fat.isAcceptableOrUnknown(data['fat']!, _fatMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedFood map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedFood(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories'],
      ),
      isEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_estimate'],
      )!,
      portionLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portion_label'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      useCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}use_count'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      )!,
      protein: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protein'],
      ),
      carbs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carbs'],
      ),
      fat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fat'],
      ),
    );
  }

  @override
  $SavedFoodsTable createAlias(String alias) {
    return $SavedFoodsTable(attachedDatabase, alias);
  }
}

class SavedFood extends DataClass implements Insertable<SavedFood> {
  final int id;
  final String name;
  final int? calories;
  final bool isEstimate;
  final String? portionLabel;
  final String? barcode;
  final int useCount;
  final DateTime lastUsedAt;
  final int? protein;
  final int? carbs;
  final int? fat;
  const SavedFood({
    required this.id,
    required this.name,
    this.calories,
    required this.isEstimate,
    this.portionLabel,
    this.barcode,
    required this.useCount,
    required this.lastUsedAt,
    this.protein,
    this.carbs,
    this.fat,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || calories != null) {
      map['calories'] = Variable<int>(calories);
    }
    map['is_estimate'] = Variable<bool>(isEstimate);
    if (!nullToAbsent || portionLabel != null) {
      map['portion_label'] = Variable<String>(portionLabel);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['use_count'] = Variable<int>(useCount);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    if (!nullToAbsent || protein != null) {
      map['protein'] = Variable<int>(protein);
    }
    if (!nullToAbsent || carbs != null) {
      map['carbs'] = Variable<int>(carbs);
    }
    if (!nullToAbsent || fat != null) {
      map['fat'] = Variable<int>(fat);
    }
    return map;
  }

  SavedFoodsCompanion toCompanion(bool nullToAbsent) {
    return SavedFoodsCompanion(
      id: Value(id),
      name: Value(name),
      calories: calories == null && nullToAbsent
          ? const Value.absent()
          : Value(calories),
      isEstimate: Value(isEstimate),
      portionLabel: portionLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(portionLabel),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      useCount: Value(useCount),
      lastUsedAt: Value(lastUsedAt),
      protein: protein == null && nullToAbsent
          ? const Value.absent()
          : Value(protein),
      carbs: carbs == null && nullToAbsent
          ? const Value.absent()
          : Value(carbs),
      fat: fat == null && nullToAbsent ? const Value.absent() : Value(fat),
    );
  }

  factory SavedFood.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedFood(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      calories: serializer.fromJson<int?>(json['calories']),
      isEstimate: serializer.fromJson<bool>(json['isEstimate']),
      portionLabel: serializer.fromJson<String?>(json['portionLabel']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      useCount: serializer.fromJson<int>(json['useCount']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
      protein: serializer.fromJson<int?>(json['protein']),
      carbs: serializer.fromJson<int?>(json['carbs']),
      fat: serializer.fromJson<int?>(json['fat']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'calories': serializer.toJson<int?>(calories),
      'isEstimate': serializer.toJson<bool>(isEstimate),
      'portionLabel': serializer.toJson<String?>(portionLabel),
      'barcode': serializer.toJson<String?>(barcode),
      'useCount': serializer.toJson<int>(useCount),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
      'protein': serializer.toJson<int?>(protein),
      'carbs': serializer.toJson<int?>(carbs),
      'fat': serializer.toJson<int?>(fat),
    };
  }

  SavedFood copyWith({
    int? id,
    String? name,
    Value<int?> calories = const Value.absent(),
    bool? isEstimate,
    Value<String?> portionLabel = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    int? useCount,
    DateTime? lastUsedAt,
    Value<int?> protein = const Value.absent(),
    Value<int?> carbs = const Value.absent(),
    Value<int?> fat = const Value.absent(),
  }) => SavedFood(
    id: id ?? this.id,
    name: name ?? this.name,
    calories: calories.present ? calories.value : this.calories,
    isEstimate: isEstimate ?? this.isEstimate,
    portionLabel: portionLabel.present ? portionLabel.value : this.portionLabel,
    barcode: barcode.present ? barcode.value : this.barcode,
    useCount: useCount ?? this.useCount,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    protein: protein.present ? protein.value : this.protein,
    carbs: carbs.present ? carbs.value : this.carbs,
    fat: fat.present ? fat.value : this.fat,
  );
  SavedFood copyWithCompanion(SavedFoodsCompanion data) {
    return SavedFood(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      calories: data.calories.present ? data.calories.value : this.calories,
      isEstimate: data.isEstimate.present
          ? data.isEstimate.value
          : this.isEstimate,
      portionLabel: data.portionLabel.present
          ? data.portionLabel.value
          : this.portionLabel,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
      protein: data.protein.present ? data.protein.value : this.protein,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
      fat: data.fat.present ? data.fat.value : this.fat,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedFood(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('calories: $calories, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('portionLabel: $portionLabel, ')
          ..write('barcode: $barcode, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    calories,
    isEstimate,
    portionLabel,
    barcode,
    useCount,
    lastUsedAt,
    protein,
    carbs,
    fat,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedFood &&
          other.id == this.id &&
          other.name == this.name &&
          other.calories == this.calories &&
          other.isEstimate == this.isEstimate &&
          other.portionLabel == this.portionLabel &&
          other.barcode == this.barcode &&
          other.useCount == this.useCount &&
          other.lastUsedAt == this.lastUsedAt &&
          other.protein == this.protein &&
          other.carbs == this.carbs &&
          other.fat == this.fat);
}

class SavedFoodsCompanion extends UpdateCompanion<SavedFood> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> calories;
  final Value<bool> isEstimate;
  final Value<String?> portionLabel;
  final Value<String?> barcode;
  final Value<int> useCount;
  final Value<DateTime> lastUsedAt;
  final Value<int?> protein;
  final Value<int?> carbs;
  final Value<int?> fat;
  const SavedFoodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.calories = const Value.absent(),
    this.isEstimate = const Value.absent(),
    this.portionLabel = const Value.absent(),
    this.barcode = const Value.absent(),
    this.useCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
  });
  SavedFoodsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.calories = const Value.absent(),
    this.isEstimate = const Value.absent(),
    this.portionLabel = const Value.absent(),
    this.barcode = const Value.absent(),
    this.useCount = const Value.absent(),
    required DateTime lastUsedAt,
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
  }) : name = Value(name),
       lastUsedAt = Value(lastUsedAt);
  static Insertable<SavedFood> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? calories,
    Expression<bool>? isEstimate,
    Expression<String>? portionLabel,
    Expression<String>? barcode,
    Expression<int>? useCount,
    Expression<DateTime>? lastUsedAt,
    Expression<int>? protein,
    Expression<int>? carbs,
    Expression<int>? fat,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (calories != null) 'calories': calories,
      if (isEstimate != null) 'is_estimate': isEstimate,
      if (portionLabel != null) 'portion_label': portionLabel,
      if (barcode != null) 'barcode': barcode,
      if (useCount != null) 'use_count': useCount,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fat != null) 'fat': fat,
    });
  }

  SavedFoodsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int?>? calories,
    Value<bool>? isEstimate,
    Value<String?>? portionLabel,
    Value<String?>? barcode,
    Value<int>? useCount,
    Value<DateTime>? lastUsedAt,
    Value<int?>? protein,
    Value<int?>? carbs,
    Value<int?>? fat,
  }) {
    return SavedFoodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      isEstimate: isEstimate ?? this.isEstimate,
      portionLabel: portionLabel ?? this.portionLabel,
      barcode: barcode ?? this.barcode,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (isEstimate.present) {
      map['is_estimate'] = Variable<bool>(isEstimate.value);
    }
    if (portionLabel.present) {
      map['portion_label'] = Variable<String>(portionLabel.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (protein.present) {
      map['protein'] = Variable<int>(protein.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<int>(carbs.value);
    }
    if (fat.present) {
      map['fat'] = Variable<int>(fat.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedFoodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('calories: $calories, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('portionLabel: $portionLabel, ')
          ..write('barcode: $barcode, ')
          ..write('useCount: $useCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat')
          ..write(')'))
        .toString();
  }
}

class $MealTemplatesTable extends MealTemplates
    with TableInfo<$MealTemplatesTable, MealTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MealType, int> mealType =
      GeneratedColumn<int>(
        'meal_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<MealType>($MealTemplatesTable.$convertermealType);
  @override
  List<GeneratedColumn> get $columns => [id, name, mealType];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      mealType: $MealTemplatesTable.$convertermealType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}meal_type'],
        )!,
      ),
    );
  }

  @override
  $MealTemplatesTable createAlias(String alias) {
    return $MealTemplatesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MealType, int, int> $convertermealType =
      const EnumIndexConverter<MealType>(MealType.values);
}

class MealTemplate extends DataClass implements Insertable<MealTemplate> {
  final int id;
  final String name;
  final MealType mealType;
  const MealTemplate({
    required this.id,
    required this.name,
    required this.mealType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['meal_type'] = Variable<int>(
        $MealTemplatesTable.$convertermealType.toSql(mealType),
      );
    }
    return map;
  }

  MealTemplatesCompanion toCompanion(bool nullToAbsent) {
    return MealTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      mealType: Value(mealType),
    );
  }

  factory MealTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealTemplate(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      mealType: $MealTemplatesTable.$convertermealType.fromJson(
        serializer.fromJson<int>(json['mealType']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'mealType': serializer.toJson<int>(
        $MealTemplatesTable.$convertermealType.toJson(mealType),
      ),
    };
  }

  MealTemplate copyWith({int? id, String? name, MealType? mealType}) =>
      MealTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        mealType: mealType ?? this.mealType,
      );
  MealTemplate copyWithCompanion(MealTemplatesCompanion data) {
    return MealTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mealType: $mealType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, mealType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.mealType == this.mealType);
}

class MealTemplatesCompanion extends UpdateCompanion<MealTemplate> {
  final Value<int> id;
  final Value<String> name;
  final Value<MealType> mealType;
  const MealTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.mealType = const Value.absent(),
  });
  MealTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required MealType mealType,
  }) : name = Value(name),
       mealType = Value(mealType);
  static Insertable<MealTemplate> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? mealType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (mealType != null) 'meal_type': mealType,
    });
  }

  MealTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<MealType>? mealType,
  }) {
    return MealTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<int>(
        $MealTemplatesTable.$convertermealType.toSql(mealType.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mealType: $mealType')
          ..write(')'))
        .toString();
  }
}

class $TemplateItemsTable extends TemplateItems
    with TableInfo<$TemplateItemsTable, TemplateItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES meal_templates (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
    'calories',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<int> protein = GeneratedColumn<int>(
    'protein',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<int> carbs = GeneratedColumn<int>(
    'carbs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<int> fat = GeneratedColumn<int>(
    'fat',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    name,
    calories,
    protein,
    carbs,
    fat,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    }
    if (data.containsKey('carbs')) {
      context.handle(
        _carbsMeta,
        carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta),
      );
    }
    if (data.containsKey('fat')) {
      context.handle(
        _fatMeta,
        fat.isAcceptableOrUnknown(data['fat']!, _fatMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories'],
      ),
      protein: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protein'],
      ),
      carbs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carbs'],
      ),
      fat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fat'],
      ),
    );
  }

  @override
  $TemplateItemsTable createAlias(String alias) {
    return $TemplateItemsTable(attachedDatabase, alias);
  }
}

class TemplateItem extends DataClass implements Insertable<TemplateItem> {
  final int id;
  final int templateId;
  final String name;
  final int? calories;
  final int? protein;
  final int? carbs;
  final int? fat;
  const TemplateItem({
    required this.id,
    required this.templateId,
    required this.name,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template_id'] = Variable<int>(templateId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || calories != null) {
      map['calories'] = Variable<int>(calories);
    }
    if (!nullToAbsent || protein != null) {
      map['protein'] = Variable<int>(protein);
    }
    if (!nullToAbsent || carbs != null) {
      map['carbs'] = Variable<int>(carbs);
    }
    if (!nullToAbsent || fat != null) {
      map['fat'] = Variable<int>(fat);
    }
    return map;
  }

  TemplateItemsCompanion toCompanion(bool nullToAbsent) {
    return TemplateItemsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      name: Value(name),
      calories: calories == null && nullToAbsent
          ? const Value.absent()
          : Value(calories),
      protein: protein == null && nullToAbsent
          ? const Value.absent()
          : Value(protein),
      carbs: carbs == null && nullToAbsent
          ? const Value.absent()
          : Value(carbs),
      fat: fat == null && nullToAbsent ? const Value.absent() : Value(fat),
    );
  }

  factory TemplateItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateItem(
      id: serializer.fromJson<int>(json['id']),
      templateId: serializer.fromJson<int>(json['templateId']),
      name: serializer.fromJson<String>(json['name']),
      calories: serializer.fromJson<int?>(json['calories']),
      protein: serializer.fromJson<int?>(json['protein']),
      carbs: serializer.fromJson<int?>(json['carbs']),
      fat: serializer.fromJson<int?>(json['fat']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateId': serializer.toJson<int>(templateId),
      'name': serializer.toJson<String>(name),
      'calories': serializer.toJson<int?>(calories),
      'protein': serializer.toJson<int?>(protein),
      'carbs': serializer.toJson<int?>(carbs),
      'fat': serializer.toJson<int?>(fat),
    };
  }

  TemplateItem copyWith({
    int? id,
    int? templateId,
    String? name,
    Value<int?> calories = const Value.absent(),
    Value<int?> protein = const Value.absent(),
    Value<int?> carbs = const Value.absent(),
    Value<int?> fat = const Value.absent(),
  }) => TemplateItem(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    name: name ?? this.name,
    calories: calories.present ? calories.value : this.calories,
    protein: protein.present ? protein.value : this.protein,
    carbs: carbs.present ? carbs.value : this.carbs,
    fat: fat.present ? fat.value : this.fat,
  );
  TemplateItem copyWithCompanion(TemplateItemsCompanion data) {
    return TemplateItem(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      name: data.name.present ? data.name.value : this.name,
      calories: data.calories.present ? data.calories.value : this.calories,
      protein: data.protein.present ? data.protein.value : this.protein,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
      fat: data.fat.present ? data.fat.value : this.fat,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateItem(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('name: $name, ')
          ..write('calories: $calories, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, templateId, name, calories, protein, carbs, fat);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateItem &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.name == this.name &&
          other.calories == this.calories &&
          other.protein == this.protein &&
          other.carbs == this.carbs &&
          other.fat == this.fat);
}

class TemplateItemsCompanion extends UpdateCompanion<TemplateItem> {
  final Value<int> id;
  final Value<int> templateId;
  final Value<String> name;
  final Value<int?> calories;
  final Value<int?> protein;
  final Value<int?> carbs;
  final Value<int?> fat;
  const TemplateItemsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.name = const Value.absent(),
    this.calories = const Value.absent(),
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
  });
  TemplateItemsCompanion.insert({
    this.id = const Value.absent(),
    required int templateId,
    required String name,
    this.calories = const Value.absent(),
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
  }) : templateId = Value(templateId),
       name = Value(name);
  static Insertable<TemplateItem> custom({
    Expression<int>? id,
    Expression<int>? templateId,
    Expression<String>? name,
    Expression<int>? calories,
    Expression<int>? protein,
    Expression<int>? carbs,
    Expression<int>? fat,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (name != null) 'name': name,
      if (calories != null) 'calories': calories,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fat != null) 'fat': fat,
    });
  }

  TemplateItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? templateId,
    Value<String>? name,
    Value<int?>? calories,
    Value<int?>? protein,
    Value<int?>? carbs,
    Value<int?>? fat,
  }) {
    return TemplateItemsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (protein.present) {
      map['protein'] = Variable<int>(protein.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<int>(carbs.value);
    }
    if (fat.present) {
      map['fat'] = Variable<int>(fat.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateItemsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('name: $name, ')
          ..write('calories: $calories, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat')
          ..write(')'))
        .toString();
  }
}

class $WeightEntriesTable extends WeightEntries
    with TableInfo<$WeightEntriesTable, WeightEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _measuredAtMeta = const VerificationMeta(
    'measuredAt',
  );
  @override
  late final GeneratedColumn<DateTime> measuredAt = GeneratedColumn<DateTime>(
    'measured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kgMeta = const VerificationMeta('kg');
  @override
  late final GeneratedColumn<double> kg = GeneratedColumn<double>(
    'kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, measuredAt, kg];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('measured_at')) {
      context.handle(
        _measuredAtMeta,
        measuredAt.isAcceptableOrUnknown(data['measured_at']!, _measuredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_measuredAtMeta);
    }
    if (data.containsKey('kg')) {
      context.handle(_kgMeta, kg.isAcceptableOrUnknown(data['kg']!, _kgMeta));
    } else if (isInserting) {
      context.missing(_kgMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeightEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      measuredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}measured_at'],
      )!,
      kg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kg'],
      )!,
    );
  }

  @override
  $WeightEntriesTable createAlias(String alias) {
    return $WeightEntriesTable(attachedDatabase, alias);
  }
}

class WeightEntry extends DataClass implements Insertable<WeightEntry> {
  final int id;
  final DateTime measuredAt;
  final double kg;
  const WeightEntry({
    required this.id,
    required this.measuredAt,
    required this.kg,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['measured_at'] = Variable<DateTime>(measuredAt);
    map['kg'] = Variable<double>(kg);
    return map;
  }

  WeightEntriesCompanion toCompanion(bool nullToAbsent) {
    return WeightEntriesCompanion(
      id: Value(id),
      measuredAt: Value(measuredAt),
      kg: Value(kg),
    );
  }

  factory WeightEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightEntry(
      id: serializer.fromJson<int>(json['id']),
      measuredAt: serializer.fromJson<DateTime>(json['measuredAt']),
      kg: serializer.fromJson<double>(json['kg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'measuredAt': serializer.toJson<DateTime>(measuredAt),
      'kg': serializer.toJson<double>(kg),
    };
  }

  WeightEntry copyWith({int? id, DateTime? measuredAt, double? kg}) =>
      WeightEntry(
        id: id ?? this.id,
        measuredAt: measuredAt ?? this.measuredAt,
        kg: kg ?? this.kg,
      );
  WeightEntry copyWithCompanion(WeightEntriesCompanion data) {
    return WeightEntry(
      id: data.id.present ? data.id.value : this.id,
      measuredAt: data.measuredAt.present
          ? data.measuredAt.value
          : this.measuredAt,
      kg: data.kg.present ? data.kg.value : this.kg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntry(')
          ..write('id: $id, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('kg: $kg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, measuredAt, kg);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightEntry &&
          other.id == this.id &&
          other.measuredAt == this.measuredAt &&
          other.kg == this.kg);
}

class WeightEntriesCompanion extends UpdateCompanion<WeightEntry> {
  final Value<int> id;
  final Value<DateTime> measuredAt;
  final Value<double> kg;
  const WeightEntriesCompanion({
    this.id = const Value.absent(),
    this.measuredAt = const Value.absent(),
    this.kg = const Value.absent(),
  });
  WeightEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime measuredAt,
    required double kg,
  }) : measuredAt = Value(measuredAt),
       kg = Value(kg);
  static Insertable<WeightEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? measuredAt,
    Expression<double>? kg,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (measuredAt != null) 'measured_at': measuredAt,
      if (kg != null) 'kg': kg,
    });
  }

  WeightEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? measuredAt,
    Value<double>? kg,
  }) {
    return WeightEntriesCompanion(
      id: id ?? this.id,
      measuredAt: measuredAt ?? this.measuredAt,
      kg: kg ?? this.kg,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (measuredAt.present) {
      map['measured_at'] = Variable<DateTime>(measuredAt.value);
    }
    if (kg.present) {
      map['kg'] = Variable<double>(kg.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntriesCompanion(')
          ..write('id: $id, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('kg: $kg')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoodEntriesTable foodEntries = $FoodEntriesTable(this);
  late final $SavedFoodsTable savedFoods = $SavedFoodsTable(this);
  late final $MealTemplatesTable mealTemplates = $MealTemplatesTable(this);
  late final $TemplateItemsTable templateItems = $TemplateItemsTable(this);
  late final $WeightEntriesTable weightEntries = $WeightEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    foodEntries,
    savedFoods,
    mealTemplates,
    templateItems,
    weightEntries,
  ];
}

typedef $$FoodEntriesTableCreateCompanionBuilder =
    FoodEntriesCompanion Function({
      Value<int> id,
      required String name,
      required MealType mealType,
      Value<int?> calories,
      Value<String?> notes,
      required DateTime loggedAt,
      Value<Portion?> portion,
      Value<bool> isEstimate,
      Value<int?> protein,
      Value<int?> carbs,
      Value<int?> fat,
    });
typedef $$FoodEntriesTableUpdateCompanionBuilder =
    FoodEntriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<MealType> mealType,
      Value<int?> calories,
      Value<String?> notes,
      Value<DateTime> loggedAt,
      Value<Portion?> portion,
      Value<bool> isEstimate,
      Value<int?> protein,
      Value<int?> carbs,
      Value<int?> fat,
    });

class $$FoodEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MealType, MealType, int> get mealType =>
      $composableBuilder(
        column: $table.mealType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Portion?, Portion, int> get portion =>
      $composableBuilder(
        column: $table.portion,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get portion => $composableBuilder(
    column: $table.portion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MealType, int> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Portion?, int> get portion =>
      $composableBuilder(column: $table.portion, builder: (column) => column);

  GeneratedColumn<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<int> get carbs =>
      $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<int> get fat =>
      $composableBuilder(column: $table.fat, builder: (column) => column);
}

class $$FoodEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodEntriesTable,
          FoodEntry,
          $$FoodEntriesTableFilterComposer,
          $$FoodEntriesTableOrderingComposer,
          $$FoodEntriesTableAnnotationComposer,
          $$FoodEntriesTableCreateCompanionBuilder,
          $$FoodEntriesTableUpdateCompanionBuilder,
          (
            FoodEntry,
            BaseReferences<_$AppDatabase, $FoodEntriesTable, FoodEntry>,
          ),
          FoodEntry,
          PrefetchHooks Function()
        > {
  $$FoodEntriesTableTableManager(_$AppDatabase db, $FoodEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<MealType> mealType = const Value.absent(),
                Value<int?> calories = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<Portion?> portion = const Value.absent(),
                Value<bool> isEstimate = const Value.absent(),
                Value<int?> protein = const Value.absent(),
                Value<int?> carbs = const Value.absent(),
                Value<int?> fat = const Value.absent(),
              }) => FoodEntriesCompanion(
                id: id,
                name: name,
                mealType: mealType,
                calories: calories,
                notes: notes,
                loggedAt: loggedAt,
                portion: portion,
                isEstimate: isEstimate,
                protein: protein,
                carbs: carbs,
                fat: fat,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required MealType mealType,
                Value<int?> calories = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime loggedAt,
                Value<Portion?> portion = const Value.absent(),
                Value<bool> isEstimate = const Value.absent(),
                Value<int?> protein = const Value.absent(),
                Value<int?> carbs = const Value.absent(),
                Value<int?> fat = const Value.absent(),
              }) => FoodEntriesCompanion.insert(
                id: id,
                name: name,
                mealType: mealType,
                calories: calories,
                notes: notes,
                loggedAt: loggedAt,
                portion: portion,
                isEstimate: isEstimate,
                protein: protein,
                carbs: carbs,
                fat: fat,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoodEntriesTable, FoodEntry>(table),
                  BaseReferences<_$AppDatabase, $FoodEntriesTable, FoodEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodEntriesTable,
      FoodEntry,
      $$FoodEntriesTableFilterComposer,
      $$FoodEntriesTableOrderingComposer,
      $$FoodEntriesTableAnnotationComposer,
      $$FoodEntriesTableCreateCompanionBuilder,
      $$FoodEntriesTableUpdateCompanionBuilder,
      (FoodEntry, BaseReferences<_$AppDatabase, $FoodEntriesTable, FoodEntry>),
      FoodEntry,
      PrefetchHooks Function()
    >;
typedef $$SavedFoodsTableCreateCompanionBuilder = SavedFoodsCompanion Function({
  Value<int> id,
  required String name,
  Value<int?> calories,
  Value<bool> isEstimate,
  Value<String?> portionLabel,
  Value<String?> barcode,
  Value<int> useCount,
  required DateTime lastUsedAt,
  Value<int?> protein,
  Value<int?> carbs,
  Value<int?> fat,
});
typedef $$SavedFoodsTableUpdateCompanionBuilder = SavedFoodsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int?> calories,
  Value<bool> isEstimate,
  Value<String?> portionLabel,
  Value<String?> barcode,
  Value<int> useCount,
  Value<DateTime> lastUsedAt,
  Value<int?> protein,
  Value<int?> carbs,
  Value<int?> fat,
});

class $$SavedFoodsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedFoodsTable> {
  $$SavedFoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get portionLabel => $composableBuilder(
    column: $table.portionLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedFoodsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedFoodsTable> {
  $$SavedFoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get portionLabel => $composableBuilder(
    column: $table.portionLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedFoodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedFoodsTable> {
  $$SavedFoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get portionLabel => $composableBuilder(
    column: $table.portionLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<int> get useCount =>
      $composableBuilder(column: $table.useCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<int> get carbs =>
      $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<int> get fat =>
      $composableBuilder(column: $table.fat, builder: (column) => column);
}

class $$SavedFoodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedFoodsTable,
          SavedFood,
          $$SavedFoodsTableFilterComposer,
          $$SavedFoodsTableOrderingComposer,
          $$SavedFoodsTableAnnotationComposer,
          $$SavedFoodsTableCreateCompanionBuilder,
          $$SavedFoodsTableUpdateCompanionBuilder,
          (
            SavedFood,
            BaseReferences<_$AppDatabase, $SavedFoodsTable, SavedFood>,
          ),
          SavedFood,
          PrefetchHooks Function()
        > {
  $$SavedFoodsTableTableManager(_$AppDatabase db, $SavedFoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedFoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedFoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedFoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> calories = const Value.absent(),
                Value<bool> isEstimate = const Value.absent(),
                Value<String?> portionLabel = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
                Value<int?> protein = const Value.absent(),
                Value<int?> carbs = const Value.absent(),
                Value<int?> fat = const Value.absent(),
              }) => SavedFoodsCompanion(
                id: id,
                name: name,
                calories: calories,
                isEstimate: isEstimate,
                portionLabel: portionLabel,
                barcode: barcode,
                useCount: useCount,
                lastUsedAt: lastUsedAt,
                protein: protein,
                carbs: carbs,
                fat: fat,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int?> calories = const Value.absent(),
                Value<bool> isEstimate = const Value.absent(),
                Value<String?> portionLabel = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                required DateTime lastUsedAt,
                Value<int?> protein = const Value.absent(),
                Value<int?> carbs = const Value.absent(),
                Value<int?> fat = const Value.absent(),
              }) => SavedFoodsCompanion.insert(
                id: id,
                name: name,
                calories: calories,
                isEstimate: isEstimate,
                portionLabel: portionLabel,
                barcode: barcode,
                useCount: useCount,
                lastUsedAt: lastUsedAt,
                protein: protein,
                carbs: carbs,
                fat: fat,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedFoodsTable, SavedFood>(table),
                  BaseReferences<_$AppDatabase, $SavedFoodsTable, SavedFood>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedFoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedFoodsTable,
      SavedFood,
      $$SavedFoodsTableFilterComposer,
      $$SavedFoodsTableOrderingComposer,
      $$SavedFoodsTableAnnotationComposer,
      $$SavedFoodsTableCreateCompanionBuilder,
      $$SavedFoodsTableUpdateCompanionBuilder,
      (SavedFood, BaseReferences<_$AppDatabase, $SavedFoodsTable, SavedFood>),
      SavedFood,
      PrefetchHooks Function()
    >;
typedef $$MealTemplatesTableCreateCompanionBuilder =
    MealTemplatesCompanion Function({
      Value<int> id,
      required String name,
      required MealType mealType,
    });
typedef $$MealTemplatesTableUpdateCompanionBuilder =
    MealTemplatesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<MealType> mealType,
    });

final class $$MealTemplatesTableReferences
    extends BaseReferences<_$AppDatabase, $MealTemplatesTable, MealTemplate> {
  $$MealTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TemplateItemsTable, List<TemplateItem>>
  _templateItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.templateItems,
    aliasName: 'meal_templates__id__template_items__template_id',
  );

  $$TemplateItemsTableProcessedTableManager get templateItemsRefs {
    final manager = $$TemplateItemsTableTableManager(
      $_db,
      $_db.templateItems,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_templateItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MealTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $MealTemplatesTable> {
  $$MealTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MealType, MealType, int> get mealType =>
      $composableBuilder(
        column: $table.mealType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> templateItemsRefs(
    Expression<bool> Function($$TemplateItemsTableFilterComposer f) f,
  ) {
    final $$TemplateItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateItems,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateItemsTableFilterComposer(
            $db: $db,
            $table: $db.templateItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MealTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $MealTemplatesTable> {
  $$MealTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealTemplatesTable> {
  $$MealTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MealType, int> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  Expression<T> templateItemsRefs<T extends Object>(
    Expression<T> Function($$TemplateItemsTableAnnotationComposer a) f,
  ) {
    final $$TemplateItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateItems,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.templateItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MealTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealTemplatesTable,
          MealTemplate,
          $$MealTemplatesTableFilterComposer,
          $$MealTemplatesTableOrderingComposer,
          $$MealTemplatesTableAnnotationComposer,
          $$MealTemplatesTableCreateCompanionBuilder,
          $$MealTemplatesTableUpdateCompanionBuilder,
          (MealTemplate, $$MealTemplatesTableReferences),
          MealTemplate,
          PrefetchHooks Function({bool templateItemsRefs})
        > {
  $$MealTemplatesTableTableManager(_$AppDatabase db, $MealTemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<MealType> mealType = const Value.absent(),
          }) => MealTemplatesCompanion(id: id, name: name, mealType: mealType),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required MealType mealType,
              }) => MealTemplatesCompanion.insert(
                id: id,
                name: name,
                mealType: mealType,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealTemplatesTable, MealTemplate>(table),
                  $$MealTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (templateItemsRefs) db.templateItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (templateItemsRefs)
                    await $_getPrefetchedData<
                      MealTemplate,
                      $MealTemplatesTable,
                      TemplateItem
                    >(
                      currentTable: table,
                      referencedTable: $$MealTemplatesTableReferences
                          ._templateItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MealTemplatesTableReferences(
                            db,
                            table,
                            p0,
                          ).templateItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.templateId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MealTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealTemplatesTable,
      MealTemplate,
      $$MealTemplatesTableFilterComposer,
      $$MealTemplatesTableOrderingComposer,
      $$MealTemplatesTableAnnotationComposer,
      $$MealTemplatesTableCreateCompanionBuilder,
      $$MealTemplatesTableUpdateCompanionBuilder,
      (MealTemplate, $$MealTemplatesTableReferences),
      MealTemplate,
      PrefetchHooks Function({bool templateItemsRefs})
    >;
typedef $$TemplateItemsTableCreateCompanionBuilder =
    TemplateItemsCompanion Function({
      Value<int> id,
      required int templateId,
      required String name,
      Value<int?> calories,
      Value<int?> protein,
      Value<int?> carbs,
      Value<int?> fat,
    });
typedef $$TemplateItemsTableUpdateCompanionBuilder =
    TemplateItemsCompanion Function({
      Value<int> id,
      Value<int> templateId,
      Value<String> name,
      Value<int?> calories,
      Value<int?> protein,
      Value<int?> carbs,
      Value<int?> fat,
    });

final class $$TemplateItemsTableReferences
    extends BaseReferences<_$AppDatabase, $TemplateItemsTable, TemplateItem> {
  $$TemplateItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MealTemplatesTable _templateIdTable(_$AppDatabase db) => db
      .mealTemplates
      .createAlias('template_items__template_id__meal_templates__id');

  $$MealTemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<int>('template_id')!;

    final manager = $$MealTemplatesTableTableManager(
      $_db,
      $_db.mealTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TemplateItemsTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateItemsTable> {
  $$TemplateItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnFilters(column),
  );

  $$MealTemplatesTableFilterComposer get templateId {
    final $$MealTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.mealTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.mealTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateItemsTable> {
  $$TemplateItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnOrderings(column),
  );

  $$MealTemplatesTableOrderingComposer get templateId {
    final $$MealTemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.mealTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealTemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.mealTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateItemsTable> {
  $$TemplateItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<int> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<int> get carbs =>
      $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<int> get fat =>
      $composableBuilder(column: $table.fat, builder: (column) => column);

  $$MealTemplatesTableAnnotationComposer get templateId {
    final $$MealTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.mealTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.mealTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplateItemsTable,
          TemplateItem,
          $$TemplateItemsTableFilterComposer,
          $$TemplateItemsTableOrderingComposer,
          $$TemplateItemsTableAnnotationComposer,
          $$TemplateItemsTableCreateCompanionBuilder,
          $$TemplateItemsTableUpdateCompanionBuilder,
          (TemplateItem, $$TemplateItemsTableReferences),
          TemplateItem,
          PrefetchHooks Function({bool templateId})
        > {
  $$TemplateItemsTableTableManager(_$AppDatabase db, $TemplateItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> templateId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> calories = const Value.absent(),
                Value<int?> protein = const Value.absent(),
                Value<int?> carbs = const Value.absent(),
                Value<int?> fat = const Value.absent(),
              }) => TemplateItemsCompanion(
                id: id,
                templateId: templateId,
                name: name,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int templateId,
                required String name,
                Value<int?> calories = const Value.absent(),
                Value<int?> protein = const Value.absent(),
                Value<int?> carbs = const Value.absent(),
                Value<int?> fat = const Value.absent(),
              }) => TemplateItemsCompanion.insert(
                id: id,
                templateId: templateId,
                name: name,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TemplateItemsTable, TemplateItem>(table),
                  $$TemplateItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (templateId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.templateId,
                        referencedTable: $$TemplateItemsTableReferences
                            ._templateIdTable(db),
                        referencedColumn: $$TemplateItemsTableReferences
                            ._templateIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TemplateItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplateItemsTable,
      TemplateItem,
      $$TemplateItemsTableFilterComposer,
      $$TemplateItemsTableOrderingComposer,
      $$TemplateItemsTableAnnotationComposer,
      $$TemplateItemsTableCreateCompanionBuilder,
      $$TemplateItemsTableUpdateCompanionBuilder,
      (TemplateItem, $$TemplateItemsTableReferences),
      TemplateItem,
      PrefetchHooks Function({bool templateId})
    >;
typedef $$WeightEntriesTableCreateCompanionBuilder =
    WeightEntriesCompanion Function({
      Value<int> id,
      required DateTime measuredAt,
      required double kg,
    });
typedef $$WeightEntriesTableUpdateCompanionBuilder =
    WeightEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> measuredAt,
      Value<double> kg,
    });

class $$WeightEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kg => $composableBuilder(
    column: $table.kg,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeightEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kg => $composableBuilder(
    column: $table.kg,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeightEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get kg =>
      $composableBuilder(column: $table.kg, builder: (column) => column);
}

class $$WeightEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightEntriesTable,
          WeightEntry,
          $$WeightEntriesTableFilterComposer,
          $$WeightEntriesTableOrderingComposer,
          $$WeightEntriesTableAnnotationComposer,
          $$WeightEntriesTableCreateCompanionBuilder,
          $$WeightEntriesTableUpdateCompanionBuilder,
          (
            WeightEntry,
            BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntry>,
          ),
          WeightEntry,
          PrefetchHooks Function()
        > {
  $$WeightEntriesTableTableManager(_$AppDatabase db, $WeightEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> measuredAt = const Value.absent(),
            Value<double> kg = const Value.absent(),
          }) => WeightEntriesCompanion(id: id, measuredAt: measuredAt, kg: kg),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime measuredAt,
                required double kg,
              }) => WeightEntriesCompanion.insert(
                id: id,
                measuredAt: measuredAt,
                kg: kg,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WeightEntriesTable, WeightEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $WeightEntriesTable,
                    WeightEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeightEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightEntriesTable,
      WeightEntry,
      $$WeightEntriesTableFilterComposer,
      $$WeightEntriesTableOrderingComposer,
      $$WeightEntriesTableAnnotationComposer,
      $$WeightEntriesTableCreateCompanionBuilder,
      $$WeightEntriesTableUpdateCompanionBuilder,
      (
        WeightEntry,
        BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntry>,
      ),
      WeightEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoodEntriesTableTableManager get foodEntries =>
      $$FoodEntriesTableTableManager(_db, _db.foodEntries);
  $$SavedFoodsTableTableManager get savedFoods =>
      $$SavedFoodsTableTableManager(_db, _db.savedFoods);
  $$MealTemplatesTableTableManager get mealTemplates =>
      $$MealTemplatesTableTableManager(_db, _db.mealTemplates);
  $$TemplateItemsTableTableManager get templateItems =>
      $$TemplateItemsTableTableManager(_db, _db.templateItems);
  $$WeightEntriesTableTableManager get weightEntries =>
      $$WeightEntriesTableTableManager(_db, _db.weightEntries);
}
