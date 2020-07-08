import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:state_test/builders.dart';
import 'package:state_test/infinite_scroll/middlewares.dart';
import 'package:state_test/infinite_scroll/models.dart';
import 'package:state_test/infinite_scroll/state.dart';
import 'package:state_test/utils.dart';
import 'package:state_test/state_manager.dart';

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
    _posts.setDefaultMiddlewares([LoggerMiddleWare()]);
    handleFetch();
    _posts.addWorker(PostActions.retry, apiRequest);
  }

  void apiRequest(Dispatcher put) {
    put(PostActions.result, pre: [FetchPostMiddleWare(0, 10)]);
  }

  void handleFetch() {
    _posts.dispatch(
      PostActions.fetch,
      pre: [
        FetchPostMiddleWare(_posts.offset, 10),
      ],
      onError: (e, stack) {
        print(e);
        print(stack);
        setState(() {
          maxReached = true;
        });
        _scaffold.currentState.showSnackBar(SnackBar(
          content: Text(e.toString()),
        ));
      },
    );
  }

  void retry() {
    _posts.dispatch(PostActions.retry, onError: (e, s) {
      print(e);
      print(s);
    });
  }

  void removeListener() {
    _posts.removeWorker(PostActions.retry, apiRequest);
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => _posts,
      child: Scaffold(
        key: _scaffold,
        appBar: AppBar(
          title: Text("Infinite Scroll"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => retry(),
            ),
            IconButton(
              icon: Icon(Icons.cancel),
              onPressed: () => removeListener(),
            )
          ],
        ),
        body: BlocBuilder<Status, List<Post>, PostState>(
          onError: (context, error, bloc) => Center(
            child: Text(error.toString()),
          ),
          onSuccess: (context, event, bloc) {
            switch (event.status) {
              case Status.idle:
                return Center(
                  child: CircularProgressIndicator(),
                );
                break;
              case Status.loading:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text("Retrying"),
                      SizedBox(height: 10),
                      SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator()),
                    ],
                  ),
                );
                break;
              case Status.success:
                final items = event.data;
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
