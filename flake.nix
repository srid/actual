{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem = { pkgs, lib, system, self', ... }: {
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
          ({pkgs, ... }: {
            fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };
            boot.loader.grub.device = "/dev/sda";

            networking.firewall.allowedTCPPorts = [ 80 443 ];

            services.nginx = {
              enable = true;
              additionalModules = [ pkgs.nginxModules.lua ];
              virtualHosts."actual.srid.garnix.me" = {
                #addSSL = true;
                #enableACME = true;
                # locations."/".proxyPass = "http://localhost:8080";
                extraConfig = ''
                  content_by_lua_block {
                    local handle = io.popen("fortune")
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
