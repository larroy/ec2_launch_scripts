# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

#if [ "$color_prompt" = yes ]; then
#    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
#else
#    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
#fi
#unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
#case "$TERM" in
#xterm*|rxvt*)
#    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
#    ;;
#*)
#    ;;
#esac

# PROMPT

source /usr/lib/git-core/git-sh-prompt

function we_are_in_git_work_tree {
    git rev-parse --is-inside-work-tree &> /dev/null
}

function parse_git_status {
    if we_are_in_git_work_tree
    then 
        local ST=$(git status --short 2> /dev/null)
        if [ -n "$ST" ]
        then
             echo -n "+"
        fi
    fi
}


export PS1="\u@\h:\$?:\w\[$Green\]\$(__git_ps1)\$(parse_git_status)\[$Color_Off\]\\$ "

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
export LS_OPTIONS='-h'
alias ll='ls $LS_OPTIONS -alF'
alias la='ls -A'
alias lS='ls $LS_OPTIONS -rlS'
alias l='ls $LS_OPTIONS -lF'
alias lt='ls $LS_OPTIONS -rltF'

alias cp='ionice -c3 nice -19 cp -i'
alias mv='ionice -c3 nice -19 mv -i'
alias rm='ionice -c3 nice -19 rm'
alias ds='ionice -c3 nice -n19 du -xms -- * | nice -n19 sort -n'
alias va='mplayer -fs -vo xv -cache 50000' 
alias hgmaindiff="hg diff -r 'ancestor(default,.)'"
alias bt='./build.sh && ./test.sh'

alias gitst='git status -uno | less'
alias gitu='git st -u | egrep -v "(~$|swp$)"'

alias ipy="python -c 'import IPython; IPython.terminal.ipapp.launch_new_instance()'"


zi() {
    set -e
    FILE=$(echo $1 | perl -wne 's/:(\d+)(?::\d+:?)?/ +$1/; print')
    echo $FILE
    vim $FILE
}

f() {
    A=($@);
    REST=${A[@]:1:$#};
    find -iname "*$1*" $REST;
}

ulimit -c unlimited

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi


ulimit -c unlimited


idx() {
    ctags -R --extra=fq --c++-kinds=+p --fields=+iaS --verbose `find -regextype posix-extended -regex ".*\.(cpp|h|hpp|cxx|hh)$"`
    cscope -v -R -b
}

function s {
    $* &>/dev/null &
    disown
}

complete -F _command launch

encrypt()
{
    openssl enc -aes-256-cfb -salt -in $1 -out $2
}

decrypt()
{
    openssl enc -d -aes-256-cfb -salt -in $1 -out $2
}

clone_mxnet()
{
    pushd .
    git clone --recursive git@github.com:apache/incubator-mxnet.git mxnet
    popd
}


md() {
    if [ "$#" -ne 1 ];
        then echo "illegal number of parameters"
        return
    fi
    pandoc $1 | lynx -stdin
}

export EDITOR=vim
alias open='xdg-open'
/usr/bin/zsh && exit
