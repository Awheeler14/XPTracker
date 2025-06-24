import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xp_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';


// To select dates on the edit entry page
class StartEndDates extends StatefulWidget {
  final String? startDate;
  final String? endDate;
  final Function(String?)? onStartDateChanged;
  final Function(String?)? onEndDateChanged;

  const StartEndDates({
    super.key,
    this.startDate,
    this.endDate,
    this.onStartDateChanged,
    this.onEndDateChanged,
  });

  @override
  StartEndDatesState createState() => StartEndDatesState();
}

class StartEndDatesState extends State<StartEndDates> {
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;

  // Tracks if date is selected
  bool _startDateSelected = false;
  bool _endDateSelected = false;

  @override
  void initState() {
    super.initState();
    // Check if entry already has dates and set values accodingly
    _startDateController = TextEditingController(text: widget.startDate ?? '');
    _endDateController = TextEditingController(text: widget.endDate ?? '');
    
    _startDateSelected = widget.startDate?.isNotEmpty ?? false;
    _endDateSelected = widget.endDate?.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  // Date picker 
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    DateTime initialDate = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: isDarkMode
              ? ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: const Color(0xFF73C954),
                    onPrimary: Colors.black,
                    surface: const Color(0xFF403C3D),
                    onSurface: Colors.white,
                  ),
                  dialogBackgroundColor: const Color(0xFF403C3D),
                )
              : ThemeData.light().copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Colors.green.shade700,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
                  dialogBackgroundColor: Colors.white,
                ),
          child: child!,
        );
      },
    );

    // Update UI if date picked
    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        if (isStartDate) {
          _startDateController.text = formattedDate;
          _startDateSelected = true;
          widget.onStartDateChanged?.call(formattedDate);
        } else {
          _endDateController.text = formattedDate;
          _endDateSelected = true;
          widget.onEndDateChanged?.call(formattedDate);
        }
      });
    }
  }

  // Builds the date fields 
  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required bool isStartDate,
    required bool isDateSelected,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context);
    final textColor = isDarkMode.isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode.isDarkMode ? Colors.white70 : Colors.black87;

    return Stack(
      children: [
        IgnorePointer(
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: textColor,
              fontSize: isDateSelected ? 18 : 24,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: textColor, fontSize: 18),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: subTextColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: subTextColor, width: 2),
              ),
            ),
            readOnly: true,
          ),
        ),
        Positioned(
          right: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: const Offset(0, 8),
                child: IconButton(
                  icon: Icon(Icons.calendar_today, color: subTextColor),
                  onPressed: () => _selectDate(context, isStartDate),
                ),
              ),
              if (controller.text.isNotEmpty)
                Transform.translate(
                  offset: const Offset(0, 8),
                  child: IconButton(
                    icon: Icon(Icons.clear, color: subTextColor),
                    onPressed: () {
                      setState(() {
                        controller.clear();
                        if (isStartDate) {
                          _startDateSelected = false;
                          widget.onStartDateChanged?.call(null);
                        } else {
                          _endDateSelected = false;
                          widget.onEndDateChanged?.call(null);
                        }
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Date fields on edit page
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 75.0),
      child: Column(
        children: [
          _buildDateField(
            label: 'Start Date',
            controller: _startDateController,
            isStartDate: true,
            isDateSelected: _startDateSelected,
          ),
          const SizedBox(height: 16),
          _buildDateField(
            label: 'End Date',
            controller: _endDateController,
            isStartDate: false,
            isDateSelected: _endDateSelected,
          ),
        ],
      ),
    );
  }
}
