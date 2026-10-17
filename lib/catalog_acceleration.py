"""Offline validation of catalog schema-2 acceleration claims.

This checks evidence structure and subject identity, not the truth of upstream
claims, package exports, or the contents of referenced documents.
"""

import ipaddress
import re
from urllib.parse import unquote, urlsplit


STAGES = ("evaluation", "build", "load", "model_execution", "provider_execution", "host")
HARDWARE_STAGES = ("model_execution", "provider_execution", "host")
STATUSES = ("not-run", "passed", "failed", "not-run-policy", "not-applicable")
KINDS = ("neural-inference", "non-neural-dsp", "training", "external-inference", "application")


def _text(value):
    return isinstance(value, str) and bool(value.strip()) and not any(ord(c) < 32 for c in value)


def _commit(value):
    return isinstance(value, str) and re.fullmatch(r"[0-9a-fA-F]{40}|[0-9a-fA-F]{64}", value) is not None


def _sha256(value):
    return isinstance(value, str) and re.fullmatch(r"[0-9a-fA-F]{64}", value) is not None


def _https(value):
    if not _text(value) or any(c.isspace() for c in value) or "\\" in value:
        return False
    try:
        parsed = urlsplit(value)
        host = parsed.hostname
        if parsed.scheme != "https" or not host or parsed.username is not None or parsed.password is not None:
            return False
        if parsed.port is not None and not 0 < parsed.port < 65536:
            return False
        if "." not in host or host.endswith((".localhost", ".local", ".internal")):
            return False
        if not all(re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?", label) for label in host.split(".")):
            return False
        try:
            if not ipaddress.ip_address(host).is_global:
                return False
        except ValueError:
            pass
        if re.search(r"(?:^|[?&])(?:token|access_token|password|secret|api_key|key)=", parsed.query, re.I):
            return False
        return True
    except (ValueError, TypeError):
        return False


def _relative(value):
    if not _text(value):
        return False
    decoded = unquote(value)
    return (not decoded.startswith(("/", "~", ".")) and ":" not in decoded
            and "\\" not in decoded and "?" not in decoded and "#" not in decoded
            and all(part not in ("", ".", "..") for part in decoded.split("/")))


def _reference(value):
    return _https(value) or _relative(value)


def _artifact(value):
    if not _text(value):
        return False
    if (re.fullmatch(r"sha256:[0-9a-fA-F]{64}", value)
            or re.fullmatch(r"sha256-[A-Za-z0-9+/]{43}=", value)):
        return True
    parts = value.split("/")
    return (len(parts) >= 4 and parts[:3] == ["", "nix", "store"]
            and re.fullmatch(r"[0-9abcdfghijklmnpqrsvwxyz]{32}-[A-Za-z0-9+_?=-][A-Za-z0-9+._?=-]{0,210}", parts[3]) is not None
            and all(part and unquote(part) not in (".", "..")
                    and not any(c in "/\\" or ord(c) < 32 or 127 <= ord(c) <= 159 for c in unquote(part))
                    for part in parts[4:]))


class _Validator:
    def __init__(self):
        self.errors = []

    def error(self, path, message):
        self.errors.append(f"{path}: {message}")

    def public_data(self, value):
        # Also inspect prose/extension fields, where private model paths can leak.
        stack = [("acceleration", value)]
        seen = set()
        while stack:
            path, item = stack.pop()
            if isinstance(item, (dict, list)):
                if id(item) in seen:
                    continue
                seen.add(id(item))
                children = sorted(item.items(), key=lambda pair: str(pair[0])) if isinstance(item, dict) else list(enumerate(item))
                stack.extend((f"{path}.{key}", child) for key, child in reversed(children))
            elif isinstance(item, str):
                decoded = unquote(item)
                # URL paths are public references, not local absolute paths.
                # Strip URLs before decoding so encoded spaces remain inside them.
                prose = unquote(re.sub(r"https?://[^\s\"'<>`]+", "", item, flags=re.I))
                # A documented single-segment HTTP endpoint is not a local file.
                # Keep bare paths and multi-component filesystem paths screened.
                prose = re.sub(r"\bconfigured\s+/[A-Za-z][A-Za-z0-9_-]*\s+endpoint\b", "", prose, flags=re.I)
                absolute_paths = re.findall(r"(?:^|[\s\"'`=(:\[{,;])(/[^\s\"'`<>()\[\]{},;]+)", prose)
                # These exact GPU device nodes are public system identities;
                # their siblings and descendants are not privacy exceptions.
                private_posix = any(not (_artifact(candidate.rstrip("."))
                                        or re.fullmatch(r"/arch:(?:IA32|SSE|SSE2|AVX|AVX2|AVX512)", candidate.rstrip("."))
                                        or re.fullmatch(r"/dev/(?:dri/renderD[0-9]+|nvidia(?:[0-9]+|ctl|-uvm))", candidate.rstrip(".")))
                                    for candidate in absolute_paths)
                if private_posix or re.search(r"(?:^|[\s\"'=(:])(?:~[/\\]|[A-Za-z]:[/\\]|\\\\)", prose):
                    self.error(path, "private filesystem paths must not be published")
                if re.search(r"https?://[^/\s]*@", decoded, re.I) or re.search(r"[?&](?:token|access_token|password|secret|api_key)=", decoded, re.I):
                    self.error(path, "credentials must not be published")

    def record(self, value, path, fields):
        if not isinstance(value, dict):
            self.error(path, "must be an object")
            return {}
        for field in fields:
            if field not in value:
                self.error(f"{path}.{field}", "required field missing")
        return value

    def collection(self, value, path):
        if not isinstance(value, list):
            self.error(path, "must be an array")
            return []
        return value

    def string(self, value, path, *, nullable=False, empty=False):
        if nullable and value is None:
            return
        if not (_text(value) or (empty and value == "")):
            self.error(path, "must be a nonempty string" + (" or null" if nullable else ""))

    def enum(self, value, path, choices):
        if not isinstance(value, str) or value not in choices:
            self.error(path, "must be one of " + ", ".join(choices))

    def revision(self, value, path, *, nullable=True):
        if not (nullable and value is None) and not _commit(value):
            self.error(path, "must be a full source commit" + (" or null" if nullable else ""))

    def evidence(self, value, path):
        result = []
        for i, item in enumerate(self.collection(value, path)):
            p = f"{path}[{i}]"
            before = len(self.errors)
            e = self.record(item, p, ("kind", "reference", "revision", "stage", "summary"))
            self.enum(e.get("kind"), p + ".kind", ("upstream", "verification"))
            self.enum(e.get("stage"), p + ".stage", ("assessment", *STAGES))
            self.string(e.get("summary"), p + ".summary")
            self.revision(e.get("revision"), p + ".revision")
            if not _reference(e.get("reference")):
                self.error(p + ".reference", "requires a public HTTPS URL or repository-relative document")
            if "subject" in e:
                self.subject(e["subject"], p + ".subject")
            if len(self.errors) == before:
                result.append(e)
        return result

    def subject(self, value, path):
        s = self.record(value, path, ("package_attribute", "source_revision", "artifact", "attempt", "runtime_id", "model_id", "model_sha256", "environment"))
        for field in ("package_attribute", "artifact", "attempt", "model_id"):
            self.string(s.get(field), path + "." + field, nullable=True)
        self.string(s.get("runtime_id"), path + ".runtime_id")
        self.revision(s.get("source_revision"), path + ".source_revision", nullable=False)
        if s.get("model_sha256") is not None and not _sha256(s["model_sha256"]):
            self.error(path + ".model_sha256", "must be a SHA-256 hex digest or null")
        e = self.record(s.get("environment"), path + ".environment", ("os", "architecture", "execution_context", "gpu_vendor", "gpu_model", "driver"))
        for field in ("os", "architecture", "execution_context", "gpu_vendor", "gpu_model", "driver"):
            self.string(e.get(field), path + ".environment." + field, nullable=field.startswith("gpu_") or field == "driver")

    def pins(self, value, path, packaged, recipe):
        pins = self.collection(value, path)
        if packaged and not pins and not recipe:
            self.error(path, "packaged runtime requires version/revision and artifact hash or cited package recipe")
        for i, item in enumerate(pins):
            p = f"{path}[{i}]"
            pin = self.record(item, p, ("name", "version", "revision", "hash", "source_url", "note"))
            self.string(pin.get("name"), p + ".name")
            for field in ("version", "hash"):
                self.string(pin.get(field), p + "." + field, nullable=True)
            self.revision(pin.get("revision"), p + ".revision")
            if pin.get("source_url") is not None and not _https(pin["source_url"]):
                self.error(p + ".source_url", "must be a public HTTPS URL or null")
            unresolved = any(pin.get(k) is None for k in ("version", "revision", "hash", "source_url"))
            self.string(pin.get("note"), p + ".note", empty=not unresolved)
            if packaged and not recipe and (not (_text(pin.get("version")) or _commit(pin.get("revision"))) or not _text(pin.get("hash"))):
                self.error(p, "packaged runtime requires version/revision and artifact hash")

    def models(self, value, path):
        models = {}
        for i, item in enumerate(self.collection(value, path)):
            p = f"{path}[{i}]"
            m = self.record(item, p, ("id", "source_kind", "source_url", "revision", "sha256", "bytes", "license_evidence", "acquisition"))
            self.string(m.get("id"), p + ".id")
            self.enum(m.get("source_kind"), p + ".source_kind", ("official-download", "user-supplied", "bundled", "manual", "unknown"))
            self.enum(m.get("acquisition"), p + ".acquisition", ("not-requested", "authorized", "acquired", "manual-required"))
            self.string(m.get("license_evidence"), p + ".license_evidence")
            self.revision(m.get("revision"), p + ".revision")
            if m.get("source_url") is not None and not _https(m["source_url"]):
                self.error(p + ".source_url", "must be a public HTTPS URL or null")
            if m.get("sha256") is not None and not _sha256(m["sha256"]):
                self.error(p + ".sha256", "must be a SHA-256 hex digest or null")
            size = m.get("bytes")
            if size is not None and (type(size) is not int or size <= 0):
                self.error(p + ".bytes", "must be a positive integer or null")
            ident = m.get("id")
            if _text(ident):
                if ident in models:
                    self.error(p, "duplicate model ID " + ident)
                models[ident] = m
        return models

    def matches(self, e, b, stage, status, models):
        if e.get("kind") != "verification" or e.get("stage") != stage:
            return False
        s = e.get("subject")
        if not isinstance(s, dict):
            return False
        if not _commit(b.get("source_revision")) or not _text(b.get("runtime_id")):
            return False
        if any(s.get(k) != b.get(k) for k in ("package_attribute", "source_revision", "runtime_id")):
            return False
        if e.get("revision") is not None and e["revision"] != b.get("source_revision"):
            return False
        if not _artifact(s.get("artifact")):
            if not (status == "failed" and stage in ("evaluation", "build") and s.get("artifact") is None and _text(s.get("attempt"))):
                return False
        env = s["environment"]
        platform = b.get("platform")
        contexts = {"linux": ("linux", "native-linux"), "windows": ("windows", "native-windows"), "macos": ("macos", "native-macos"), "wine": ("wine",)}
        if not isinstance(platform, str) or env.get("execution_context") not in contexts.get(platform, ()):
            return False
        if env.get("os") != ("linux" if platform == "wine" else platform) or env.get("architecture") != b.get("architecture"):
            return False
        if stage in HARDWARE_STAGES and b.get("vendor") != "cpu":
            if status == "passed" and b.get("vendor") in ("multi", "unknown"):
                return False
            if env.get("gpu_vendor") != b.get("vendor") or not all(_text(env.get(k)) for k in ("gpu_vendor", "gpu_model", "driver")):
                return False
        if stage in ("model_execution", "provider_execution"):
            ident = s.get("model_id")
            model = models.get(ident) if isinstance(ident, str) else None
            if not model or model.get("acquisition") != "acquired" or not _sha256(model.get("sha256")) or s.get("model_sha256") != model["sha256"]:
                return False
        return True

    def backend(self, value, path, components):
        fields = ("component", "platform", "architecture", "vendor", "provider", "upstream_status", "integration_status", "runtime_pins", "model_refs", "cpu_fallback", "package_attribute", "source_revision", "runtime_id", "validation", "evidence", "next_action")
        b = self.record(value, path, fields)
        for field in ("component", "architecture", "provider", "next_action"):
            self.string(b.get(field), path + "." + field)
        for field in ("package_attribute", "runtime_id"):
            self.string(b.get(field), path + "." + field, nullable=True)
        self.revision(b.get("source_revision"), path + ".source_revision")
        for field, choices in (
            ("platform", ("linux", "windows", "macos", "wine")),
            ("vendor", ("cpu", "nvidia", "amd", "intel", "apple", "multi", "unknown")),
            ("upstream_status", ("implemented", "experimental", "documented-only", "port-required", "unsupported", "unknown")),
            ("integration_status", ("not-packaged", "packaged", "blocked")),
            ("cpu_fallback", ("supported", "unsupported", "unknown", "not-applicable")),
        ):
            self.enum(b.get(field), path + "." + field, choices)
        component = b.get("component")
        if not isinstance(component, str) or component not in components:
            self.error(path + ".component", "undefined component")
        evidence = self.evidence(b.get("evidence"), path + ".evidence")
        recipe = any(urlsplit(e["reference"]).path.endswith(".nix") for e in evidence)
        packaged = b.get("integration_status") == "packaged"
        if packaged and not all(_text(b.get(k)) for k in ("package_attribute", "source_revision", "runtime_id")):
            self.error(path, "packaged backend requires package_attribute, source_revision and runtime_id")
        self.pins(b.get("runtime_pins"), path + ".runtime_pins", packaged, recipe)
        models = self.models(b.get("model_refs"), path + ".model_refs")
        v = self.record(b.get("validation"), path + ".validation", (*STAGES, "reason"))
        self.string(v.get("reason"), path + ".validation.reason", nullable=True)
        for stage in STAGES:
            status = v.get(stage)
            self.enum(status, path + ".validation." + stage, STATUSES)
            if status == "not-run-policy" and not _text(v.get("reason")):
                self.error(path + ".validation." + stage, "policy skip requires reason")
            if b.get("vendor") == "amd" and stage in HARDWARE_STAGES and status != "not-run-policy":
                if "AMD hardware execution is outside campaign policy" not in self.errors:
                    self.errors.append("AMD hardware execution is outside campaign policy")
            if status in ("passed", "failed") and not any(self.matches(e, b, stage, status, models) for e in evidence):
                self.error(path + ".validation." + stage, "requires matching backend-local verification evidence subject (stage, source, runtime, artifact, model and environment)")
        return b


def validation_errors(entry: dict, *, require_assessed: bool = False) -> list[str]:
    """Return deterministic diagnostics for malformed data; never perform IO."""
    v = _Validator()
    if not isinstance(entry, dict):
        return ["entry must be an object"]
    if "acceleration" not in entry:
        return ["missing acceleration"]
    v.public_data(entry["acceleration"])
    a = v.record(entry["acceleration"], "acceleration", ("assessment", "ai_role", "execution_mode", "components", "backends", "evidence", "blocked_reason", "next_action"))
    v.enum(a.get("assessment"), "acceleration.assessment", ("pending", "complete", "blocked-evidence"))
    v.enum(a.get("ai_role"), "acceleration.ai_role", ("none", "inference", "training-only", "external-service", "mixed", "unknown"))
    v.enum(a.get("execution_mode"), "acceleration.execution_mode", ("audio-callback", "worker-thread", "background-job", "external-service", "mixed", "not-applicable", "unknown"))
    v.string(a.get("next_action"), "acceleration.next_action")
    if a.get("assessment") == "blocked-evidence":
        v.string(a.get("blocked_reason"), "acceleration.blocked_reason")
    elif a.get("blocked_reason") is not None:
        v.error("acceleration.blocked_reason", "must be null unless assessment is blocked-evidence")
    if require_assessed and a.get("assessment") == "pending":
        v.errors.append("pending assessment " + str(entry.get("id", "<unknown>")))
    components = {}
    for i, item in enumerate(v.collection(a.get("components"), "acceleration.components")):
        path = f"acceleration.components[{i}]"
        c = v.record(item, path, ("id", "summary", "kind"))
        v.string(c.get("id"), path + ".id")
        v.string(c.get("summary"), path + ".summary")
        v.enum(c.get("kind"), path + ".kind", KINDS)
        if _text(c.get("id")):
            if c["id"] in components:
                v.error(path, "duplicate component ID " + c["id"])
            components[c["id"]] = c
    evidence = v.evidence(a.get("evidence"), "acceleration.evidence")
    if a.get("assessment") == "complete":
        if not evidence:
            v.errors.append("completed assessment requires evidence")
        role = a.get("ai_role")
        kinds = [c.get("kind") for c in components.values()]
        local = "neural-inference" in kinds
        training = "training" in kinds
        external = "external-inference" in kinds
        valid = ((role == "none" and all(k in ("non-neural-dsp", "application") for k in kinds))
                 or (role == "training-only" and training and not local and not external)
                 or (role == "inference" and local)
                 or (role == "external-service" and external)
                 or (role == "mixed" and sum((local, training, external)) >= 2))
        if not valid:
            v.error("acceleration.ai_role", "completed role is inconsistent with component kinds")
    backends = []
    seen = set()
    for i, item in enumerate(v.collection(a.get("backends"), "acceleration.backends")):
        path = f"acceleration.backends[{i}]"
        b = v.backend(item, path, components)
        key = tuple(b.get(k) for k in ("component", "platform", "architecture", "vendor", "provider"))
        if all(isinstance(k, str) for k in key):
            if key in seen:
                v.error(path, "duplicate backend tuple")
            seen.add(key)
        backends.append(b)
    if a.get("assessment") == "complete" and a.get("ai_role") == "none" and a.get("execution_mode") != "not-applicable":
        if not any(isinstance(b.get("component"), str) and components.get(b["component"], {}).get("kind") == "non-neural-dsp" and b.get("vendor") not in ("cpu", "unknown") for b in backends):
            v.error("acceleration.execution_mode", "non-neural conclusion requires not-applicable or explicit GPU DSP backend")
    return v.errors
