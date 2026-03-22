import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/gemini_service.dart';

class ApiTestScreen extends ConsumerStatefulWidget {
  const ApiTestScreen({super.key});

  @override
  ConsumerState<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends ConsumerState<ApiTestScreen> {
  String _status = "Press button to test API";
  bool _isLoading = false;

  Future<void> _testApi() async {
    setState(() {
      _isLoading = true;
      _status = "Testing Gemini API...";
    });

    try {
      final gemini = ref.read(geminiServiceProvider);
      final response = await gemini.chatWithAI(
        contextString: "User is testing the API. High height, healthy weight.",
        userMessage: "Hello AI, are you working? Please respond with a short greeting.",
        language: "English",
      );

      setState(() {
        _status = "SUCCESS!\n\nAI Response: $response";
      });
    } catch (e) {
      setState(() {
        _status = "FAILED!\n\nError: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gemini API Test")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _testApi,
                  icon: const Icon(Icons.bolt),
                  label: const Text("Run API Test"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
