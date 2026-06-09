class Reminder {
  final int id;
  final String name;
  final int intervalMinutes;
  final bool enabled;

  Reminder({
    required this.id,
    required this.name,
    required this.intervalMinutes,
    this.enabled = true,
  });

  Reminder copyWith({String? name, int? intervalMinutes, bool? enabled}) =>
      Reminder(
        id: id,
        name: name ?? this.name,
        intervalMinutes: intervalMinutes ?? this.intervalMinutes,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'intervalMinutes': intervalMinutes,
        'enabled': enabled,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'],
        name: j['name'],
        intervalMinutes: j['intervalMinutes'],
        enabled: j['enabled'] ?? true,
      );
}
