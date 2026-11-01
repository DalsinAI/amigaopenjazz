import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('fetch_runtime_data', ROOT / 'scripts/fetch_runtime_data.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class RuntimeDataTests(unittest.TestCase):
    """Every dataset is pinned to the file it was on 1 November 2026: its SHA-256 and its size (Dale: "resolve")."""

    def test_every_dataset_is_pinned(self):
        manifest = MODULE.load_manifest(ROOT)
        for name, spec in manifest['datasets'].items():
            self.assertRegex(spec.get('sha256') or '', r'^[0-9a-f]{64}$', name)
            self.assertIsInstance(spec.get('size'), int, name)
            self.assertGreater(spec['size'], 0, name)

    def test_cached_file_of_other_content_or_size_is_dropped(self):
        manifest = MODULE.load_manifest(ROOT)
        for name, spec in manifest['datasets'].items():
            with tempfile.TemporaryDirectory() as directory:
                cache = Path(directory)
                (cache / spec['filename']).write_bytes(b'not the dataset')
                result = MODULE.fetch_one(name, spec, cache, allow_network=False)
                self.assertEqual(result['state'], 'missing-network-disabled', name)
                self.assertFalse((cache / spec['filename']).exists(), name)

    def test_right_hash_wrong_size_is_dropped(self):
        manifest = MODULE.load_manifest(ROOT)
        for name, spec in manifest['datasets'].items():
            with tempfile.TemporaryDirectory() as directory:
                cache = Path(directory)
                data = b'x' * 10
                (cache / spec['filename']).write_bytes(data)
                odd = dict(spec, sha256=MODULE.hashlib.sha256(data).hexdigest(), size=11)
                result = MODULE.fetch_one(name, odd, cache, allow_network=False)
                self.assertEqual(result['state'], 'missing-network-disabled', name)
                self.assertFalse((cache / spec['filename']).exists(), name)


if __name__ == '__main__':
    unittest.main()
