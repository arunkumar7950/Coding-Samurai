import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  _toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = !isDarkMode;
    });
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do List',
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: TodoListScreen(toggleTheme: _toggleTheme, isDarkMode: isDarkMode),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  TodoListScreen({required this.toggleTheme, required this.isDarkMode});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<String> tasks = [];
  TextEditingController _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedTasks = prefs.getStringList('tasks');
    if (savedTasks != null) {
      setState(() {
        tasks = savedTasks;
      });
    }
  }

  _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tasks', tasks);
  }

  _addTask(String task) async {
    if (task.trim().isEmpty) return;
    setState(() {
      tasks.add(task.trim());
    });
    _saveTasks();
    _taskController.clear();
  }

  _editTask(int index) {
    _taskController.text = tasks[index];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: TextField(
            controller: _taskController,
            decoration: InputDecoration(hintText: "Update task"),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                setState(() {
                  tasks[index] = _taskController.text.trim();
                });
                _saveTasks();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  _removeTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
    _saveTasks();
  }

  _markTaskComplete(int index) {
    setState(() {
      if (!tasks[index].startsWith('✔️')) {
        tasks[index] = '✔️ ${tasks[index]}';
      }
    });
    _saveTasks();
  }

  _clearAllTasks() {
    setState(() {
      tasks.clear();
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
        actions: [
          IconButton(
            icon: Icon(
                widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: InputDecoration(labelText: 'Enter Task'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: Colors.blue),
                  onPressed: () => _addTask(_taskController.text),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child:
                        Text('No tasks yet!', style: TextStyle(fontSize: 18)))
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          title: Text(tasks[index]),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.orange),
                                onPressed: () => _editTask(index),
                              ),
                              IconButton(
                                icon: Icon(Icons.check, color: Colors.green),
                                onPressed: () => _markTaskComplete(index),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeTask(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (tasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _clearAllTasks,
                child: Text('Clear All Tasks'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
