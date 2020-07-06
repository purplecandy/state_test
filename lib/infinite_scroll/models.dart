class Post {
  final int id;
  final String title;
  final String body;

  Post({this.id, this.title, this.body});

  factory Post.fromJson(Map<String, dynamic> json) =>
      Post(id: json["id"], title: json["title"], body: json["body"]);
}

class PostModel {
  final List<Post> items;
  final int offset;
  PostModel({this.items = const [], this.offset = 0});
}
