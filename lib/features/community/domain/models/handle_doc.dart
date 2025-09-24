class HandleDoc {
  const HandleDoc({required this.handle, required this.uid});

  final String handle;
  final String uid;

  HandleDoc copyWith({String? uid}) => HandleDoc(handle: handle, uid: uid ?? this.uid);

  Map<String, Object?> toJson() => <String, Object?>{'uid': uid};

  static HandleDoc fromJson(String handle, Map<String, Object?> json) => HandleDoc(
        handle: handle,
        uid: (json['uid'] as String?) ?? '',
      );
}


