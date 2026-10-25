import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

import 'package:recipe_genui/agent/surface_check.dart';
import 'package:recipe_genui/catalog/recipe_catalog.dart';

void main() {
  SurfaceDefinition surface(List<JsonMap> components) => SurfaceDefinition(
    surfaceId: 's',
    components: {
      for (final c in components) c['id']! as String: Component.fromJson(c),
    },
  );

  group('missingComponentIds', () {
    test('is empty for a complete tree', () {
      expect(
        missingComponentIds(
          surface([
            {
              'id': 'root',
              'component': 'Column',
              'children': ['a'],
            },
            {'id': 'a', 'component': 'RecipeCard', 'recipeId': 'poha'},
          ]),
        ),
        isEmpty,
      );
    });

    test('finds children that were never sent', () {
      expect(
        missingComponentIds(
          surface([
            {
              'id': 'root',
              'component': 'Column',
              'children': ['title', 'card'],
            },
            {'id': 'title', 'component': 'Text', 'text': 'Hi'},
          ]),
        ),
        ['card'],
      );
    });

    test('follows templates, tabs and single children', () {
      expect(
        missingComponentIds(
          surface([
            {
              'id': 'root',
              'component': 'Column',
              'children': {'componentId': 'tabs', 'path': '/items'},
            },
            {
              'id': 'tabs',
              'component': 'Tabs',
              'tabs': [
                {'label': 'One', 'content': 'card'},
              ],
            },
            {'id': 'card', 'component': 'Card', 'child': 'gone'},
          ]),
        ),
        ['gone'],
      );
    });

    test('reports a surface without a root', () {
      expect(missingComponentIds(surface([])), ['root']);
    });
  });

  test('unknownComponentTypes finds types the catalog lacks', () {
    expect(
      unknownComponentTypes(
        surface([
          {
            'id': 'root',
            'component': 'Column',
            'children': ['a', 'b'],
          },
          {'id': 'a', 'component': 'RecipeCard', 'recipeId': 'poha'},
          {'id': 'b', 'component': 'tomato_paneer_masala'},
        ]),
        recipeCatalog,
      ),
      ['tomato_paneer_masala'],
    );
  });

  test('childComponentIds reads raw component JSON', () {
    expect(
      childComponentIds({
        'id': 'row',
        'component': 'Row',
        'children': ['a', 'b'],
      }),
      ['a', 'b'],
    );
    expect(
      childComponentIds({'id': 't', 'component': 'Text', 'text': 'x'}),
      isEmpty,
    );
  });
}
