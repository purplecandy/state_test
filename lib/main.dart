import 'package:flutter/material.dart';
import 'package:state_test/longlist.dart';
// import 'package:state_test/bloc_provider.dart';
import 'n_bloc.dart';
import 'package:state_test/counterbloc.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return CrossAccessedBlocNotifier(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
        ),
        home: LongList(),
        // home: SingleBlocProvider<CounterBloc>(
        //   bloc: CounterBloc(),
        //   child: MyHomePage(title: 'Flutter Demo Home Page'),
        // ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    var bloc = SingleBlocProvider.of<CounterBloc>(context);
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: <Widget>[
          OutlineButton(
            child: Text("Dispose"),
            onPressed: () {
              bloc.dispose();
            },
          ),
          OutlineButton(
            child: Text("NULL"),
            onPressed: () {
              bloc = null;
            },
          )
        ],
      ),
      body: CounterText(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[Increment(), Decrement()],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class Increment extends StatelessWidget {
  const Increment({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CounterBloc bloc = SingleBlocProvider.of<CounterBloc>(context);
    return OutlineButton(
      onPressed: () {
        bloc.increment();
      },
      // tooltip: 'Increment',
      child: Icon(Icons.add),
    );
  }
}

class Decrement extends StatelessWidget {
  const Decrement({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CounterBloc bloc = SingleBlocProvider.of<CounterBloc>(context);
    return OutlineButton(
      onPressed: () {
        bloc.decrement();
      },
      child: Icon(Icons.remove),
    );
  }
}

class CounterText extends StatelessWidget {
  const CounterText({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CounterBloc bloc = SingleBlocProvider.of<CounterBloc>(context);
    return StreamBuilder(
      stream: bloc.counter,
      initialData: bloc.count,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              OutlineButton(
                child: Text("Form Page"),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => FormModal()));
                },
              ),
              OutlineButton(
                child: Text("MultiBLoc Test"),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => MultiBlocTest()));
                },
              ),
              Text(
                'You have pushed the button this many times:',
              ),
              Text(
                snapshot.data.toString(),
                style: Theme.of(context).textTheme.display1,
              ),
            ],
          ),
        );
      },
    );
  }
}

class MultiBlocTest extends StatefulWidget {
  MultiBlocTest({Key key}) : super(key: key);

  @override
  _MultiBlocTestState createState() => _MultiBlocTestState();
}

class _MultiBlocTestState extends State<MultiBlocTest> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      blocs: [First(), Second()],
      child: Scaffold(
        appBar: AppBar(
          title: Text("Multibloc"),
        ),
        body: Column(
          children: <Widget>[
            MultiBlocProvider(blocs: [Second()], child: One()),
            Two(),
            Third()
          ],
        ),
      ),
    );
  }
}

class One extends StatelessWidget {
  const One({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = MultiBlocProvider.of<First>(context);
    return FlatButton(
        onPressed: () {
          bloc.printValue();
        },
        child: Text("One Bloc"));
  }
}

class Two extends StatelessWidget {
  const Two({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = MultiBlocProvider.of<Second>(context);
    return FlatButton(
        onPressed: () {
          bloc.printValue();
        },
        child: Text("Two Bloc"));
  }
}

class Third extends StatelessWidget {
  const Third({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = MultiBlocProvider.of<CounterBloc>(context);
    return FlatButton(
        onPressed: () {
          print(bloc.count);
        },
        child: Text("Third Bloc"));
  }
}

class FormModal extends StatefulWidget {
  FormModal({Key key}) : super(key: key);

  @override
  _FormModalState createState() => _FormModalState();
}

class _FormModalState extends State<FormModal> {
  final form = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return SingleBlocProvider<FormBloc>(
      key: UniqueKey(),
      bloc: FormBloc(),
      child: Scaffold(
        appBar: AppBar(),
        body: Form(
          key: form,
          child: Column(
            children: <Widget>[
              TextFormField(),
              Divider(),
              TextFormField(),
              Divider(),
              TextFormField(),
              Divider(),
            ],
          ),
        ),
      ),
    );
  }
}

class FormBloc extends BlocBase {
  @override
  void dispose() {
    print("DISPOSED");
  }
}
