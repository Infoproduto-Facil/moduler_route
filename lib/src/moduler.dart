import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:moduler_route/presentation/unknown_view.dart';
import 'package:moduler_route/src/module_route.dart';
import 'package:moduler_route/src/modules/unknown_module.dart';
import 'package:page_transition/page_transition.dart';

import 'collection/module_stack.dart';
import 'injector.dart';
import 'module.dart';
import 'moduler_route_observer.dart';
import 'route_transition_type.dart';

part 'inject.dart';

mixin Moduler {
  static final _modulesStack = StackModule();

  List<Module> get modules;
  List<Injector> get globalInjections;

  final ModulerRouteObserver modulerRouteObserver = ModulerRouteObserver(
    _modulesStack,
  );

  Module _module(String path) {
    final dividedPath = path.split("/");
    final modulePath = dividedPath.length > 1 ? dividedPath[0] : path;

    final module = modules.firstWhere(
      (module) => module.path == modulePath,
      orElse: () => UnknownModule(),
    );

    return module;
  }

  ModuleRoute _route(String path, Module module) {
    if (path.endsWith("/")) {
      path = path.substring(0, path.length - 1);
    }

    return module.routes.firstWhere(
      (route) => route.path == path,
      orElse: () => module.routes.firstWhere(
          (route) => route.path == "/" && module.path == path, orElse: () {
        final dividedRoute = path.split("/")..removeAt(0);
        final routePath = dividedRoute.join("/");

        return module.routes.firstWhere(
          (route) => route.path == routePath,
          orElse: () => ModuleRoute(
              path: "/", builder: (_) => UnknownView(routeName: "Unknown")),
        );
      }),
    );
  }

  void _manageInjections(Module module) {
    Module? _stack = _modulesStack.top();

    if (_stack == null) {
      return;
    }

    if (_stack.path == module.path) {
      return;
    }

    _modulesStack.push(module);

    final injectedTypes = this
        .globalInjections
        .map(
          (injector) => injector.type,
        )
        .toList()
          ..addAll(
            _modulesStack.injectedTypes,
          );

    Inject._objects.removeWhere(
      (type, injector) => !injectedTypes.contains(type),
    );

    Inject._injections.removeWhere(
      (injector) => !injectedTypes.contains(injector.type),
    );

    this.globalInjections.forEach((injector) {
      if (Inject._injections.any((i) => i == injector)) {
        return;
      }

      Inject._injections.add(injector);
    });

    Inject._injections.addAll(_stack.injections);
  }

  String initialRoute(String Function() initialPath) => initialPath();

  Route routeTo(RouteSettings routeSettings) {
    final module = _module(routeSettings.name!);

    _manageInjections(module);

    final route = _route(routeSettings.name!, module);

    Inject._parameter = routeSettings.arguments!;

    final view = route.builder(routeSettings.arguments!);
    final pageRoute = _pageRoute(
      view: view,
      transitionType: route.transitionType,
      name: routeSettings.name!,
      modulePath: module.path,
    );

    return pageRoute;
  }

  // Route unknownRoute(RouteSettings route) {
  //   return _pageRoute(
  //       view: UnknownView(routeName: route.name!), name: "unknown");
  // }

  PageRoute _pageRoute({
    required Widget view,
    RouteTransitionType? transitionType,
    required String name,
    String? modulePath,
  }) {
    final settings = RouteSettings(
      name: name,
      arguments: modulePath,
    );

    if (transitionType == null ||
        transitionType == RouteTransitionType.cupertino ||
        transitionType == RouteTransitionType.material) {
      if (transitionType == RouteTransitionType.cupertino ||
          transitionType == null && Platform.isIOS) {
        return CupertinoPageRoute(
          settings: settings,
          builder: (BuildContext context) => view,
        );
      }

      return MaterialPageRoute(
        settings: settings,
        builder: (BuildContext context) => view,
      );
    }

    return PageTransition(
      settings: settings,
      child: view,
      type: transitionTypeConversion[transitionType]!,
    );
  }
}
