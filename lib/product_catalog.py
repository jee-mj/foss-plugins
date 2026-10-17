"""Offline product/route report validation and deterministic catalog assembly.

Evidence checks are structural, not source verification. Callers needing to
verify source claims must inspect the referenced immutable sources separately;
this module never fetches URLs or executes source/build callbacks or payloads.
"""

import copy
import ipaddress
import json
from pathlib import Path
import re
from urllib.parse import unquote, urlsplit


IDENTITY_FIXTURE = Path(__file__).resolve().parents[1] / "tests/product-catalog-identities.json"
ALIASES = {"AUDIO-003": ["BA-013"], "AUDIO-007": ["BA-006"], "AUDIO-058": ["BA-004"]}
REPORT_FIELDS = set("identity repository alias_ids source_revision disposition reason products evidence copyright_notes next_action".split())
PRODUCT_FIELDS = set("id name kind formats plugin_ids native windows".split())
NATIVE_FIELDS = set("status attributes reason next_action".split())
WINDOWS_FIELDS = set("status architecture toolchain artifact_type installer_source_status reason next_action".split())
NATIVE_STATUSES = {"packaged", "reuse-nixpkgs", "source-candidate", "upstream-binary", "port-required", "not-applicable", "needs-evidence"}
WINDOWS_STATUSES = {"source-candidate", "requires-windows-builder", "upstream-fallback", "port-required", "not-applicable", "needs-evidence"}
KINDS = {"instrument", "effect", "midi", "application", "utility", "scaffold", "unknown"}


def _text(value):
    return isinstance(value, str) and bool(value.strip())


def _commit(value):
    return isinstance(value, str) and re.fullmatch(r"(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})", value) is not None


