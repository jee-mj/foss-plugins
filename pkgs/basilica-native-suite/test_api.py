"""Negative evaluations of the real recipe API in narrowly copied fixtures.

No per-case build: only nix eval, including when a candidate identity changes.
"""
import copy
import json
import shutil
import subprocess
import tempfile
import unittest
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
from evidence import manifest
from finalize import validate_all
from source_profiles import evaluate_profiles, validate_profiles

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]

class Eligibility(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory(prefix='basilica-api-')
        cls.fixture = Path(cls.temporary.name)
        for relative in ('pkgs/basilica-native-suite','pkgs/basilica-miserere'):
            shutil.copytree(ROOT/relative,cls.fixture/relative,ignore=shutil.ignore_patterns('__pycache__'))
        for relative in ('lib/juce-runtime.nix','lib/plugin-artifacts.nix',
                         'tests/basilica-native-suite.nix','tests/basilica-miserere.nix'):
            target = cls.fixture/relative
            target.parent.mkdir(parents=True,exist_ok=True)
            shutil.copyfile(ROOT/relative,target)
        cls.family = cls.fixture/'pkgs/basilica-native-suite'
        cls.originals = {p:p.read_bytes() for p in cls.fixture.rglob('*') if p.is_file()}

    @classmethod
    def tearDownClass(cls):
        cls.temporary.cleanup()

    def setUp(self):
        for path, payload in self.originals.items():
            path.write_bytes(payload)

    def change(self, filename, operation):
        path = self.family/filename
        data = json.loads(path.read_text())
        operation(data)
        path.write_text(json.dumps(data))

    def evaluate(self, override=''):
        expression = f'''let
          f = builtins.getFlake "git+file://{ROOT}";
          p = import f.inputs.nixpkgs {{system="x86_64-linux";config.allowUnfree=true;}};
          s = p.callPackage {self.family} {{ {override} }};
        in {{
          packages = builtins.attrNames s.namedPackages;
          definitions = builtins.attrNames (s.candidateDefinitions or {{}});
          candidateChecks = builtins.attrNames (s.candidateChecks or {{}});
          sourceStatuses = builtins.mapAttrs (_: v: v.sourceStatus or "missing") s.profiles;
          aggregate = s ? aggregate;
          statuses = builtins.mapAttrs (_: v: v.status) s.profiles;
          licenses = if s ? aggregate then s.aggregate.meta.license or [] else [];
          description = if s ? aggregate then s.aggregate.meta.description or "" else "";
          platforms = if s ? aggregate then s.aggregate.meta.platforms or [] else [];
        }}'''
        result = subprocess.run(['nix','eval','--impure','--no-write-lock-file','--json','--expr',expression],capture_output=True,text=True)
        self.assertNotIn("will be built",result.stderr, 'evaluation must not build candidates')
        return result, json.loads(result.stdout) if result.returncode == 0 else None

    def stale(self, name='Overture'):
        result, value = self.evaluate()
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertNotIn('basilica-'+name.lower(),value['packages'])
        self.assertIn(value['statuses'][name],('stale','not-tested'))
        self.assertFalse(value['aggregate'])
        return value

    def test_current_baseline_and_flat_aggregate_metadata(self):
        result, value = self.evaluate()
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(len(value['packages']),13)
        self.assertTrue(value['aggregate'])
        self.assertTrue(value['description'])
        self.assertEqual(value['platforms'],['x86_64-linux'])
        self.assertTrue(all(isinstance(item,dict) for item in value['licenses']))
        ids = [item['spdxId'] for item in value['licenses']]
        self.assertEqual(set(ids),{'AGPL-3.0-only','OFL-1.1','MIT','CC0-1.0'})
        self.assertEqual(len(ids),len(set(ids)))

    def test_portable_definitions_do_not_require_build_receipts(self):
        self.change('results.json',lambda data:data.clear())
        result, value = self.evaluate()
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(len(value['definitions']),13)
        self.assertEqual(value['candidateChecks'],value['definitions'])
        self.assertEqual(set(value['sourceStatuses'].values()),{'source-audited'})
        self.assertEqual(set(value['statuses'].values()),{'not-tested'})
        self.assertEqual(value['packages'],[])
        self.assertFalse(value['aggregate'])

    def test_portable_definitions_require_every_consumed_source_audit(self):
        for source, blocked in [('Overture',['basilica-overture']),('linear',['basilica-seraph']),
                                ('JUCE',None),('Miserere',['basilica-miserere'])]:
            for kind in ('revision','hash','unexpected','missing'):
                with self.subTest(source=source,kind=kind):
                    self.setUp()
                    def mutate(data):
                        if kind == 'missing':
                            data.pop(source)
                        else:
                            data[source][kind] = ['unknown-model-source'] if kind == 'unexpected' else 'stale'
                    self.change('asset-audit.json',mutate)
                    result, value = self.evaluate()
                    self.assertEqual(result.returncode,0,result.stderr)
                    expected = 0 if blocked is None else 12
                    self.assertEqual(len(value['definitions']),expected)
                    self.assertEqual(value['candidateChecks'],value['definitions'])
                    for attribute in blocked or []:
                        self.assertNotIn(attribute,value['definitions'])
                    self.assertFalse(value['aggregate'])

    def test_two_public_nixpkgs_profiles_offline(self):
        results = validate_profiles(evaluate_profiles(self.family))
        baseline = json.loads((HERE/'api-verification.json').read_text())['metadata']
        own = results['verified-fd146']['metadata']
        self.assertEqual({name:p['out'] for name,p in own['namedPackages'].items()},baseline['packages'])
        self.assertEqual({name:p['drv'] for name,p in own['namedPackages'].items()},baseline['packageDrvs'])
        self.assertEqual({name:p['drv'] for name,p in own['checks'].items()},baseline['checkDrvs'])
        self.assertEqual({name:p['status'] for name,p in own['profiles'].items()},baseline['profiles'])
        self.assertEqual(own['aggregateOutput'],baseline['aggregateOutput'])

    def test_stale_result_fields(self):
        changes = [
            ('version','99.0'),('sourceHash','sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='),
            ('exitCode',1),('exitCode',False),('checkOutput','/nix/store/stale-check'),
            ('packageDrv','/nix/store/stale-package.drv'),('checkDrv','/nix/store/stale-check.drv'),
            ('format','AU'),('receiptSha256','0'*64)]
        for key, value in changes:
            with self.subTest(field=key):
                self.setUp()
                self.change('results.json',lambda data: data['Overture'].__setitem__(key,value))
                self.stale()

    def test_stale_verifier_receipt(self):
        for operation in (lambda r:r['verification'].__setitem__('plugin','/nix/store/stale-plugin'),
                          lambda r:r['verification'].__setitem__('sha256','0'*64),
                          lambda r:r.pop('verification'),lambda r:r.pop('binding',None)):
            with self.subTest(operation=str(operation)):
                self.setUp()
                self.change('results.json',lambda data: operation(data['Overture']))
                self.stale()

    def test_pin_changes_invalidate_previous_proof(self):
        for key, value in [('hash','sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='),('version','99.0')]:
            with self.subTest(field=key):
                self.setUp()
                self.change('pins.json',lambda data: data['Overture'].__setitem__(key,value))
                self.stale()

    def test_recipe_verifier_and_test_changes_invalidate(self):
        for path in (self.family/'package.nix',self.family/'verify.py',
                     self.fixture/'tests/basilica-native-suite.nix'):
            with self.subTest(path=path.name):
                self.setUp()
                with path.open('a') as stream:
                    stream.write('\n# changed recipe/verifier test fixture\n')
                self.stale()

    def test_nave_requires_current_patch_and_modification_evidence(self):
        self.change('results.json',lambda data:data['Nave'].pop('sourceModification'))
        self.stale('Nave')
        self.setUp()
        path = self.family/'nave-scalar-minimum.patch'
        path.write_text(path.read_text()+'\n# changed patch fixture\n')
        self.stale('Nave')

    def test_every_consumed_dependency_audit_is_required(self):
        for dependency in ('linear','stretch','JUCE'):
            for kind in ('revision','hash','unexpected','missing'):
                with self.subTest(dependency=dependency,kind=kind):
                    self.setUp()
                    def mutate(data):
                        if kind == 'missing':
                            data.pop(dependency,None)
                        else:
                            data.setdefault(dependency,{})[kind] = ['unreviewed'] if kind == 'unexpected' else 'stale'
                    self.change('asset-audit.json',mutate)
                    value = self.stale('Seraph')
                    if dependency != 'JUCE':
                        self.assertIn('basilica-overture',value['packages'])

    def test_dependency_pin_change_requires_matching_audit(self):
        self.change('pins.json',lambda data:data['linear'].__setitem__('hash','sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='))
        self.stale('Seraph')

    def test_finalizer_rejects_original_receipt_mismatch_without_rewriting(self):
        current = manifest()
        for field, value in [('sourceHash','sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='),('exitCode',False),('audio','missing')]:
            with self.subTest(field=field):
                self.setUp()
                def mutate(data):
                    if field == 'audio':
                        data['Overture'].pop(field)
                    else:
                        data['Overture'][field] = value
                self.change('results.json',mutate)
                path = self.family/'results.json'
                before = path.read_bytes()
                with redirect_stdout(StringIO()), self.assertRaisesRegex(ValueError,field):
                    validate_all(self.family,current)
                self.assertEqual(path.read_bytes(),before)

    def test_relabeling_record_to_new_pin_does_not_refresh_evidence(self):
        new_hash = 'sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
        self.change('pins.json',lambda data:data['Overture'].__setitem__('hash',new_hash))
        self.change('results.json',lambda data:data['Overture'].__setitem__('sourceHash',new_hash))
        self.stale()

    def test_results_do_not_change_candidate_identities(self):
        expression = f'''let f=builtins.getFlake "git+file://{ROOT}";
          p=import f.inputs.nixpkgs {{system="x86_64-linux";}};
          c=p.callPackage {self.family}/candidates.nix {{}};
        in builtins.mapAttrs (_: check: {{drv=check.drvPath;out=check.outPath;}}) c.checks'''
        command = ['nix','eval','--impure','--no-write-lock-file','--json','--expr',expression]
        before = subprocess.check_output(command,stderr=subprocess.PIPE)
        self.change('results.json',lambda data:data.clear())
        after = subprocess.check_output(command,stderr=subprocess.PIPE)
        self.assertEqual(json.loads(before),json.loads(after))

    def test_missing_archived_receipt_is_not_passed(self):
        (self.family/'proofs/Overture.json').unlink()
        self.stale()

    def test_expected_inventory_is_not_inferred_from_mutated_pins(self):
        operations = [lambda d:d.pop('Overture'),lambda d:d['Overture'].pop('identity'),
                      lambda d:d.clear(),lambda d:d['Overture'].__setitem__('identity','BA-999'),
                      lambda d:d['Overture'].__setitem__('audio','AUDIO-999'),
                      lambda d:d['Silentium'].__setitem__('audio','AUDIO-003'),
                      lambda d:d.__setitem__('Invented',copy.deepcopy(d['Overture']))]
        for operation in operations:
            with self.subTest(operation=str(operation)):
                self.setUp()
                self.change('pins.json',operation)
                result, value = self.evaluate()
                if result.returncode:
                    self.assertIn('Basilica inventory',result.stderr)
                else:
                    self.assertFalse(value['aggregate'])
                    self.assertEqual(value['packages'],[])
                    self.assertEqual(value['definitions'],[])
                    self.assertEqual(value['candidateChecks'],[])

    def test_aggregate_rejects_missing_or_nonfree_member_license(self):
        for meta in ('builtins.removeAttrs old.meta ["license"]',
                     'old.meta // {license=p.lib.licenses.unfree;}',
                     'old.meta // {license=[];}'):
            with self.subTest(meta=meta):
                override = f'''basilica-miserere = (p.callPackage {self.fixture}/pkgs/basilica-miserere {{
                  juceRuntime=p.callPackage {self.fixture}/lib/juce-runtime.nix {{}};
                  pluginArtifacts=p.callPackage {self.fixture}/lib/plugin-artifacts.nix {{}};
                }}).overrideAttrs (old: {{meta={meta};}});'''
                result, value = self.evaluate(override)
                if result.returncode:
                    self.assertIn('Basilica aggregate metadata',result.stderr)
                else:
                    self.assertFalse(value['aggregate'])

if __name__ == '__main__':
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(Eligibility)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    (HERE/'api-tests.json').write_text(json.dumps(dict(
        command='python3 pkgs/basilica-native-suite/test_api.py',
        methods=result.testsRun,failures=len(result.failures),errors=len(result.errors),
        passed=result.wasSuccessful(),scope='nix eval mutations; no per-case source builds'),indent=2)+'\n')
    raise SystemExit(not result.wasSuccessful())
