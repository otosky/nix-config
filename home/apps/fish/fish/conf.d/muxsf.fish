# /usr/bin/fish

function muxsf -d 'Start a tmuxinator session from an fzf picker.'
  set -l config_dir "$HOME/.config/tmuxinator/"
  set -l choice (ls $config_dir | sed 's/\.[^.]*$//' | fzf)
  tmuxinator start -p (string join '' $config_dir $choice '.yml')
end 
