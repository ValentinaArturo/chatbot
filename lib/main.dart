import 'package:flutter/material.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';

void main() {
  runApp(const ChatScreen());
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //https://api.telegram.org/bot7041606750:AAEREszYtAq9kKkU06v3VkBjPUcwVN9_NXg/sendMessage?chat_id=5849378547&text=mensaje
  final String token = '7041606750:AAEREszYtAq9kKkU06v3VkBjPUcwVN9_NXg';
  final String userName = '5849378547';
  late TeleDart _teledart;
  List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  List<String> symptoms = [];

  @override
  void initState() {
    super.initState();
    _initBot();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Screen',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.deepPurple.withOpacity(0.8),
        appBar: AppBar(
          title: const Text('TinaluBot'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  final message = _messages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: Align(
                      alignment: message.isSentByMe
                          ? Alignment.topRight
                          : Alignment.topLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: message.isSentByMe
                              ? Colors.blueGrey[600]
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          message.text,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: BottomAppBar(
          color: Colors.grey[900],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    onSubmitted: (String message) {
                      _sendMessage(message);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    _sendMessage(
                      _controller.text,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isSentByMe: true,
      ));
    });
    _teledart.sendMessage(userName, message);
    setState(() {
      _controller.text = '';
    });
    // Envía el mensaje al bot
  }

  void _initBot() async {
    final telegram = Telegram(token);
    final username = (await telegram.getMe()).username;
    _teledart = TeleDart(token, Event(username!));
    _teledart.start();

    bool isFirstMessage = true;

    _teledart.onMessage().listen((message) {
      final text = message.text!.toLowerCase();
      bool requestingSymptoms = true;

      if (isFirstMessage) {
        _sendMessage('Hola soy TinaluBot, puedo ayudarte a detectar tu enfermedad, escribe tus 3 sintomas principales');
        isFirstMessage = false;
        return;
      }

      if (requestingSymptoms) {
        if (symptoms.length < 2) {
          String newSymptom = text.trim();
          if (newSymptom.isNotEmpty) {
            setState(() {
              symptoms.add(newSymptom);
              newSymptom = '';
            });
          }
          _sendMessage('Por favor, proporciona al menos ${3 - symptoms.length} síntomas más.');
          print(symptoms.length);
        } else {
          _sendMessage('Has proporcionado suficientes síntomas. Ahora voy a determinar tu enfermedad.');
          requestingSymptoms = false;
          _determineDisease(symptoms);
        }
      }
      _listenToMessages();
    });
  }

  void _determineDisease(List<String> symptoms) {

    final Map<String, List<String>> diseases = {
      'Gripe': ['dolor de cabeza', 'fiebre', 'dolor muscular'],
      'Resfriado común': ['congestión nasal', 'estornudos', 'garganta irritada'],
      'Alergias': ['picazón en los ojos', 'estornudos frecuentes', 'nariz que moquea'],
    };

    String? matchedDisease;
    for (final entry in diseases.entries) {
      final diseaseSymptoms = entry.value;
      if (symptoms.every((symptom) => diseaseSymptoms.contains(symptom))) {
        matchedDisease = entry.key;
        break;
      }
    }

    if (matchedDisease != null) {
      _sendMessage('Basado en los síntomas proporcionados, parece que podrías tener $matchedDisease.');
    } else {
      _sendMessage('Lo siento, no pude determinar la enfermedad en base a los síntomas proporcionados.');
    }
  }

  void _listenToMessages() {
    _teledart.onMessage().listen((message) {
      setState(() {
        _messages.add(ChatMessage(
          text: message.text!,
          isSentByMe: false,
        ));
      });
    });
  }
}

class ChatMessage {
  final String text;
  final bool isSentByMe;

  ChatMessage({
    required this.text,
    required this.isSentByMe,
  });
}
