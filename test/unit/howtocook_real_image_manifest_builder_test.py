import unittest
from pathlib import Path

from scripts.build_howtocook_real_image_manifest import (
    HowToCookImageRecord,
    HowToCookRecipeRecord,
    build_aliases_for_markdown,
    build_recipe_presence_index,
    build_source_audit,
    enrich_manifest_sources,
    extract_local_image_refs,
    fill_missing_entries_by_dish_name,
    match_records_to_dishes,
    normalize_text,
)


class HowToCookRealImageManifestBuilderTest(unittest.TestCase):
    def test_extract_local_image_refs_filters_remote_images(self):
        markdown = '''
![成品](./1.jpeg)
![远端图](https://example.com/a.jpg)
![步骤图](./2.png)
'''
        self.assertEqual(
            extract_local_image_refs(markdown),
            ['./1.jpeg', './2.png'],
        )

    def test_build_aliases_for_markdown_uses_parent_folder_variant(self):
        path = Path('/tmp/HowToCook/dishes/meat_dish/红烧肉/简易红烧肉.md')
        aliases = build_aliases_for_markdown(path)
        self.assertIn('简易红烧肉', aliases)
        self.assertIn('红烧肉', aliases)
        self.assertIn(normalize_text('红烧肉'), {normalize_text(item) for item in aliases})

    def test_match_records_to_dishes_prefers_exact_or_parent_alias(self):
        record = HowToCookImageRecord(
            markdown_path=Path('/tmp/HowToCook/dishes/meat_dish/红烧肉/简易红烧肉.md'),
            recipe_name='简易红烧肉',
            aliases=['简易红烧肉', '红烧肉'],
            local_image_refs=['./000.jpg'],
        )
        matches = match_records_to_dishes(
            dishes=[
                {'dishId': '3', 'dishName': '红烧肉'},
                {'dishId': '6', 'dishName': '宫保鸡丁'},
            ],
            records=[record],
        )
        self.assertEqual(len(matches), 1)
        self.assertEqual(matches[0]['dishId'], '3')
        self.assertEqual(matches[0]['dishName'], '红烧肉')
        self.assertEqual(matches[0]['imageRef'], './000.jpg')

    def test_fill_missing_entries_by_dish_name_clones_same_name_asset(self):
        dishes = [
            {'dishId': '8', 'dishName': '可乐鸡翅'},
            {'dishId': '10', 'dishName': '可乐鸡翅'},
        ]
        existing = {
            '8': {
                'dishId': '8',
                'dishName': '可乐鸡翅',
                'aliases': ['可乐鸡翅'],
                'heroUrl': 'assets/images/prebuilt_dishes/dish-8-dish_1280.jpg',
                'thumbUrl': 'assets/images/prebuilt_dishes/dish-8-dish_768.jpg',
                'styleTag': 'golden_crisp',
                'updatedAt': '2026-04-10T00:00:00Z',
            },
        }
        filled = fill_missing_entries_by_dish_name(dishes=dishes, existing_by_id=existing)
        self.assertIn('10', filled)
        self.assertEqual(filled['10']['dishName'], '可乐鸡翅')
        self.assertEqual(filled['10']['heroUrl'], existing['8']['heroUrl'])
        self.assertIn('可乐鸡翅', filled['10']['aliases'])

    def test_enrich_manifest_sources_marks_legacy_prebuilt(self):
        enriched = enrich_manifest_sources(
            {
                '8': {
                    'dishId': '8',
                    'dishName': '可乐鸡翅',
                    'aliases': ['可乐鸡翅'],
                    'heroUrl': 'assets/images/prebuilt_dishes/dish-8-dish_1280.jpg',
                    'thumbUrl': 'assets/images/prebuilt_dishes/dish-8-dish_768.jpg',
                    'styleTag': 'golden_crisp',
                    'updatedAt': '2026-04-10T00:00:00Z',
                },
            }
        )
        self.assertEqual(enriched['8']['sourceType'], 'legacy_prebuilt_asset')
        self.assertEqual(enriched['8']['sourceProject'], 'eatwhat_assets')
        self.assertEqual(
            enriched['8']['sourcePath'],
            'assets/images/prebuilt_dishes/dish-8-dish_1280.jpg',
        )

    def test_build_source_audit_marks_existing_recipe_without_local_image(self):
        recipe_index = build_recipe_presence_index(
            [
                HowToCookRecipeRecord(
                    markdown_path=Path('/tmp/HowToCook/dishes/meat_dish/可乐鸡翅.md'),
                    recipe_name='可乐鸡翅',
                    aliases=['可乐鸡翅'],
                )
            ]
        )
        audit = build_source_audit(
            dishes=[{'dishId': '8', 'dishName': '可乐鸡翅'}],
            manifest_items=[
                {
                    'dishId': '8',
                    'dishName': '可乐鸡翅',
                    'aliases': ['可乐鸡翅'],
                    'heroUrl': 'assets/images/prebuilt_dishes/dish-8-dish_1280.jpg',
                    'thumbUrl': 'assets/images/prebuilt_dishes/dish-8-dish_768.jpg',
                    'styleTag': 'golden_crisp',
                    'updatedAt': '2026-04-10T00:00:00Z',
                    'sourceType': 'legacy_prebuilt_asset',
                    'sourceProject': 'eatwhat_assets',
                    'sourcePath': 'assets/images/prebuilt_dishes/dish-8-dish_1280.jpg',
                }
            ],
            recipe_presence_index=recipe_index,
        )
        self.assertEqual(audit['summary']['legacyPrebuiltCount'], 1)
        self.assertEqual(audit['summary']['exactRecipeWithoutLocalImageCount'], 1)
        self.assertTrue(audit['items'][0]['hasHowToCookRecipe'])
        self.assertEqual(audit['items'][0]['coverage'], 'legacy_prebuilt')


if __name__ == '__main__':
    unittest.main()
