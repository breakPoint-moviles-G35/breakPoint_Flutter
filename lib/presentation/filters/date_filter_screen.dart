import 'package:flutter/material.dart';

class DateFilterScreen extends StatefulWidget {
  const DateFilterScreen({super.key});

  @override
  State<DateFilterScreen> createState() => _DateFilterScreenState();
}

class _DateFilterScreenState extends State<DateFilterScreen> {
  DateTime? start, end;

  DateTime get _today => DateTime.now();
  DateTime _monthStart(DateTime d) => DateTime(d.year, d.month, 1);
  DateTime _nextMonth(DateTime d)  => DateTime(d.year, d.month + 1, 1);

  void _pick(DateTime day) {
    setState(() {
      final d = DateTime(day.year, day.month, day.day);
      if (start == null || (start != null && end != null)) {
        start = d; end = null;
      } else {
        if (d.isBefore(start!)) { end = start; start = d; }
        else { end = d; }
      }
    });
  }

  String _monthName(int m) => const [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ][m-1];

  @override
  Widget build(BuildContext context) {
    final thisMonth = _monthStart(_today);
    final nextMonth = _nextMonth(thisMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccione el rango de fechas'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          // Calendario mes actual
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CalendarDatePicker(
              initialDate: start ?? _today,
              firstDate: DateTime(2020, 1, 1),
              lastDate:  DateTime(2030, 12, 31),
              currentDate: thisMonth,
              onDateChanged: _pick,
            ),
          ),
          // Título mes siguiente
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              '${_monthName(nextMonth.month)} ${nextMonth.year}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          // Calendario mes siguiente
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CalendarDatePicker(
              initialDate: end ?? nextMonth,
              firstDate: DateTime(2020, 1, 1),
              lastDate:  DateTime(2030, 12, 31),
              currentDate: nextMonth,
              onDateChanged: _pick,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5C1B6C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: (start == null || end == null)
                ? null
                : () {
                    Navigator.pop(context, DateTimeRange(start: start!, end: end!));
                  },
            child: const Text('Aplicar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
// USO DE ESTE WIDGET EN explore_screen.dart