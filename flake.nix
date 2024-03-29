{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem = { pkgs, lib, self', ... }: {
        formatter = pkgs.nixpkgs-fmt;
        packages = {
          db = pkgs.runCommandNoCC "db"
            {
              buildInputs = [
                pkgs.fortune
                pkgs.findutils
              ];
            } ''
            mkdir -p $out
            cp -r ${./db} $out/db
            chmod u+w -R $out/
            find $out/db -maxdepth 1 -type f | xargs -n 1 strfile
          '';
          default = pkgs.writeShellApplication {
            name = "actual";
            runtimeInputs = with pkgs; [
              fortune
              cowsay
            ];
            text = ''
              fortune ${self'.packages.db}/db | cowsay
            '';
          };
        };
      };
    };
}
