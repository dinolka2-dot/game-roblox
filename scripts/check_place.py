from pathlib import Path
import xml.etree.ElementTree as ET
root = Path(__file__).resolve().parents[1]
tree = ET.parse(root / "build/ELDORIA.rbxlx")
items = list(tree.iter("Item"))
classes = [item.attrib["class"] for item in items]
assert classes.count("Script") == 1, classes
assert classes.count("LocalScript") == 2, classes
assert classes.count("ModuleScript") == 7, classes
for item in items:
    if item.attrib["class"] in ("Script", "LocalScript", "ModuleScript"):
        source = item.find("Properties/*[@name='Source']")
        assert source is not None and len(source.text or "") > 100
print("PASS built place: server entrypoint, two client scripts and all seven modules contain source")

for name, cls in [("Ground", "Part"), ("SanctuarySpawn", "SpawnLocation")]:
    matches = [i for i in items if i.attrib["class"] == cls and i.findtext("Properties/string[@name='Name']") == name]
    assert len(matches) == 1, name
    assert matches[0].findtext("Properties/bool[@name='Anchored']") == "true"
print("PASS ground and spawn are embedded before scripts run")

for cls, name in [("ModuleScript", "Characters"), ("ModuleScript", "Scenery"), ("LocalScript", "Presentation")]:
    assert any(i.attrib["class"] == cls and i.findtext("Properties/string[@name='Name']") == name for i in items), name
print("PASS visual update modules and presentation entrypoint are embedded")
