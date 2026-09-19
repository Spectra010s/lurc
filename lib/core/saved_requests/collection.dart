class Collection {
  const new({required this.id, required this.name, this.parentId});

  factory fromJson(Map<String, dynamic> json) {
    if (json case {'id': final String id, 'name': final String name}) {
      final parentId = json['parentId'];
      if (parentId != null && parentId is! String) {
        throw const FormatException('Invalid collection parent');
      }
      return Collection(id: id, name: name, parentId: parentId as String?);
    }
    throw const FormatException('Invalid collection data');
  }

  final String id;
  final String name;
  final String? parentId;

  Collection copyWith({
    String? name,
    String? parentId,
    bool clearParent = false,
  }) => Collection(
    id: id,
    name: name ?? this.name,
    parentId: clearParent ? null : parentId ?? this.parentId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (parentId != null) 'parentId': parentId,
  };
}
