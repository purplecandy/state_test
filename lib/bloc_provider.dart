import 'package:flutter/material.dart';

abstract class BlocBase {
  void dispose();
}

class BlocProvider<T extends BlocBase> extends StatefulWidget {
  const BlocProvider({
    Key key,
    @required this.child,
    @required this.bloc,
  }) : super(key: key);

  final T bloc;
  final Widget child;

  @override
  _BlocProviderState<T> createState() => _BlocProviderState<T>();

  static T of<T extends BlocBase>(BuildContext context) {
    final type = _typeOf<BlocProvider<T>>();
    BlocProvider<T> provider = context.ancestorWidgetOfExactType(type);
    return provider.bloc;
  }

  static Type _typeOf<T>() => T;
}

class _BlocProviderState<T> extends State<BlocProvider<BlocBase>> {
  @override
  void dispose() {
    widget.bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class StaticBloc<T extends BlocBase> extends StatelessWidget {
  const StaticBloc({Key key, T bloc, Widget child})
      : this.bloc = bloc,
        this.child = child,
        super(key: key);

  final T bloc;
  final Widget child;

  static T of<T extends BlocBase>(BuildContext context) {
    final type = _typeOf<StaticBloc<T>>();
    StaticBloc<T> provider = context.ancestorWidgetOfExactType(type);
    return provider.bloc;
  }

  static Type _typeOf<T>() => T;

  static Type getType<T extends BlocBase>() => StaticBloc<T>(
        bloc: null,
        child: null,
        key: null,
      ).runtimeType;

  @override
  Widget build(BuildContext context) {
    print(context.widget);
    return child;
  }
}

class DisposableBlocContent extends StatefulWidget {
  final List<Type> ancestorBlocs;
  final Widget child;

  DisposableBlocContent({Key key, this.child, this.ancestorBlocs})
      : super(key: key);

  @override
  _DisposableBlocContentState createState() => _DisposableBlocContentState();

  void disposeblocs(BuildContext context) {
    for (Type bloc in ancestorBlocs) {
      final StaticBloc blocbase = context.ancestorWidgetOfExactType(bloc);
      blocbase.bloc.dispose();
    }
  }
}

class _DisposableBlocContentState extends State<DisposableBlocContent> {
  @override
  void deactivate() {
    // widget.disposeblocs(context);
    super.deactivate();
  }

  @override
  void dispose() {
    widget.disposeblocs(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
