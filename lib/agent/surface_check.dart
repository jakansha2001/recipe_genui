import 'package:genui/genui.dart';

/// Props through which a component points at other components by id, across
/// the basic catalog: Card/Button `child`, Column/Row/List `children` (a list
/// of ids or a `{componentId, path}` template), Modal `trigger`/`content`,
/// and each Tabs entry's `content`.
const Set<String> _childRefKeys = {
  'child',
  'children',
  'content',
  'trigger',
  'componentId',
};

/// The ids of the components that [component] (raw A2UI component JSON or
/// its properties) references as children.
Iterable<String> childComponentIds(Map<String, Object?> component) =>
    _childRefs(component);

/// The ids [definition]'s tree references but never defines, walking from
/// `root`. Empty means every component can be built.
///
/// A2UI is an adjacency list: a Column lists child *ids*, and the model must
/// also send a component for each id. When it forgets one, genui renders a red
/// fallback box and tells the model only "INTERNAL_ERROR", which it can't act
/// on. Checking up front lets us hide the surface and send a precise error.
List<String> missingComponentIds(SurfaceDefinition definition) {
  final components = definition.components;
  if (!components.containsKey('root')) return const ['root'];

  final missing = <String>{};
  final visited = <String>{};
  final pending = ['root'];
  while (pending.isNotEmpty) {
    final id = pending.removeLast();
    if (!visited.add(id)) continue;
    final component = components[id];
    if (component == null) {
      missing.add(id);
    } else {
      pending.addAll(childComponentIds(component.properties));
    }
  }
  return missing.toList();
}

/// Component types in [definition] that [catalog] doesn't define — e.g. a
/// model writing a recipe id where a component name belongs. genui would draw
/// a red fallback box for each.
List<String> unknownComponentTypes(
  SurfaceDefinition definition,
  Catalog catalog,
) {
  final known = {for (final item in catalog.items) item.name};
  return {
    for (final component in definition.components.values)
      if (!known.contains(component.type)) component.type,
  }.toList();
}

Iterable<String> _childRefs(Object? value, {bool isRef = false}) sync* {
  if (value is String) {
    if (isRef) yield value;
  } else if (value is List) {
    for (final item in value) {
      yield* _childRefs(item, isRef: isRef);
    }
  } else if (value is Map) {
    for (final MapEntry(:key, value: child) in value.entries) {
      yield* _childRefs(child, isRef: _childRefKeys.contains(key));
    }
  }
}
