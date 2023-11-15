{
  description = "Good basic flake template";
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
     flake-utils.lib.eachDefaultSystem (system:
       let
         # Get the SHA by guessing, and nix develop will yell at you
         # Tarball is much, much faster than the git fetch option
         # Use https://lazamar.co.uk/nix-versions to find the package version
         # you need.
         #
         # This might be useful at some point, but I don't know when:
         # https://discourse.nixos.org/t/fixing-error-attribute-currentsystem-missing-in-flake/22386/7
         hugoPinnedAt108 = import (builtins.fetchTarball {
          url = "https://github.com/NixOS/nixpkgs/archive/79b3d4bcae8c7007c9fd51c279a8a67acfa73a2a.tar.gz";
          sha256 = "1lsrlgx4rg2wqxrz5j7kzsckgk4ymvr1l77rbqm1zxap6hg07dxf";
         }) {
           inherit system;
         };
         systempkgs = nixpkgs.legacyPackages.${system};
       in
       {
         devShells.default = systempkgs.mkShell {
            buildInputs = with systempkgs; [
              hugoPinnedAt108.hugo
            ];
         };
       }
     );
}
