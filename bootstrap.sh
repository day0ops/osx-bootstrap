#!/bin/zsh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

BREW_CASK_DEFAULT_APP_DIR=/Applications
BREW_CASK_APP_DIR=/Applications/Development

DEFAULT_GO_VERSION="1.22.1"
DEFAULT_PYTHON_VERSION="3.12.2"
DEFAULT_RUBY_VERSION="3.3.0"
DEFAULT_NODE_VERSION="20.11.1"

DEFAULT_GCLOUD_PATH="/usr/share/google-cloud-sdk"

core_utility_casks=(

)

core_dev_casks=(
  # The apps below are encouraged to install outside of casks
  # visual-studio-code
  # postman
  # virtualbox
  # vagrant
)

casks=(
  google-cloud-sdk
  # Install jdk8
  temurin8
  # Install jdk11
  temurin11
  # Install latest jdk
  temurin21
)

prereq_brews=(
  asdf
  aws-iam-authenticator
  awscli
  azure-cli
  fd
  fzf
  git
  git-extras
  go
  gh
  gpg
  jenv
  pyenv
  svn
  terminal-notifier
  wget
  zsh
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-syntax-highlighting
)

gnu_brews=(
  autoconf
  bash
  bazelisk
  binutils
  cfssl
  coreutils
  diffutils
  ed 
  findutils
  flex
  gawk
  gnu-getopt
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
  argocd
  dnsmasq
  fortio
  k6
  k9s
  krew
  kind
  kops
  kubectl
  kubectx
  kustomize
  glooctl
  gnupg
  gradle
  helm
  hey
  httpie
  jq
  lima
  maven
  mitmproxy
  openssl
  packer
  skaffold
  stern
  terraform
  vault
  weaveworks/tap/eksctl
  yq
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
  pushd $SCRIPT_DIR

  if [[ -f "$HOME/.zshrc" ]]; then
    local backup_file=".zshrc-backup-$(date +"%Y-%m-%d-%s")"
    mv -n $HOME/.zshrc $HOME/$backup_file &> /dev/null
    if [[ $? -eq 0 ]]; then
      log_info "Backed up the current .zshrc to $backup_file"
    fi
  fi

  if [[ -d $HOME/.oh-my-zsh ]]; then
    log_warn "oh-my-zsh is already installed"
  else
    log_info "Installing oh-my-zsh"
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git $HOME/.oh-my-zsh
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

  if [[ -d $HOME/.oh-my-zsh/custom/plugins ]]; then
    log_info "Installing kube-aliases plugin"
    git clone https://github.com/Dbz/kube-aliases.git $HOME/.oh-my-zsh/custom/plugins/kube-aliases
  fi

  brew install --cask font-source-code-pro

  if sudo chsh -s $(which zsh) && cd "$HOME/.oh-my-zsh" && sh -c "$HOME/.oh-my-zsh/tools/upgrade.sh"; then
    log_info "Installation Successful"
  else
    log_error "Something is wrong, exiting"
    exit 1
  fi

  omz_reload

  popd
}

log_info "==================================="
log_info "Bootstrapping OS X 🖥️"
log_info "==================================="
log_info "Starting .... this process takes a while so grab a ☕"
log_info "You may be asked for sudo password."

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

log_info "Installing remaining packages"
install 'brew_install_or_upgrade' "${brews[@]}"

# oh my zsh
omz_installer

# Install gvm and Golang
if command -v "gvm" >/dev/null; then
  log_warn "gvm (Golang Version Manager) is already installed"
