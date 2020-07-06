import 'package:state_test/infinite_scroll/models.dart';
import 'package:state_test/state_manager.dart';
import 'package:state_test/utils.dart';

enum PostActions {
  fetch,
}

class PostState extends StateManager<Status, PostModel> {
  PostState() : super(state: Status.idle, object: PostModel());
  @override
  Future<void> handleAction(action, props) async {
    if (action is PostActions && props is Reply) {
      if (props.status == Status.success) {
        updateState(
            Status.success,
            PostModel(
              items: [
                ...event.object.items,
                ...(props.data.items as List<Post>)
              ],
              offset: props.data.offset,
            ));
      } else {
        updateStateWithError(props.error);
      }
    }
  }
}
