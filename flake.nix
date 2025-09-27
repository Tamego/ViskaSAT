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
        overlays = [
          rust-overlay.overlays.default
        ];
        pkgs = import nixpkgs { inherit system overlays; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            godot
            rust-bin.stable.latest.default
            hax.packages.${system}.default
            elan
            just
          ];
        };
      }
    );
}
