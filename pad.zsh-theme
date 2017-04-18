# Exec time

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

function add_if {
    if $(echo "$1" | grep $2 &> /dev/null); then
        STATUS+=$3
    fi
}

function svn_status {
    local ROOT="$(svn info | sed -n 's/^Working Copy Root Path: //p')"
    local INDEX="$(svn status "$ROOT")"
    local STATUS=""

    add_if $INDEX '^A'               $ZSH_THEME_GIT_PROMPT_STAGED_ADDED
    add_if $INDEX '^M'               $ZSH_THEME_GIT_PROMPT_STAGED_MODIFIED
    add_if $INDEX '^R'               $ZSH_THEME_GIT_PROMPT_STAGED_RENAMED
    add_if $INDEX '^D'               $ZSH_THEME_GIT_PROMPT_STAGED_DELETED

    add_if $INDEX '^!'               $ZSH_THEME_GIT_PROMPT_DELETED
    add_if $INDEX '^?'               $ZSH_THEME_GIT_PROMPT_UNTRACKED

    [[ -n "$STATUS" ]] && STATUS+=" "
    STATUS+="%{$FG[011]%}$(svn_get_branch_name)"

    echo $STATUS
}

function git_status {
    echo "$(gitHUD zsh)%{$BG[019]%}"
}

function vcs_status {
    local STATUS
    if [[ -n "$(current_branch)" ]]; then
        STATUS=$(git_status)
    elif [[ -n "$(svn_get_branch_name)" ]]; then
        STATUS=$(svn_status)
    fi
    [[ -n "$STATUS" ]] && echo "%{$BG[019]%} $STATUS "
}

function render_top_bar {
    local ZERO='%([BSUbfksu]|([FB]|){*})'

    # Top right
    local TOP_RIGHT="$(vcs_status)"
    local RIGHT_WIDTH=${#${(S%%)TOP_RIGHT//$~ZERO/}}

    # Top left
    local PWD_MAX_LEN
    (( PWD_MAX_LEN = $COLUMNS - $RIGHT_WIDTH - 3 ))
    local PWD_PATH="%$PWD_MAX_LEN<...<${PWD/#$HOME/~}%<<"
    [[ "${PWD_PATH:h}" != "." ]] && local PREFIX="${PWD_PATH:h}/"
    local TOP_LEFT="%{$FG[008]%}$PREFIX%{$FG[004]%}${PWD_PATH:t}"
    local LEFT_WIDTH=${#${(S%%)TOP_LEFT//$~ZERO/}}

    # Middle (fill)
    local FILL="\${(l:(($COLUMNS - ($LEFT_WIDTH + $RIGHT_WIDTH + 2))):: :)}"

    # Whole bar
    TOP_BAR="%{$BG[018]%} "
    TOP_BAR+="$TOP_LEFT%{$FX[reset]%}"
    TOP_BAR+="%{$BG[018]%}$FILL"
    TOP_BAR+="$TOP_RIGHT%{$FX[reset]%}"
    TOP_BAR+="%{$BG[018]%} %{$FX[reset]%}"
}

setprompt () {
    PROMPT='${(e)TOP_BAR}
%{$FG[003]%}»%{$FX[reset]%} '

    # display exitcode on the right when >0
    return_code="%(?..%{$FG[001]%}⌗%?)"

    RPROMPT=' $return_code %{$FG[019]%}${LAST_EXEC_TIME}s%{$FX[reset]%}'
}

setopt prompt_subst

setprompt

add-zsh-hook precmd render_top_bar
