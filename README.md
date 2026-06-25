<!--
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-FileCopyrightText: 2025-2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->

[![Topology](https://img.shields.io/badge/Project-Topology-9558B2)](TOPOLOGY.md)
[![90](https://img.shields.io/badge/Completion-90%25-green)](TOPOLOGY.md) [![OpenSSF Best Practices](https://img.shields.io/badge/OpenSSF-Best_Practices-green?logo=opensourcesecurity)](https://www.bestpractices.dev/en/projects/new?repo_url=https://github.com/hyperpolymath/JuliaPackage-Reuse-Audit.jl)
[![License: MPL-2.0](https://img.shields.io/badge/License-MPL--2.0-blue.svg)](https://www.mozilla.org/MPL/2.0/)
<embed
src="https://api.thegreenwebfoundation.org/greencheckimage/github.com"
data-link="https://www.thegreenwebfoundation.org/green-web-check/?url=github.com" />
image:<a href="https://img.shields.io/badge/Julia-1.10+-9558B2?logo=julia"
data-link="https://julialang.org/">Julia</a>

**Standardized Package Scaffolding for the Hyperpolymath Ecosystem**

*Generate production-ready Julia package skeletons where you only fill
the domain gaps.*

<div id="toc">

</div>

# Overview

JuliaPackageSpitter.jl is an automated scaffolding tool that implements
the "Reuse vs. Remake" philosophy for Julia packages. It handles 80%+ of
the boilerplate required for production-grade repos—including CI,
quality gates, docs skeletons, and ABI/FFI adapters—allowing developers
and LLMs to focus purely on domain models and core algorithms.

# The "Reuse vs. Remake" Philosophy

- **Reuse Heavily**: Scaffolding, CI workflows, release playbooks, test
  harness patterns, ABI/FFI adapters.

- **Remake Per Package**: Domain entities, safety invariants, core
  algorithms, public API semantics.

# Core Capabilities

- **Full Directory Generation**: Creates `src`, `test`, `docs`, and
  `.github/workflows` in seconds.

- **Smart Templating**: Boilerplate files include "TODO" anchors ONLY in
  domain-specific sections.

- **CI Profiles**: Choose between `minimal`, `standard`, and `strict`
  quality gate configurations.

- **LLM Handoff**: Generates a pre-filled brief (`SONNET-TASKS.md`)
  ready for an AI agent to begin implementation.

- **FFI Ready**: Optional generation of Idris2 ABI and Zig FFI
  skeletons.

# Quick Start

```julia
using JuliaPackageSpitter

# Scaffold a new safety-critical package
generate_package(
    name = "NuclearSafety.jl",
    domain_summary = "Core cooling logic for SMR reactors",
    ci_profile = :strict,
    ffi_enabled = true
)
```

# Success Criteria

- **Speed**: New package scaffolded in under 2 minutes.

- **Consistency**: 80%+ non-domain files are generated identical to
  ecosystem standards.

- **Ease of Implementation**: LLMs can implement the first domain module
  from the generated brief without extra prompting.

# License

Palimpsest-MPL-1.0 License - see [LICENSE](LICENSE) for details.
