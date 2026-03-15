import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:io';
import 'task.dart';
import 'task_item.dart';
import 'database_helper.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkTheme;
  
  const HomeScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _tasks = [];
  final _controller = TextEditingController();
  Timer? _timer;
  int? _selectedPriority;
  bool _showCompleted = true;


  @override
  void initState() {
    super.initState();
    _loadTasks();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await DatabaseHelper.instance.getTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
        });
      }
    } catch (e) {
      print('Ошибка загрузки задач: $e');
    }
  }

  Future<void> _addTask(String text) async {
    if (text.trim().isEmpty) return;
    
    final task = Task(
      title: text.trim(),
      created: DateTime.now(),
      priority: _selectedPriority ?? 3,
    );
    
    try {
      final id = await DatabaseHelper.instance.insertTask(task);
      if (mounted) {
        task.id = id;
        setState(() {
          _tasks.add(task);
        });
        _controller.clear();
      }
    } catch (e) {
      print('Ошибка добавления задачи: $e');
    }
  }

  Future<void> _toggleComplete(int index) async {
    if (index >= _tasks.length) return;
    final task = _tasks[index];
    final updatedTask = task.copyWith(completed: !task.completed);
    
    try {
      await DatabaseHelper.instance.updateTask(updatedTask);
      if (mounted) {
        setState(() {
          _tasks[index] = updatedTask;
        });
      }
    } catch (e) {
      print('Ошибка обновления задачи: $e');
    }
  }

  Future<void> _delete(int index) async {
    if (index >= _tasks.length) return;
    final task = _tasks[index];
    
    try {
      if (task.id != null) {
        await DatabaseHelper.instance.deleteTask(task.id!);
      }
      if (mounted) {
        setState(() {
          _tasks.removeAt(index);
        });
      }
    } catch (e) {
      print('Ошибка удаления задачи: $e');
    }
  }

  Future<void> _changePriority(int index, int priority) async {
    if (index >= _tasks.length) return;
    final task = _tasks[index];
    final updatedTask = task.copyWith(priority: priority);
    
    try {
      await DatabaseHelper.instance.updateTask(updatedTask);
      if (mounted) {
        setState(() {
          _tasks[index] = updatedTask;
        });
      }
    } catch (e) {
      print('Ошибка изменения приоритета: $e');
    }
  }

  List<Task> get _filteredTasks {
    return _tasks.where((task) {
      if (_selectedPriority != null && task.priority != _selectedPriority) {
        return false;
      }
      if (!_showCompleted && task.completed) {
        return false;
      }
      return true;
    }).toList();
  }

  Map<String, int> _getStats() {
    final filtered = _filteredTasks;
    int total = filtered.length;
    int completed = filtered.where((t) => t.completed).length;
    int overdue = filtered.where((t) => 
      !t.completed && 
      t.deadline != null && 
      t.deadline!.isBefore(DateTime.now())
    ).length;
    int onTime = filtered.where((t) => 
      t.completed && 
      t.deadline != null && 
      !t.deadline!.isBefore(DateTime.now())
    ).length;

    Map<int, int> priorityStats = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var task in filtered) {
      priorityStats[task.priority] = (priorityStats[task.priority] ?? 0) + 1;
    }

    return {
      'total': total,
      'completed': completed,
      'overdue': overdue,
      'onTime': onTime,
      'priority1': priorityStats[1]!,
      'priority2': priorityStats[2]!,
      'priority3': priorityStats[3]!,
      'priority4': priorityStats[4]!,
      'priority5': priorityStats[5]!,
    };
  }

  Future<void> _editDeadline(int index) async {
    if (index >= _tasks.length) return;
    final t = _tasks[index];
    int days = t.deadline != null
        ? t.deadline!
            .difference(t.created)
            .inDays
        : 0;
    int hours = t.deadline != null
        ? t.deadline!
            .difference(t.created)
            .inHours % 24
        : 0;
    int minutes = t.deadline != null
        ? t.deadline!
            .difference(t.created)
            .inMinutes % 60
        : 0;

    final dCtrl = TextEditingController(text: days.toString());
    final hCtrl = TextEditingController(text: hours.toString());
    final mCtrl = TextEditingController(text: minutes.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Установить дедлайн'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Дней'),
            ),
            TextField(
              controller: hCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Часов'),
            ),
            TextField(
              controller: mCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Минут'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final newDays = int.tryParse(dCtrl.text) ?? 0;
      final newHours = int.tryParse(hCtrl.text) ?? 0;
      final newMinutes = int.tryParse(mCtrl.text) ?? 0;
      
      final updatedTask = t.copyWith(
        deadline: DateTime.now().add(Duration(
          days: newDays,
          hours: newHours,
          minutes: newMinutes,
        ))
      );
      
      try {
        await DatabaseHelper.instance.updateTask(updatedTask);
        if (mounted) {
          setState(() {
            _tasks[index] = updatedTask;
          });
        }
      } catch (e) {
        print('Ошибка обновления дедлайна: $e');
      }
    }
  }

  void _showStats() {
    final stats = _getStats();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статистика задач'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Общая статистика:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Всего задач: ${stats['total']}'),
              Text('Выполнено: ${stats['completed']}'),
              Text('Просрочено: ${stats['overdue']}'),
              Text('Выполнено вовремя: ${stats['onTime']}'),
              
              const SizedBox(height: 16),
              const Text('По приоритетам:', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildPriorityStatItem('1 - Максимальная', stats['priority1']!, Colors.red),
              _buildPriorityStatItem('2 - Высокая', stats['priority2']!, Colors.orange),
              _buildPriorityStatItem('3 - Средняя', stats['priority3']!, Colors.yellow),
              _buildPriorityStatItem('4 - Низкая', stats['priority4']!, Colors.blue),
              _buildPriorityStatItem('5 - Минимальная', stats['priority5']!, Colors.grey),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityStatItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text('$label: $count'),
      ],
    );
  }

  void _showPriorityFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Фильтр по приоритету',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPriorityFilterButton(null, 'Все'),
                _buildPriorityFilterButton(1, '1'),
                _buildPriorityFilterButton(2, '2'),
                _buildPriorityFilterButton(3, '3'),
                _buildPriorityFilterButton(4, '4'),
                _buildPriorityFilterButton(5, '5'),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            
            SwitchListTile(
              title: const Text('Показывать выполненные'),
              value: _showCompleted,
              onChanged: (value) {
                setState(() {
                  _showCompleted = value;
                });
                Navigator.pop(context);
              },
            ),
            
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedPriority = null;
                  _showCompleted = true;
                });
                Navigator.pop(context);
              },
              child: const Text('Сбросить фильтры'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityFilterButton(int? priority, String label) {
    final bool isSelected = _selectedPriority == priority;
    Color color;
    
    if (priority == null) {
      color = Theme.of(context).primaryColor;
    } else {
      switch (priority) {
        case 1: color = Colors.red; break;
        case 2: color = Colors.orange; break;
        case 3: color = Colors.yellow; break;
        case 4: color = Colors.blue; break;
        case 5: color = Colors.grey; break;
        default: color = Colors.grey;
      }
    }
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      backgroundColor: isSelected ? color.withValues(alpha: 0.3) : Colors.grey[200],
      selectedColor: color.withValues(alpha: 0.5),
      checkmarkColor: Colors.white,
      onSelected: (_) {
        setState(() {
          _selectedPriority = priority;
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _showResetDatabaseDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс базы данных'),
        content: const Text('Вы уверены, что хотите удалить все задачи? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await DatabaseHelper.instance.deleteAllTasks();
                if (mounted) {
                  setState(() {
                    _tasks.clear();
                  });
                }
              } catch (e) {
                print('Ошибка сброса БД: $e');
              }
              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить всё'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatabaseInfo() async {
    try {
      final path = await DatabaseHelper.instance.getDatabasePath();
      final taskCount = _tasks.length;
      
      if (!mounted) return;

      String fileSize = 'Неизвестно';
      try {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.length();
          if (bytes < 1024) {
            fileSize = '$bytes B';
          } else if (bytes < 1024 * 1024) {
            fileSize = '${(bytes / 1024).toStringAsFixed(2)} KB';
          } else {
            fileSize = '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
          }
        } else {
          fileSize = 'Файл будет создан при добавлении задач';
        }
      } catch (e) {
        fileSize = 'Ошибка чтения';
      }

      String platform = 'Неизвестно';
      if (Platform.isWindows) platform = 'Windows';
      else if (Platform.isLinux) platform = 'Linux';
      else if (Platform.isMacOS) platform = 'macOS';
      else if (Platform.isAndroid) platform = 'Android';
      else if (Platform.isIOS) platform = 'iOS';

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Информация о базе данных'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Платформа:', platform),
                  const SizedBox(height: 8),
                  _buildInfoRow('Версия:', '1.0.0'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Всего задач:', '$taskCount'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Размер БД:', fileSize),
                  const SizedBox(height: 16),
                  const Text('Путь к файлу:'),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      path,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Закрыть'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Ошибка получения информации о БД: $e');
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('По делам IT TOP'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showPriorityFilter,
              ),
              if (_selectedPriority != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _selectedPriority.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                        title: const Text('Тёмная тема'),
                        value: widget.isDarkTheme,
                        onChanged: (value) {
                          widget.toggleTheme();
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.analytics),
                        title: const Text('Статистика'),
                        onTap: () {
                          Navigator.pop(context);
                          _showStats();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.filter_list),
                        title: const Text('Фильтр по приоритету'),
                        onTap: () {
                          Navigator.pop(context);
                          _showPriorityFilter();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.storage),
                        title: const Text('Информация о БД'),
                        onTap: () {
                          Navigator.pop(context);
                          _showDatabaseInfo();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_sweep),
                        title: const Text('Сбросить базу данных'),
                        onTap: () {
                          Navigator.pop(context);
                          _showResetDatabaseDialog();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedPriority != null || !_showCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 16, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Активные фильтры: ${_selectedPriority != null ? 'Приоритет $_selectedPriority' : ''}${_selectedPriority != null && !_showCompleted ? ', ' : ''}${!_showCompleted ? 'Без выполненных' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() {
                        _selectedPriority = null;
                        _showCompleted = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет задач',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_selectedPriority != null || !_showCompleted)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedPriority = null;
                                _showCompleted = true;
                              });
                            },
                            child: const Text('Сбросить фильтры'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (_, i) {
                      final task = filteredTasks[i];
                      final originalIndex = _tasks.indexWhere((t) => t.id == task.id);
                      
                      return TaskItem(
                        task: task,
                        onToggle: () => _toggleComplete(originalIndex),
                        onEditDeadline: () => _editDeadline(originalIndex),
                        onDelete: () => _delete(originalIndex),
                        onPriorityChanged: (priority) => _changePriority(originalIndex, priority),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Новая задача...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addTask(_controller.text),
                ),
              ),
              onSubmitted: _addTask,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}