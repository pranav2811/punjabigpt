import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ModelSelectionScreen extends StatelessWidget {
  const ModelSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> models = [
      {
        "name": "Gemma",
        "url": "https://5c00-34-125-215-19.ngrok-free.app/predict",
        "icon": Icons.ac_unit
      },
      {
        "name": "Sarvam",
        "url": "https://5c00-34-125-215-19.ngrok-free.app/predict",
        "icon": Icons.cloud
      },
      {
        "name": "Llama",
        "url": "https://5c00-34-125-215-19.ngrok-free.app/predict",
        "icon": Icons.emoji_nature
      },
      {
        "name": "Rag",
        "url": "https://5c00-34-125-215-19.ngrok-free.app/predict",
        "icon": Icons.terrain
      },
      {
        "name": "Agriculture",
        "url": "https://5c00-34-125-215-19.ngrok-free.app/predict",
        "icon": Icons.grass
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
          children: models.asMap().entries.map((entry) {
            final index = entry.key;
            final model = entry.value;

            // Check if this is the last item (Agriculture)
            final bool isLastItem = index == models.length - 1;

            return Container(
              width: isLastItem
                  ? MediaQuery.of(context).size.width *
                      0.6 // Center Agriculture
                  : MediaQuery.of(context).size.width * 0.4, // Normal icons
              child: GestureDetector(
                onTap: () {
                  // Navigate to the ChatScreen and pass the selected server URL
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(serverUrl: model['url']),
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
