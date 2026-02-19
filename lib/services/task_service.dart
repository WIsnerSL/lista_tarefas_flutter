import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class TaskService {
  static const _baseUrl = 'https://jsonplaceholder.typicode.com/todos';
  static const _storageKey = 'saved_tasks';

  final http.Client _client;

  TaskService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Task>> fetchTasks({int limit = 5}) async {
    final normalized = _normalTaskTitles();

    try {
      final response = await _client.get(Uri.parse('$_baseUrl?_limit=$limit'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final tasks = data
            .map((item) => Task.fromJson(item as Map<String, dynamic>))
            .toList();

        final normalizedTasks = List.generate(tasks.length, (index) {
          final task = tasks[index];
          return task.copyWith(title: normalized[index]);
        });

        await persistTasks(normalizedTasks);
        return normalizedTasks;
      }
    } catch (_) {
      // Tenta cache local abaixo.
    }

    final persisted = await loadPersistedTasks();
    if (persisted.isNotEmpty) {
      return persisted;
    }

    final mock = _mockTasks(limit: limit);
    await persistTasks(mock);
    return mock;
  }

  Future<Task> createTask(String title) async {
    final body = {
      'title': title,
      'completed': false,
      'userId': 1,
    };

    try {
      final response = await _client.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Task(
          id: DateTime.now().millisecondsSinceEpoch,
          title: data['title'] as String? ?? title,
          completed: data['completed'] as bool? ?? false,
        );
      }
    } catch (_) {}

    return Task(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      completed: false,
    );
  }


  Future<void> deleteTask(int id) async {
    try {
      final response = await _client.delete(Uri.parse('$_baseUrl/$id'));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Falha ao remover tarefa. Código ${response.statusCode}');
      }
    } catch (_) {
      // DELETE fake: em modo offline/local, consideramos removido com sucesso.
    }
  }

  Future<void> persistTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = tasks.map((task) => task.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(encoded));
  }

  Future<List<Task>> loadPersistedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Task.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  List<String> _normalTaskTitles() {
    return const [
      'Estudar Flutter básico',
      'Criar tela de lista de tarefas',
      'Adicionar nova tarefa pelo formulário',
      'Marcar tarefa como concluída',
      'Remover tarefa com swipe',
    ];
  }

  List<Task> _mockTasks({required int limit}) {
    final tarefas = <Task>[
      Task(id: 1, title: 'Estudar Flutter básico', completed: true),
      Task(id: 2, title: 'Criar tela de lista de tarefas', completed: false),
      Task(id: 3, title: 'Adicionar nova tarefa pelo formulário', completed: true),
      Task(id: 4, title: 'Marcar tarefa como concluída', completed: false),
      Task(id: 5, title: 'Remover tarefa com swipe', completed: false),
    ];

    return tarefas.take(limit).toList();
  }
}