else
  log_info "Installing gvm"
  /bin/bash < <(curl -sSL https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
  omz_reload
fi
if [[ $(gvm list | grep '=> go' > /dev/null) ]]; then
  log_warn "gvm is already managing Go"
else
  log_info "Installing Go ${DEFAULT_GO_VERSION}"
  gvm install "go${DEFAULT_GO_VERSION}"
  gvm use "go${DEFAULT_GO_VERSION}" --default
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
  # Believe it or not some apps are still reliant on java 8/11
  jenv add /Library/Java/JavaVirtualMachines/temurin-8.jdk/Contents/Home
  jenv add /Library/Java/JavaVirtualMachines/temurin-11.jdk/Contents/Home
  jenv add /Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home
  jenv global 21
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
  log_info "Installing Ruby ${DEFAULT_RUBY_VERSION}"
  rvm --default install "${DEFAULT_RUBY_VERSION}"
fi

# Install nvm
if command -v "nvm" > /dev/null; then
  log_warn "nvm is already installed"
else
  log_info "Installing nvm"
  /bin/bash < <(curl -sSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh)
  . "$HOME/.nvm/nvm.sh"
fi
if [[ $(nvm current) == "none" ]]; then
  nvm install "v${DEFAULT_NODE_VERSION}"
  nvm alias default "v${DEFAULT_NODE_VERSION}"
fi

# Install Rust and Cargo
if command -v "rustup" > /dev/null; then
  log_warn "Rust is already installed"
else
  log_info "Installing Rust"
  curl -sSL https://sh.rustup.rs | sh -s -- -y --profile minimal
  . "$HOME/.cargo/env"
fi

# Updating Google Cloud SDK
if command -v gcloud > /dev/null; then
  log_warn "gcloud is already installed. Will be updating to the latest version instead"
  gcloud components update -q
fi

prompt "brew cleanup"
brew cleanup

# Disable last login
touch ~/.hushlogin

# Setup vim
if [[ -f "$HOME/.vimrc" ]]; then
  local backup_file=".vimrc-backup-$(date +"%Y-%m-%d-%s")"
  mv -n $HOME/.vimrc $HOME/$backup_file &> /dev/null
  if [[ $? -eq 0 ]]; then
    log_info "Backed up the current .vimrc to $backup_file"
  fi

  cp -f $SCRIPT_DIR/.vimrc $HOME/.
  # Plugin management
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# Install asdf plugins
asdf plugin-add istioctl
asdf install istioctl latest
asdf global istioctl latest

confirm "Would you like to setup the GitHub SSH authentication"
if [[ "$?" -eq 0 ]]; then
  # Setup GitHub specific key
  GITHUB_SSH_KEY=$HOME/.ssh/github_id_rsa
  GITHUB_SSH_PUB_KEY=$HOME/.ssh/github_id_rsa.pub
  SSH_CONFIG=$HOME/.ssh/config
  if [[ -f "$GITHUB_SSH_KEY" ]]; then
    log_warn "GitHub SSH key $GITHUB_SSH_KEY already exists ..."
  else
    echo ''
    echo '#### Please enter your name: '
    read github_name
    echo '#### Please enter your GitHub username: '
    read github_user
    echo '#### Please enter your GitHub email address: '
    read github_email
    echo '#### Please enter your GPG key: '
    read gpg_key_id

    if [[ $github_user && $github_email ]]; then
      log_info "Generating a GitHub SSH key ..."
      sudo ssh-keygen -t ed25519 -C "$github_email" -f $GITHUB_SSH_KEY
      eval "$(ssh-agent -s)"

      log_info "Generating GitHub configuration"
      git config --global user.name "$github_name"
      git config --global user.username "$github_user"
      git config --global user.email "$github_email"
      git config --global github.user "$github_user"
      git config --global color.ui true
      git config --global push.default current
      git config --global tag.sort version:refname
      if [[ -z "${gpg_key_id}" ]]; then
        git config --global user.signingkey "$gpg_key_id"
        git config --global commit.gpgsign true
      fi

      cat $SSH_CONFIG > /dev/null
      check_ssh_config_file=$?
      if [ ${check_ssh_config_file} == 0 ]; then
        log_info "Adding another configuration to $SSH_CONFIG"
      else
        log_warn "You do not have an SSH config file yet"
        log_info "Lets create a SSH config file"
        touch $SSH_CONFIG
      fi

      read -p "Enter the host name alias for GitHub: " github_alias
      github_alias=${github_alias}
      grep -q ${github_alias} $HOME/.ssh/config
      check_github_alias=$?
      while [ ${check_github_alias} == 0 ]; do
        read -p "Enter the host name alias for GitHub (It must be new): " github_alias
        github_alias=${github_alias}
        grep -q ${github_alias} $SSH_CONFIG
        check_github_alias=$?
      done

      log_info "The following will be added to your ssh config file:"
      echo -e "Host ${github_alias}\nHostName github.com\nUser git\n"
      confirm "Is this information correct ?"
      if [[ "$?" -eq 0 ]]; then
        cp $SSH_CONFIG "${SSH_CONFIG}_backup_"$(date +"%Y-%m-%d-%s")
        echo -en '\n' >> $SSH_CONFIG
        echo "Host ${github_alias}" >> $SSH_CONFIG
        echo -e "\tHostName github.com" >> $SSH_CONFIG
        echo -e "\tUser git" >> $SSH_CONFIG
        echo -e "\IdentityFile ${GITHUB_SSH_KEY}" >> $SSH_CONFIG
        echo -e "\tAddKeysToAgent yes" >> $SSH_CONFIG
        echo -e "\tIdentitiesOnly yes" >> $SSH_CONFIG
        log_info "New host added to ssh config!"
      fi

      log_info "\nPlease add this public key (in clipboard) to GitHub"
      pbcopy < $GITHUB_SSH_PUB_KEY
      cat $GITHUB_SSH_PUB_KEY
      log_info "Follow step 4 to complete: https://help.github.com/articles/generating-ssh-keys"
      prompt "continue after setting up GitHub"
      chmod 400 $GITHUB_SSH_KEY
      # Test SSH to GitHub
      ssh -T git@github.com
    fi
  fi
fi

log_info "🎉 Bootstrapping successfully finished - Make sure to reload the terminal 🎉"
