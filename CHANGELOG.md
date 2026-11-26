# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.7] - 2026-11-26

### Fixed
- `callto:` links now dial the number (previously only `tel:` links were handled; `callto:` opened the app without dialing) — Linux, Windows and macOS
- Windows (NSIS installer): the post-install script registering `tel:`/`callto:` was never executed (`!ifdef INSTALL` block was compiled out); it now runs through the `customInstall` macro
- Windows: `postinstall_windows.ps1` now registers `callto:` in addition to `tel:` (ProgId, URL associations, HKLM/HKCU protocol keys)

### Changed
- Configuration files are now two-level, for multi-user workstations:
  - **administrator** `config.ini` / `sso.ini`, deployed once per workstation: `/etc/celyavox/` (Linux), `%ProgramData%\CelyaVox\` (Windows), `/Library/Application Support/CelyaVox/` (macOS), or the directory set in `CELYAVOX_ADMIN_CONFIG_DIR`; the installation directory is still accepted for compatibility
  - **user** `config.ini` (optional) in the user profile, overriding the administrator values key by key
  - `sso.ini`: the administrator file takes precedence over the user file
- `config.ini` is no longer copied into the user profile on first launch (the copied template used to hide the administrator file from the second launch onwards)
- Single lookup logic for `sso.ini` (`config-locations.js`), shared by the startup check, the renderer check and the SAML loader

### Fixed
- SSO was reported as configured when `sso.ini` contained only `;`-commented lines or a lowercase `[saml]` section, then failed to load
- Files read by the renderer (`profilePicture`, `CustomRingtone`) are restricted to the administrator and user configuration directories with a strict path check (no `/tmp` fallback, no prefix ambiguity)

### Removed
- `config.reloadConfig()` (it re-read the same files and could not update `serverUrl`)
- Unused `package.json.debian` (renamed to `package.json.debian.old`); Debian packages are built from `package.json`

## [1.1.4] - 2026-10-28

### Added
- Support for SAML-based Single Sign-On (SSO) authentication
- Enhanced configuration management with protected config files
- Improved logging capabilities across the application
- Support for multiple platforms: Linux, Windows, and macOS
- Advanced audio features and configuration options

### Changed
- Updated Electron to version 38.2.2
- Improved build process with prebuild script
- Enhanced security with code signing support for macOS and Windows
- Better error handling and reporting

### Fixed
- Configuration file protection mechanisms
- Protocol registration for telephone URLs (tel:, callto:)

## [1.1.3] - 2026-10-20

### Added
- Initial support for Windows code signing
- MAC OS code signing and notarization support

### Changed
- Reorganized build configuration
- Improved installer scripts for multiple platforms

## [1.1.2] - 2026-10-10

### Added
- Cross-platform build support
- Icon generation and management
- Electron builder integration

### Fixed
- Build process reliability
- Asset management

## [1.1.1] - 2026-09-15

### Added
- Basic Electron application structure
- SIP protocol support
- Initial configuration system

## [1.1.0] - 2026-09-01

### Added
- Core CelyaVox Desktop application
- SIP phone functionality with WebRTC
- Configuration management system
