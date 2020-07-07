import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state_manager.dart';
import 'package:rxdart/rxdart.dart';

/// Author: Nadeem Siddique

typedef Widget SnapshotBuilder<A, K, T>(
    BuildContext context, Event<A, K> event, T bloc);
typedef Widget ErrorBuilder<T>(BuildContext context, Object error, T bloc);

/// BlocBuilder is just a wrapper on [Consumer] and [StreamBuilder]
/// Consumer widget looks up the widget tree and returns the instance of the bloc
/// StreamBuilder listens to the stream provided from the bloc
/// Types of: [State],[Data],[Bloc]
class BlocBuilder<A, K, T extends StateManager> extends StatelessWidget {
  ///[updateState] is called a successful state is passed to stream
  final SnapshotBuilder<A, K, T> onSuccess;

  ///[updateStateWithError] is called an state with exception is passed
  final ErrorBuilder<T> onError;
  const BlocBuilder({Key key, this.onSuccess, this.onError}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<T>(
      builder: (_, bloc, __) => StreamBuilder<Event<A, K>>(
        stream: bloc.stream,
        initialData: bloc.event,
        builder: (context, snap) =>
            (snap.hasError || bloc.currentState.hasError)
                ? onError(context,
                    snap.hasError ? snap.error : bloc.currentState.error, bloc)
                : onSuccess(context, snap.data, bloc),
      ),
    );
  }
}
