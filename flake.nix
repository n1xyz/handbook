{
  description = "Layer N development tooling";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    foundry = {
      url = "github:shazow/foundry.nix/monthly";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    layern = {
      url = "github:Layer-N/layern.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          formatter = pkgs.nixfmt-rfc-style;

          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              cargo-deny
              cargo-vet
              cargo-zigbuild
              foundry-bin
              just
              nixos-generators
              rustup
              solc-0_8_26
            ];
          };

          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config = { };
            overlays = with inputs; [
              foundry.overlay
              rust-overlay.overlays.default
              layern.overlays.default
            ];
          };
        };
    };
}
