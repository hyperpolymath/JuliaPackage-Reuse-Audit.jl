#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#
# check-identity-fixtures.sh — self-test for the mechanical identity checker.
#
# tests/check-identity.sh is the half of the gate that reads the tree. A checker
# that only ever reports PASS on the real repository proves nothing: it could be
# vacuous, or it could be failing open on every section. So it is run against
# deliberately broken trees, each broken in exactly one way, and each must be
# REJECTED. One control tree is deliberately consistent and must be ACCEPTED —
# otherwise "everything fails" would look like success.
#
# The fixture trees are built here rather than committed, for two reasons: every
# case is visible in one reviewable file, and a fixture cannot drift out of step
# with the checker it exercises. They are built in a temporary directory and
# removed afterwards; nothing is written into the repository.
#
# The canonical identity module in the consistent fixture is produced by the real
# generator (scripts/gen-identity-agda.sh --mode canonical), so this self-test
# also exercises the transcriber against a second Project.toml.
set -uo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

# name|sections|expected-exit|builder
#   sections: comma-separated list, or ALL for the whole checker
cases=(
  "consistent|ALL|0|build_consistent"
  "repo-name-mismatch|reconciled|1|build_repo_name_mismatch"
  "module-name-mismatch|module-decl|1|build_module_name_mismatch"
  "missing-src-file|src-file|1|build_missing_src_file"
  "hyphenated-package-name|project-name,identifier|1|build_hyphenated_package_name"
  "digit-leading-package-name|identifier|1|build_digit_leading_package_name"
  "missing-using|tests-using|1|build_missing_using"
  "readme-omits-package|readme-names|1|build_readme_omits_package"
  "readme-example-drift|readme-example|1|build_readme_example_drift"
  "missing-example|readme-example|1|build_missing_example"
  "stale-self-url|internal-urls|1|build_stale_self_url"
  "no-self-url|internal-urls|1|build_no_self_url"
  "retired-name-reintroduced|retired-names|1|build_retired_name_reintroduced"
  "retired-register-missing|retired-names|1|build_retired_register_missing"
  "decided-identity-drift|decided-identity|1|build_decided_identity_drift"
)

PKG="MyThing"
REPO="MyThing.jl"
RETIRED="OldThing.jl"

# A consistent tree: every section of the checker passes on it.
build_consistent() {
  local d="$1"
  mkdir -p "$d/src" "$d/test" "$d/examples" "$d/docs/naming" "$d/proofs/agda"

  cat >"$d/Project.toml" <<TOML
name = "$PKG"
uuid = "00000000-0000-0000-0000-000000000000"
version = "0.1.0"

[deps]
TOML

  cat >"$d/src/${PKG}.jl" <<JL
# SPDX-License-Identifier: MPL-2.0
module ${PKG}

greeting() = "hello"

end # module ${PKG}
JL

  cat >"$d/test/runtests.jl" <<JL
using ${PKG}
using Test

@testset "${PKG}" begin
    @test ${PKG}.greeting() == "hello"
end
JL

  cat >"$d/examples/quickstart.jl" <<JL
# SPDX-License-Identifier: MPL-2.0
using ${PKG}

${PKG}.greeting()
JL

  cat >"$d/README.adoc" <<ADOC
= ${PKG}.jl

Clone with:

    git clone https://github.com/hyperpolymath/${REPO}

== Quick start

[source,julia]
----
$(awk 'BEGIN { skip = 1 } skip && /^#/ { next } skip && /^[[:space:]]*$/ { next } { skip = 0; print }' "$d/examples/quickstart.jl")
----
ADOC

  cat >"$d/docs/naming/retired-names.txt" <<TXT
# Retired names for the fixture repository.
${RETIRED}
TXT

  cat >"$d/docs/naming/retired-names-allowlist.txt" <<TXT
# The register and the allowlist may name a retired name; nothing else may.
docs/naming/retired-names.txt
docs/naming/retired-names-allowlist.txt
TXT

  bash scripts/gen-identity-agda.sh --mode canonical --root "$d" >/dev/null 2>&1 ||
    { printf 'FAIL: fixture builder could not generate the canonical identity module\n'; return 1; }
}

