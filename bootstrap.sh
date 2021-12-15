#!/bin/zsh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

BREW_CASK_DEFAULT_APP_DIR=/Applications
BREW_CASK_APP_DIR=/Applications/Development

DEFAULT_GO_VERSION="1.17.5"
DEFAULT_PYTHON_VERSION="3.10.1"
DEFAULT_RUBY_VERSION="3.0.3"
DEFAULT_NODE_VERSION="16.13.1"
DEFAULT_BAZEL_VERSION="3.6.0"

DEFAULT_GCLOUD_PATH="/usr/share/google-cloud-sdk"

core_utility_casks=(
  authy
)

core_dev_casks=(
  visual-studio-code
  postman
  virtualbox
)

casks=(
  adoptopenjdk{8,11}
  google-cloud-sdk
  vagrant
)

prereq_brews=(
  asdf
  awscli
  azure-cli
  fd
  fzf
  git
  git-extras
  go
  gpg
  jenv
  pyenv
  svn
  wget
  zsh
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-syntax-highlighting
)

gnu_brews=(
  autoconf
  bash
  binutils
  coreutils
  diffutils
  ed 
  findutils
  flex
  gawk
  gnu-indent
  gnu-sed
  gnu-tar
  gnu-which
  gpatch
  grep
  gzip
  less
  m4
  make
  nano
  screen
  tree
  watch
  wdiff 
)

brews=(
  ansible
  fortio
  k9s
  krew
  kind
  kops
  kubectl
  glooctl
  gnupg
  gradle
  helm
  hey
  httpie
  jq
  maven
  mitmproxy
  openssl
  skaffold
  spotify-tui
  spotifyd
  terraform
  weaveworks/tap/eksctl
)

set +e
[[ "$DEBUG" == 'true' ]] && set -x

function log_info { echo -e '\033[1;32m'"$1"'\033[0m'; }
function log_warn { echo -e '\033[1;33m'"$1"'\033[0m'; }
function log_error { echo -e '\033[1;31mERROR: '"$1"'\033[0m'; }

function prompt {
  echo ""
  read "?Press [Enter] key to $1 ..."
}

function get_keypress {
  local REPLY IFS=
  >/dev/tty printf '%s' "$*"
  [[ $ZSH_VERSION ]] && read -rk1
  [[ $BASH_VERSION ]] && </dev/tty read -rn1
  printf '%s' "$REPLY"
}

function get_yes_keypress {
  local prompt="${1:-Are you sure [y/n]? }"
  local enter_return=$2
  local REPLY
  while REPLY=$(get_keypress "$prompt"); do
    [[ $REPLY ]] && printf '\n'
    case "$REPLY" in
      Y|y|yes|Yes)  return 0;;
      N|n|no|No)  return 1;;
      '')   [[ $enter_return ]] && return "$enter_return"
    esac
  done
}

function confirm {
  local prompt="${*:-Are you sure} [y/N - Enter to no]? "
  get_yes_keypress "$prompt" 1
}

function install {
  cmd=$1
  shift
  for pkg in "$@";
  do
    if eval "$cmd $pkg"; then
      log_info "Installed ${pkg}"
    else
      log_error "Failed to execute: ${cmd} ${pkg}"
      exit 1
    fi
  done
}

function brew_install_or_upgrade {
  if $(brew ls --versions "$1" >/dev/null); then
    if $(brew outdated | grep "$1" > /dev/null); then 
      log_warn "Upgrading already installed package $1 ..."
      brew upgrade "$1"
    else 
      log_warn "Latest $1 is already installed"
    fi
  else
    brew install "$1"
  fi
}

function run_installer {
  if ! command -v "$1" >/dev/null; then
    curl -sSL $2
  fi
}

function omz_reload {
    source "$HOME/.zshrc"
}

function omz_installer {
  if [[ -f "$HOME/.zshrc" ]]; then
    mv -n $HOME/.zshrc $HOME/.zshrc-backup-$(date +"%Y-%m-%d-%s") &> /dev/null
    if [[ $? -eq 0 ]]; then
      log_info "Backed up the current .zshrc to .zshrc-backup-$(date +"%Y-%m-%d-%s")"
    fi
  fi

  if [[ -d $HOME/.oh-my-zsh ]]; then
      log_warn "oh-my-zsh is already installed"
  else
      log_info "Installing oh-my-zsh"
      git clone --depth=1 git://github.com/robbyrussell/oh-my-zsh.git $HOME/.oh-my-zsh
  fi

  if [[ -d $HOME/.oh-my-zsh/custom/themes/powerlevel10k ]]; then
    log_warn "powerlevel10k is already installed, updating to latest"
    cd $HOME/.oh-my-zsh/custom/themes/powerlevel10k && git pull
  else
      log_info "Installing powerlevel10k"
      git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/.oh-my-zsh/custom/themes/powerlevel10k
  fi

  log_info "Deploying latest zshrc and p10k.zsh"
  cp -f $SCRIPT_DIR/oh-my-zsh-theme/.zshrc $HOME/.
  cp -f $SCRIPT_DIR/oh-my-zsh-theme/.p10k.zsh $HOME/.

  cd $HOME/.oh-my-zsh
  if sudo chsh -s $(which zsh) && sh -c "$HOME/.oh-my-zsh/tools/upgrade.sh"; then
      log_info "Installation Successful"
  else
      log_error "Something is wrong, exiting"
      exit 1
  fi

  cd $SCRIPT_DIR

  brew install --cask font-source-code-pro

  omz_reload

}

