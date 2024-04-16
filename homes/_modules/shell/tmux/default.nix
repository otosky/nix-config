{
  config,
  pkgs,
  ...
}: {
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    keyMode = "vi";
    tmuxinator.enable = true;
    prefix = "C-Space";
    extraConfig = ''
      # splits
      unbind '"'
      unbind '%'
      bind h split-window -v
      bind v split-window -h

      # other sane things
      unbind '&'
      bind X confirm kill-window

      # TokyoNight colors for Tmux
      # https://github.com/folke/tokyonight.nvim/blob/main/extras/tmux/tokyonight_storm.tmux

      set -g mode-style "fg=#7aa2f7"

      set -g message-style "fg=#7aa2f7"
      set -g message-command-style "fg=#7aa2f7"

      set -g pane-border-style "fg=#3b4261"
      set -g pane-active-border-style "fg=#7aa2f7"

      set -g status "on"
      set -g status-justify "left"

      set -g status-style "fg=#7aa2f7"

      set -g status-left-length "100"
      set -g status-right-length "100"

      set -g status-left-style NONE
      set -g status-right-style NONE

      set -g status-left "#[fg=#bb9af7,bold] #S"
      set -g status-right ""

      setw -g window-status-activity-style "underscore,fg=#a9b1d6"
      setw -g window-status-separator ""
      setw -g window-status-style "NONE,fg=#a9b1d6"
      setw -g window-status-format "#[fg=#1f2335,nobold,nounderscore,noitalics]#[default] #I #W #[fg=#1f2335,nobold,nounderscore,noitalics]"
      setw -g window-status-current-format "#[fg=#7aa2f7,bold] #I #W"

      # ensure neovim in tmux uses correct colors
      set -ga terminal-overrides ",*256col*:Tc"
    '';
  };
}
