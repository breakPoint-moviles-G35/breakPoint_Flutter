import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:breakpoint/presentation/faq/viewmodel/faq_viewmodel.dart';

class FaqThreadScreen extends StatefulWidget {
  final String id;

  const FaqThreadScreen({super.key, required this.id});

  @override
  State<FaqThreadScreen> createState() => _FaqThreadScreenState();
}

class _FaqThreadScreenState extends State<FaqThreadScreen> {
  final answerCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<FaqViewModel>().loadThread(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FaqViewModel>();
    final thread = vm.currentThread;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF5FF),
        elevation: 0,
        title: const Text("Pregunta"),
      ),
      body: vm.loading || thread == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Cabecera de la pregunta
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        thread.question,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Respuestas",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Lista de respuestas
                Expanded(
                  child: thread.answers.isEmpty
                      ? const Center(
                          child: Text(
                            "Aún no hay respuestas",
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: thread.answers.length,
                          itemBuilder: (_, i) {
                            final a = thread.answers[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                a.text,
                                style: const TextStyle(fontSize: 15),
                              ),
                            );
                          },
                        ),
                ),

                // Caja de enviar respuesta
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: answerCtrl,
                          decoration: InputDecoration(
                            hintText: "Escribe una respuesta...",
                            filled: true,
                            fillColor: const Color(0xFFF1E7FF),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF5C1B6C),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () async {
                            await vm.submitAnswer(widget.id, answerCtrl.text);
                            answerCtrl.clear();
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
