#!/usr/bin/env bash
set -euo pipefail
pipeline="$(dirname "${BASH_SOURCE[0]}")/../python-sdist-mirror.yaml"
# Resolver revisions are deployment-supplied full SHAs, never mutable/defaulted.
grep -Fq 'name: taskGitRevision' "${pipeline}"
grep -Fq 'name: taisceCuanGitRevision' "${pipeline}"
grep -Fq 'value: $(params.taskGitRevision)' "${pipeline}"
grep -Fq 'value: $(params.taisceCuanGitRevision)' "${pipeline}"
grep -Fq 'test "$(params.taisceRevision)" = "48da35ef1c068c7d5185e4bdda029f9378f85294"' "${pipeline}"
! grep -Eq 'default: "[0-9a-f]{7,40}"' "${pipeline}"
! grep -Eiq 'revision:[[:space:]]*(main|master|development)' "${pipeline}"
# Official catalog/Taisce paths only; no unpublished archive-sources resolver.
grep -Fq 'https://github.com/konflux-ci/release-service-catalog.git' "${pipeline}"
grep -Fq 'https://github.com/konflux-lightwell/taisce-cuan.git' "${pipeline}"
! grep -Fq 'archive-sources' "${pipeline}"
# Carrier and RPA-selected forge/secret are wired.
grep -Fq 'sdist-transformation.json' tasks/managed/prepare-lightwell-release-inputs/prepare-lightwell-release-inputs.yaml
grep -Fq 'gitSecretName' "${pipeline}"
grep -Fq 'gitlabUrl' "${pipeline}"
echo 'python-sdist-mirror contract tests passed'
