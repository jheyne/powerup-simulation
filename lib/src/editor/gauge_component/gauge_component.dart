import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';

typedef String LabelFunction();
typedef void ClickFunction(MouseEvent event);
typedef int PercentileFunction();

@Component(
    selector: 'gauge-component',
    templateUrl: 'gauge_component.html',
    styleUrls: const [
      'gauge_component.css'
    ],
    directives: const [
      materialDirectives,
      CORE_DIRECTIVES,
      MaterialCheckboxComponent,
      MaterialExpansionPanel,
      MaterialExpansionPanelSet,
      MaterialProgressComponent,
    ],
    pipes: const [
      COMMON_PIPES
    ],
    providers: const [
      materialProviders
    ])
class GaugeComponent implements OnInit {

  @Input()
  String tooltip = '';
  @Input()
  String ident = 'ident_not_set';

  @Input()
  LabelFunction labelFunction = () => 'labelFunction not defined';
  @Input()
  ClickFunction clickFunction =
      (MouseEvent e) => print('clickFunction not defined');
  @Input()
  PercentileFunction percentileFunction = () => 50;

  @Input()
  String leftLabel = 'leftLabel not defined';
  @Input()
  String rightLabel = "rightLabel not defined";

  String get label => labelFunction();

  int get rank => percentileFunction();

  click(MouseEvent e) => clickFunction(e);

  GaugeComponent();

  @override
  void ngOnInit() {}
}
