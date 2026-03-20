import 'package:flutter/material.dart';

class AmountKeypad extends StatelessWidget {
  final Function(String) onInput;

  const AmountKeypad({
    super.key,
    required this.onInput,
  });

  Widget buildKey(String value) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onInput(value),
        child: Container(
          height: 60,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRow(List<String> values) {
    return Row(
      children: values.map((v) => buildKey(v)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildRow(["1", "2", "3"]),
        buildRow(["4", "5", "6"]),
        buildRow(["7", "8", "9"]),
        Row(children: [
          buildKey("000"),
          buildKey("0"),
          Expanded(
            child: InkWell(
              onTap: () => onInput("BACKSPACE"),
              child: Container(
                height: 60,
                alignment: Alignment.center,
                child: const Icon(Icons.backspace),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}