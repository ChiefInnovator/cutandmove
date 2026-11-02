# Project-local design tools

This folder contains the EGM runtime pinned to `403d8881d62022490637d740657b33f01e321ea8` and the separate
Impeccable skill. Project rules live in the repository's AGENTS.md.

- [Upstream EGM README](https://github.com/google/elephant-goldfish-model/blob/403d8881d62022490637d740657b33f01e321ea8/README.md)
- [Upstream testing guide](https://github.com/google/elephant-goldfish-model/blob/403d8881d62022490637d740657b33f01e321ea8/TESTING.md)
- [Upstream packaging builder](https://github.com/google/elephant-goldfish-model/blob/403d8881d62022490637d740657b33f01e321ea8/scripts/pack_plugin.py)
- Installed runtime: skills/egm-*, agents, resources, docs, assets, LICENSE.
- Provenance: egm-source.json and impeccable-source.json.

EGM development guides, packaging commands, and offline EGM tests describe the
full upstream EGM repository, not Cut & Move or this mixed-skill runtime folder.
Obtain the pinned source before running those commands:

```sh
git clone https://github.com/google/elephant-goldfish-model.git /tmp/cutandmove-egm-source
git -C /tmp/cutandmove-egm-source checkout --detach 403d8881d62022490637d740657b33f01e321ea8
cd /tmp/cutandmove-egm-source
python3 -m venv /tmp/cutandmove-egm-test-env
/tmp/cutandmove-egm-test-env/bin/pip install -r requirements-dev.txt
/tmp/cutandmove-egm-test-env/bin/python -m pytest tests/unit
python3 scripts/pack_plugin.py --target openai --output /tmp/cutandmove-egm-package
```

Use fresh output paths. No package upload or native integration test is implied.
The application has separate checks documented in its root AGENTS.md and
`docs/reviews/verification.md`. Consumer documentation links are adapted locally;
EGM SKILL.md prompts, personas, standards, and skill assets retain upstream bytes.
