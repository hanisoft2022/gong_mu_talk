import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/life_section.dart';

class LifeSectionCubit extends Cubit<LifeSection> {
  LifeSectionCubit() : super(LifeSection.meetings);

  void setSection(LifeSection section) {
    if (state == section) {
      return;
    }
    emit(section);
  }
}
