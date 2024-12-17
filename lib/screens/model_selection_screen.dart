import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ModelSelectionScreen extends StatelessWidget {
  const ModelSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> models = [
      {
        "name": "Gemma",
        "url": "https://f59f-34-135-214-133.ngrok-free.app/predict",
        "icon": Icons.ac_unit,
        "isRagModel": false
      },
      {
        "name": "Sarvam",
        "url": "https://a8a0-34-122-7-125.ngrok-free.app/predict",
        "icon": Icons.cloud,
        "isRagModel": false
      },
      {
        "name": "Llama",
        "url": "https://e029-34-122-88-67.ngrok-free.app/predict",
        "icon": Icons.emoji_nature,
        "isRagModel": false
      },
      {
        "name": "Rag",
        "url": "https://5c00-34-125-215-19.ngrok-free.app/predict/predict",
        "icon": Icons.terrain,
        "isRagModel": true // Mark as RAG model
      },
      {
        "name": "Agriculture",
        "url": "https://d306-34-123-110-33.ngrok-free.app/predict",
        "icon": Icons.grass,
        "isRagModel": false
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF202123),
      appBar: AppBar(
        title: const Text("Select a Model"),
        backgroundColor: const Color(0xFF343541),
      ),
      body: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16.0,
          runSpacing: 16.0,
          children: models.map((model) {
            return Container(
              width: MediaQuery.of(context).size.width * 0.4,
              child: GestureDetector(
                onTap: () {
                  // Pass the selected server URL and isRagModel flag to ChatScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        serverUrl: model['url'],
                        isRagModel: model['isRagModel'],
                      ),
                    ),
                  );
                },
                child: Card(
                  color: const Color(0xFF343541),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(model['icon'], color: Colors.white, size: 50),
                      const SizedBox(height: 16.0),
                      Text(
                        model['name'],
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
