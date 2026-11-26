import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const TasksApp());
}

class TasksApp extends StatelessWidget {
  const TasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de tarefas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const TasksPage(),
    );
  }
}

class Task {
  Task({required this.title, this.isCompleted = false});

  final String title;
  bool isCompleted;

  Map<String, dynamic> toJson() {
    return {'title': title, 'isCompleted': isCompleted};
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool,
    );
  }
}

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final List<Task> _tasks = [];
  final TextEditingController _taskController = TextEditingController();

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static const String _tasksKey = 'tasks';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final String? tasksJson = await _preferences.getString(_tasksKey);

      if (tasksJson != null) {
        final List<dynamic> decodedTasks =
            jsonDecode(tasksJson) as List<dynamic>;

        final loadedTasks = decodedTasks
            .map((item) => Task.fromJson(item as Map<String, dynamic>))
            .toList();

        if (!mounted) return;

        setState(() {
          _tasks
            ..clear()
            ..addAll(loadedTasks);
        });
      }
    } catch (error) {
      debugPrint('Erro ao carregar tarefas: $error');
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveTasks() async {
    final String tasksJson = jsonEncode(
      _tasks.map((task) => task.toJson()).toList(),
    );

    await _preferences.setString(_tasksKey, tasksJson);
  }

  Future<void> _addTask() async {
    final title = _taskController.text.trim();

    if (title.isEmpty) return;

    setState(() {
      _tasks.add(Task(title: title));
      _taskController.clear();
    });

    await _saveTasks();
  }

  Future<void> _toggleTask(int index, bool? value) async {
    setState(() {
      _tasks[index].isCompleted = value ?? false;
    });

    await _saveTasks();
  }

  Future<void> _removeTask(int index) async {
    setState(() {
      _tasks.removeAt(index);
    });

    await _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('As minhas tarefas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      labelText: 'Nova tarefa',
                      hintText: 'Escreva uma tarefa',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add),
                  tooltip: 'Adicionar tarefa',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _tasks.isEmpty
                  ? const Center(child: Text('Ainda não existem tarefas.'))
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: task.isCompleted,
                                  onChanged: (value) {
                                    _toggleTask(index, value);
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Remover tarefa',
                                  onPressed: () {
                                    _removeTask(index);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}
