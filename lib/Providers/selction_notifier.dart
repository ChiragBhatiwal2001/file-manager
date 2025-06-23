import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectionState {
  final Set<String> selectedPaths;
  final bool isSelectionMode;

  SelectionState({
    this.selectedPaths = const {},
    this.isSelectionMode = false,
  });

  SelectionState copyWith({
    Set<String>? selectedPaths,
    bool? isSelectionMode,
  }) {
    return SelectionState(
      selectedPaths: selectedPaths ?? this.selectedPaths,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }
}

class SelectionNotifier extends StateNotifier<SelectionState> {
  SelectionNotifier() : super(SelectionState());

  void toggleSelection(String path) {
    final selected = Set<String>.from(state.selectedPaths);
    if (selected.contains(path)) {
      selected.remove(path);
    } else {
      selected.add(path);
    }
    state = state.copyWith(
      selectedPaths: selected,
      isSelectionMode: selected.isNotEmpty,
    );
  }

  void clearSelection() {
    state = state.copyWith(selectedPaths: {}, isSelectionMode: false);
  }

  void selectAll(List<String> allPaths) {
    state = state.copyWith(
      selectedPaths: Set<String>.from(allPaths),
      isSelectionMode: allPaths.isNotEmpty,
    );
  }
}

final selectionProvider = StateNotifierProvider<SelectionNotifier, SelectionState>(
      (ref) => SelectionNotifier(),
);