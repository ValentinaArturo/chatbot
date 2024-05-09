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
    _teledart.onMessage(keyword: 'Hola').listen((message) {
      _sendMessage('¡Hola! ¿En qué puedo ayudarte?');
    });

    _teledart.onMessage(keyword: 'Adios').listen((message) {
      _sendMessage('¡Hasta luego! Que tengas un buen día.');
    });

    _teledart.onMessage(keyword: 'Ayuda').listen((message) {
      _sendMessage('¡Claro! ¿En qué necesitas ayuda?');
    });
    _teledart.onMessage(keyword: 'Gracias').listen((message) {
      _sendMessage('Es un placer ayudarte. :)');
    });
    _listenToMessages();
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
