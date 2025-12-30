# Contributing to Windows Auto Updater

Thanks for your interest in contributing! This document outlines the recommended workflow and guidelines to make contributions smooth and consistent.

## Getting started
1. Fork the repository and create a feature branch from `main`.
2. Make changes in a topic branch (feature/bugfix). Keep commits small and focused.
3. Run the test suite locally (see below) and ensure linting passes.
4. Open a Pull Request against `main` and fill the PR template.

## Development environment
- PowerShell 5.1 or PowerShell 7+
- Install required modules locally:

```powershell
Install-Module -Name Pester -Scope CurrentUser -Force
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
```

## Tests
We use Pester for unit/integration tests. Run the test suite from the repo root:

```powershell
Invoke-Pester -Script .\tests -EnableExit
```

## Linting
We use PSScriptAnalyzer with the provided `PSScriptAnalyzerSettings.psd1`. Run:

```powershell
Invoke-ScriptAnalyzer -Path . -Settings PSScriptAnalyzerSettings.psd1 -Recurse
```

## Commit messages
Use clear, imperative commits. Example:

```
Add: new feature X
Fix: adjust behavior for Y
Docs: update README
```

## Pull request process
- Ensure tests and linting pass locally
- Link any related issues
- Provide steps to reproduce for bug fixes

## Reporting a bug
Use the bug report issue template and include logs, PowerShell version, and the script commit.

## Code of Conduct
This project follows the Contributor Covenant. Please be kind and respectful.
