# Technical Stack

Tools and technologies we use to build our software. The supported
target platforms for development are:

- `aarch64-linux`
- `aarch64-darwin`
- `x86_64-linux`

All tooling should support these platforms. MacOS is included despite
not being used for deployments as it is a common development platform.
If you are using Windows, you will need to use WSL and deal with any
issues that arise. Defaults for each tool are used as much as possible
to avoid enforcing idiosyncrasies.

## Languages

These are the only languages we use. Other languages should be avoided
so as to avoid creating a barrier to entry for new engineers.

- [Rust](https://www.rust-lang.org/) is the default language for
  everything. All engineers are expected to be able to write Rust,
  irrespective of role or background.

- [TypeScript](https://www.typescriptlang.org/) is used for frontend work,
  preferred over JavaScript.

- [Solidity](https://docs.soliditylang.org/) is used for smart contracts
  developed against the Ethereum Virtual Machine.

- [Nix](https://nix.dev/) is used for managing development environments,
  tooling, and provisioning software during deployments.

- [Typst](https://typst.app/) is used for any long-form documentation
  that should be rendered as a PDF. TeX/LaTeX should never be used,
  though LaTeX math syntax is alright for use in markdown files.

Any form of shell scripting is forbidden, as writing correct shell
scripts requires significant tacit knowledge. Instead, we suggest using
`just` for small scripts and encapsulating more complex logic in Rust or
[forge
scripts](https://book.getfoundry.sh/reference/forge/forge-script).
Python may be used in a limited fashion for exploratory work and domain
modelling, but should not touch anything production-related nor be used
for automation.

## Tools

### Miscellaneous

These are some extra tools that we use for convenience.

- [just](https://github.com/casey/just)
  - This is the only tool we use for running scripts.
  - For example, you could use `just build-static-release` with the
    following `justfile`:
    ```
    build-static-release:
        RUSTFLAGS="-C target-feature=+crt-static" cargo zigbuild --release --target x86_64-unknown-linux-musl
    ```

- [direnv](https://direnv.net/)
  - Isn't strictly necessary, but is convenient for development.
  - Suggested to use with `use flake` so that the dev dependencies are
    automatically loaded when entering the repo directory.

- [editorconfig](https://editorconfig.org/)
  - Primarily used to deal with editors that use non-UNIX line endings.
  - Neovim enables this by default. VSCode and Emacs require a plugin.
  - See our starter config [.editorconfig](.editorconfig).

### Continuous Integration

We use GitHub Actions for CI. Alternatives are being considered though
as GitHub Actions doesn't support `aarch64-linux`.

### Nix

We use nix to install development dependencies and manage development
environments. Nix is infamous for being difficult to learn as resources
are scarce. I recommend going through these, in order:

1. [Zero to Nix](https://zero-to-nix.com/) covers getting started and
   using nix with flakes.
2. [Nix language](https://nix.dev/tutorials/nix-language) is a good
   follow-up to learn the basics of the nix language. If you're already
   familiar with functional languages, this will be a breeze.
3. [Stop calling everything
   Nix](https://www.haskellforall.com/2022/08/stop-calling-everything-nix.html)
   provides a good explanation how nix, nixpkgs, and NixOS differ.
4. [home-manager](https://nix-community.github.io/home-manager/) is
   suggested to have some way to familiarize yourself with nix. If
   you're on MacOS, this is a strictly better alternative to brew and I
   highly recommend replacing it. You'll get exposure to NixOS' module
   system, which is useful for deployments. Make sure to use the [flakes
   installation](https://nix-community.github.io/home-manager/index.xhtml#ch-nix-flakes).

This won't be easy. Take your time and reach out to colleagues that are
familiar with nix for help. We all understand the frustrations, but I
promise you it'll all make sense. In case it helps, I've found that
Claude is great at writing nix.

In terms of specific tooling:

- [`layern.nix`](https://github.com/Layer-N/layern.nix) is our flake for
  packaging tools that are not yet in nixpkgs or don't have builds for
  our supported platforms.
- [`nixfmt-rfc-style`](https://github.com/NixOS/nixfmt) is used as the
  formatter. Your editor should be configured to use it.
- [`flake-parts`](https://github.com/hercules-ci/flake-parts) should be
  used instead of `flake-utils` as the former is more idiomatic.
- [`crane`](https://crane.dev/) may be used to create derivations of
  Rust if needed, such as for deployments, though is generally not
  recommended for development as `Cargo.lock` and `rust-toolchain.toml`
  provide enough reproducibility.
- [`nixos-generators`](https://github.com/nix-community/nixos-generators)
  is used to generate NixOS images to test locally and for deployments.

Nix should not be used to create small convenience scripts, as that
causes litter to build up. Instead, opt for `just` or write scripts in
appropriate languages.

See our starter [flake.nix](flake.nix) for a complete example.

### Rust

Stick to Rust's defaults as much as possible, using Cargo for managing
dependencies and building binaries. We recommend installing Rust through
[rustup](https://rustup.rs/) from nixpkgs and adding a
[`rust-toolchain.toml`](https://rust-lang.github.io/rustup/overrides.html#the-toolchain-file)
file to the root of your project. Every `Cargo.toml` should specify a
[`rust-version`](https://doc.rust-lang.org/cargo/reference/manifest.html#the-rust-version-field).

An example toolchain file:

```toml
[toolchain]
channel = "stable"
components = ["clippy", "rust-analyzer"]
targets = ["x86_64-unknown-linux-musl"]
```

You'll notice that we're targeting `x86_64-unknown-linux-musl`. This is
because we statically link all binaries for deployment. We additionally
use

- [`clippy`](https://github.com/rust-lang/rust-clippy) for additional
  lints. This is included as part of the toolchain.
- [`cargo-deny`](https://github.com/EmbarkStudios/cargo-deny) for
  dependency auditing.
- [`cargo-vet`](https://github.com/mozilla/cargo-vet) for ensuring that
  all dependencies are audited.
- [`cargo-zigbuild`](https://github.com/rust-cross/cargo-zigbuild) for
  cross-compilation, especially for statically linked binaries like
  for `x86_64-unknown-linux-musl` or `aarch64-unknown-linux-musl`.

All code must be formatted with `cargo fmt` and linted with `cargo
clippy`. Ensure your editor is configured appropriately. For
observability, we use the [`tracing`](https://crates.io/crates/tracing)
and [`metrics`](https://crates.io/crates/metrics) crates with
appropriate configuration. `opentelemetry` should be avoided.

### TypeScript

All frontend work should be done in TypeScript. Stick to the simplest
possible `tsconfig.json` with `strict` enabled and don't get caught up
in changing the defaults. Prefer ES modules. In terms of tooling, we
recommend:

- [`bun`](https://bun.sh/) for development.
- [`npm`](https://www.npmjs.com/) for `npm publish` as `bun` doesn't
  support publishing yet.
- [`prettier`](https://prettier.io/) for formatting, with default
  settings. Ensure your editor is configured appropriately.

[`eslint`](https://eslint.org/) may be used, though we don't enforce it
as it has quite a few false positives and overly strict defaults,
generally seems to be aimed at novices.

### Solidity

All smart contracts targetting the Ethereum Virtual Machine should be
written in Solidity. In terms of tooling, we use:

- [`foundry`](https://book.getfoundry.sh/) suite for most things,
  including
  - `forge` for compiling, testing, deploying, formatting.
  - `anvil` as the local development chain.
  - `cast` for interacting with local and remote chains.
  - `chisel` for inspecting chain state and as a nice debugger and repl.

For scripting anything involving Ethereum, [`forge
script`](https://book.getfoundry.sh/tutorials/solidity-scripting) should
be used. This includes, for example, deploying contracts, calling
functions, performance upgrades, etc.

### Terraform

Terraform is used for deploying infrastructure. Avoid using it to
provision software and instead prefer nix with `nixos-generators`.

### Discouraged

Some tools that we recommend against. If you do use some of these tools,
make sure it's strongly justified and preferably isolated to a single
project.

- Any scripting language other than Python, such Ruby or Perl. Not
  because they're bad, but because supporting multiple languages
  leads to a scattered codebase.

- OpenTelemetry. Overall riddled with accidental complexity, Java-isms,
  and is unergonomic with Rust. We prefer to model our observability as
  a slight variation of ["wide
  events"](https://isburmistrov.substack.com/p/all-you-need-is-wide-events-not-metrics).
  Essentially, we use `tracing` to emit structured events, some of which
  are part of a trace. Metrics are emitted separately as they may be
  more frequent.

- `pre-commit` and `husky`, or generally any tool that is trivially
  reconstructible with `nix` or `just`. These add additional learning
  overhead for other engineers. Prefer existing, composable tools.
