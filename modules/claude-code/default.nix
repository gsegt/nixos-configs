{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.modules.claude-code;
in
{
  options.modules.claude-code = {
    enable = lib.mkEnableOption "Whether to enable Claude Code.";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.claude-code;
      defaultText = lib.literalExpression "pkgs.claude-code";
      description = "Claude Code package to install (from the claude-code-nix overlay by default).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Replace the nixpkgs package with the more frequently updated one from claude-code-nix
    nixpkgs.overlays = [ inputs.claude-code.overlays.default ];

    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude-code" ];

    environment.systemPackages = [ cfg.package ];
  };
}
