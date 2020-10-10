class Todo {
  final int id;
  final String name;
  Todo({this.id, this.name});
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      name: json['name'],
    );
  }
}