import 'package:flutter/material.dart';

class CalculatorTool extends StatefulWidget {
  const CalculatorTool({super.key});
  @override
  State<CalculatorTool> createState() => _S();
}

class _S extends State<CalculatorTool> {
  String display = '0'; double? acc; String? op; bool fresh = true;
  void _tap(String k) => setState(() {
    if ('0123456789.'.contains(k)) {
      display = fresh ? (k == '.' ? '0.' : k) : display + k; fresh = false;
    } else if (k == 'C') { display = '0'; acc = null; op = null; fresh = true; }
    else {
      final v = double.tryParse(display) ?? 0;
      if (acc != null && op != null && !fresh) {
        acc = switch (op) { '+' => acc! + v, '−' => acc! - v, '×' => acc! * v, '÷' => v == 0 ? 0 : acc! / v, _ => v };
      } else { acc ??= v; }
      display = acc! % 1 == 0 ? acc!.toInt().toString() : acc!.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '');
      op = k == '=' ? null : k; if (k == '=') acc = null; fresh = true;
    }
  });
  @override
  Widget build(BuildContext context) {
    const keys = ['C', '÷', '×', '−', '7', '8', '9', '+', '4', '5', '6', '=', '1', '2', '3', '.', '0'];
    return Column(children: [
      Expanded(child: Container(alignment: Alignment.bottomRight, padding: const EdgeInsets.all(24),
        child: Text(display, style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300)))),
      GridView.count(shrinkWrap: true, crossAxisCount: 4, padding: const EdgeInsets.all(12), mainAxisSpacing: 10, crossAxisSpacing: 10,
        children: [for (final k in keys) FilledButton.tonal(
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          onPressed: () => _tap(k), child: Text(k, style: const TextStyle(fontSize: 26)))]),
    ]);
  }
}
