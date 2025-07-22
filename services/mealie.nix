{
  services.mealie = {
    enable = true;
    port = 9925;
    settings = {
      ALLOW_SIGNUP = "false";
      TZ = Europe/Paris;
    };
  };
}
