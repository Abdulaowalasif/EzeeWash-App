import 'package:equatable/equatable.dart';

class OrderTimelineStep extends Equatable {
  final String title;
  final String? description;
  final DateTime? eventTime;
  final bool isDone;
  final int stepOrder;

  const OrderTimelineStep({
    required this.title,
    this.description,
    this.eventTime,
    required this.isDone,
    required this.stepOrder,
  });

  @override
  List<Object?> get props => [title, isDone, stepOrder];
}
