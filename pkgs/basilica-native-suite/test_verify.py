"""Regressions: missing bundles and empty bundles must fail before loading."""
import subprocess
import os
import sys
import tempfile
import unittest
from pathlib import Path

class BundleValidation(unittest.TestCase):
    def test_missing_bundle_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run([sys.executable,os.environ.get('VERIFY_SCRIPT',str(Path(__file__).with_name('verify.py'))),
                                     directory,'Overture'],capture_output=True,text=True)
            self.assertNotEqual(result.returncode,0)
            self.assertIn('missing or empty VST3 bundle',result.stderr)

    def test_empty_bundle_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            (Path(directory)/'lib/vst3/Overture.vst3').mkdir(parents=True)
            result = subprocess.run([sys.executable,os.environ.get('VERIFY_SCRIPT',str(Path(__file__).with_name('verify.py'))),
                                     directory,'Overture'],capture_output=True,text=True)
            self.assertNotEqual(result.returncode,0)
            self.assertIn('missing or empty VST3 bundle',result.stderr)

if __name__ == '__main__':
    unittest.main()
