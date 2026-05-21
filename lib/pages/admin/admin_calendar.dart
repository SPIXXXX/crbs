part of 'admin_page.dart';

class _AdminCalendar extends StatefulWidget {
  const _AdminCalendar({required this.bookings});

  final List<_RentalBooking> bookings;

  @override
  State<_AdminCalendar> createState() => _AdminCalendarState();
}

class _AdminCalendarState extends State<_AdminCalendar> {
  DateTime _focused = DateTime.now();

  void _prevMonth() {
    setState(() => _focused = DateTime(_focused.year, _focused.month - 1, 1));
  }

  void _nextMonth() {
    setState(() => _focused = DateTime(_focused.year, _focused.month + 1, 1));
  }

  void _showBookingsForDay(BuildContext context, int day) {
    final year = _focused.year;
    final month = _focused.month;
    final date = DateTime(year, month, day);
    final entries = widget.bookings.where((b) {
      if (b.createdSort <= 0) return false;
      final dt = DateTime.fromMillisecondsSinceEpoch(b.createdSort).toLocal();
      return dt.year == date.year &&
          dt.month == date.month &&
          dt.day == date.day;
    }).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bookings for ${_monthName(month)} $day, $year',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No bookings for this day.'),
                  )
                else
                  ...entries.map((b) {
                    final dt = DateTime.fromMillisecondsSinceEpoch(
                      b.createdSort,
                    ).toLocal();
                    final time =
                        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(b.vehicleName),
                      subtitle: Text('${b.pickupLocation} • $time'),
                      trailing: Text(_money(b.totalFee)),
                    );
                  }),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final year = _focused.year;
    final month = _focused.month;
    final first = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = first.weekday % 7; // make Sunday = 0

    // group bookings by date (local)
    final Map<int, int> counts = {};
    for (final b in widget.bookings) {
      if (b.createdSort <= 0) continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(b.createdSort).toLocal();
      if (dt.year == year && dt.month == month) {
        counts[dt.day] = (counts[dt.day] ?? 0) + 1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_monthName(month)} $year',
                  style: const TextStyle(
                    color: _text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildWeekDaysRow(),
          const SizedBox(height: 8),
          _buildDaysGrid(startWeekday, daysInMonth, counts),
        ],
      ),
    );
  }

  Widget _buildWeekDaysRow() {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: labels
          .map(
            (l) => Expanded(
              child: Center(
                child: Text(
                  l,
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDaysGrid(
    int startWeekday,
    int daysInMonth,
    Map<int, int> counts,
  ) {
    final totalCells = startWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (r) {
        return Row(
          children: List.generate(7, (c) {
            final idx = r * 7 + c;
            final dayNum = idx - startWeekday + 1;
            final hasDay = dayNum >= 1 && dayNum <= daysInMonth;
            final count = hasDay ? (counts[dayNum] ?? 0) : 0;
            final isToday =
                hasDay &&
                DateTime.now().year == _focused.year &&
                DateTime.now().month == _focused.month &&
                DateTime.now().day == dayNum;

            return Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: hasDay
                        ? () => _showBookingsForDay(context, dayNum)
                        : null,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isToday ? _soft : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                hasDay ? '$dayNum' : '',
                                style: TextStyle(
                                  color: hasDay ? _text : _muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          if (count > 0)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  count > 1 ? '$count' : '1',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}
