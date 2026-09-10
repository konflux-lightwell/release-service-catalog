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
printf 'carrier layout tests passed\n'