log_info "==================================="
log_info "Bootstrapping OS X"
log_info "==================================="
log_info "Starting .... this process takes a while so grab a coffee :)"
log_info "You may be asked for your password (for sudo)."

# Deal with SSH key generation
mkdir -p $HOME/.ssh

# Setup default SSH key
DEFAULT_SSH_KEY=$HOME/.ssh/id_rsa
if [[ -f "$DEFAULT_SSH_KEY" ]]; then
  log_warn "Default SSH key $DEFAULT_SSH_KEY exists ..."
else
  log_info "Generating a default SSH key ..."
  sudo ssh-keygen -b 2048 -t rsa -f $DEFAULT_SSH_KEY
fi

sudo -v # Ask for the administrator password upfront
# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Check for Homebrew,
# Install if we don't have it along with command line tools
if test ! "$(command -v brew)"; then
  prompt "install Homebrew"
  /bin/bash < <(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
  brew doctor
else
  prompt "update Homebrew"
  brew update
  brew upgrade
  brew doctor
fi

brew tap homebrew/cask-versions
# cask-versions already includes jdk8 tap so remove the duplicate
if [[ -f /usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask-versions/Casks/adoptopenjdk8.rb ]]; then
  rm -f /usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask-versions/Casks/adoptopenjdk8.rb
fi
brew tap adoptopenjdk/openjdk
brew tap homebrew/cask-fonts
brew tap weaveworks/tap

log_info "Installing core cask software"
install "brew install --appdir=$BREW_CASK_DEFAULT_APP_DIR --cask" "${core_utility_casks[@]}"

log_info "Installing core cask dev software"
install "brew install --appdir=$BREW_CASK_APP_DIR --cask" "${core_dev_casks[@]}"

log_info "Installing cask software"
install 'brew install --cask' "${casks[@]}"

log_info "Installing pre-req packages"
install 'brew_install_or_upgrade' "${prereq_brews[@]}"

log_info "Installing gnu packages"
install 'brew_install_or_upgrade' "${gnu_brews[@]}"

# oh my zsh
omz_installer

# Install g and Golang
if command -v "ggovm" >/dev/null; then
  log_warn "g (Golang Version Manager) is already installed"
else
  log_info "Installing g"
  curl -sSL https://git.io/g-install | sh -s -- -y
  omz_reload
fi

if [[ $(ggovm list | grep '>' > /dev/null) ]]; then
  log_warn "g is already managing Go"
else
  log_info "Installing Go $DEFAULT_GO_VERSION"
  ggovm install $DEFAULT_GO_VERSION
  ggovm set $DEFAULT_GO_VERSION
fi

# Install and set Python
if pyenv global > /dev/null; then
  log_warn "pyenv is already managing Python"
else
  log_info "Installing Python $DEFAULT_PYTHON_VERSION"
  pyenv install -s $DEFAULT_PYTHON_VERSION
  pyenv global $DEFAULT_PYTHON_VERSION
fi

# Set Java
if jenv version | grep 11 > /dev/null; then
  log_warn "Java is already setup"
else
  log_info "Setting up Java"
  jenv enable-plugin export
  jenv enable-plugin maven
  jenv add /Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home
  jenv add /Library/Java/JavaVirtualMachines/adoptopenjdk-11.jdk/Contents/Home
  jenv global 11
fi

# Install rvm and Ruby
if command -v "rvm" > /dev/null; then
  log_warn "rvm is already installed"
else
  log_info "Installing rvm"
  gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  /bin/bash < <(curl -sSL https://get.rvm.io)
  source $HOME/.rvm/scripts/rvm
fi
if rvm list strings | grep ruby- > /dev/null; then
  log_warn "rvm is already managing Ruby"
else
  log_info "Installing Ruby $DEFAULT_RUBY_VERSION"
  rvm --default install "$DEFAULT_RUBY_VERSION"
fi

# Install nvm
if command -v "nvm" > /dev/null; then
  log_warn "nvm is already installed"
else
  log_info "Installing nvm"
  /bin/bash < <(curl -sSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh)
  . $HOME/.nvm/nvm.sh
fi
if [[ $(nvm current) == "none" ]]; then
  nvm install "v${DEFAULT_NODE_VERSION}"
  nvm alias default "v${DEFAULT_NODE_VERSION}"
fi

log_info "Installing remaining packages"
install 'brew_install_or_upgrade' "${brews[@]}"

# Updating Google Cloud SDK
if command -v gcloud > /dev/null; then
  log_warn "gcloud is already installed. Will be updating to the latest version instead"
  gcloud components update -q
fi

prompt "brew cleanup"
brew cleanup

# Disable last login
touch ~/.hushlogin

# Install asdf plugins
asdf plugin-add istioctl
asdf plugin-add bazel https://github.com/mrinalwadhwa/asdf-bazel.git
asdf install istioctl latest
asdf install bazel $DEFAULT_BAZEL_VERSION

# Disable Gatekeeper
confirm "Disable Gatekeeper (WARNING: any malicious app can be installed) ?"
if [[ "$?" -eq 0 ]]; then
  sudo spctl --master-disable
  sudo spctl --status
fi

confirm "Would you like to setup the Github SSH authentication"
if [[ "$?" -eq 0 ]]; then
  # Setup Github specific key
  GITHUB_SSH_KEY=$HOME/.ssh/github_id_rsa
  if [[ -f "$GITHUB_SSH_KEY" ]]; then
    log_warn "GitHub SSH key $GITHUB_SSH_KEY exists ..."
  else
    echo ''
    echo '#### Please enter your GitHub username: '
    read github_user
    echo '#### Please enter your GitHub email address: '
    read github_email
    echo '#### Please enter your GitHub token: '
    read github_token

    if [[ $github_user && $github_email ]]; then
      git config --global user.name "$github_user"
      git config --global user.email "$github_email"
      git config --global github.user "$github_user"
      git config --global github.token "$github_token"
      git config --global color.ui true
      git config --global push.default current
      git config --global tag.sort version:refname

      ## Set RSA key
      curl -s -O http://github-media-downloads.s3.amazonaws.com/osx/git-credential-osxkeychain
      chmod u+x git-credential-osxkeychain
      sudo mv git-credential-osxkeychain "$(dirname $(which git))/git-credential-osxkeychain"
      git config --global credential.helper osxkeychain

      log_info "Generating a GitHub SSH key ..."
      sudo ssh-keygen -b 2048 -t rsa -C "$github_email" -f $GITHUB_SSH_KEY

      log_info "\nPlease add this public key (in clipboard) to GitHub"
      pbcopy < $HOME/.ssh/github_id_rsa.pub
      cat $HOME/.ssh/github_id_rsa.pub
      log_info "Follow step 4 to complete: https://help.github.com/articles/generating-ssh-keys"
      prompt "continue after setting up GitHub"
      ## Test SSH to GitHub
      ssh -T git@github.com
    fi
  fi
fi

if [[ -f "$HOME/.zshrc" && ($(grep -e "{GLOO_EDGE_LICENSE_KEY}" -e "{GLOO_MESH_LICENSE_KEY}" -e "{GLOO_MESH_GATEWAY_LICENSE_KEY}" "$HOME/.zshrc")) ]]; then
  confirm "Would you like to update solo.io licenses ?"
  if [[ "$?" -eq 0 ]]; then
    if [[ $(grep "{GLOO_EDGE_LICENSE_KEY}" "$HOME/.zshrc") ]]; then
      echo '#### Enter your Gloo Edge Enterprise license: '
      read ge_license
      sed -in "s/{GLOO_EDGE_LICENSE_KEY}/$ge_license/g" "$HOME/.zshrc"   
    fi
    if [[ $(grep "{GLOO_MESH_LICENSE_KEY}" "$HOME/.zshrc") ]]; then
      echo '#### Enter your Gloo Mesh Enterprise license: '
      read gm_license
      sed -in "s/{GLOO_MESH_LICENSE_KEY}/$gm_license/g" "$HOME/.zshrc"
    fi
    if [[ $(grep "{GLOO_MESH_GATEWAY_LICENSE_KEY}" "$HOME/.zshrc") ]]; then
      echo '#### Enter your Gloo Mesh Gateway license: '
      read gmg_license
      sed -in "s/{GLOO_MESH_GATEWAY_LICENSE_KEY}/$gmg_license/g" "$HOME/.zshrc"
    fi
  fi
fi

log_info "Bootstrapping successfully finished - Make sure to reload the terminal"
