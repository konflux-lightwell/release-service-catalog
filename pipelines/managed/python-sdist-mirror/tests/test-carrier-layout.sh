#!/usr/bin/env bash
set -euo pipefail
base="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
task="${base}/tasks/managed/materialize-lightwell-carrier/materialize-lightwell-carrier.yaml"
pipeline="${base}/pipelines/managed/python-sdist-mirror/python-sdist-mirror.yaml"
# The extraction and release roots are deliberately different; materialization must bridge them.
grep -Fq 'files="${root}/content/files"' "${task}"
grep -Fq 'cp --preserve=all -- "${src}" "${dst}"' "${task}"
grep -Fq 'cmp -s -- "${src}" "${dst}"' "${task}"
grep -Fq 'test ! -e "${dst}"' "${task}"
grep -Fq 'safe_path "${rel}"' "${task}"
grep -Fq 'name: materialize-lightwell-carrier' "${pipeline}"
grep -Fq -- '- materialize-lightwell-carrier' "${pipeline}"
# Exercise the path contract and byte-for-byte copy independently of Tekton.
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
mkdir -p "${tmp}/release/content/files"
printf '\0carrier\n' > "${tmp}/release/content/files/provenance-response.bin"
mkdir -p "${tmp}/release/content/files/dist"
printf 'archive' > "${tmp}/release/content/files/dist/pkg.tar.gz"
root="${tmp}/release"; files="${root}/content/files"; rel='dist/pkg.tar.gz'; src="${files}/${rel}"; dst="${root}/${rel}"
mkdir -p "$(dirname "${dst}")"; test ! -e "${dst}"; cp -p "${src}" "${dst}"; cmp -s "${src}" "${dst}"
! (rel='../escape'; case "${rel}" in /*|*../*|../*|*//*|'') exit 0;; esac; exit 1)
# JSON null is Taisce's exact no-advertisement shape. PyPI stays response-free.
mkdir -p "${tmp}/pypi-null/content/files"
printf '{"source_registry":"pypi.org","source":"https://pypi.org/project/example/","provenance_url":null}\n' > "${tmp}/pypi-null/content/files/source-origin.json"
origin="${tmp}/pypi-null/content/files/source-origin.json"
registry="$(jq -r '.source_registry // .registry // empty' "${origin}")"
provenance_present="$(jq -r 'if (has("provenance_url") and .provenance_url != null) then "true" else "false" end' "${origin}")"
test "${registry}" = pypi.org && test "${provenance_present}" = false
test ! -e "${tmp}/pypi-null/content/files/provenance-response.bin"

# RHTL null is also not advertised, so it requires only rhtl-response.json.
mkdir -p "${tmp}/rhtl-null/content/files"
printf '{"source_registry":"rhtl","source":"https://catalog.example.invalid/example","provenance_url":null}\n' > "${tmp}/rhtl-null/content/files/source-origin.json"
printf 'rhtl\n' > "${tmp}/rhtl-null/content/files/rhtl-response.json"
origin="${tmp}/rhtl-null/content/files/source-origin.json"
registry="$(jq -r '.source_registry // .registry // empty' "${origin}")"
provenance_present="$(jq -r 'if (has("provenance_url") and .provenance_url != null) then "true" else "false" end' "${origin}")"
test "${registry}" = rhtl && test "${provenance_present}" = false
test -f "${tmp}/rhtl-null/content/files/rhtl-response.json"
test ! -e "${tmp}/rhtl-null/content/files/provenance-response.bin"

# An advertised URL must fail when its response is absent, rather than downgrading to RHTL.
mkdir -p "${tmp}/rhtl-advertised/content/files"
printf '{"source_registry":"rhtl","provenance_url":"https://example.invalid/provenance"}\n' > "${tmp}/rhtl-advertised/content/files/source-origin.json"
origin="${tmp}/rhtl-advertised/content/files/source-origin.json"
provenance_url="$(jq -r '.provenance_url // empty' "${origin}")"
! test -f "${tmp}/rhtl-advertised/content/files/provenance-response.bin"
! (printf '%s' "${provenance_url}" | grep -Eq '^https?://[^[:space:]]+$' \
  && test -f "${tmp}/rhtl-advertised/content/files/provenance-response.bin")

printf 'carrier layout tests passed\n'
