import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_test/flutter_test.dart';

/// These bloc implementation are based on my own understanding
/// The goal of this implementation is to give flexiblity to user with Blocs
/// while keeping this simple and easy to adopt

///
/// Methodology:
///
/// One Bloc will only manage one stream
///
/// Anything that can cause a change in the stream/state has to go through `dispatch()`
///
/// Methods that modify the stream should be kept private
///
/// Anyother helper function that doesn't cause change in the state/stream
/// Exaple - An input validation
/// should begin with `handle` keyword

/// ActionReciver or ActionHandler
/// provides a method to handle incoming events that can cause change in the stream
/// hence the resultant change can cause views to rebuild
/// T - ActionState tells the dispatch function what kind of actions it will receive
/// and what to do when a specific action is received
abstract class ActionReceiver<T> {
  /// T - actionState - represents the type of actions it will receive
  /// dispatch will invoke methods depending on the actionState
  /// data - it's used to pass extra arguments
  void dispatch(T actionState, [Map<String, dynamic> data]);
}

/// A subState is the actual state that get's passed through the stream
/// T - The object which represents the data that's beind passed along with the stream
/// S - State represents the state of data that View Models will youse to rebuild themself
/// I have decided to use both along as it's easier to build depending on one
/// Example - A [State.Loading] will represed data object when it's null, empty
/// A [State.Done] will repsent data object when it's non-null, not-empty, modified
class SubState<S, T> {
  // An enum what represents the State of the object value at an instance
  S state;
  // Object which will carry the data
  T object;
  SubState(this.state, this.object);
}

class StreamState<S, T> {
  //Decalration of subState
  final SubState<S, T> _subState;

  BehaviorSubject<SubState<S, T>> _subject;

  //The value pass will be considered as initial state and value
  StreamState(this._subState) {
    //Initializing the stream
    _subject = BehaviorSubject.seeded(_subState);
  }

  /// Returs the stream of the subject
  Observable<SubState<S, T>> get stream => _subject.stream;

  /// Since the subState are nothing more than events for the StreamController
  /// It can also be called as event
  SubState<S, T> get event => _subState;

  /// getters and setters for (subState/event)
  /// These are the actual representative of subState
  T get data => _subState.object;
  S get currentState => _subState.state;

  set data(T value) => _subState.object = value;
  set currentState(S newState) => _subState.state = newState;

  /// The subject is called controller
  BehaviorSubject<SubState<S, T>> get controller => _subject;

  /// A handy function which adds the event to StreamController
  /// which will automatically update listeners
  void notifyListeners() {
    _subject.add(event);
  }

  void dispose() {
    _subject.close();
  }
}

// This is my own implementation of Bloc
// I perosnally don't like to use any state management library
// you lose the flexibilty of just Streams and States

/// [BlocBase] abstract class is supposed to be inherited by all the Blocs
abstract class BlocBase {
  void dispose();
}

/// [SingleBlocProvider] provides only one Bloc to the child widgets
class SingleBlocProvider<T> extends StatefulWidget {
  const SingleBlocProvider(
      {Key key,
      @required T bloc,
      @required Widget child,
      this.attachToNotifier = false,
      this.unqiueKey})
      : this.bloc = bloc,
        this.child = child,
        super(key: key);

  final String unqiueKey;
  final bool attachToNotifier;
  final T bloc;
  final Widget child;

  /// Returs the nearest Bloc extending from [BlocBase] from the widget tree
  static T of<T extends BlocBase>(BuildContext context) {
    final provider =
        context.findAncestorWidgetOfExactType<SingleBlocProvider<T>>();
    return provider.bloc;
  }

  @override
  _SingleBlocProviderState createState() => _SingleBlocProviderState();
}

class _SingleBlocProviderState<T> extends State<SingleBlocProvider<T>> {
  @override
  void initState() {
    super.initState();
    attachKey();
  }

  void attachKey() {
    if (widget.attachToNotifier) {
      BlocChangeNotifier.addKey(context, widget.unqiueKey, widget.key);
    }
  }

  @override
  Widget build(BuildContext context) {
    print(context.widget);
    return widget.child;
  }
}

class CrossAccessedBloc<T> extends StatelessWidget {
  CrossAccessedBloc(
      {@required this.uniqueKey,
      @required this.bloc,
      @required this.child,
      Key key})
      : super(key: key);
  final Widget child;
  final T bloc;
  final String uniqueKey;
  final GlobalKey<_SingleBlocProviderState<T>> globalKey =
      GlobalKey<_SingleBlocProviderState<T>>();

  @override
  Widget build(BuildContext context) {
    return SingleBlocProvider(
      bloc: bloc,
      key: globalKey,
      attachToNotifier: true,
      child: child,
      unqiueKey: uniqueKey,
    );
  }
}

/// MultiBlocProvider gives access to multiple/list blocs to child widgets from one provider
/// It's very handy in reducing the boiler plate
/// NOTE: MultiBlocProvider expects you to have all different Blocs of different types
/// you can't have two Blocs of same class
/// As it will only return the first instance of Bloc
class MultiBlocProvider extends StatelessWidget {
  const MultiBlocProvider({Key key, List<dynamic> blocs, Widget child})
      : this.blocs = blocs,
        this.child = child,
        super(key: key);
  final List<dynamic> blocs;
  final Widget child;

  /// Returs the first instance nearest of Bloc extending from [BlocBase] from the widget tree
  static T of<T extends BlocBase>(BuildContext context) {
    final provider = context.findAncestorWidgetOfExactType<MultiBlocProvider>();
    for (var bloc in provider.blocs) {
      if (bloc.runtimeType == T) return bloc;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    print(context.widget);
    return child;
  }
}

class BlocChangeNotifier extends StatelessWidget {
  BlocChangeNotifier({Key key, this.child}) : super(key: key);
  final Map<String, GlobalKey<dynamic>> _keys = {};
  final Widget child;

  static notifyWidgetWithKey<T>(BuildContext context, String uniqueKey,
      [Map<String, dynamic> data]) {
    final notifier =
        context.findAncestorWidgetOfExactType<BlocChangeNotifier>();
    if (notifier._keys.containsKey(uniqueKey)) {
      final SingleBlocProvider widget = notifier._keys[uniqueKey].currentWidget;
      widget.bloc.dispatch(data["action_state"], data["data"]);
    }
  }

  static addKey(BuildContext context, String uniqueKey, GlobalKey key) {
    final notifier =
        context.findAncestorWidgetOfExactType<BlocChangeNotifier>();
    notifier._keys[uniqueKey] = key;
    print(notifier._keys);
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
