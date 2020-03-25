import 'dart:math';

import 'package:flutter/material.dart';
import 'package:state_test/long_bloc.dart';
import 'package:state_test/n_bloc.dart';

class LongList extends StatefulWidget {
  LongList({Key key}) : super(key: key);

  @override
  _LongListState createState() => _LongListState();
}

class _LongListState extends State<LongList> {
  final LongBloc longBloc = LongBloc();
  final SelectItemBloc selectItemBloc = SelectItemBloc();
  @override
  Widget build(BuildContext context) {
    return CrossAccessedBloc<LongBloc>(
      uniqueKey: "longBloc",
      bloc: longBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Long List"),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.gesture),
                onPressed: () {
                  // BlocChangeNotifier.notifyWidgetWithKey<LongBloc>(context,
                  //     "longBloc", {"action_state": ActionState.getAll});
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => NotifyTest()));
                })
          ],
        ),
        body: SingleBlocProvider(
          bloc: selectItemBloc,
          child: Container(
            child: StreamBuilder<SubState<LongState, List<String>>>(
              stream: longBloc.state.stream,
              builder: (BuildContext context, snapshot) {
                if (snapshot.hasData) {
                  switch (snapshot.data.state) {
                    case LongState.loading:
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                      break;

                    default:
                      return ListView.builder(
                        itemCount: longBloc.state.data.length,
                        itemBuilder: (context, index) => ListTile(
                          title: Text(longBloc.state.data[index]),
                          trailing: Container(
                              width: 50,
                              height: 50,
                              child: CheckBoxButton(
                                index: index,
                              )),
                        ),
                      );
                  }
                }
                if (snapshot.hasError)
                  return Center(
                    child: Text(snapshot.error),
                  );
                return Container();
              },
            ),
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
              heroTag: null,
              onPressed: () {
                longBloc.dispatch(ActionState.getAll, null);
              },
              child: Icon(Icons.file_download),
            ),
            FloatingActionButton(
              heroTag: null,
              onPressed: () {
                longBloc.dispatch(ActionState.delete, {"index": 0});
                selectItemBloc.dispatch(ItemState.inactive, {"index": 0});
              },
              child: Icon(Icons.remove),
            ),
            FloatingActionButton(
              heroTag: null,
              onPressed: () {
                longBloc
                    .dispatch(ActionState.add, {"query": Random().toString()});
                selectItemBloc.dispatch(
                    ItemState.inactive, {"index": longBloc.state.data.length});
              },
              child: Icon(Icons.add),
            ),
            ResetButton(),
            // FloatingActionButton(
            //   heroTag: null,
            //   onPressed: () {
            //     longBloc.dispatch(ActionState.reset, null);
            //     selectItemBloc.dispatch(ItemState.reset, null);
            //   },
            //   child: Icon(Icons.refresh),
            // ),
          ],
        ),
      ),
    );
  }
}

class ResetButton extends StatelessWidget {
  const ResetButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LongBloc bloc = SingleBlocProvider.of<LongBloc>(context);
    return FloatingActionButton(
      heroTag: null,
      onPressed: () {
        bloc.dispatch(ActionState.reset, null);
        // selectItemBloc.dispatch(ItemState.reset, null);
      },
      child: Icon(Icons.refresh),
    );
  }
}

class CheckBoxButton extends StatelessWidget {
  final int index;
  const CheckBoxButton({Key key, this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SelectItemBloc bloc = SingleBlocProvider.of<SelectItemBloc>(context);
    return StreamBuilder<SubState<ItemState, Map>>(
      stream: bloc.state.stream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return Checkbox(
              value: bloc.state.data.containsKey(index.toString()),
              onChanged: (bool value) {
                bloc.dispatch(value ? ItemState.active : ItemState.inactive,
                    {"index": index});
              });
        }
        return Container();
      },
    );
  }
}

class NotifyTest extends StatefulWidget {
  const NotifyTest({Key key}) : super(key: key);

  @override
  _NotifyTestState createState() => _NotifyTestState();
}

class _NotifyTestState extends State<NotifyTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notify Test"),
      ),
      body: Center(
        child: FlatButton(
            onPressed: () {
              CrossAccessedBlocNotifier.notifyWidgetWithKey<LongBloc>(
                  context, "longBloc", {"action_state": ActionState.getAll});
            },
            child: Text("Notify")),
      ),
    );
  }
}
