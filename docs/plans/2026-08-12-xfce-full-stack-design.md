# Full XFCE Stack Design

## Goal

Provide AdavaLinux with the complete current stable XFCE desktop as independently
installable SystemPackager packages as the sole desktop environment.

## Layout

The downloaded and unpacked XFCE source trees live in the workspace-level
`../xfce/` directory.  The unpacked files that form a package live in
`../syspckg/<package-version>/`; libraries use
`../syspckg/libs/<package-version>/`.  Every generated `.syspckg` archive,
including XFCE desktop components and their libraries, is written to the shared
`../syspckg/packages/` repository.

## Packaging Model

Each upstream component is built as its own package.  Packages contain a
`syspckg-info` manifest, an explicit `syspckg-deps` file, and a staged root
filesystem tree.  The desktop set includes the XFCE core, session manager,
window manager, panel, settings, desktop manager, terminal, file manager,
power manager, notification daemon, app finder, screenshooter, task manager,
clipman, weather plugin, and the remaining upstream XFCE applications and
panel plugins available in the selected stable release set.

Libraries absent from the existing repository are built and staged under
`syspckg/libs/`; desktop applications and utilities are staged under
`syspckg/`.  Existing packages are reused where their ABI and metadata satisfy
the dependency instead of duplicating them.

## Build Flow

A reproducible build entry point resolves the latest stable upstream source
versions at invocation time, downloads and verifies source archives, then
builds in dependency order with a dedicated sysroot populated from staged
packages.  It produces archives only after each staged tree and manifest pass
validation.  A generated aggregate package depends on all XFCE components so a
complete desktop can be installed with one command while retaining individual
package control.

## Integration and Validation

The build supplies an X session desktop entry for XFCE.  Validation checks the
required package placement, package archive
format, dependency closure, and presence of the XFCE session entry.  The
existing ISO build may consume the resulting package directory without moving
archives elsewhere.

## Error Handling

Downloads fail closed on missing archives or checksum mismatch.  A component
build stops before packaging if configure, compile, install staging, dependency
resolution, or package validation fails.  Existing source and package data are
never deleted by the XFCE build.
