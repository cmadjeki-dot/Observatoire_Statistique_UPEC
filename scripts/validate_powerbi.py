"""Validate PBIR with Microsoft's public schemas; cache schemas locally."""
import hashlib
import json
import pathlib
import sys
import urllib.request
import urllib.parse

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "outputs/powerbi_validation/python"))
import jsonschema
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT7

CACHE = ROOT / "outputs/powerbi_validation/schemas"
CACHE.mkdir(parents=True, exist_ok=True)

def retrieve(uri):
    if not uri.startswith("https://developer.microsoft.com/json-schemas/"):
        raise ValueError("Unexpected schema source: " + uri)
    path = CACHE / (hashlib.sha256(uri.encode()).hexdigest() + ".json")
    if not path.exists():
        url = uri.replace("https://developer.microsoft.com/json-schemas/",
                          "https://raw.githubusercontent.com/microsoft/json-schemas/main/")
        with urllib.request.urlopen(url, timeout=30) as response:
            path.write_bytes(response.read())
    schema = json.loads(path.read_text(encoding="utf-8-sig"))
    return Resource.from_contents(schema, default_specification=DRAFT7)

registry = Registry(retrieve=retrieve)
files = sorted((ROOT / "powerbi").rglob("*.json"))
files += list((ROOT / "powerbi").rglob("*.pbir"))
files += list((ROOT / "powerbi").rglob("*.pbip"))
files += list((ROOT / "powerbi").rglob("*.pbism"))
files += list((ROOT / "powerbi").rglob("*.platform"))
count = 0
for path in files:
    obj = json.loads(path.read_text(encoding="utf-8-sig"))
    uri = obj.get("$schema")
    if not uri:
        continue
    resource = retrieve(uri)
    validator = jsonschema.Draft7Validator(resource.contents,
        registry=registry.with_resource(uri, resource))
    try:
        validator.validate(obj)
    except jsonschema.ValidationError as exc:
        print(str(path.relative_to(ROOT)), list(exc.absolute_path), exc.message)
        raise SystemExit(1)
    count += 1
print(f"PBIR: {count} fichiers valides selon les schemas Microsoft")
(ROOT / "outputs/powerbi_validation/schema_result.json").write_text(
    json.dumps({"validated": count, "jsonschema": "4.26.0", "status": "success"}), encoding="utf-8")
