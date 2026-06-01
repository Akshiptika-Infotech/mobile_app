import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/admin/data/calendar_repository.dart';
import 'package:mobile_app/features/admin/domain/calendar_model.dart';

class CalendarState {
  const CalendarState({
    required this.year,
    required this.month,
    this.events = const [],
    this.isLoading = false,
    this.error,
    this.selectedDay,
  });

  final int year;
  final int month;
  final List<CalendarEvent> events;
  final bool isLoading;
  final String? error;
  final int? selectedDay;

  CalendarState copyWith({
    int? year,
    int? month,
    List<CalendarEvent>? events,
    bool? isLoading,
    String? error,
    int? selectedDay,
    bool clearSelectedDay = false,
  }) {
    return CalendarState(
      year: year ?? this.year,
      month: month ?? this.month,
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDay:
          clearSelectedDay ? null : selectedDay ?? this.selectedDay,
    );
  }

  List<CalendarEvent> eventsForDay(int day) {
    final target = DateTime(year, month, day);
    return events.where((e) => e.coversDay(target)).toList();
  }

  List<CalendarEvent> get selectedDayEvents {
    if (selectedDay == null) return [];
    return eventsForDay(selectedDay!);
  }
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier(this._repo)
      : super(CalendarState(
          year: DateTime.now().year,
          month: DateTime.now().month,
          selectedDay: DateTime.now().day,
        )) {
    _load();
  }

  final CalendarRepository _repo;

  Future<void> _load() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      final events = await _repo.fetchEvents(
        month: state.month,
        year: state.year,
      );
      if (!mounted) return;
      state = state.copyWith(events: events, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectDay(int day) {
    if (!mounted) return;
    state = state.copyWith(selectedDay: day);
  }

  void previousMonth() {
    if (!mounted) return;
    final d = DateTime(state.year, state.month - 1);
    state = state.copyWith(
        year: d.year, month: d.month, events: [], clearSelectedDay: true);
    _load();
  }

  void nextMonth() {
    if (!mounted) return;
    final d = DateTime(state.year, state.month + 1);
    state = state.copyWith(
        year: d.year, month: d.month, events: [], clearSelectedDay: true);
    _load();
  }

  void refresh() => _load();

  Future<void> createEvent({
    required String title,
    required String description,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String? classId,
    String? sectionId,
  }) async {
    final fmt = DateFormat('yyyy-MM-dd');
    await _repo.createEvent(
      title: title,
      description: description,
      eventType: type,
      startDate: fmt.format(startDate),
      endDate: fmt.format(endDate),
      classId: classId,
      sectionId: sectionId,
    );
    await _load();
  }

  Future<void> updateEvent({
    required String id,
    required String title,
    required String description,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String? classId,
    String? sectionId,
  }) async {
    final fmt = DateFormat('yyyy-MM-dd');
    await _repo.updateEvent(
      id: id,
      title: title,
      description: description,
      eventType: type,
      startDate: fmt.format(startDate),
      endDate: fmt.format(endDate),
      classId: classId,
      sectionId: sectionId,
    );
    await _load();
  }

  Future<void> deleteEvent(String id) async {
    await _repo.deleteEvent(id);
    await _load();
  }
}

final calendarProvider =
    StateNotifierProvider.autoDispose<CalendarNotifier, CalendarState>(
        (ref) {
  return CalendarNotifier(ref.watch(calendarRepositoryProvider));
});
