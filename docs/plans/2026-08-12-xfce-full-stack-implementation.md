# Full XFCE Stack Implementation Plan

> **For Codex:** Implement in this workspace without commits.

**Goal:** Build current stable XFCE as individually installable SystemPackager archives.

**Architecture:** `xfce/build-xfce.sh` owns source acquisition, dependency ordering, staging, metadata generation, and archive creation.  Its manifest distinguishes library packages in `syspckg/libs/` from desktop packages in `syspckg/`; every archive is emitted to `syspckg/packages/`.

**Tech Stack:** POSIX shell, tar, curl, sha256sum, Autotools, Meson, pkg-config, SystemPackager archive layout.

---

### Task 1: Add test coverage for the XFCE package contract

**Files:**
- Create: `tests/xfce_package_layout_test.sh`
- Create: `tests/xfce_session_package_test.sh`

1. Write the layout test for the three required package locations.
2. Run the tests and confirm they fail because the XFCE manifest/build harness is missing.

### Task 2: Add a reproducible XFCE build harness

**Files:**
- Create: `../xfce/build-xfce.sh`
- Create: `../xfce/xfce-components.tsv`
- Modify: `Makefile`

1. Add a manifest for all XFCE core components, applications, and plugins, and their direct dependencies.
2. Add a build entry point that validates the manifest, downloads official release archives, stages packages by class, and writes archives only to `../syspckg/packages/`.
3. Add `make xfce` in AdavaLinux as the supported entry point.
4. Run the layout test and make it pass before adding package builds.

### Task 3: Resolve, build, stage, and archive the full set

**Files:**
- Create: `../xfce/sources/`
- Create: `../xfce/build/`
- Create: `../syspckg/libs/<name-version>/`
- Create: `../syspckg/<name-version>/`
- Create: `../syspckg/packages/<name-version>.syspckg`

1. Fetch stable releases and validate checksums.
2. Build in manifest dependency order against a staged sysroot.
3. Create `syspckg-info`, `syspckg-deps`, and a root tree per component.
4. Archive each package and create the full-XFCE meta-package with the session entry.

### Task 4: Validate output

**Files:**
- Modify: `README.md`

1. Run the two XFCE tests, archive inspections, and package dependency checks.
2. Confirm the XFCE package set is complete.
3. Document the build invocation and output locations.
