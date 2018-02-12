import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import '../../scoring/goal_spec.dart';
import '../goal_component/goal_component.dart';
import 'package:angular_components/auto_dismiss/auto_dismiss.dart';
import 'package:angular_components/focus/focus.dart';
import 'package:angular_components/laminate/components/modal/modal.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_dialog/material_dialog.dart';
import 'package:angular_components/material_icon/material_icon.dart';

@Component(
  selector: 'goal-list-component',
  templateUrl: 'goal_list_component.html',
  styleUrls: const ['goal_list_component.css'],
    directives: const [
      materialDirectives,
      CORE_DIRECTIVES,
      MaterialCheckboxComponent,
      ReorderListComponent,
      GoalComponent,
      AutoDismissDirective,
      AutoFocusDirective,
      MaterialButtonComponent,
      MaterialDialogComponent,
      MaterialIconComponent,
      ModalComponent,
    ],
    pipes: const [
      COMMON_PIPES
    ],
    providers: const [
      materialProviders
    ])
class GoalListComponent implements OnInit {

  @Input()
  List<GoalSpec> specs;

  GoalSpec selectedSpec;

  GoalListComponent();

  @override
  void ngOnInit() {}

  onReorder(ReorderEvent reorder) {
    specs.insert(
        reorder.destIndex, specs.removeAt(reorder.sourceIndex));
  }

  addGoal() {
    var goalSpec = new GoalSpec();
    specs.add(goalSpec);
    selectedSpec = goalSpec;
  }

}
