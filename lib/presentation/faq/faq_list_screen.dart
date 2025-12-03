import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:breakpoint/presentation/faq/viewmodel/faq_viewmodel.dart';
import 'package:breakpoint/routes/app_router.dart';

class FaqListScreen extends StatefulWidget {
  const FaqListScreen({super.key});

  @override
  State<FaqListScreen> createState() => _FaqListScreenState();
}

class _FaqListScreenState extends State<FaqListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<FaqViewModel>().loadQuestions();
    });
  }

  void _openCreateQuestionDialog() {
    final titleCtrl = TextEditingController();
    final questionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Nueva pregunta",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: "Título",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: questionCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Pregunta",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C1B6C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await context.read<FaqViewModel>().submitQuestion(
                    titleCtrl.text.trim(),
                    questionCtrl.text.trim(),
                  );
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Enviar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FaqViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF5FF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Preguntas frecuentes",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateQuestionDialog,
        backgroundColor: const Color(0xFF5C1B6C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Preguntar",
    style: TextStyle(color: Colors.white),),
      ),

      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
              ? Center(child: Text("Error: ${vm.error}"))
              : vm.questions.isEmpty
                  ? const Center(
                      child: Text(
                        "No hay preguntas todavía",
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vm.questions.length,
                      itemBuilder: (_, i) {
                        final q = vm.questions[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRouter.faqThread,
                                arguments: q.id,
                              );
                            },
                            title: Text(
                              q.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                q.question,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          ),
                        );
                      },
                    ),
    );
  }
}
