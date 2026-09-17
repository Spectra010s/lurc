class Collection {
  const new({required this.id, required this.name});

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(id: json['id'] as String, name: json['name'] as String);
  }

  final String id;
  final String name;

  Collection copyWith({String? name}) =>
      Collection(id: id, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
