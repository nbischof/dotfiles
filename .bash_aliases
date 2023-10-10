# only if interactive
[[ $- != *i* ]] && return

stty -ixon

### ENVIRONMENT ###
export HISTFILESIZE=1000000
export HISTSIZE=1000000
export GOPATH=~/.go
export PATH=~/adm/bin:~/jive/bin:$GOPATH/bin:/usr/local/go/bin:~/.local/bin:$PATH
export CDPATH=".:~:~/jive/issues:~/jive/git"
export EDITOR=vim
export VISUAL=vim # for mutt
export GIT_EDITOR=vim
export TIMEFORMAT='(time used: %1lR)'

### ALIAS FILES ###
function source_file () { [ -n "$1" -a -r "$1" ] && source "$1" ; }
source_file   $HOME/adm/sh/local_env.sh
source_file   $HOME/adm/sh/local_aliases.sh
source_file   $HOME/adm/sh/itworksone_local_aliases.sh
source_file   $HOME/adm/sh/mac_aliases.sh
source_file   $HOME/adm/sh/audio_and_tools_aliases.sh

alias	ll='ls -Bhltr'
alias	lla='ls -altr'
llt  () { ls -lhtr  "$@" | tail ; }
llto () { ls -lhtrO "$@" | tail ; }

alias	l='ls -BF'
alias	l.='ls -AF'
alias	la='ls -aF'
alias	sll='sudo ls -Bhltr'
alias	lll='ls -LhBltr'
alias	lla='ls -alhtr'
alias	lls='ls -alhSr'
alias	lld='ls -dalhtr'
llg () { ls -lhtr | grep  "$@" ; }
lvi () { ls -tr | tail -1 | xargs gvim -p ; }
alias	igrep='grep -i'
alias	wgrep='grep -w'
alias	iwgrep='grep -iw'
alias ,p='pgrep -l'
alias ppp='python3'

alias x=exit
alias md='mkdir -p'
alias mv='mv -v'
alias rm='rm -v'
alias cp='cp -pv'
alias rs='source ~/.bashrc ~/.bash_aliases'

alias ,ee='gvi ~/.bash_aliases'
alias ,v='gvi -S'
,h  () { history | grep    "$*" | uniq -f 1 | tail -10 ; }
,hi () { history | grep -i "$*" | uniq -f 1 | tail -10 ; }
,hh()  { local t=$(mktemp); history > ${t};  while [ -n "$1" ] ; do grep  "$1"  ${t} > ${t}.1; /bin/mv ${t}.1 ${t} ; shift; done; tail  ${t}; }
,parallel () { parallel --will-cite -k -j500 "$@" ; }
untar () { local f=`mktemp`; tar tzf "$@" | tee $f | head ; tail $f ; echo -n 'un-tar? ' ; read _a ; [ "$_a" == "${_a#n}" ] && tar xzf "$@" ; }
,tar () { local d="$1" ; local tgz=${d%%*(/)}.tar.gz ; [ -d $d ] && { tar zcf $tgz $d ; ls -hl $tgz ; } || echo not a dir: $d ? ; }

function ,,  () { pushd "$@" ; }
function ,,, () { pushd +1 ; }

shist	() { history | grep -i "$1" ; }
alias	..='dot2=$dot ; dot=`pwd` ; cd ..'
alias	,='dot2=$dot ; dot=`pwd` ; pushd $dot2'
alias	std='pwd >$HOME/.startdir'
alias	cdd='dot2=$dot ; dot=`pwd` ; [ -f $HOME/.startdir ] && pushd `cat $HOME/.startdir` '
alias	nod='pwd >$HOME/.nowdir'
alias	mnod='_nod=`pwd`'
alias	cdn='dot2=$dot ; dot=`pwd` ; [ -z "${_nod}" ] && pushd `cat $HOME/.nowdir` || pushd ${_nod}'
alias	cdnnn='cd "$(ls -tr | tail -1 || .)"'
alias cd..='cd ..'



################################################################################
###     Utility Functions     ##################################################
################################################################################

tsave	() # make a copy
	{
          ___cmd='cp -a'
          [ "$1" == "-m" ] && { ___cmd='mv -i'; shift; }
          for old in "$@" ; do
            new=$(date +"${old%%/}.%F-%T")
            [ -f $new ] && echo failed. || $___cmd  $old $new
          done
	}
dsave	() # make a copy
	{
          for old in "$@" ; do
            new=$(date +"${old%%/}.%Y-%m-%d")
            [ -f $new ] || cp -a $old $new
          done
	}
unrpm   () 
        { 
          rpm2cpio $* |cpio -idmv --no-absolute-filenames
        }
