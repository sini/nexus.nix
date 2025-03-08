{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.services.podman;
in
{
  options.services.podman = {
    enable = mkBoolOpt false "Whether or not to enable Podman.";
  };

  config = mkIf cfg.enable {
    # NixOS 22.05 moved NixOS Containers to a new state directory and the old
    # directory is taken over by OCI Containers (eg. podman). For systems with
    # system.stateVersion < 22.05, it is not possible to have both enabled.
    # This option disables NixOS Containers, leaving OCI Containers available.
    boot.enableContainers = false;

    environment.systemPackages = with pkgs; [
      podman-compose
    ];

    virtualisation = {
      podman = {
        inherit (cfg) enable;

        # prune images and containers periodically
        autoPrune = {
          enable = true;
          flags = [ "--all" ];
          dates = "weekly";
        };

        defaultNetwork.settings.dns_enabled = true;
        dockerCompat = true;
        dockerSocket.enable = true;
      };

      oci-containers = {
        backend = "podman";
      };
    };
  };
}
