import 'package:flutter_riverpod/flutter_riverpod.dart';

class SampleState {
  const SampleState({
    this.isLoading = false,
    this.items = const [],
    this.error,
  });

  final bool isLoading;
  final List<String> items;
  final String? error;

  SampleState copyWith({
    bool? isLoading,
    List<String>? items,
    String? error,
  }) {
    return SampleState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: error,
    );
  }
}

class SampleNotifier extends Notifier<SampleState> {
  @override
  SampleState build() => const SampleState();

  Future<void> loadSamples() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(
        isLoading: false,
        items: const ['Sample 1', 'Sample 2', 'Sample 3'],
      );
   } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final sampleProvider = NotifierProvider<SampleNotifier, SampleState>(
  SampleNotifier.new,
);
