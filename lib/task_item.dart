import 'package:flutter/material.dart';
import 'task.dart';

typedef VoidTaskCallback = void Function();
typedef EditDeadlineCallback = void Function();
typedef PriorityCallback = void Function(int priority);

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidTaskCallback onToggle;
  final EditDeadlineCallback onEditDeadline;
  final VoidTaskCallback onDelete;
  final PriorityCallback onPriorityChanged;

  const TaskItem({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEditDeadline,
    required this.onDelete,
    required this.onPriorityChanged,
  });

  String _formatRemaining() {
    if (task.completed || task.deadline == null) return '';
    final diff = task.deadline!.difference(DateTime.now());
    if (diff.isNegative) return 'Просрочено';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    final parts = <String>[];
    if (days > 0) parts.add('$days дн.');
    if (hours > 0) parts.add('$hours ч.');
    if (minutes > 0) parts.add('$minutes мин.');
    parts.add('$seconds сек.');
    return parts.join(' ');
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.yellow;
      case 4: return Colors.blue;
      case 5: return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onDelete,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<int>(
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${task.priority}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text('1 - Максимальная'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Text('2 - Высокая'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 3,
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: Colors.yellow, size: 16),
                      SizedBox(width: 8),
                      Text('3 - Средняя'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 4,
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Text('4 - Низкая'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 5,
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: Colors.grey, size: 16),
                      SizedBox(width: 8),
                      Text('5 - Минимальная'),
                    ],
                  ),
                ),
              ],
              onSelected: onPriorityChanged,
            ),
            const SizedBox(width: 8),
            Checkbox(
              value: task.completed,
              onChanged: (_) => onToggle(),
            ),
          ],
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration:
                task.completed ? TextDecoration.lineThrough : null,
            fontWeight: task.priority <= 2 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(_formatRemaining()),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEditDeadline,
        ),
      ),
    );
  }
}