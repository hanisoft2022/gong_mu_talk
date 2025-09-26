import 'package:equatable/equatable.dart';

class AnnualSalary extends Equatable {
  const AnnualSalary({
    required this.year,
    required this.gross,
    required this.net,
  });

  final int year;
  final double gross;
  final double net;

  @override
  List<Object?> get props => <Object?>[year, gross, net];
}
