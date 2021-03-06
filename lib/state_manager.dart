import 'dart:async';
import 'dart:isolate';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
export 'package:rxdart/transformers.dart';
import 'package:meta/meta.dart';
import 'package:state_test/utils.dart';
import 'middleware.dart';

part 'state_utils.dart';

/// Author: Nadeem Siddique

class StateSnapshot<S, T> {
  final S status;
  final T data;
  final Object error;

  const StateSnapshot(
    this.status,
    this.data,
    this.error,
  ) : assert(!(data != null && error != null),
            "Both data and error cant be set at the same time");
  bool get hasData => data != null;
  bool get hasError => error != null;

  @override
  String toString() {
    return hasError ? error.toString() : data.toString();
  }
}

abstract class StateManager<S, T, A> {
  /// Controller that manges the actual data events
  BehaviorSubject<StateSnapshot<S, T>> _controller;

  /// Controller that only manges the error events
  PublishSubject<StateSnapshot<S, T>> _errorController;

  /// A publishSubject doesn't hold values hence a store to save the last error
  Object _lastEmittedError;

  bool _hasError = false;

  StateManager({S state, T object}) {
    //emit the error object with a null first
    _errorController = PublishSubject<StateSnapshot<S, T>>();
    _controller = BehaviorSubject<StateSnapshot<S, T>>();
    _controller = BehaviorSubject<StateSnapshot<S, T>>.seeded(
        _initialState(state, object));
  }

  ///Controller of the event stream
  BehaviorSubject<StateSnapshot<S, T>> get controller => _controller;

  ///Stream that recieves both events and errors
  ///
  ///You should always listen to this stream
  Stream<StateSnapshot<S, T>> get stream =>
      _controller.stream.mergeWith([_errorController.stream]);

  /// It returns a stream of `T` insted of [StateSnapshot]
  ///
  /// Makes tests easier to write
  Stream<T> get rawStream => stream
          .transform(StreamTransformer.fromHandlers(handleData: (state, sink) {
        if (state.hasData)
          sink.add(state.data);
        else
          sink.add(state.error);
      }));

  /// Returns the [StateSnapshot.data] from last emitted state without errors
  ///
  /// You will always be able to obtain the value of data it's the developers responsiblity
  /// to handle state proper when there is an error
  T get cData => _controller.value.data;

  /// Returns the [StateSnapshot.status] from last emitted state without errors
  ///
  /// You will always be able to obtain the value of data it's the developers responsiblity
  /// to handle state proper when there is an error
  S get cStatus => _controller.value.status;

  /// Current state
  StateSnapshot<S, T> get state => StateSnapshot(
      _controller.value.status, _controller.value.data, _lastEmittedError);

  /// Emit a new state without error
  @protected
  void updateState(S state, T data) {
    _hasError = false;
    _lastEmittedError = null;
    _controller.add(StateSnapshot<S, T>(state, data, _lastEmittedError));
  }

  /// Emit a state with error
  @protected
  void updateStateWithError(Object error) {
    assert(error != null);
    _errorController.addError(error);
    _lastEmittedError = error;
    _hasError = true;
  }

  StateSnapshot<S, T> _initialState(S state, T object) =>
      StateSnapshot<S, T>(state, object, null);

  void dispose() {
    _controller.close();
    _errorController.close();
    _watchers.clear();
  }

  Future<void> reducer(A action, Reply props);

  final _queue = ActionQueue();

  Future<void> _internalDispatch(QueuedAction qa) async {
    try {
      /// Props are values that are passed between middlewares and actions
      var props = qa.initialProps;
      final combined = List<MiddleWare>()
        ..addAll(_defaultMiddlewares)
        ..addAll(qa.pre ?? []);
      for (var middleware in combined) {
        // final resp = await compute(threadedExecution,
        //     MutliThreadArgs(middleware, state, qa.actionType, props));
        final resp = await middleware.run(state, qa.actionType, props);

        /// Reply of status unkown will cause an exception,
        /// unkown can will repsent situations that are considerend as traps
        /// this is abost the state update and [onError] will be called
        if (resp.isUnknown) {
          print("Middleware failed at: ${middleware.runtimeType}");
          throw Exception(resp.error);
        } else {
          props = resp;
        }
      }
      await reducer(qa.actionType, props);
      qa.onSuccess?.call();
      _notifyWorkers(qa.actionType);
    } catch (e, stack) {
      print("An exception occured when executing the action: ${qa.actionType}");
      qa.onError?.call(e, stack);
    } finally {
      qa.onDone?.call();
    }
  }

  /// Action can be any class
  /// onDone is option method which you need to call when the action is completed

  void dispatch(
    A action, {
    dynamic initialProps,

    /// When the action is completed
    void Function() onDone,

    /// When the action is successfully completed
    void Function() onSuccess,

    /// When the action fails to complete
    void Function(Object error, StackTrace stack) onError,

    /// Middleware that will be called before the action is processed
    List<MiddleWare> pre,
  }) async {
    _queue.enqueue(
      QueuedAction<A>(
          actionType: action,
          initialProps: initialProps,
          onDone: onDone,
          onSuccess: onSuccess,
          onError: onError,
          pre: pre),
      _internalDispatch,
    );
  }

  final _defaultMiddlewares = List<MiddleWare>();
  final _watchers = <A, List<ActionWorker<A>>>{};

  ///Sets a default middlewares that will be executed on every action
  void setDefaultMiddlewares(List<MiddleWare> middlewares) {
    if (_defaultMiddlewares.isNotEmpty)
      throw Exception("Default middlewares can only be set once");
    else
      _defaultMiddlewares.addAll(middlewares);
  }

  /// Add a listerner that executes everytime the specified action is executed
  void addWorker(A action, ActionWorker<A> worker) {
    if (_watchers.containsKey(action))
      _watchers[action].add(worker);
    else
      _watchers[action] = <ActionWorker<A>>[worker];
  }

  /// Executes all workers attached to the specified action
  void _notifyWorkers(A action) {
    if (_watchers.containsKey(action))
      for (var worker in _watchers[action]) {
        worker.call(dispatch);
      }
  }

  /// Returns `true` if a worker is removed
  bool removeWorker(A action, ActionWorker worker) {
    if (!_watchers.containsKey(action)) return false;
    _watchers[action].removeWhere((element) => element == worker);
    return true;
  }
}

typedef Dispatcher<A> = void Function(
  A action, {
  dynamic initialProps,
  void Function() onDone,
  void Function() onSuccess,
  void Function(Object error, StackTrace stack) onError,
  List<MiddleWare> pre,
});

typedef ActionWorker<A> = Function(Dispatcher<A> put);
