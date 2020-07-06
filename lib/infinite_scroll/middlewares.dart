import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:state_test/infinite_scroll/models.dart';
import 'package:state_test/middleware.dart';
import 'package:state_test/utils.dart';

class FetchPostMiddleWare extends MiddleWare {
  final int limit, startIndex;
  FetchPostMiddleWare(this.startIndex, this.limit);
  @override
  Future<Reply> run(props) async {
    /// We are not going to use any props in this case
    try {
      final url =
          'https://jsonplaceholder.typicode.com/posts?_start=$startIndex&_limit=$limit';
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final jsonData = json.decode(resp.body);
        var postList = List<Post>();
        for (var item in jsonData as List) {
          postList.add(Post.fromJson(item));
        }
        return Reply.success(PostModel(items: postList, offset: startIndex));
      } else {
        throw Exception("Request unsuccessful. Please check your internet");
      }
    } catch (e, stack) {
      print(stack);
      return Reply.error(Status.unkown, e);
    }
  }
}
