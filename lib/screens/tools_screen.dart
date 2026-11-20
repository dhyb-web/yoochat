import 'package:flutter/material.dart';
import 'tools/weather.dart';
import 'tools/exchange.dart';
import 'tools/football.dart';
import 'tools/prayer.dart';
import 'tools/calculator.dart';
import 'tools/notes.dart';
import 'tools/quote.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final tools = <(IconData, String, Widget)>[
      (Icons.wb_sunny_rounded, 'Météo Lomé', const WeatherTool()),
      (Icons.currency_exchange, 'Taux de change', const ExchangeTool()),
      (Icons.sports_soccer, 'Scores foot', const FootballTool()),
      (Icons.mosque_rounded, 'Heures de prière', const PrayerTool()),
      (Icons.calculate_rounded, 'Calculatrice', const CalculatorTool()),
      (Icons.sticky_note_2_rounded, 'Notes rapides', const NotesTool()),
      (Icons.format_quote_rounded, 'Citation du jour', const QuoteTool()),
    ];
    return GridView.count(crossAxisCount: 2, padding: const EdgeInsets.all(12), mainAxisSpacing: 12, crossAxisSpacing: 12,
      children: [for (final t in tools) Card(child: InkWell(borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: Text(t.$2)), body: t.$3))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(t.$1, size: 40, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 10),
          Text(t.$2, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
        ])))]);
  }
}
