import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:state_test/builders.dart';
import 'counter_state.dart';

class CounterApp extends StatefulWidget {
  CounterApp({Key key}) : super(key: key);

  @override
  _CounterAppState createState() => _CounterAppState();
}

class _CounterAppState extends State<CounterApp> {
  final _counter = CounterState();

  void autoIncrement() {
    if (_counter.event.object < 50)
      _counter.dispatch(CounterActions.increment, onSuccess: () async {
        await Future.delayed(Duration(seconds: 1));
        autoIncrement();
      });
  }

  @override
  Widget build(BuildContext context) {
    return Provider<CounterState>(
      create: (_) => _counter,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Counter State"),
        ),
        body: CounterText(),
        // body: StreamBuilder(
        //   stream: _counter.stream,
        //   initialData: _counter.event,
        //   builder: (context, snap) => Text(
        //     snap.data.object.toString(),
        //     style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
        //   ),
        // ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
              mini: true,
              onPressed: () => _counter.dispatch(
                CounterActions.increment,
                onDone: () => print("action completed"),
                onSuccess: () => print(_counter.event.object),
                onError: (e) => print(e),
              ),
              child: Icon(Icons.add),
            ),
            FloatingActionButton(
              mini: true,
              onPressed: () => _counter.dispatch(CounterActions.decrement),
              child: Icon(Icons.remove),
            ),
            FloatingActionButton(
              mini: true,
              onPressed: () => _counter.dispatch(
                "Invalid action",
                onDone: () => print("action completed"),
                onSuccess: () => print(_counter.event.object),
                onError: (e) => print(e),
              ),
              child: Icon(Icons.close),
            ),
            FloatingActionButton(
              mini: true,
              onPressed: autoIncrement,
              child: Icon(Icons.plus_one),
            ),
          ],
        ),
      ),
    );
  }
}

class CounterText extends StatelessWidget {
  const CounterText({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<dynamic, int, CounterState>(
      onSuccess: (context, event, bloc) => Center(
        child: Text(
          event.object.toString(),
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
