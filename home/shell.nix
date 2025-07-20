{
  programs.fish = {
    enable = true;
    generateCompletions = true;
    shellInit = ''
      set -g fish_greeting
      fish_user_key_bindings
    '';
    shellAbbrs = {
      ls = "ls -l";
      mkdir = "mkdir -vp";
      cp = "cp -v";
      mv = "mv -v";
      rm = "rm -v";
      bye = "sudo systemctl poweroff";
      reboot = "sudo systemctl reboot";
      watch = "watch -n 1";
      snrs = "sudo nixos-rebuild switch";
      snrb = "sudo nixos-rebuild boot";
    };
    functions = {
      bind_bang = ''
        switch (commandline -t)[-1]
          case "!"
            commandline -t -- $history[1]
            commandline -f repaint
          case "*"
            commandline -i !
        end
      '';
      bind_dollar = ''
        switch (commandline -t)[-1]
          case "!"
            commandline -f backward-delete-char history-token-search-backward
          case "*"
            commandline -i '$'
        end
      '';
      fish_user_key_bindings = ''
        bind ! bind_bang
        bind '$' bind_dollar
      '';
    };
  };

  programs.starship.enable = true;
}
