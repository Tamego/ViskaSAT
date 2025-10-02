{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    hax.url = "github:hacspec/hax";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      rust-overlay,
      hax,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        rust-version = "1.86.0";
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            godot
            rust-bin.stable.${rust-version}.minimal
            rust-bin.stable.${rust-version}.rust-analyzer
            hax.packages.${system}.default
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
