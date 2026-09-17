class Environment {
  const new({
    required this.id,
    required this.name,
    this.variables = const {},
  });

  final String id;
  final String name;
  final Map<String, String> variables;

  Environment copyWith({
    String? name,
    Map<String, String>? variables,
  }) => Environment(
    id: id,
    name: name ?? this.name,
    variables: variables ?? this.variables,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'variables': variables,
  };

  factory Environment.fromJson(Map<String, Object?> json) {
    final rawVariables = json['variables'];
    if (json['id'] case final String id when id.isNotEmpty) {
      if (json['name'] case final String name when name.isNotEmpty) {
        final variables = <String, String>{};
        if (rawVariables is Map) {
          for (final entry in rawVariables.entries) {
            if (entry.key is String && entry.value is String) {
              variables[entry.key as String] = entry.value as String;
            }
          }
        }
        return Environment(id: id, name: name, variables: variables);
      }
    }
    throw const FormatException('Invalid environment');
  }
}
