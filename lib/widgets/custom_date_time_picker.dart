import 'package:flutter/material.dart';

class CustomDateTimePicker extends StatefulWidget {
  final DateTime initial;

  const CustomDateTimePicker({
    super.key,
    required this.initial,
  });

  @override
  State<CustomDateTimePicker> createState() => _CustomDateTimePickerState();
}

class _CustomDateTimePickerState extends State<CustomDateTimePicker> {

  late DateTime date;
  int hour = 0;
  int minute = 0;

  final List<int> minutes = [0, 15, 30, 45];

  @override
  void initState() {
    super.initState();
    date = widget.initial;
    hour = widget.initial.hour;
    minute = minutes.contains(widget.initial.minute)
        ? widget.initial.minute
        : minutes.first; // default 0, 15, 30, 45
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale("vi", "VN"),
    );

    if (picked != null) {
      setState(() {
        date = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      title: const Text("Chọn ngày giờ"),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// DATE
          InkWell(
            onTap: pickDate,
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text("${date.day}/${date.month}/${date.year}")
              ],
            ),
          ),

          const SizedBox(height: 24),

          /// TIME
          Row(
            children: [

              /// HOUR
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: hour,
                  decoration: const InputDecoration(labelText: "Giờ"),
                  items: List.generate(24, (i) {
                    return DropdownMenuItem(
                      value: i,
                      child: Text(i.toString().padLeft(2, '0')),
                    );
                  }),
                  onChanged: (v) {
                    setState(() => hour = v!);
                  },
                ),
              ),

              const SizedBox(width: 16),

              /// MINUTE
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: minute,
                  decoration: const InputDecoration(labelText: "Phút"),
                  items: minutes.map((m) {
                    return DropdownMenuItem(
                      value: m,
                      child: Text(m.toString().padLeft(2, '0')),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() => minute = v!);
                  },
                ),
              ),
            ],
          ),
        ],
      ),

      actions: [

        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy"),
        ),

        ElevatedButton(
          onPressed: () {
            final result = DateTime(
              date.year,
              date.month,
              date.day,
              hour,
              minute,
            );

            Navigator.pop(context, result);
          },
          child: const Text("OK"),
        ),
      ],
    );
  }
}