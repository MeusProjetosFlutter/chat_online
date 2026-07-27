import 'package:flutter/material.dart';

class TextComposer extends StatefulWidget {
  TextComposer(this.sendMessage, {super.key});
  Function(String) sendMessage;

  @override
  State<TextComposer> createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {
  bool isComposing = false;

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.camera_alt), onPressed: () {}),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (text) => setState(() {
                isComposing = text.isNotEmpty;
              }),
              onSubmitted: (text) {
                //callback que executa a função passada no construtor do widget
                widget.sendMessage(text);
              },
              decoration: const InputDecoration.collapsed(
                hintText: "Enviar uma mensagem",
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: isComposing
                ? () {
                    widget.sendMessage(_controller.text);
                    _controller.clear();
                    setState(() {
                      isComposing = false;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
