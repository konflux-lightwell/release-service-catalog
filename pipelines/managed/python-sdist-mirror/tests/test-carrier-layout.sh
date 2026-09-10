#!/usr/bin/env bash
set -euo pipefail
base="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
task="${base}/tasks/managed/materialize-lightwell-carrier/materialize-lightwell-carrier.yaml"
pipeline="${base}/pipelines/managed/python-sdist-mirror/python-sdist-mirror.yaml"
# The extraction and release roots are deliberately different; materialization must bridge them.
grep -Fq 'files="${root}/content/files"' "${task}"
grep -Fq 'os.O_NOFOLLOW' "${task}"
grep -Fq 'os.link(tmp, dst)' "${task}"
grep -Fq 'carrier destination collision' "${task}"
grep -Fq 'cmp -s -- "${src}" "${dst}"' "${task}"
grep -Fq 'test ! -e "${dst}"' "${task}"
grep -Fq 'safe_path "${rel}"' "${task}"
grep -Fq 'test ! -L "${src}"' "${task}"
grep -Fq 'os.unlink(tmp)' "${task}"
grep -Fq 'test -z "$(find "${files}" -type l -print -quit)"' "${task}"
grep -Fq 'GIT_TERMINAL_PROMPT' "${task}"
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
! (rel='.'; case "${rel}" in ''|'.'|/*|*../*|../*|*//* ) exit 0;; esac; exit 1)
! (src="${tmp}/release/content/files/link"; ln -s dist/pkg.tar.gz "${src}"; test -z "$(find "${files}" -type l -print -quit)")
# JSON null is Taisce's exact no-advertisement shape. PyPI stays response-free.
mkdir -p "${tmp}/pypi-null/content/files"
printf '{"source_registry":"pypi.org","source":"https://pypi.org/project/example/","provenance_url":null}\n' > "${tmp}/pypi-null/content/files/source-origin.json"
origin="${tmp}/pypi-null/content/files/source-origin.json"
registry="$(jq -r '.source_registry // .registry // empty' "${origin}")"
provenance_present="$(jq -r 'if (has("provenance_url") and .provenance_url != null) then "true" else "false" end' "${origin}")"
test "${registry}" = pypi.org && test "${provenance_present}" = false
test ! -e "${tmp}/pypi-null/content/files/provenance-response.bin"
# PyPI remains response-free even when an upstream field is present and a raw response exists.
mkdir -p "${tmp}/pypi-advertised/content/files"
printf '{"source_registry":"pypi.org","provenance_url":"https://example.invalid/provenance"}\n' > "${tmp}/pypi-advertised/content/files/source-origin.json"
printf '\0must-not-copy\n' > "${tmp}/pypi-advertised/content/files/provenance-response.bin"
origin="${tmp}/pypi-advertised/content/files/source-origin.json"
registry="$(jq -r '.source_registry // .registry // empty' "${origin}")"
test "${registry}" = pypi.org
# This is the materializer's dispatch contract: no PyPI branch copy is permitted.
test ! -e "${tmp}/pypi-advertised/provenance-response.bin"

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

# An advertised URL requires provenance-response.bin only; rhtl-response.json is not required.
mkdir -p "${tmp}/rhtl-advertised/content/files"
printf '{"source_registry":"rhtl","provenance_url":"https://example.invalid/provenance"}\n' > "${tmp}/rhtl-advertised/content/files/source-origin.json"
printf '\0provenance\n' > "${tmp}/rhtl-advertised/content/files/provenance-response.bin"
origin="${tmp}/rhtl-advertised/content/files/source-origin.json"
provenance_url="$(jq -r '.provenance_url // empty' "${origin}")"

# Hostless, empty, non-string, whitespace-containing, and malformed URLs are invalid advertisements.
valid_provenance_url() {
  local url="$1" authority hostport host port suffix
  case "${url}" in http://*|https://*) ;; *) return 1 ;; esac
  case "${url}" in ''|*[[:space:]]*) return 1 ;; esac
  authority="${url#*://}"; authority="${authority%%[/?#]*}"
  test -n "${authority}" || return 1
  hostport="${authority##*@}"; test -n "${hostport}" || return 1
  case "${hostport}" in
    \[*\]) host="${hostport#\[}"; host="${host%\]}"; test -n "${host}" || return 1 ;;
    \[*\]:*)
      host="${hostport%%\]*}"; host="${host#\[}"; suffix="${hostport#*\]}"; port="${suffix#:}"
      test "${suffix#*:}" != "${suffix}" && test -n "${port}" || return 1
      case "${port}" in *[!0-9]*) return 1 ;; esac ;;
    *:*) host="${hostport%:*}"; port="${hostport##*:}"; test -n "${host}" && test -n "${port}" || return 1
      case "${port}" in *[!0-9]*) return 1 ;; esac ;;
    *) host="${hostport}" ;;
  esac
  test -n "${host}"
}
valid_provenance_url "${provenance_url}" && test -s "${tmp}/rhtl-advertised/content/files/provenance-response.bin"
test ! -e "${tmp}/rhtl-advertised/content/files/rhtl-response.json"
for invalid_url in 'https:///missing-host' '' '   ' 'https://example.invalid/a b' 'https://?query' 'https://#fragment' 'ftp://example.invalid' 'https://:443/path' 123; do
  ! valid_provenance_url "${invalid_url}"
done
for valid_url in 'http://example.invalid' 'https://example.invalid/path?query#fragment' 'https://user@example.invalid:8443/path'; do
  valid_provenance_url "${valid_url}"
done

printf 'carrier layout tests passed\n'
