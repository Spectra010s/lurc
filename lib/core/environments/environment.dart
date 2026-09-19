class EnvironmentVariable {
  const new({
    required this.key,
    required this.value,
    this.secret = false,
  });

  factory fromJson(Map<String, Object?> json) {
    final key = json['key'];
    final value = json['value'];
    if (key is! String || value is! String) {
      throw const FormatException('Invalid environment variable');
    }
    return EnvironmentVariable(
      key: key,
      value: value,
      secret: json['secret'] == true,
    );
  }

  final String key;
  final String value;
  final bool secret;

  Map<String, Object> toJson() => {
    'key': key,
    'value': value,
    if (secret) 'secret': true,
  };
}

class Environment {
  const new({
    required this.id,
    required this.name,
    this.variables = const [],
  });

  factory fromJson(Map<String, Object?> json) {
    if (json['id'] case final String id when id.isNotEmpty) {
      if (json['name'] case final String name when name.isNotEmpty) {
        final rawVariables = json['variables'];
        final variables = <EnvironmentVariable>[];
        if (rawVariables is List) {
          for (final item in rawVariables) {
            if (item is Map) {
              variables.add(
                EnvironmentVariable.fromJson(Map<String, Object?>.from(item)),
              );
            }
          }
        } else if (rawVariables is Map) {
          // Read the v1 map representation so existing installs migrate safely.
          for (final entry in rawVariables.entries) {
            if (entry.key is String && entry.value is String) {
              variables.add(
                EnvironmentVariable(
                  key: entry.key as String,
                  value: entry.value as String,
                ),
              );
            }
          }
        }
        return Environment(id: id, name: name, variables: variables);
      }
    }
    throw const FormatException('Invalid environment');
  }

  final String id;
  final String name;
  final List<EnvironmentVariable> variables;

  Map<String, String> get resolvedVariables => {
    for (final variable in variables) variable.key: variable.value,
  };

  Environment copyWith({
    String? name,
    List<EnvironmentVariable>? variables,
  }) => Environment(
    id: id,
    name: name ?? this.name,
    variables: variables ?? this.variables,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'variables': variables.map((variable) => variable.toJson()).toList(),
  };
}
