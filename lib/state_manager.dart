import 'dart:async';
import 'package:rxdart/rxdart.dart';
export 'package:rxdart/transformers.dart';
import 'package:meta/meta.dart';
import 'package:state_test/utils.dart';

import 'middleware.dart';

/// Author: Nadeem Siddique
///
/// Guide:
///
/// Create a class that extends the blocbase class
/// Implement the dispatch function
/// All the state change should happened to functions passed via the dispatch function
///
/// To make this class available in the widget tree
///
/// Create an instance of the bloc in a stateful widget
/// Wrap the build method's widget tree with [Provider<ClassName>] and in the create parameter return the bloc object
///
///
/// How to listen or access the bloc?
///
/// If you want to use it in a function user
/// [Provider.of<ClassName>(context,listen:false)] this will find and return the instance of that bloc from the widget tree
///
/// If you want to user in the build method to handle a widget update
/// Wrap your widget with [BlocBuilder<State,DataType,ClassName>]
/// this returns you two function [onSuccess] and [onError] with the current event
///
///
/// Methodology:
///
/// One Bloc will only manage one stream
///
/// Anything that can cause a change in the stream/state has to go through `dispatch()`
///
/// Methods that modify the stream should be kept private
///
/// Anyother helper function that doesn't cause change in the state/stream can be made public and directly used
/// Example - Calculate the sum from the stream of events

/// Stream will emit the instance of Events
/// Every StateSnapshot has 2 members
/// `state` : A meaningfull representation of the `object`
/// `object`: The actual value of the state at given instance
/// Example:
/// `object` is like symptoms of the pateint
/// `sate` is the name of the disease concluded from the symptoms of the patient.
class _SState<S, T> {
  final S state;
  final T object;
  const _SState(this.state, this.object);
}

class _EState {
  final Object error;
  const _EState(this.error);
}

class StateSnapshot<S, T> {
  final S status;
  final T data;
  final Object error;

  StateSnapshot(
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
  // Stream<StateSnapshot<S, T>> get _errorStream => _errorController.stream;

  /// Returns the last emitted state without errors
  /// If there was no state emitted it will return the initial state value
  T get cData => _controller.value.data;
  S get cStatus => _controller.value.status;
  StateSnapshot<S, T> get state => StateSnapshot(
      _controller.value.status, _controller.value.data, _lastEmittedError);

  /// Emit a new value
  @protected
  void updateState(S state, T data) {
    _hasError = false;
    _lastEmittedError = null;
    _controller.add(StateSnapshot<S, T>(state, data, _lastEmittedError));
  }

  /// Emit an error
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

  /// Action can be any class
  /// onDone is option method which you need to call when the action is completed

  Future<void> dispatch(
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
    try {
      /// Props are values that are passed between middlewares and actions
      var props = initialProps;
      final combined = List<MiddleWare>()
        ..addAll(_defaultMiddlewares)
        ..addAll(pre ?? []);
      for (var middleware in combined) {
        final resp = await middleware.run(state, action, props);

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
      await reducer(action, props);
      onSuccess?.call();
      _notifyWorkers(action);
    } catch (e, stack) {
      onError?.call(e, stack);
    } finally {
      onDone?.call();
    }
  }

  final _defaultMiddlewares = List<MiddleWare>();
  final _watchers = <A, List<ActionWorker>>{};

  ///Sets a default middlewares that will be executed on every action
  void setDefaultMiddlewares(List<MiddleWare> middlewares) {
    if (_defaultMiddlewares.isNotEmpty)
      throw Exception("Default middlewares can only be set once");
    else
      _defaultMiddlewares.addAll(middlewares);
  }

  /// Add a listerner that executes everytime the specified action is executed
  void addWorker(A action, ActionWorker worker) {
    if (_watchers.containsKey(action))
      _watchers[action].add(worker);
    else
      _watchers[action] = <ActionWorker>[worker];
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

typedef Dispatcher = Future<void> Function(
  dynamic action, {
  dynamic initialProps,
  void Function() onDone,
  void Function() onSuccess,
  void Function(Object error, StackTrace stack) onError,
  List<MiddleWare> pre,
});

typedef ActionWorker = Function(Dispatcher put);
