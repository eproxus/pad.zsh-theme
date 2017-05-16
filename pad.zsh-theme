export LAST_EXEC_TIME="0"

function pad_hook_preexec {
    timer=${timer:-$SECONDS}
}

autoload -U add-zsh-hook

function pad_hook_precmd {
    if [ $timer ]; then
        export LAST_EXEC_TIME="$(($SECONDS - $timer))"
        unset timer
    fi
}

add-zsh-hook preexec pad_hook_preexec
add-zsh-hook precmd pad_hook_precmd

function render_top_bar {
    local ZERO='%([BSUbfksu]|([FB]|){*})'

    # Top right
    local TOP_RIGHT="${vcs_info_msg_0_}"
    # local TOP_RIGHT=" foo "
    local RIGHT_WIDTH=${#${(S%%)TOP_RIGHT//$~ZERO/}}

    # Top left
    local PWD_MAX_LEN
    (( PWD_MAX_LEN = $COLUMNS - $RIGHT_WIDTH - 3 ))
    local PWD_PATH="%$PWD_MAX_LEN<...<${PWD/#$HOME/~}%<<"
    [[ "${PWD_PATH:h}" != "." ]] && local PREFIX="${PWD_PATH:h}/"
    local TOP_LEFT="%F{8}$PREFIX%F{4}${PWD_PATH:t}"
    local LEFT_WIDTH=${#${(S%%)TOP_LEFT//$~ZERO/}}

    # Middle (fill)
    local FILL="\${(l:(($COLUMNS - ($LEFT_WIDTH + $RIGHT_WIDTH + 2))):: :)}"

    # Whole bar
    TOP_BAR="%K{18} $TOP_LEFT$FILL%K{19}$TOP_RIGHT%K{18} $k"
}

setprompt () {
    PROMPT='${(e)TOP_BAR}
%F{3}»%f%k '

    # display exitcode on the right when >0
    return_code="%(?..%F{1}⌗%?)"

    RPROMPT=' ${return_code} %F{19}${LAST_EXEC_TIME}s%f%k'
}

autoload -Uz vcs_info
add-zsh-hook precmd vcs_info

zstyle ':vcs_info:*' enable git svn hg
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' check-for-staged-changes true
zstyle ':vcs_info:hg*:*' get-bookmarks true
zstyle ':vcs_info:*' stagedstr " %F{green}S"
zstyle ':vcs_info:*' unstagedstr " %F{red}U"
zstyle ':vcs_info:*:*' formats " \
%F{8}%s: \
%{%F{3}%B%}%b%{%%b%f%}\
%u%c%m "

setopt prompt_subst

setprompt

add-zsh-hook precmd render_top_bar
