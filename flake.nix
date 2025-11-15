{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        rust-version = "latest";
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            godot
            rust-bin.stable.${rust-version}.minimal
            rust-bin.stable.${rust-version}.rust-analyzer
            elan
            just
            typst
          ];

          shellHook = ''
            export TYPST_ROOT="$PWD"
          '';
        };
      }
    );
}
