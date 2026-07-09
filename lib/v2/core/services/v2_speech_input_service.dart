import 'package:speech_to_text/speech_to_text.dart';

abstract class V2SpeechInputService {
  bool get isListening;

  Future<bool> initialize();

  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
  });

  Future<String> stopListening();
}

class V2SpeechInputServiceImpl implements V2SpeechInputService {
  V2SpeechInputServiceImpl({SpeechToText? speechToText})
      : _speechToText = speechToText ?? SpeechToText();

  final SpeechToText _speechToText;
  String _latestTranscript = '';
  bool _initialized = false;

  @override
  bool get isListening => _speechToText.isListening;

  @override
  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }
    _initialized = await _speechToText.initialize();
    return _initialized;
  }

  @override
  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
  }) async {
    final ready = await initialize();
    if (!ready) {
      onResult('', true);
      return;
    }
    _latestTranscript = '';
    await _speechToText.listen(
      localeId: 'zh_CN',
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.confirmation,
        partialResults: true,
      ),
      onResult: (result) {
        _latestTranscript = result.recognizedWords.trim();
        onResult(_latestTranscript, result.finalResult);
      },
    );
  }

  @override
  Future<String> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    return _latestTranscript.trim();
  }
}
