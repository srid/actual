{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem = { pkgs, lib, self', ... }: {

        packages = {
          db = pkgs.runCommandNoCC "db" { buildInputs = [ pkgs.fortune ]; } ''
            mkdir -p $out
            cp -r ${./db} $out/db
            chmod u+w -R $out/
            strfile $out/db/*
          '';
          default = pkgs.writeShellApplication {
            name = "actual";
            runtimeInputs = with pkgs; [
              fortune
              charasay
            ];
            text = ''
              fortune ${self'.packages.db}/db/precis | chara say -r
            '';
          };
        };
      };
    };
}
