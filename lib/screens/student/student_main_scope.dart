import 'package:flutter/material.dart';

/// Доступ к действиям главного экрана студента (смена вкладки, открытие группы).
class StudentMainScope extends InheritedWidget {
  const StudentMainScope({
    super.key,
    required this.openGroupSchedule,
    required super.child,
  });

  final void Function(String groupName) openGroupSchedule;

  static StudentMainScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StudentMainScope>();
  }

  @override
  bool updateShouldNotify(StudentMainScope oldWidget) => false;
}
