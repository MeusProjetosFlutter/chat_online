import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TextComposer extends StatefulWidget {
  const TextComposer(this.sendMessage, {super.key});
  final Function({XFile? image, String? text}) sendMessage;

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
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.deepPurple),
            onPressed: () async {
              final picker = ImagePicker();
              XFile? image = await picker.pickImage(source: ImageSource.camera);
              if (image != null) {
                widget.sendMessage(image: image);
              }
            },
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (text) => setState(() {
                isComposing = text.isNotEmpty;
              }),
              onSubmitted: (text) {
                //callback que executa a função passada no construtor do widget
                widget.sendMessage(text: text);
              },
              decoration: const InputDecoration.collapsed(
                hintText: "Enviar uma mensagem",
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: isComposing ? Colors.deepPurple : Colors.grey,
            ),
            onPressed: isComposing
                ? () {
                    widget.sendMessage(text: _controller.text);
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
