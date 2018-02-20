
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_components/angular_components.dart'
    show materialProviders;

import 'package:power_up_2018/app_component.dart';

void main() {
  bootstrap(
      AppComponent, [materialProviders, ROUTER_PROVIDERS,
  const Provider(LocationStrategy, useClass: HashLocationStrategy)
  ]);
}