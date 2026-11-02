import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatMessage extends StatelessWidget {
  //final String text;
  final bool isMine;
  final Map<String, dynamic> data;

  const ChatMessage({
    super.key,
    //required this.text,
    this.isMine = false,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMine ? Colors.deepPurple.shade300 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: CircleAvatar(
                radius: 25,
                child: Image.network(
                  data['senderPhotoUrl'] ??
                      'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  data['imageUrl'] != null
                      ? Image.network(data['imageUrl'])
                      : Text(
                          data['text'],
                          //softWrap: true,
                          style: TextStyle(
                            color: isMine ? Colors.white : Colors.black87,
                          ),
                        ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          data['senderName']
                                  .trim()
                                  .split(' ')
                                  .take(2)
                                  .join(' ') ??
                              'Desconhecido"',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Text(
                        data['timestamp'] != null
                            ? DateFormat(
                                'HH:mm',
                              ).format(data['timestamp'].toDate())
                            : " ",
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
