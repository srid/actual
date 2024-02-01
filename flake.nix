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

      flake.nixosConfigurations.site = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, lib, ... }: {
            fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };
            boot.loader.grub.device = "/dev/sda";

            networking.firewall.allowedTCPPorts = [ 80 443 ];

            services.nginx = {
              enable = true;
              package = pkgs.openresty;
              virtualHosts."site.garnix.actual.srid.garnix.me" = {
                #addSSL = true;
                #enableACME = true;
                locations."/".extraConfig = ''
                  default_type 'text/plain';
                  charset utf-8;

                  content_by_lua_block {
                    local handle = io.popen("${lib.getExe self.packages.${pkgs.system}.default}", 'r')
                    local result = handle:read("*a")
                    handle:close()
                    ngx.say(result)
                  }
                '';
              };
            };

            security.acme = {
              acceptTerms = true;
              defaults.email = "srid@srid.ca";
            };
          })
        ];
      };
    };
}