ssh-init ()
{
  [ -z "$PUBKEY_FILE" ] && { echo PUBKEY_FILE must be set in .bashrc.local; return; }
  if [ -z "$1" ]
    then
    echo "Copies the public key to the given ssh host, sample usage:
      ssh-init root@myhost.adomain.net
    "
    return
  fi

  _host="$1"
  scp ~/.ssh/$PUBKEY_FILE $_host: && \
  ssh $_host "mkdir -p .ssh; mv -v $PUBKEY_FILE .ssh/; cd .ssh/; { grep -q \"\`head $PUBKEY_FILE\`\" authorized_keys 2>/dev/null && echo Already there. || cat $PUBKEY_FILE >> authorized_keys; }"
}

ppass ()
{
  echo $* | md5sum | perl -ane 'print "$F[0]\n";'
}

treee ()
{
  ls -R | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'
}

jver ()
{
  [ "$1" == "" ] && echo usage:     jver     '<jar file> ...' && return
  for j in "$@" ; do
    printf '*********           %-50s%10s\n' $j  '******'
    unzip -p  "$j" META-INF/MANIFEST.MF | grep -i version 
    printf '********************************************************************************\n\n'
  done
}

dumpDir ()
{
  DIR=${1:-.}
  LABEL=${2:-dir-dump}
  [ -z "$1" ] && echo " usage: dumpDir [ directory ] [ label ]" >&2
  find $DIR -type f -printf '%P\t%s\t%t\n' | sort | tee $LABEL-files.txt
  find $DIR -type d -printf '%P\t%s\t%t\n' | sort | tee $LABEL-dirs.txt
}

findJars ()
{
  [ -z "$1" ] && echo usage: findJars '<directory>' >&2 && return
  find $1 \( -type f -o -type l \) -name '*.[hwrj]ar'
}

findClassInJar ()
{
  class="$1"
  jar="$2"
  context="$3"
  label="${context}${context:+ : }"

  [ -z "$jar" ] && \
    echo usage: findClassInJar class jar '[ context/label ]' >&2 && return
  [ -f "$jar" ] || \
    { echo No such file: $jar >&2 && return ; }

  [ "${jar#/}" == "$jar" ] && jar="`pwd`/$jar"

  # first direct content
  if jar tf $jar | grep -q $class ; then
    echo ==== $label$jar :
    jar tf $jar | grep $class || { echo "Can\'t open $jar ($context)"; return; }
    echo
  fi

  # processing nested jars
  if jar tf $jar | grep -q '\.[whjr]ar$' ; then
    tmpdir=/tmp/_jar-`date +%N`
    here=`pwd`
    mkdir -p $tmpdir
    cd $tmpdir
    jar xf $jar || { echo "Can\'t open $jar ($context)"; return; }
    for njar in `findJars $tmpdir` ; do
      ( findClassInJar "$class" "$njar" "${label}$jar" )
    done
    cd "$here"
    mkdir -p /tmp/DELETE-ME
    mv -f $tmpdir /tmp/DELETE-ME/
  fi
}

findClass ()
{
  unset JARS
  [ -z "$1" ] && echo " usage: findClass className [ directory ... ] " >&2 && return
  class=$1 ; shift
  for d in $*  ; do
    JARS="$JARS `findJars $d`"
  done
  for j in $JARS ; do
    findClassInJar "$class" "$j"
  done
}

function set_nb_prompt {
local       BLUE="\[\033[0;34m\]"
local LIGHT_BLUE="\[\033[1;34m\]"
local        RED="\[\033[0;31m\]"
local  LIGHT_RED="\[\033[1;31m\]"
local      WHITE="\[\033[1;37m\]"
local  NO_COLOUR="\[\033[0m\]"
case $TERM in
    xterm*)
        TITLEBAR='\[\033]0;\u@\h:\w\007\]'
        ;;
    *)
        TITLEBAR=""
        ;;
esac

PS1="${TITLEBAR}\
$LIGHT_RED\u${LIGHT_BLUE}@\h:\w\
$NO_COLOUR\n\$ "
PS2='\s>  '
PS4='+ '
}

# ===============================================
# solarized color scheme
# ===============================================

