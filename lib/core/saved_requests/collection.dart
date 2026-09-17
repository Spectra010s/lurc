class Collection {
  const new({required this.id, required this.name});

  factory fromJson(Map<String, dynamic> json) {
    if (json case {'id': final String id, 'name': final String name}) {
      return Collection(id: id, name: name);
    }
    throw const FormatException('Invalid collection data');
  }

  final String id;
  final String name;

  Collection copyWith({String? name}) =>
      Collection(id: id, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
