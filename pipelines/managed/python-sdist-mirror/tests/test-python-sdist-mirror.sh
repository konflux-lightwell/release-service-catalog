#!/usr/bin/env bash
# Static contract tests for the fail-closed Python sdist pipeline.
set -euo pipefail

pipeline="$(dirname "${BASH_SOURCE[0]}")/../python-sdist-mirror.yaml"

# Every resolver in this pipeline must use the catalog commit that contains its path.
grep -Eq 'default: "[0-9a-f]{40}"' "${pipeline}"
! grep -Eq 'default: "[0-9a-f]{7,39}"' "${pipeline}"
! grep -Eq 'default: "(main|master|development(-python)?)"' "${pipeline}"

# The unverified/nonexistent archive-sources task must never be resolved.
! grep -Fq 'pathInRepo: tekton/tasks/archive-sources' "${pipeline}"
! grep -Fq 'name: taisceCuanGitRevision' "${pipeline}"

# Source origin is explicit, and PyPI remains usable without RHTL parameters.
grep -Fq 'name: sourceOriginType' "${pipeline}"
grep -Fq 'default: "pypi"' "${pipeline}"
grep -Fq 'name: sourceOriginPath' "${pipeline}"
! grep -Fq 'name: rhtl' "${pipeline}"

echo 'python-sdist-mirror contract tests passed'
