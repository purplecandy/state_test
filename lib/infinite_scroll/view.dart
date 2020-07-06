import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:state_test/builders.dart';
import 'package:state_test/infinite_scroll/middlewares.dart';
import 'package:state_test/infinite_scroll/models.dart';
import 'package:state_test/infinite_scroll/state.dart';
import 'package:state_test/utils.dart';

class InfiniteScroll extends StatefulWidget {
  @override
  _InfiniteScrollState createState() => _InfiniteScrollState();
}

class _InfiniteScrollState extends State<InfiniteScroll> {
  final _scrollController = ScrollController();
  final _scrollThreshold = 200.0;
  final _posts = PostState();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _posts.dispatch(PostActions.fetch,
        pre: [FetchPostMiddleWare(0, 10)], onError: (e) => print(e));
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => _posts,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Infinite Scroll"),
        ),
        body: BlocBuilder<Status, PostModel, PostState>(
          onError: (context, error, bloc) => Center(
            child: Text(error.toString()),
          ),
          onSuccess: (context, event, bloc) {
            switch (event.state) {
              case Status.idle:
                return Center(
                  child: CircularProgressIndicator(),
                );
                break;
              case Status.success:
                final items = event.object.items;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) => index >= items.length
                      ? BottomLoader()
                      : PostWidget(post: items[index]),
                );
              default:
                // this condition should never reach
                return Container();
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= _scrollThreshold) {
      var offset = _posts.event.object.offset;
      _posts.dispatch(PostActions.fetch, pre: [
        FetchPostMiddleWare(offset + 10, 10),
      ]);
    }
  }
}

class BottomLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Center(
        child: SizedBox(
          width: 33,
          height: 33,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
          ),
        ),
      ),
    );
  }
}

class PostWidget extends StatelessWidget {
  final Post post;

  const PostWidget({Key key, @required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(
        '${post.id}',
        style: TextStyle(fontSize: 10.0),
      ),
      title: Text(post.title),
      isThreeLine: true,
      subtitle: Text(post.body),
      dense: true,
    );
  }
}
