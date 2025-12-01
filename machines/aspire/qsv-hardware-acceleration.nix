{ pkgs, ... }:

{
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  # This section allows build on 25.11+ where intel-media-sdk is marked insecure and Google Test 1.17.0 requires C++17 but the Intel Media SDK project doesn't explicitly set a C++ standard.
  # https://github.com/NixOS/nixpkgs/issues/432403
  nixpkgs = {
    config.permittedInsecurePackages = [
      "intel-media-sdk-23.2.2"
    ];
    overlays = [
      (_self: super: {
        intel-media-sdk = super.intel-media-sdk.overrideAttrs (old: {
          cmakeFlags = old.cmakeFlags ++ [ "-DCMAKE_CXX_STANDARD=17" ];
          NIX_CFLAGS_COMPILE = "-std=c++17";
        });
      })
    ];
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # For Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
      libva-vdpau-driver # Previously vaapiVdpau
      intel-compute-runtime-legacy1
      intel-media-sdk # QSV up to 11th gen
      intel-ocl # OpenCL support
    ];
  };
}
