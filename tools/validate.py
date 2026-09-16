"""Validate the Powerfarm specifications repository.

Checks every JSON Schema against Draft 2020-12, validates every example by its
`kind`, applies cheap semantic invariants the schemas cannot express, checks
the conformance catalog, and resolves local Markdown links. Behavioral
conformance is proven by implementations, not by this tool.
"""

import json
import re
import sys
from datetime import datetime
from pathlib import Path
from urllib.parse import unquote

import yaml
from jsonschema import Draft202012Validator, FormatChecker
from referencing import Registry, Resource

ROOT = Path(__file__).resolve().parent.parent
SCHEMA_BY_KIND = {
    "AppContract": "app-contract-v0.schema.json",
    "ExecutabilityContract": "executability-contract-v0.schema.json",
    "AdmissionReceipt": "admission-receipt-v0.schema.json",
    "HeartimeContract": "heartime-contract-v0.schema.json",
    "WakePack": "wakepack-v0.schema.json",
    "DirectionDecision": "direction-decision-v0.schema.json",
}
MANDATORY_ROLES = {"contracts", "authority", "constraints", "state"}
CASE_ID = re.compile(r"^[A-Z]+-[0-9]{3}$")


def instant(value):
    return datetime.strptime(value, "%Y-%m-%dT%H:%M:%SZ")


def semantic_problems(document):
    kind = document.get("kind")
    if kind == "HeartimeContract":
        spec = document["spec"]
        anchor = instant(spec["recurrence"]["anchor"])
        review = instant(spec["planning"]["nextPlanningReviewAt"])
        coverage = instant(spec["planning"]["planValidThrough"])
        if not anchor <= review < coverage:
            yield "planning review must lie within the initial coverage and before it ends"
        if "expiresAt" in spec and instant(spec["expiresAt"]) <= anchor:
            yield "expiresAt must follow the recurrence anchor"
    if kind == "WakePack":
        roles = {item["role"] for item in document["mandatory"]}
        if not MANDATORY_ROLES <= roles:
            yield f"mandatory roles missing: {sorted(MANDATORY_ROLES - roles)}"
        if document["usedBytes"] > document["budgetBytes"]:
            yield "usedBytes exceeds budgetBytes"


def main():
    failures = []
    schemas = {path.name: json.loads(path.read_text()) for path in sorted((ROOT / "schemas").glob("*.json"))}
    registry = Registry().with_resources((name, Resource.from_contents(document)) for name, document in schemas.items())
    for name, document in schemas.items():
        Draft202012Validator.check_schema(document)
        print(f"PASS schema {name}")

    examples = sorted((ROOT / "examples").glob("*.yaml")) + sorted((ROOT / "examples").glob("*.json"))
    for path in examples:
        document = yaml.safe_load(path.read_text()) if path.suffix == ".yaml" else json.loads(path.read_text())
        json.dumps(document, allow_nan=False)
        schema = SCHEMA_BY_KIND.get(document.get("kind"))
        if schema is None:
            failures.append(f"{path.name}: no schema for kind {document.get('kind')!r}")
            continue
        validator = Draft202012Validator(schemas[schema], registry=registry, format_checker=FormatChecker())
        problems = [f"{'/'.join(map(str, error.absolute_path))}: {error.message}" for error in validator.iter_errors(document)]
        problems += list(semantic_problems(document))
        if problems:
            failures.extend(f"{path.name}: {problem}" for problem in problems)
        else:
            print(f"PASS example {path.name} ({document['kind']})")

    cases = yaml.safe_load((ROOT / "conformance" / "cases.yaml").read_text())["cases"]
    identifiers = [case.get("id") for case in cases]
    if len(set(identifiers)) != len(identifiers):
        failures.append("conformance: duplicate case identifiers")
    for case in cases:
        if not CASE_ID.match(str(case.get("id"))) or not all(case.get(field) for field in ("id", "area", "title", "given", "expect")):
            failures.append(f"conformance: incomplete case {case.get('id')!r}")
    print(f"PASS conformance catalog: {len(cases)} cases (behavior is proven by implementations)")

    for path in sorted(ROOT.rglob("*.md")):
        for link in re.findall(r"\]\(([^)]+)\)", path.read_text()):
            if ":" in link or link.startswith("#"):
                continue
            if not (path.parent / unquote(link.split("#")[0])).exists():
                failures.append(f"{path.relative_to(ROOT)}: broken local link {link}")
    print("PASS local Markdown links" if not any("broken local link" in failure for failure in failures) else "FAIL local Markdown links")

    for failure in failures:
        print(f"FAIL {failure}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
