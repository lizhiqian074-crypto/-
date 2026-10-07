"""Media importer integration tests using temporary fixtures, not user's archive."""
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1]

class ImporterTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root/'tools').mkdir()
        (self.root/'data').mkdir()
        shutil.copyfile(PROJECT/'tools/import_assets.py', self.root/'tools/import_assets.py')
        shutil.copyfile(PROJECT/'data/assets.json', self.root/'data/assets.json')
        self.archive = self.root/'素材.zip'
        self.before = (self.root/'data/assets.json').read_bytes()

    def tearDown(self):
        self.tmp.cleanup()

    def archive_with(self, files):
        with zipfile.ZipFile(self.archive, 'w') as z:
            for path, value in files.items():
                z.writestr(path, value)

    def run_tool(self, *args):
        return subprocess.run([sys.executable, str(self.root/'tools/import_assets.py'), str(self.archive), *args], capture_output=True, text=True)

    def test_inspection_changes_nothing(self):
        self.archive_with({'模型/毛冠鹿.glb': b'fixture'})
        result = self.run_tool()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.root/'assets').exists())
        self.assertEqual((self.root/'data/assets.json').read_bytes(), self.before)
        self.assertIn('deer_model', result.stdout)

    def test_import_preserves_gltf_dependencies_and_ignores_code(self):
        self.archive_with({'模型/毛冠鹿.gltf': b'{}', '模型/deer.bin': b'bin', '模型/texture.png': b'img', 'evil.gd': b'not executed', 'project.godot': b'not imported'})
        result = self.run_tool('--apply')
        self.assertEqual(result.returncode, 0, result.stderr)
        base = self.root/'assets/imported/素材'
        self.assertTrue((base/'模型/deer.bin').exists())
        self.assertTrue((base/'模型/texture.png').exists())
        self.assertFalse((base/'evil.gd').exists())
        self.assertFalse((base/'project.godot').exists())
        data = json.loads((self.root/'data/assets.json').read_text())
        self.assertTrue(data['deer_model'].endswith('毛冠鹿.gltf'))

    def test_idempotent_repeat(self):
        self.archive_with({'毛冠鹿.glb': b'abc'})
        self.assertEqual(self.run_tool('--apply').returncode, 0)
        after = (self.root/'data/assets.json').read_bytes()
        self.assertEqual(self.run_tool('--apply').returncode, 0)
        self.assertEqual((self.root/'data/assets.json').read_bytes(), after)

    def test_refuses_existing_different_asset(self):
        self.archive_with({'毛冠鹿.glb': b'one'})
        self.assertEqual(self.run_tool('--apply').returncode, 0)
        self.archive_with({'毛冠鹿.glb': b'two'})
        self.assertNotEqual(self.run_tool('--apply').returncode, 0)
        self.assertEqual((self.root/'assets/imported/素材/毛冠鹿.glb').read_bytes(), b'one')

    def test_path_traversal_rejected(self):
        self.archive_with({'../outside.png': b'image'})
        self.assertNotEqual(self.run_tool('--apply').returncode, 0)
        self.assertFalse((self.root/'outside.png').exists())

    def test_ambiguous_models_not_guessed(self):
        self.archive_with({'毛冠鹿A.glb': b'a', '毛冠鹿B.glb': b'b'})
        self.assertEqual(self.run_tool('--apply').returncode, 0)
        config = json.loads((self.root/'data/assets.json').read_text())
        self.assertEqual(config['deer_model'], 'res://assets/models/tufted_deer.glb')

    def test_explicit_mapping(self):
        self.archive_with({'one.glb': b'a', 'two.glb': b'b'})
        mapping = self.root/'mapping.json'
        mapping.write_text(json.dumps({'deer_model': 'res://assets/imported/素材/two.glb'}))
        result = self.run_tool('--mapping', str(mapping), '--apply')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(json.loads((self.root/'data/assets.json').read_text())['deer_model'].endswith('two.glb'))

    def test_mp4_not_mapped_as_playable_video(self):
        self.archive_with({'纪录片.mp4': b'video'})
        self.assertEqual(self.run_tool('--apply').returncode, 0)
        config = json.loads((self.root/'data/assets.json').read_text())
        self.assertEqual(config['documentary'], 'res://assets/video/tufted_deer_documentary.ogv')

if __name__ == '__main__':
    unittest.main(verbosity=2)
