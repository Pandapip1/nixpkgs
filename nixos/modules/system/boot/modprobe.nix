{ config, lib, pkgs, ... }:

with lib;

{

  ###### interface

  options = {
    boot.modprobe = {
      enable = mkEnableOption "modprobe config. This is useful for systems like containers which do not require a kernel" // {
        default = true;
      };
      blacklist = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [ "cirrusfb" "i2c_piix4" ];
        description = ''
          List of names of kernel modules that should not be loaded
          automatically by the hardware probing code.
        '';
      };
      alias = mkOption {
        type = types.attrsOf types.str;
        default = {};
        example = {
          "usb-storage" = "sd_mod";
        };
        description = ''
          A mapping of kernel module names to aliases. This is useful
          when a module is known by a different name in the kernel, or
          to disable a module by aliasing it to 'off'.
        '';
      };
      options = mkOption {
        type = types.attrsOf types.str;
        default = {};
        example = {
          "parport_pc" = {
            io = "0x378";
            irq = "7";
            dma = "1";
          };
        };
      };
      softdep = mkOption {
        type = types.attrsOf types.str;
        default = {};
        example = {
          "snd_hda_intel" = "snd_hda_codec";
        };
        description = ''
          A mapping of kernel module names to soft dependencies. This is
          useful when a module depends on another module to be loaded
          first.
        '';
      };
      extraModprobeConfig = mkOption {
        default = "";
        example =
          ''
            options parport_pc io=0x378 irq=7 dma=1
          '';
        description = ''
          Any additional configuration to be appended to the generated
          {file}`modprobe.conf`.  This is typically used to
          specify module options.  See
          {manpage}`modprobe.d(5)` for details.
        '';
        type = types.lines;
      };
    };
  };


  ###### implementation

  config = let 
    withWarnings = x:
      lib.warnIf (evalModulesArgs?args) "The args argument to evalModules is deprecated. Please set config._module.args instead."
      lib.warnIf (evalModulesArgs?check) "The check argument to evalModules is deprecated. Please set config._module.check instead."
      x;
  in mkIf config.boot.modprobe.enable {
    environment.etc."modprobe.d/nixos.conf".text = ''
      ${flip concatMapStrings config.boot.modprobe.blacklist (name: ''
        blacklist ${name}
      '')}
      ${flip concatMapStrings (attrNames config.boot.modprobe.alias) (name: alias: ''
        alias ${name} ${alias}
      '')}
      ${flip concatMapStrings (attrNames config.boot.modprobe.options) (name: options: ''
        options ${name} ${concatStringsSep " " (attrValues options)}
      '')}
      ${flip concatMapStrings (attrNames config.boot.modprobe.softdep) (name: dep: ''
        softdep ${name} ${dep}
      '')}
      ${config.boot.extraModprobeConfig}
    '';

    environment.etc."modprobe.d/ubuntu.conf".source = "${pkgs.kmod-blacklist-ubuntu}/modprobe.conf";
    environment.etc."modprobe.d/debian.conf".source = pkgs.kmod-debian-aliases;
    environment.etc."modprobe.d/systemd.conf".source = "${config.systemd.package}/lib/modprobe.d/systemd.conf";
    
    environment.systemPackages = [ pkgs.kmod ];

    system.activationScripts.modprobe = stringAfter ["specialfs"]
      ''
        # Allow the kernel to find our wrapped modprobe (which searches
        # in the right location in the Nix store for kernel modules).
        # We need this when the kernel (or some module) auto-loads a
        # module.
        echo ${pkgs.kmod}/bin/modprobe > /proc/sys/kernel/modprobe
      '';

  };

}
