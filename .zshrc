# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

alias reepfetch='/home/neo/reepfetch.sh'

# Enable command auto-correction
ENABLE_CORRECTION="true"

# Load plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# User configuration
export MAGICK_CONFIGURE_PATH=/usr/share/ImageMagick-7/policy.xml

# Aliases
alias convert="magick convert"
alias ls='lsd -a'


# Import pywal colorscheme asynchronously
(cat ~/.cache/wal/sequences &)
[ -f ~/.cache/wal/colors.sh ] && source ~/.cache/wal/colors.sh

# Enable TTY colors
[ -f ~/.cache/wal/colors-tty.sh ] && source ~/.cache/wal/colors-tty.sh

# Enable prompt substitution
setopt PROMPT_SUBST

# Set Oh My Posh prompt
export POSH_THEME="$HOME/.config/oh-my-posh/themes/pywal-atomic.omp.json"
eval "$(oh-my-posh init zsh --config $POSH_THEME)"

# Set custom prompt prefix
PROMPT=$'\uf11c Neo> '

# Enable completion
autoload -Uz compinit
if [ -z "$ZSH_COMPDUMP" ]; then
    ZSH_COMPDUMP=~/.zcompdump
fi
if [[ ! -f "$ZSH_COMPDUMP" || -z "$(find "$ZSH_COMPDUMP" -mmin -60)" ]]; then
    compinit -d "$ZSH_COMPDUMP"
else
    compinit
fi

# Enable menu selection for autocompletion
zstyle ':completion:*' menu select

# Enable case-insensitive and fuzzy completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Enable history-based suggestions
bindkey '^I' complete-word

# Load custom plugins
ZSH_CUSTOM_PLUGINS="$HOME/.zsh"
source "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt incappendhistory
setopt hist_ignore_dups
setopt hist_reduce_blanks
setopt hist_ignore_all_dups
setopt extended_history

# Pywal LS_COLORS
source "${HOME}/.cache/wal/colors.sh"
hex_to_ansi() {
    local HEX=${1#"#"}
    local R=$((16#${HEX:0:2}))
    local G=$((16#${HEX:2:2}))
    local B=$((16#${HEX:4:2}))
    printf "%d" $((16 + (R/43)*36 + (G/43)*6 + (B/43)))
}
C1=$(hex_to_ansi "$color1")
C2=$(hex_to_ansi "$color2")
C3=$(hex_to_ansi "$color3")
C4=$(hex_to_ansi "$color4")
C5=$(hex_to_ansi "$color5")
C6=$(hex_to_ansi "$color6")
C7=$(hex_to_ansi "$color7")
export LS_COLORS="
di=38;5;${C1}:
fi=38;5;${C2}:
ln=38;5;${C3}:
pi=38;5;${C4}:
so=38;5;${C5}:
do=38;5;${C6}:
bd=38;5;${C7}:
cd=38;5;${C1}:
or=38;5;${C2}:
mi=38;5;${C3}:
ex=38;5;${C4}:
*.sh=38;5;${C5}:
*.py=38;5;${C6}:
*.cpp=38;5;${C7}:
"


# Single-line LS_COLORS string
export LS_COLORS="di=38;5;${C1}:fi=38;5;${C2}:ln=38;5;${C3}:pi=38;5;${C4}:so=38;5;${C5}:do=38;5;${C6}:bd=38;5;${C7}:cd=38;5;${C1}:or=38;5;${C2}:mi=38;5;${C3}:ex=38;5;${C4}:*.sh=38;5;${C5}:*.py=38;5;${C6}:*.cpp=38;5;${C7}"

# Custom ls with space
unalias ls 2>/dev/null
ls() {
    command lsd -a --color=auto "$@"
    if [ $? -eq 0 ] && [ -t 1 ]; then
        echo ""
        echo ""
    fi
}
cd() {
    builtin cd "$@"
    if [ $? -eq 0 ] && [ -t 1 ]; then
        echo ""
    fi
}




# Load custom sysinfo script
~/reepfetch.sh
wal -R >/dev/null 2>&1





