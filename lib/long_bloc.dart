import 'package:rxdart/rxdart.dart';
// import 'package:state_test/bloc_provider.dart';
import 'n_bloc.dart';
// import 'package:state_test/bloc_provider.dart';

enum LongState { loading, done, update }
enum ActionState { getAll, add, delete, reset }

typedef VoidFuction = void Function();

class LongBloc extends BlocBase implements ActionReceiver<ActionState> {
  // List<String> movieNames = [];
  // BehaviorSubject<LongState> _mSubject =
  //     BehaviorSubject.seeded(LongState.loading);

  // Observable<LongState> get stream => _mSubject.stream;

  var stateKey;

  StreamState<LongState, List<String>> state;

  LongBloc() {
    state = StreamState<LongState, List<String>>(
        SubState(LongState.done, List<String>()));
  }

  @override
  void dispatch(ActionState state, [Map<String, dynamic> data]) {
    switch (state) {
      case ActionState.getAll:
        _getData();
        // addEror();
        break;
      case ActionState.add:
        _addItem(data["query"]);
        break;
      case ActionState.delete:
        _removeItem(data["index"]);
        break;
      case ActionState.reset:
        _reset();
        break;
      default:
    }
  }

  Future<void> _getMockData() async {
    // await Future.delayed(Duration(seconds: 1));
    state.data = ["Spiderman", "Avengers", "The last of us", "Hitman"];
  }

  void _getData() {
    // await _getMockData();
    // _mSubject.add(LongState.done);
    state.data = ["Spiderman", "Avengers", "The last of us", "Hitman"];
    state.currentState = LongState.done;
    state.controller.add(state.event);
  }

  void _addItem(String query) async {
    // movieNames.add(query);
    // _mSubject.add(LongState.update);
    state.data.add(query);
    state.currentState = LongState.update;
    state.controller.add(state.event);
  }

  void _removeItem(int index) {
    // movieNames.removeAt(index);
    // _mSubject.add(LongState.update);
    state.data.removeAt(index);
    state.currentState = LongState.update;
    state.controller.add(state.event);
  }

  void _reset() async {
    // _mSubject.add(LongState.loading);
    // movieNames = [];
    state.data = [];
    state.currentState = LongState.loading;
    state.controller.add(state.event);
  }

  void addEror() async {
    // _mSubject.addError("It wont work");
    state.controller.addError("It won't work");
  }

  @override
  void dispose() {
    // _mSubject.close();
    state.dispose();
  }
}

enum ItemState { active, inactive, reset }

class SelectItemBloc extends BlocBase implements ActionReceiver<ItemState> {
  StreamState<ItemState, Map> state;
  SelectItemBloc() {
    state = StreamState<ItemState, Map>(
        SubState<ItemState, Map>(ItemState.inactive, {}));
  }

  @override
  void dispatch(ItemState state, [Map<String, dynamic> data]) {
    switch (state) {
      case ItemState.active:
        _setActive(data["index"]);
        break;
      case ItemState.inactive:
        _setInactive(data["index"]);
        break;

      case ItemState.reset:
        _reset();
        break;
      default:
    }
  }

  void _reset() {
    state.data = {};
    state.currentState = ItemState.inactive;
    state.notifyListeners();
  }

  void _setInactive(int index) {
    if (state.data.containsKey(index.hashCode.toString())) {
      state.data.remove(index.hashCode.toString());
      state.currentState = ItemState.inactive;
      state.notifyListeners();
    }
  }

  void _setActive(int index) {
    state.data[index.hashCode.toString()] = "";
    state.currentState = ItemState.active;
    state.notifyListeners();
  }

  void dispose() {
    state.dispose();
  }
}
