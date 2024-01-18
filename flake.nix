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
            cp ${./db.fortune} $out/db.fortune
            chmod u+w -R $out/
            cd $out/
            strfile db.fortune
          '';
          default = pkgs.writeShellApplication {
            name = "actual";
            runtimeInputs = with pkgs; [
              fortune
              charasay
            ];
            text = ''
              fortune ${self'.packages.db}/db.fortune | chara say -r
            '';
          };
        };
      };
    };
}
