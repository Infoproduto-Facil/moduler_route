import 'package:moduler_route/moduler_route.dart';
import 'package:moduler_route/presentation/unknown_view.dart';

String _modulePath = "home";

class UnknownModule extends Module {
  static final routePaths = _Routes();

  @override
  String get path => _modulePath;

  @override
  List<ModuleRoute> get routes => [
        ModuleRoute(
            path: "/",
            builder: (_) => UnknownView(routeName: "Unknown",),
            transitionType: RouteTransitionType.rightToLeft),
      ];
}

class _Routes {
  String get home => "$_modulePath";
}
