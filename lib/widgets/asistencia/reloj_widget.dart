import 'dart:async';
import 'package:flutter/material.dart';

class RelojWidget extends StatefulWidget {
  const RelojWidget({Key? key}) : super(key: key);

  @override
  State<RelojWidget> createState() => _RelojWidgetState();
}

class _RelojWidgetState extends State<RelojWidget> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hour = time.hour;
    final isAm = hour < 12;
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '${twoDigits(hour12)}:${twoDigits(time.minute)}:${twoDigits(time.second)} ${isAm ? 'AM' : 'PM'}';
  }

  String _formatDate(DateTime date) {
    const meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    
    final diaSemana = dias[date.weekday - 1];
    final mes = meses[date.month - 1];
    
    return '$diaSemana ${date.day} de $mes, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _formatDate(_currentTime),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          _formatTime(_currentTime),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}
