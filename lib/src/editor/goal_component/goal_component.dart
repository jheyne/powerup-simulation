import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';

import '../../scoring/goal_spec.dart';

@Component(
    selector: 'goal-component',
    templateUrl: 'goal_component.html',
    styleUrls: const [
      'goal_component.css'
    ],
    directives: const [
      materialDirectives,
      CORE_DIRECTIVES,
      MaterialInputComponent,
      MaterialDropdownSelectComponent,
      MaterialSelectComponent,
      MaterialCheckboxComponent
    ],
    pipes: const [
      COMMON_PIPES
    ],
    providers: const [
      materialProviders
    ])
class GoalComponent implements OnInit, AfterContentInit {
  @Input()
  GoalSpec spec;

  static const idList = const [
    'my switch',
    'opposite switch',
    'scale',
    'vault',
    'platform',
    'climb'
  ];

  final SelectionOptions<String> idOptions =
      new SelectionOptions.fromList(idList);
  final SelectionModel<String> idSelection =
      new SelectionModel.withList(allowMulti: false);

  static const sourceList = const [
    'portal left',
    'portal right',
    '6 by my switch',
    '6 by opposite switch',
    'my stack of 10'
  ];

  final SelectionOptions<String> sourceOptions =
      new SelectionOptions.fromList(sourceList);
  final SelectionModel<String> sourceSelection =
      new SelectionModel.withList(allowMulti: true);

  sourceChecked(bool checked, String source) {
    if (checked) {
      spec.sources.add(source);
    } else {
      spec.sources.remove(source);
      ;
    }
  }

  onReorderSources(ReorderEvent reorder) {
    spec.sources.insert(
        reorder.destIndex, spec.sources.removeAt(reorder.sourceIndex));
  }

  GoalComponent();

  @override
  void ngOnInit() {
    for (String source in spec.sources) {
      sourceSelection.select(source);
    }
    update(List<SelectionChangeRecord> record) {
      if (record.isNotEmpty && record.first.added.isNotEmpty) {
        spec.id = (record.first.added.first);
      }
    }

    idSelection.selectionChanges.listen(update);
    updateSources(List<SelectionChangeRecord> records) {
      for (SelectionChangeRecord record in records) {
        spec.sources.addAll(record.added);
        for (String removed in record.removed) {
          spec.sources.remove(removed);
        }
      }
    }

    sourceSelection.selectionChanges.listen(updateSources);
  }

  @override
  void ngAfterContentInit() {
  }
}
