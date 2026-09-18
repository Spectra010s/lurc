final _variablePattern = RegExp(r'\{\{\s*([\w.-]+)\s*\}\}');

String resolveVariables(String input, Map<String, String> variables) {
  return input.replaceAllMapped(_variablePattern, (match) {
    final name = match.group(1);
    if (name == null) return match.group(0) ?? '';
    return variables[name] ?? match.group(0) ?? '';
  });
}

Map<String, String> resolveVariableMap(
  Map<String, String> input,
  Map<String, String> variables,
) => input.map(
  (key, value) => MapEntry(
    resolveVariables(key, variables),
    resolveVariables(value, variables),
  ),
);
