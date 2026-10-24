from pathlib import Path
import xml.etree.ElementTree as ET
root = Path(__file__).resolve().parents[1]
tree = ET.parse(root / "build/ELDORIA.rbxlx")
items = list(tree.iter("Item"))
classes = [item.attrib["class"] for item in items]
assert classes.count("Script") == 1, classes
assert classes.count("LocalScript") == 1, classes
assert classes.count("ModuleScript") == 5, classes
for item in items:
    if item.attrib["class"] in ("Script", "LocalScript", "ModuleScript"):
        source = item.find("Properties/*[@name='Source']")
        assert source is not None and len(source.text or "") > 100
print("PASS built place: server entrypoint, client entrypoint and all five modules contain source")
