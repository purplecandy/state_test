import 'dart:async';

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
  final _scaffold = GlobalKey<ScaffoldState>();
  final _posts = PostState();
  Timer _debouce;
  bool maxReached = false;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    handleFetch();
  }

  void handleFetch() {
    _posts.dispatch(
      PostActions.fetch,
      pre: [FetchPostMiddleWare(_posts.offset, 10)],
      onError: (e) {
        print(e);
        setState(() {
          maxReached = true;
        });
        _scaffold.currentState.showSnackBar(SnackBar(
          content: Text(e.toString()),
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => _posts,
      child: Scaffold(
        key: _scaffold,
        appBar: AppBar(
          title: Text("Infinite Scroll"),
        ),
        body: BlocBuilder<Status, List<Post>, PostState>(
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
                final items = event.object;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) => index >= items.length
                      ? (maxReached ? Container() : BottomLoader())
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
    _debouce.cancel();
    _posts.dispose();
    super.dispose();
  }

  var count = 0;
  void _onScroll() {
    if (!maxReached) if (!_scrollController.position.outOfRange &&
        _scrollController.offset >=
            _scrollController.position.maxScrollExtent) {
      _debouce = Timer(Duration(milliseconds: 500), handleFetch);
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
