{
  options,
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.user;
  defaultIconFileName = "profile.png";
  defaultIcon = pkgs.stdenvNoCC.mkDerivation {
    name = "default-icon";
    src = ./. + "/${defaultIconFileName}";

    dontUnpack = true;

    installPhase = ''
      cp $src $out
    '';

    passthru = {
      fileName = defaultIconFileName;
    };
  };
  propagatedIcon =
    pkgs.runCommandNoCC "propagated-icon" { passthru = { inherit (cfg.icon) fileName; }; }
      ''
        local target="$out/share/icons/user/${cfg.name}"
        mkdir -p "$target"

        cp ${cfg.icon} "$target/${cfg.icon.fileName}"
      '';
in
{
  options.user = with types; {
    name = mkOpt str "sini" "The name to use for the user account.";
    initialPassword =
      mkOpt str "password"
        "The initial password to use when the user is first created.";
    icon = mkOpt (nullOr package) defaultIcon "The profile picture to use for the user.";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
    extraOptions = mkOpt attrs { } "Extra options passed to <option>users.users.<name></option>.";
  };

  config = {
    environment.systemPackages = with pkgs; [
      propagatedIcon
    ];

    environment.sessionVariables.FLAKE = "/home/${cfg.name}/repos/construct.nix";

    home = {
      file = {
        "Documents/.keep".text = "";
        "Downloads/.keep".text = "";
        "Music/.keep".text = "";
        "Pictures/.keep".text = "";
        "dev/.keep".text = "";
        ".face".source = cfg.icon;
        "Pictures/${cfg.icon.fileName or (builtins.baseNameOf cfg.icon)}".source = cfg.icon;
      };
    };

    users.users.${cfg.name} = {
      isNormalUser = true;
      # inherit (cfg) name initialPassword;
      initialHashedPassword = "$y$j9T$RpfkDk8AusZr9NS09tJ9e.$kbc4SL9Cu45o1YYPlyV1jiVTZZ/126ue5Nff2Rfgpw8";

      home = "/home/${cfg.name}";
      group = "users";

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAOa9kFogEBODAU4YVs4hxfVx3b5ryBzct4HoAHgwPio jason.bowman@pm.me"
      ];

      extraGroups = [
        "wheel"
        "audio"
        "sound"
        "video"
        "networkmanager"
        "input"
        "tty"
        "docker"
      ] ++ cfg.extraGroups;
    } // cfg.extraOptions;
  };
}