build_repo_name_mismatch() {
  build_consistent "$1" || return 1
}
build_module_name_mismatch() {
  build_consistent "$1" || return 1
  sed -i "s/^module ${PKG}$/module SomethingElse/" "$1/src/${PKG}.jl"
}
build_missing_src_file() {
  build_consistent "$1" || return 1
  rm -f "$1/src/${PKG}.jl"
}
build_hyphenated_package_name() {
  build_consistent "$1" || return 1
  sed -i 's/^name = "MyThing"/name = "My-Thing"/' "$1/Project.toml"
}
build_digit_leading_package_name() {
  build_consistent "$1" || return 1
  sed -i 's/^name = "MyThing"/name = "9Lives"/' "$1/Project.toml"
}
build_missing_using() {
  build_consistent "$1" || return 1
  sed -i "s/^using ${PKG}$/using Test/" "$1/test/runtests.jl"
}
build_readme_omits_package() {
  build_consistent "$1" || return 1
  # Every mention goes, not just the title: a README that names the package only
  # inside a clone URL still fails this section, because the title is what a
  # reader takes as the name of the thing.
  sed -i "s/${PKG}\.jl/SomeOtherThing.jl/g" "$1/README.adoc"
}
build_readme_example_drift() {
  build_consistent "$1" || return 1
  printf '\nprintln("this line is not in the README")\n' >>"$1/examples/quickstart.jl"
}
build_missing_example() {
  build_consistent "$1" || return 1
  rm -f "$1/examples/quickstart.jl"
}
build_stale_self_url() {
  build_consistent "$1" || return 1
  sed -i "s|hyperpolymath/${REPO}|hyperpolymath/${RETIRED}|" "$1/README.adoc"
}
build_no_self_url() {
  build_consistent "$1" || return 1
  sed -i '/github\.com\/hyperpolymath/d' "$1/README.adoc"
}
build_retired_name_reintroduced() {
  build_consistent "$1" || return 1
  mkdir -p "$1/docs"
  printf '= Notes\n\nFormerly known as %s, which is retired.\n' "$RETIRED" >"$1/docs/notes.adoc"
}
build_retired_register_missing() {
  build_consistent "$1" || return 1
  rm -f "$1/docs/naming/retired-names.txt"
}
build_decided_identity_drift() {
  build_consistent "$1" || return 1
  # Simulate somebody editing the generated module by hand: one character of the
  # decided package name changed.
  sed -i "0,/'T'/s//'X'/" "$1/proofs/agda/CanonicalIdentity.agda"
}

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

fail=0
ran=0
for entry in "${cases[@]}"; do
  IFS='|' read -r name sections expected builder <<<"$entry"
  dir="${workdir}/${name}"
  mkdir -p "$dir"
  if ! "$builder" "$dir"; then
    printf 'FAIL: %s: fixture builder failed\n' "$name"
    fail=1
    continue
  fi
  args=(--root "$dir")
  if [ "$sections" != "ALL" ]; then args+=(--sections "$sections"); fi
  # The repository name the checker is told it lives in. Every case except the
  # reconciliation one is told the truth, so a failure can only come from the
  # tree.
  case "$name" in
    repo-name-mismatch) args+=(--repo-name "NotMyThing.jl") ;;
    *) args+=(--repo-name "$REPO") ;;
  esac
  status=0
  output="$(bash tests/check-identity.sh "${args[@]}" 2>&1)" || status=$?
  ran=$((ran + 1))
  if [ "$status" -eq "$expected" ] || { [ "$expected" -eq 1 ] && [ "$status" -ne 0 ]; }; then
    printf 'PASS: %-28s exited %d as expected (sections: %s)\n' "$name" "$status" "$sections"
    if [ "$expected" -ne 0 ]; then
      printf '%s\n' "$output" | grep -m1 '^FAIL:' | sed 's/^/        /'
    fi
  else
    printf 'FAIL: %-28s exited %d, expected %s (sections: %s)\n' "$name" "$status" "$expected" "$sections"
    printf '%s\n' "$output" | sed 's/^/        /'
    fail=1
  fi
done

printf '\nidentity-checker self-test: %d of %d cases ran\n' "$ran" "${#cases[@]}"
if [ "$ran" -ne "${#cases[@]}" ]; then
  printf 'FAIL: some declared cases did not run\n'
  fail=1
fi
if [ "$fail" -ne 0 ]; then
  printf 'FAIL: the identity checker did not behave as declared\n'
  exit 1
fi
printf 'PASS: the identity checker accepted the consistent tree and rejected all %d broken ones\n' "$((ran - 1))"