def _https(value):
    if not _text(value) or any(c.isspace() for c in value) or "\\" in value:
        return False
    try:
        parsed = urlsplit(value)
        host = parsed.hostname
        if (parsed.scheme != "https" or not host or parsed.username is not None
                or parsed.password is not None or (parsed.port is not None and not 0 < parsed.port < 65536)):
            return False
        try:
            address = ipaddress.ip_address(host)
        except ValueError:
            # inet_aton-style shortened, octal and hex addresses must not fall
            # back to DNS names when strict IP parsing rejects their spelling.
            if re.fullmatch(r"(?:[0-9]+|0[xX][0-9a-fA-F]+)(?:\.(?:[0-9]+|0[xX][0-9a-fA-F]+))*\.?", host):
                return False
            if "." not in host or host.endswith((".local", ".localhost", ".internal", ".test", ".invalid")):
                return False
            if not all(re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?", part) for part in host.split(".")):
                return False
        else:
            if not address.is_global or "%" in host:
                return False
        if re.search(r"(?:^|[?&])(?:token|access_token|password|secret|api_key|key)=", unquote(parsed.query), re.I):
            return False
        return True
    except (TypeError, ValueError):
        return False


def _identities():
    return load_json(IDENTITY_FIXTURE)


def _github_source(value):
    """Return (repository, embedded ref) for explicit GitHub source URL forms.

    A recognized form is not necessarily immutable: the caller must require a
    full commit equal to the evidence revision. Other URLs are supplementary.
    """
    if not _https(value):
        return None
    parsed = urlsplit(value)
    parts = unquote(parsed.path).strip("/").split("/")
    if any(part in ("", ".", "..") for part in parts):
        return None
    if parsed.hostname == "github.com" and len(parts) >= 4 and parts[2] in ("blob", "tree", "commit", "raw"):
        if parts[2] in ("blob", "raw") and len(parts) < 5:
            return None
        return "/".join(parts[:2]), parts[3]
    if parsed.hostname == "raw.githubusercontent.com" and len(parts) >= 4:
        return "/".join(parts[:2]), parts[2]
    return None


def load_json(path):
    """Read strict JSON, rejecting duplicate keys at every nesting level."""
    def pairs(items):
        result = {}
        for key, value in items:
            if key in result:
                raise ValueError(f"duplicate JSON key: {key}")
            result[key] = value
        return result

    def constant(value):
        raise ValueError(f"non-JSON constant: {value}")

    with Path(path).open(encoding="utf-8") as stream:
        return json.load(stream, object_pairs_hook=pairs, parse_constant=constant)


class _Validator:
    def __init__(self):
        self.errors = []

    def error(self, path, message):
        self.errors.append(f"{path}: {message}")

    def fields(self, value, required, path):
        if not isinstance(value, dict):
            self.error(path, "must be an object")
            return False
        for key in sorted(required - value.keys()):
            self.error(path + "." + key, "required field missing")
        for key in sorted(value.keys() - required, key=str):
            self.error(path, f"unknown field {key!r}")
        return True

    def text(self, value, path):
        if not _text(value):
            self.error(path, "must be nonempty text")

    def enum(self, value, choices, path):
        if not isinstance(value, str) or value not in choices:
            self.error(path, "invalid enum value")

    def texts(self, value, path):
        if not isinstance(value, list):
            self.error(path, "must be an array of text")
            return
        seen = set()
        for i, item in enumerate(value):
            self.text(item, f"{path}[{i}]")
            if isinstance(item, str):
                if item in seen:
                    self.error(path, "duplicate item")
                seen.add(item)

    def public(self, value, path="report", ancestors=None, source_id=False):
        ancestors = set() if ancestors is None else ancestors
        if isinstance(value, (dict, list)):
            if id(value) in ancestors:
                self.error(path, "cyclic structure is not JSON")
                return
            ancestors = ancestors | {id(value)}
            items = sorted(value.items(), key=lambda pair: str(pair[0])) if isinstance(value, dict) else enumerate(value)
            for key, item in items:
                if isinstance(value, dict) and not isinstance(key, str):
                    self.error(path, "object keys must be strings")
                elif isinstance(value, dict):
                    self.public(key, path + ".<key>", ancestors)
                self.public(item, f"{path}.{key}", ancestors,
                            source_id or key == "plugin_ids")
        elif isinstance(value, str):
            decoded = unquote(unquote(value))
            if re.search(r"(?:/(?:home|Users|root|tmp|nix/store)/|~[/\\]|[A-Za-z]:\\|/private/|/var/(?:home|tmp)/|\\\\[^\\/\s]+[\\/][^\\/\s]+)", decoded):
                self.error(path, "private/local path is not public metadata")
            if re.search(r"\b(?:audio[-_]issue[-_]?\d+|site[-_]lab)\b", decoded, re.I):
                self.error(path, "private project marker is not public metadata")
            # Prose and nested keys can contain URLs too, outside evidence.url.
            for url in re.findall(r"\b[A-Za-z][A-Za-z0-9+.-]*://[^\s<>\"']+", decoded):
                try:
                    parsed = urlsplit(url)
                    credentials = parsed.username is not None or parsed.password is not None
                except ValueError:
                    credentials = "@" in url.split("/", 3)[2]
                if credentials:
                    self.error(path, "credential-bearing URL is not public metadata")
            if any(ord(c) < 32 and c not in "\n\r\t" and not (source_id and c == "\0") for c in value):
                self.error(path, "control character in text")
        elif value is not None and not isinstance(value, (bool, int, float)):
            self.error(path, "value is not JSON data")

    def source_ids(self, value, path, ancestors=None):
        # Source IDs may be nested format-specific objects, FUID word arrays,
        # byte strings, numeric IDs or explicit nulls. Never synthesize a UUID.
        ancestors = set() if ancestors is None else ancestors
        if value is None:
            return
        if isinstance(value, str):
            self.text(value, path)
            try:
                value.encode("utf-8")
            except UnicodeEncodeError:
                self.error(path, "source-ID text must encode as UTF-8")
        elif type(value) is int:
            return
        elif isinstance(value, (dict, list)):
            if id(value) in ancestors:
                return  # public() already reports the cycle.
            ancestors = ancestors | {id(value)}
            if isinstance(value, dict) and ("source_encoding" in value or "bytes_hex" in value):
                self.fields(value, {"source_encoding", "bytes_hex"}, path)
                if value.get("source_encoding") != "utf8-hex":
                    self.error(path + ".source_encoding", "must be utf8-hex")
                hexadecimal = value.get("bytes_hex")
                if not isinstance(hexadecimal, str) or re.fullmatch(r"(?:[0-9a-fA-F]{2})+", hexadecimal) is None:
                    self.error(path + ".bytes_hex", "must be nonempty contiguous hexadecimal byte pairs")
                    return
                try:
                    decoded = bytes.fromhex(hexadecimal).decode("utf-8")
                except UnicodeDecodeError:
                    self.error(path + ".bytes_hex", "must decode as UTF-8")
                    return
                if "\0" not in decoded:
                    self.error(path + ".bytes_hex", "escape representation requires an actual NUL in decoded source ID")
                self.public(decoded, path + ".<decoded>", source_id=True)
                return
            if not value:
                self.error(path, "empty source-ID structure")
            items = sorted(value.items(), key=lambda pair: str(pair[0])) if isinstance(value, dict) else enumerate(value)
            for key, item in items:
                if isinstance(key, str) and key.endswith("fuid_words"):
                    if (not isinstance(item, list) or len(item) != 4 or not all(
                            (isinstance(word, str) and re.fullmatch(r"(?:0x)?[0-9a-fA-F]{8}", word))
                            or (type(word) is int and 0 <= word <= 0xffffffff) for word in item)):
                        self.error(path + "." + key, "FUID requires four source 32-bit words")
                self.source_ids(item, f"{path}.{key}", ancestors)
        else:
            self.error(path, "invalid source-ID type")

    def route(self, value, path, windows=False):
        if not self.fields(value, WINDOWS_FIELDS if windows else NATIVE_FIELDS, path):
            return
        self.enum(value.get("status"), WINDOWS_STATUSES if windows else NATIVE_STATUSES, path + ".status")
        for field in ("reason", "next_action"):
            self.text(value.get(field), path + "." + field)
        if windows:
            self.enum(value.get("architecture"), {"x86_64", "x86", "arm64", "multi", "unknown"}, path + ".architecture")
            self.enum(value.get("artifact_type"), {"manual-copy-archive", "exe-installer", "msi-installer", "installer-zip", "plugin-bundle", "source-only", "unknown", "none"}, path + ".artifact_type")
            self.enum(value.get("installer_source_status"), {"present", "not-found", "unverified", "not-applicable"}, path + ".installer_source_status")
            self.text(value.get("toolchain"), path + ".toolchain")
        else:
            self.texts(value.get("attributes"), path + ".attributes")
            if value.get("status") in ("packaged", "reuse-nixpkgs") and not value.get("attributes"):
                self.error(path + ".attributes", "package route requires a real package reference")

    def report(self, value):
        self.public(value)
        if not self.fields(value, REPORT_FIELDS, "report"):
            return
        identities = _identities()
        identity = value.get("identity")
        if not isinstance(identity, str) or identity not in identities:
            self.error("identity", "unknown primary identity")
        else:
            if value.get("repository") != identities[identity]:
                self.error("repository", "canonical repository mismatch")
            if value.get("alias_ids") != ALIASES.get(identity, []):
                self.error("alias_ids", "canonical alias mismatch")
        self.text(value.get("repository"), "repository")
        self.texts(value.get("alias_ids"), "alias_ids")
        self.enum(value.get("disposition"), {"applicable", "needs-evidence", "skip"}, "disposition")
        for field in ("reason", "next_action"):
            self.text(value.get(field), field)
        self.texts(value.get("copyright_notes"), "copyright_notes")
        revision = value.get("source_revision")
        if revision is None:
            if (not _text(value.get("reason"))
                    or not re.search(r"(?:gap|missing|unresolved|unverified|unknown|unavailable|not .{0,30}(?:verified|resolved|found|available))", value["reason"], re.I)):
                self.error("source_revision", "null requires an explicit source evidence gap")
        elif not _commit(revision):
            self.error("source_revision", "must be a full commit or null with an evidence gap")
        evidence = value.get("evidence")
        if not isinstance(evidence, list):
            self.error("evidence", "must be an array")
        else:
            if revision is not None and not evidence:
                self.error("evidence", "pinned source requires evidence")
            source_evidence = False
            for i, item in enumerate(evidence):
                path = f"evidence[{i}]"
                if not self.fields(item, {"url", "revision", "summary"}, path):
                    continue
                url = item.get("url")
                if not _https(url):
                    self.error(path + ".url", "must be a public HTTPS source without credentials")
                pin = item.get("revision")
                if pin is not None and not _commit(pin):
                    self.error(path + ".revision", "must be a full commit or null")
                self.text(item.get("summary"), path + ".summary")
                source = _github_source(url)
                if source is not None:
                    repository, embedded_revision = source
                    immutable = _commit(embedded_revision) and pin == embedded_revision
                    if not immutable:
                        self.error(path, "source URL and full evidence revision must match")
                    if immutable and pin == revision and repository == value.get("repository"):
                        source_evidence = True
            if _commit(revision) and not source_evidence:
                self.error("evidence", "must include evidence for source_revision")
        products = value.get("products")
        if not isinstance(products, list):
            self.error("products", "must be an array")
            return
        ids = set()
        for i, product in enumerate(products):
            path = f"products[{i}]"
            if not self.fields(product, PRODUCT_FIELDS, path):
                continue
            product_id = product.get("id")
            if (not isinstance(product_id, str) or not isinstance(identity, str)
                    or re.fullmatch(re.escape(identity) + r"/[a-z0-9]+(?:-[a-z0-9]+)*", product_id) is None):
                self.error(path + ".id", "must be primary-identity/stable-source-target-slug")
            elif product_id in ids:
                self.error(path + ".id", "duplicate product ID")
            else:
                ids.add(product_id)
            self.text(product.get("name"), path + ".name")
            self.enum(product.get("kind"), KINDS, path + ".kind")
            formats = product.get("formats")
            self.texts(formats, path + ".formats")
            plugin_ids = product.get("plugin_ids")
            if not isinstance(plugin_ids, dict):
                self.error(path + ".plugin_ids", "must be a format-to-source-ID object")
            else:
                for format_name, source_id in sorted(plugin_ids.items(), key=lambda pair: str(pair[0])):
                    if not isinstance(formats, list) or format_name not in formats:
                        self.error(path + ".plugin_ids", "format absent from evidenced formats")
                    self.source_ids(source_id, path + ".plugin_ids." + str(format_name))
            self.route(product.get("native"), path + ".native")
            self.route(product.get("windows"), path + ".windows", windows=True)


def validation_errors(report):
    """Return stable, path-qualified errors for a decoded report; never mutate it.

    Structural evidence validation does not establish source truth, installed
    counts, package availability, build success, host acceptance or readiness.
    """
    validator = _Validator()
    validator.report(report)
    return sorted(set(validator.errors))


def _canonical_source_ids(value):
    """Losslessly escape actual NULs in source-ID values, never source literals."""
    if isinstance(value, str) and "\0" in value:
        return {"source_encoding": "utf8-hex", "bytes_hex": value.encode("utf-8").hex()}
    if isinstance(value, dict):
        return {key: _canonical_source_ids(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_canonical_source_ids(item) for item in value]
    return value


def merge_reports(reports):
    """Validate the captured set and copy it with NUL-safe canonical source IDs."""
    identities = _identities()
    errors = []
    by_id = {}
    repositories = set()
    for index, report in enumerate(reports):
        errors.extend(f"report[{index}]: {error}" for error in validation_errors(report))
        if not isinstance(report, dict):
            continue
        identity = report.get("identity")
        if isinstance(identity, str):
            if identity in by_id:
                errors.append(f"duplicate identity: {identity}")
            by_id[identity] = report
        repository = report.get("repository")
        if isinstance(repository, str):
            canonical = repository.casefold()
            if canonical in repositories:
                errors.append(f"duplicate canonical repository: {repository}")
            repositories.add(canonical)
    for identity in sorted(identities.keys() - by_id.keys()):
        errors.append(f"missing identity: {identity}")
    for identity in sorted(by_id.keys() - identities.keys()):
        errors.append(f"extra identity: {identity}")
    if errors:
        raise ValueError("\n".join(sorted(errors)))
    ordered = copy.deepcopy([by_id[identity] for identity in identities])
    for report in ordered:
        for product in report["products"]:
            product["plugin_ids"] = _canonical_source_ids(product["plugin_ids"])
    return {
        "schema_version": 1, "captured_date": "2026-10-17",
        "source_catalog": "catalog/audio-104.json",
        "product_count": sum(len(report["products"]) for report in ordered),
        "repositories": ordered,
    }
