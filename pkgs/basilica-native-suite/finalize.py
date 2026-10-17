"""Validate original captured receipts against current recipes; never relabel."""
import json
from evidence import HERE, manifest, require, validate_record

def validate_all(directory, current):
    results = json.loads((directory/'results.json').read_text())
    audits = json.loads((directory/'asset-audit.json').read_text())
    require(set(results) == set(current['members']),'exact thirteen result identities')
    for name, candidate in current['members'].items():
        validate_record(name,results[name],candidate,directory/'proofs'/f'{name}.json',audits)
        print(name+': current receipt validated')

def main():
    validate_all(HERE,manifest())

if __name__ == '__main__':
    main()
