#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
VERSION="${1:?usage: scripts/rust/release/publish-package-release.sh <version> [<ref>]}"
REF="${2:-HEAD}"
PACKAGE_FILE="Package.swift"
EXPECTED_ARTIFACT_PATH="releases/download/tokenizers-rust-${VERSION}/TokenizersRust-${VERSION}.xcframework.zip"

if [[ ! "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "Version must be semantic, for example 0.3.1 or 0.3.1-rc.1." >&2
  exit 1
fi

cd "${REPO_ROOT}"

git rev-parse --verify "${REF}" >/dev/null

if git rev-parse --verify "refs/tags/${VERSION}" >/dev/null 2>&1; then
  echo "Tag ${VERSION} already exists locally." >&2
  exit 1
fi

if gh release view "${VERSION}" >/dev/null 2>&1; then
  echo "Package release ${VERSION} already exists." >&2
  exit 1
fi

git show "${REF}:${PACKAGE_FILE}" | grep -F "${EXPECTED_ARTIFACT_PATH}" >/dev/null || {
  echo "${PACKAGE_FILE} at ${REF} does not point at tokenizers-rust-${VERSION}." >&2
  exit 1
}

rust_release_url="$(gh release view "tokenizers-rust-${VERSION}" --json url --jq '.url')"

git tag -a "${VERSION}" "${REF}" -m "${VERSION}"
git push origin "refs/tags/${VERSION}"

notes_file="$(mktemp)"
trap 'rm -f "${notes_file}"' EXIT

cat >"${notes_file}" <<EOF
Associated Rust artifact release:
${rust_release_url}
EOF

if [[ "${VERSION}" == *-* ]]; then
  gh release create "${VERSION}" \
    --verify-tag \
    --title "${VERSION}" \
    --notes-file "${notes_file}" \
    --prerelease
else
  gh release create "${VERSION}" \
    --verify-tag \
    --title "${VERSION}" \
    --notes-file "${notes_file}"
fi

package_release_url="$(gh release view "${VERSION}" --json url --jq '.url')"

echo
echo "Published package release ${VERSION}."
echo "Release: ${package_release_url}"
