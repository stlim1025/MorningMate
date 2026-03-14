import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminDatePicker extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const AdminDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<AdminDatePicker> createState() => _AdminDatePickerState();
}

class _AdminDatePickerState extends State<AdminDatePicker> {
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  final GlobalKey _buttonKey = GlobalKey();

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss layer
          GestureDetector(
            onTap: _closeDropdown,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.transparent,
            ),
          ),
          Positioned(
            // 버튼의 우측 끝에 맞추기 위해 x좌표 계산: offset.dx + 버튼너비 - 달력너비(320)
            left: offset.dx + size.width - 320,
            top: offset.dy + size.height + 8,
            width: 320,
            child: Material(
              elevation: 12,
              shadowColor: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF6366F1),
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Color(0xFF1E293B),
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: widget.selectedDate,
                    firstDate: DateTime(2023, 1, 1),
                    lastDate: DateTime.now(),
                    onDateChanged: (date) {
                      widget.onDateSelected(date);
                      _closeDropdown();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy. MM. dd');
    return InkWell(
      key: _buttonKey,
      onTap: _toggleDropdown,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isOpen ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
            width: _isOpen ? 1.5 : 1,
          ),
          boxShadow: _isOpen ? [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: _isOpen ? const Color(0xFF6366F1) : const Color(0xFF64748B),
              size: 16,
            ),
            const SizedBox(width: 10),
            Text(
              dateFormat.format(widget.selectedDate),
              style: TextStyle(
                color: _isOpen ? const Color(0xFF6366F1) : const Color(0xFF334155),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: _isOpen ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
