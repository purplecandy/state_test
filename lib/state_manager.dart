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
/// Every Event has 2 members
/// `state` : A meaningfull representation of the `object`
/// `object`: The actual value of the state at given instance
/// Example:
/// `object` is like symptoms of the pateint
/// `sate` is the name of the disease concluded from the symptoms of the patient.
class Event<S, T> {
  final S state;
  final T object;
  Event(this.state, this.object);
}

abstract class StateManager<S, T> {
  /// Controller that manges the actual data events
  BehaviorSubject<Event<S, T>> _controller;

  /// Controller that only manges the error events
  PublishSubject<Event<S, T>> _errorController;

  /// A publishSubject doesn't hold values hence a store to save the last error
  Object lastEmittedError;
  bool hasError = false;
  StateManager({S state, T object}) {
    //emit the error object with a null first
    _errorController = PublishSubject<Event<S, T>>();
    _controller = BehaviorSubject<Event<S, T>>();
    _controller =
        BehaviorSubject<Event<S, T>>.seeded(_initialState(state, object));
  }

  ///Controller of the event stream
  BehaviorSubject<Event<S, T>> get controller => _controller;

  ///Stream that recieves both events and errors
  ///
  ///You should always listen to this stream
  Stream<Event<S, T>> get stream =>
      _controller.stream.mergeWith([_errorController.stream]);
  // Stream<Event<S, T>> get _errorStream => _errorController.stream;
  Event<S, T> get event => _controller.value;

  /// Emit a new value
  @protected
  void updateState(S state, T data) {
    if (hasError) hasError = false;
    _controller.add(Event<S, T>(state, data));
  }

  /// Emit an error
  @protected
  void updateStateWithError(Object error) {
    lastEmittedError = error;
    hasError = true;
    _errorController.addError(error);
  }

  Event<S, T> _initialState(S state, T object) => Event<S, T>(state, object);

  void dispose() {
    _controller.close();
    _errorController.close();
  }

  Future<void> reducer(dynamic action, dynamic props);

  /// Action can be any class
  /// onDone is option method which you need to call when the action is completed

  Future<void> dispatch(
    dynamic action, {
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
      if (pre != null)
        for (var middleware in pre) {
          final resp = await middleware.run(event, action, props);

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
    } catch (e, stack) {
      onError?.call(e, stack);
    } finally {
      onDone?.call();
    }
  }
}
