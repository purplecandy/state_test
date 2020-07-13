part of 'state_manager.dart';

class QueuedAction<A> {
  final A actionType;
  final dynamic initialProps;
  final void Function() onDone, onSuccess;
  final void Function(Object error, StackTrace stack) onError;
  final List<MiddleWare> pre;
  QueuedAction(
      {@required this.actionType,
      @required this.initialProps,
      @required this.onDone,
      @required this.onSuccess,
      @required this.onError,
      @required this.pre});
}

class ActionQueue<A> {
  final _queue = List<QueuedAction>();
  bool _busy = false;

  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;

  void enqueue(QueuedAction<A> action,
      Future<void> Function(QueuedAction action) callback) {
    _queue.add(action);

    if (_busy == false) onChange(callback);
  }

  void _dequeue() => _queue.removeAt(0);

  void onChange(Future<void> Function(QueuedAction action) cb) async {
    if (_queue.isNotEmpty) {
      _busy = true;
      await cb?.call(_queue.first);
      _dequeue();
      print("Remaining ${_queue.length}");
      onChange(cb);
    }
    _busy = false;
  }
}

class MutliThreadArgs<T> {
  final T state;
  final dynamic action, props;
  final MiddleWare middleWare;
  const MutliThreadArgs(this.middleWare, this.state, this.action, this.props);
}

Future<Reply> threadedExecution(MutliThreadArgs args) async {
  return await args.middleWare.run(args.state, args.action, args.props);
}
