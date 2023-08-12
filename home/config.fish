set -g -x fish_greeting ''

# Colors
set pink eb54c6
set teal 54ebc5
set blue 4bb2d3
set light_blue 54c6eb
set magenta a570ff
set green 83ff70
set grey 808080
set orange f28a1b

set fish_color_quote white
set fish_color_cwd $green
set fish_color_command $magenta
set fish_color_hostname $orange

# Fish git prompt
set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_showstashstate 'yes'
set __fish_git_prompt_showuntrackedfiles 'yes'
set __fish_git_prompt_showupstream 'verbose'
set __fish_git_prompt_color $grey
set __fish_git_prompt_color_flags $pink
set __fish_git_prompt_color_upstream $pink
set __fish_git_prompt_color_branch $light_blue
set __fish_git_prompt_color_upstream_ahead $pink
set __fish_git_prompt_color_upstream_behind $pink

# Status Chars
set __fish_git_prompt_char_dirtystate '*'
set __fish_git_prompt_char_stagedstate '▴'
set __fish_git_prompt_char_untrackedfiles '•'
set __fish_git_prompt_char_stashstate 's'
set __fish_git_prompt_char_upstream_ahead '↑ '
set __fish_git_prompt_char_upstream_behind '↓ '

function fish_prompt
  set last_status $status

  set_color -o
  set_color $fish_color_hostname
  printf '%s ' (hostname)
  set_color $fish_color_cwd
  printf '%s' (prompt_pwd)
  set_color normal
  printf '%s ' (__fish_git_prompt)

  set_color normal
end

# autojump
begin
    set --local AUTOJUMP_PATH $HOME/.autojump/share/autojump/autojump.fish
    if test -e $AUTOJUMP_PATH
        source $AUTOJUMP_PATH
    end
end

set -x N_PREFIX $HOME/n
set PATH $PATH $N_PREFIX/bin
set PATH $PATH $HOME/bin
set PATH $PATH $HOME/go/bin
set PATH $PATH $HOME/.cargo/bin
set PATH $PATH /usr/local/go/bin
set -x NAMESPACE kyle
set TERM xterm-256color

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/kyle/google-cloud-sdk/path.fish.inc' ]; . '/home/kyle/google-cloud-sdk/path.fish.inc'; end

# fish_vi_key_bindings
bind -M insert \ea accept-autosuggestion execute
bind -M insert \ee accept-autosuggestion
bind -M insert \ew nextd-or-forward-word

alias cat="bat --paging=never"
alias dotfiles="git --git-dir=/home/kyle/.dotfiles/.git --work-tree=/"

set -gx PNPM_HOME "/home/kyle/.local/share/pnpm"
set -gx PATH "$PNPM_HOME" $PATH

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
