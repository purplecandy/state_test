// import 'package:state_test/bloc_provider.dart';
import 'n_bloc.dart';
import 'package:rxdart/rxdart.dart';

class CounterBloc extends BlocBase {
  int count = 0;
  BehaviorSubject<int> _counter;

  CounterBloc() {
    print("Instance of ${this.runtimeType}");
    _counter = BehaviorSubject.seeded(count);
  }

  Observable<int> get counter => _counter.stream;

  void increment() {
    count++;
    _counter.add(count);
  }

  void decrement() {
    count--;
    _counter.add(count);
  }

  void dispose() {
    print("Disposing ${this.runtimeType}");
    _counter.close();
  }
}

class First extends BlocBase {
  void printValue() => print("FIRST BLOC");
  void dispose() {}
}

class Second extends BlocBase {
  void printValue() => print("SECOND BLOC");
  void dispose() {}
}
