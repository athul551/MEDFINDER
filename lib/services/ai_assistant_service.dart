import 'package:cloud_functions/cloud_functions.dart';

import 'firestore_service.dart';

class AIAssistantService {
  AIAssistantService({FirestoreService? firestoreService});

  Future<String> answerQuestion(String question, {List<Map<String, String>> history = const []}) async {
    final prompt = question.trim();
    if (prompt.isEmpty) {
      return 'Ask Jasper a question such as "Where can I find Dolo 650?" or "Which pharmacy near me has insulin?"';
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('askJasper');
      final result = await callable.call(<String, dynamic>{
        'question': prompt,
        'history': history,
      });

      final data = result.data as Map<String, dynamic>? ?? {};
      final answer = data['answer'] as String?;

      if (answer != null && answer.trim().isNotEmpty) {
        return answer.trim();
      }

      return 'Jasper could not answer right now, please try again.';
    } catch (error) {
      return 'Jasper could not answer right now, please try again.';
    }
  }
}
