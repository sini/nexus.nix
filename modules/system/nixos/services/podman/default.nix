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
    environment.systemPackages = with pkgs; [
      dive # look into docker image layers
      podman-compose
      podman-tui # Terminal mgmt UI for Podman
      passt # For Pasta rootless networking
    ];

    virtualisation = {
      containers.enable = true;
      oci-containers.backend = "podman";
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

      containers.storage.settings = {
        storage = {
          driver = "btrfs";
          runroot = "/run/containers/storage";
          graphroot = "/var/lib/containers/storage";
          options.overlay.mountopt = "nodev,metacopy=on";
        }; # storage
      };
    };

    # Add 'newuidmap' and 'sh' to the PATH for users' Systemd units.
    # Required for Rootless podman.
    systemd.user.extraConfig = ''
      DefaultEnvironment="PATH=/run/current-system/sw/bin:/run/wrappers/bin:${lib.makeBinPath [ pkgs.bash ]}"
    '';
  };
}