set_solarized_dark() {
  echo -ne   '\eP\e]10;#839496\a'  # Foreground   -> base0
  echo -ne   '\eP\e]11;#002B36\a'  # Background   -> base03

  echo -ne   '\eP\e]12;#DC322F\a'  # Cursor       -> red

  echo -ne  '\eP\e]4;0;#073642\a'  # black        -> Base02
  echo -ne  '\eP\e]4;8;#002B36\a'  # bold black   -> Base03
  echo -ne  '\eP\e]4;1;#DC322F\a'  # red          -> red
  echo -ne  '\eP\e]4;9;#CB4B16\a'  # bold red     -> orange
  echo -ne  '\eP\e]4;2;#859900\a'  # green        -> green
  echo -ne '\eP\e]4;10;#586E75\a'  # bold green   -> base01 *
  echo -ne  '\eP\e]4;3;#B58900\a'  # yellow       -> yellow
  echo -ne '\eP\e]4;11;#657B83\a'  # bold yellow  -> base00 *
  echo -ne  '\eP\e]4;4;#268BD2\a'  # blue         -> blue
  echo -ne '\eP\e]4;12;#839496\a'  # bold blue    -> base0 *
  echo -ne  '\eP\e]4;5;#D33682\a'  # magenta      -> magenta
  echo -ne '\eP\e]4;13;#6C71C4\a'  # bold magenta -> violet
  echo -ne  '\eP\e]4;6;#2AA198\a'  # cyan         -> cyan
  echo -ne '\eP\e]4;14;#93A1A1\a'  # bold cyan    -> base1 *
  echo -ne  '\eP\e]4;7;#EEE8D5\a'  # white        -> Base2
  echo -ne '\eP\e]4;15;#FDF6E3\a'  # bold white   -> Base3
}

set_solarized_light() {
  echo -ne   '\eP\e]10;#657B83\a'  # Foreground   -> base00
  echo -ne   '\eP\e]11;#FDF6E3\a'  # Background   -> base3

  echo -ne   '\eP\e]12;#DC322F\a'  # Cursor       -> red

  echo -ne  '\eP\e]4;0;#073642\a'  # black        -> Base02
  echo -ne  '\eP\e]4;8;#002B36\a'  # bold black   -> Base03
  echo -ne  '\eP\e]4;1;#DC322F\a'  # red          -> red
  echo -ne  '\eP\e]4;9;#CB4B16\a'  # bold red     -> orange
  echo -ne  '\eP\e]4;2;#859900\a'  # green        -> green
  echo -ne '\eP\e]4;10;#586E75\a'  # bold green   -> base01 *
  echo -ne  '\eP\e]4;3;#B58900\a'  # yellow       -> yellow
  echo -ne '\eP\e]4;11;#657B83\a'  # bold yellow  -> base00 *
  echo -ne  '\eP\e]4;4;#268BD2\a'  # blue         -> blue
  echo -ne '\eP\e]4;12;#839496\a'  # bold blue    -> base0 *
  echo -ne  '\eP\e]4;5;#D33682\a'  # magenta      -> magenta
  echo -ne '\eP\e]4;13;#6C71C4\a'  # bold magenta -> violet
  echo -ne  '\eP\e]4;6;#2AA198\a'  # cyan         -> cyan
  echo -ne '\eP\e]4;14;#93A1A1\a'  # bold cyan    -> base1 *
  echo -ne  '\eP\e]4;7;#EEE8D5\a'  # white        -> Base2
  echo -ne '\eP\e]4;15;#FDF6E3\a'  # bold white   -> Base3
}

# ===============================================
# TERMINAL
# ===============================================
for _term in xterm-256color  xterm-color  xterm+256color ; do
  ls /usr/share/terminfo/* 2> /dev/null | grep -q  xterm+256color && export TERM=$_term && break
done

set_nb_prompt
GIT_PROMPT_ONLY_IN_REPO=1
# GIT_PROMPT_FETCH_REMOTE_STATUS=0   # uncomment to avoid fetching remote status
# GIT_PROMPT_SHOW_UPSTREAM=1 # uncomment to show upstream tracking branch
# GIT_PROMPT_SHOW_UNTRACKED_FILES=all # can be no, normal or all; determines counting of untracked files
# GIT_PROMPT_SHOW_CHANGED_FILES_COUNT=0 # uncomment to avoid printing the number of changed files
# GIT_PROMPT_STATUS_COMMAND=gitstatus_pre-1.7.10.sh # uncomment to support Git older than 1.7.10
# GIT_PROMPT_START=...    # uncomment for custom prompt start sequence
# GIT_PROMPT_END=...      # uncomment for custom prompt end sequence
# as last entry source the gitprompt script
# GIT_PROMPT_THEME=Custom # use custom theme specified in file GIT_PROMPT_THEME_FILE (default ~/.git-prompt-colors.sh)
# GIT_PROMPT_THEME_FILE=~/.git-prompt-colors.sh
# GIT_PROMPT_THEME=Solarized # use theme optimized for solarized color schemesource_file   $HOME/.bash-git-prompt/gitprompt.sh
source_file   $HOME/.bash-git-prompt/gitprompt.sh

echo NOT SETTING:  set_solarized_dark
# set_solarized_dark
# set_solarized_light

# ===============================================
# load local settings
[ -r ~/.bash_aliases.local ] && . ~/.bash_aliases.local
# ===============================================
