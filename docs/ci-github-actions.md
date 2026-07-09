# GitHub Actions CI/CD

This project uses `.github/workflows/godot-ci.yml` for Godot 4.7 automation.

## CI

Pull requests and pushes to `main`, `code/**`, `design/**`, `art/**`, and `audio/**` run:

- download the Godot 4.7 stable Linux editor;
- import project assets with `godot --headless --path . --import`;
- run a short headless smoke test with `godot --headless --path . --quit-after 1`.

The import step is required because a clean runner has no `.godot` UID cache. Running the smoke test before import can fail to resolve the main scene UID.

## CD

Tags matching `v*` and manual `workflow_dispatch` runs export the existing `Windows Desktop` preset from `export_presets.cfg`.

The job downloads the matching Godot 4.7 export templates, exports `build/windows/anchor-cant-hold-windows-x86_64.exe`, zips the Windows build, and uploads it as a workflow artifact. For `v*` tags, it also creates or updates the matching GitHub Release using `GITHUB_TOKEN`.

## Local Baseline

Use the same commands locally before pushing workflow changes:

```bash
godot --headless --path . --import
godot --headless --path . --quit-after 1
```
