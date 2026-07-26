{ pkgs, config, ... }:

{
  users.extraGroups = {
    render.members = [ config.modules.base.userName ];
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # For Broadwell (2014) or newer processors.
      libva-vdpau-driver # Previously vaapiVdpau
      intel-compute-runtime-legacy1
      intel-ocl # OpenCL support
    ];
  };

  environment.systemPackages = with pkgs; [
    intel-gpu-tools # Monnitoring and debugging tools for Intel GPUs
  ];
}
