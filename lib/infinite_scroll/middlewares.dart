import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:state_test/infinite_scroll/models.dart';
import 'package:state_test/middleware.dart';
import 'package:state_test/utils.dart';

class FetchPostMiddleWare extends MiddleWare {
  final int limit, startIndex;
  FetchPostMiddleWare(this.startIndex, this.limit);
  @override
  Future<Reply> run(state, action, props) async {
    /// We are not going to use any `props`,`action`,`state` in this case
    /// Although the startIndex is can also be obtained from `state`
    try {
      if (startIndex == 50)
        return Reply.error(Status.unkown, "Can't fetch anymore items");
      final url =
          'https://jsonplaceholder.typicode.com/posts?_start=$startIndex&_limit=$limit';
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final jsonData = json.decode(resp.body);
        var postList = List<Post>();

        for (var item in jsonData as List) {
          postList.add(Post.fromJson(item));
        }
        print(jsonData.length);
        print(postList.length);
        print("Start $startIndex - Limit $limit");
        return Reply.success(postList);
      } else {
        return Reply.error(Status.error, "API rate limit exceeded");
      }
    } on SocketException catch (e) {
      print(e);
      return Reply.error(
          Status.failed, "Request unsuccessful. Please check your internet");
    } catch (e, stack) {
      print(stack);
      return Reply.error(Status.unkown, e);
    }
  }
}
