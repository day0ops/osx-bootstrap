# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Support for 256 colors
export TERM="xterm-256color"

# Set vim as default EDITOR
export EDITOR=vim

# Set default PATH
export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin"

export ZSH="$HOME/.oh-my-zsh"
# Disable insecure validation
export ZSH_DISABLE_COMPFIX=true
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(
  ansible
  aws
  bgnotify
  brew
  gcloud
  git
  helm
  httpie
  kubectl
  npm
  macos
  terraform
  vagrant
  vscode
  web-search
)
# Load plugins managed by Homebrew
[[ ! -f $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] || source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ ! -f $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] || source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ ! -f $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]] || source $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh

# Load zsh-autosuggestions plugin
[[ ! -f $ZSH/oh-my-zsh.sh ]] || source $ZSH/oh-my-zsh.sh

# Sourcing p10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Use GNU tools instead of BSD tools
export GNUBINS="$(find /usr/local/opt -type d -follow -name gnubin -print | tr '\n' ':' | sed 's/.$//')";
export MANPATH="$(find /usr/local/opt -type d -follow -name gnuman -print | tr '\n' ':' | sed 's/.$//')";
export PATH=$GNUBINS:$MANPATH:$PATH;

# Other paths
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH="/usr/local/google-cloud-sdk/bin:$PATH"

# Python
eval "$(pyenv init --path)"

# jEnv
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

# asdf (https://github.com/ohmyzsh/ohmyzsh/blob/9e9a384edb89a489ccba958eaf33117b48e404d0/plugins/asdf/asdf.plugin.zsh)
export ASDF_DIR="$(brew --prefix asdf)/libexec"
export ASDF_COMPLETIONS="$(brew --prefix asdf)/etc/bash_completion.d"
. "$ASDF_DIR/asdf.sh"

# g - Golang version manager (https://github.com/stefanmaric/g)
export GOROOT="$HOME/.go";
export GOPATH="$HOME/.golib";
export PATH="$GOPATH/bin:$PATH"; # g-install: do NOT edit, see https://github.com/stefanmaric/g
[[ -f "$GOPATH/bin/g" ]] && alias ggovm="$GOPATH/bin/g"

# rvm - Ruby version manager
export PATH="$PATH:$HOME/.rvm/bin"
[[ ! -f $HOME/.rvm/scripts/rvm ]] || source $HOME/.rvm/scripts/rvm

# nvm - Node.js version manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# To stop Homebrew warnings !
export PATH="$GEM_HOME/bin:$PATH"

# -------------------
# solo.io specific
# -------------------

export GLOO_EDGE_LICENSE_KEY={GLOO_EDGE_LICENSE_KEY}
export GLOO_MESH_LICENSE_KEY={GLOO_MESH_LICENSE_KEY}
export GLOO_MESH_GATEWAY_LICENSE_KEY={GLOO_MESH_GATEWAY_LICENSE_KEY}

# -------------------
# Aliases
# -------------------

# Kubectl
alias k="kubectl"
alias kc='kubectl'
alias kube='kubectl'
alias kg='kubectl get'
alias kga='kubectl get --all-namespaces'
alias kgpo='kubectl get pods'

alias kaf='kubectl apply -f'
alias kcf='kubectl create -f'
alias kdf='kubectl delete -f'
alias kef='kubectl edit -f'
alias kdsf='kubectl describe -f'
alias kgf='kubectl get -f'

# Solo.io
alias gl="glooctl"

alias cdsi='cd $GOPATH/src/github.com/solo-io'
alias cdg='cd $GOPATH/src/github.com/solo-io/gloo'
alias cdgf='cd $GOPATH/src/github.com/solo-io/gloo-fed'
alias cdsp='cd $GOPATH/src/github.com/solo-io/solo-projects'
alias cdgm='cd $GOPATH/src/github.com/solo-io/gloo-mesh'
alias cdgmui='cd $GOPATH/src/github.com/solo-io/gloo-mesh-ui'
alias cdgme='cd $GOPATH/src/github.com/solo-io/gloo-mesh-enterprise'

export GOPRIVATE="github.com/solo-io"

# Istioctl
alias is='istioctl'

# Brew
alias brew='env PATH="${PATH//$(pyenv root)\/shims:/}" brew'
alias bci="brew install --cask"

# End of customized settings
# --------------------------

