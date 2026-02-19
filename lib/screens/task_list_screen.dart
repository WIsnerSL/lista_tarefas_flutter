import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import '../widgets/task_item.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _service = TaskService();
  final TextEditingController _controller = TextEditingController();
  final List<Task> _tasks = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final persisted = await _service.loadPersistedTasks();
      if (!mounted) return;

      if (persisted.isNotEmpty) {
        setState(() {
          _tasks
            ..clear()
            ..addAll(persisted);
          _isLoading = false;
        });
        return;
      }

      final result = await _service.fetchTasks();
      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(result);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final result = await _service.fetchTasks();
      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(result);
      });
      await _service.persistTasks(_tasks);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Não foi possível atualizar: $e');
    }
  }

  Future<void> _loadFromCache() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final persisted = await _service.loadPersistedTasks();
      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(persisted);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTask() async {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      _showSnackBar('Digite uma tarefa antes de adicionar.');
      return;
    }

    try {
      final newTask = await _service.createTask(title);
      if (!mounted) return;
      setState(() {
        _tasks.insert(0, newTask);
      });
      await _service.persistTasks(_tasks);
      _controller.clear();
    } catch (e) {
      _showSnackBar('Erro ao adicionar tarefa: $e');
    }
  }

  Future<void> _removeTask(Task task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;

    setState(() {
      _tasks.removeAt(index);
    });

    try {
      await _service.deleteTask(task.id);
      await _service.persistTasks(_tasks);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tasks.insert(index, task);
      });
      _showSnackBar('Erro ao remover tarefa: $e');
    }
  }

  Future<void> _toggleTask(Task task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;

    setState(() {
      _tasks[index] = task.copyWith(completed: !task.completed);
    });

    try {
      await _service.persistTasks(_tasks);
    } catch (e) {
      _showSnackBar('Erro ao salvar alterações: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Tarefas'),
        centerTitle: true,
        actions: [


        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Nova tarefa',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('Adicionar'),
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _bootstrap,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tasks.isEmpty) {
      return const Center(
        child: Text('Nenhuma tarefa encontrada.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Dismissible(
            key: ValueKey(task.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.redAccent,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => _removeTask(task),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: TaskItem(
                task: task,
                onToggle: () => _toggleTask(task),
              ),
            ),
          );
        },
      ),
    );
  }
}

