#!/bin/bash
# author: buzhibujue
set -euo pipefail

red='\033[91m'
green='\033[92m'
yellow='\033[93m'
magenta='\033[95m'
cyan='\033[96m'
none='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS=""
PKG_MANAGER=""

log() {
  printf "%b%s%b\n" "${2:-$cyan}" "$1" "$none"
}

detect_platform() {
  case "$(uname -s)" in
    Darwin)
      OS="macos"
      PKG_MANAGER="brew"
      ;;
    Linux)
      OS="linux"
      if command -v apt-get >/dev/null 2>&1; then
        PKG_MANAGER="apt"
      elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
      elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
      else
        echo "Unsupported Linux distribution: apt-get/dnf/yum not found." >&2
        exit 1
      fi
      ;;
    *)
      echo "Unsupported operating system: $(uname -s)" >&2
      exit 1
      ;;
  esac
}

ensure_homebrew() {
  if [[ "$OS" != "macos" ]]; then
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    return
  fi

  log "Installing Homebrew..." "$yellow"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

pkg_is_installed() {
  local pkg="$1"
  local cmd="${2:-$pkg}"

  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi

  if [[ "$PKG_MANAGER" == "brew" ]]; then
    brew list "$pkg" >/dev/null 2>&1
    return
  fi

  if [[ "$PKG_MANAGER" == "apt" ]]; then
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
    return
  fi

  rpm -q "$pkg" >/dev/null 2>&1
}

install_pkg() {
  local pkg="$1"
  local cmd="${2:-$pkg}"

  if pkg_is_installed "$pkg" "$cmd"; then
    log "$pkg already installed, skip." "$green"
    return
  fi

  log "$pkg has not been installed. Installing..." "$yellow"
  case "$PKG_MANAGER" in
    brew)
      brew install "$pkg"
      ;;
    apt)
      sudo apt-get install -y "$pkg"
      ;;
    dnf)
      sudo dnf install -y "$pkg"
      ;;
    yum)
      sudo yum install -y "$pkg"
      ;;
  esac
}

install_cask() {
  local pkg="$1"

  if [[ "$OS" != "macos" ]]; then
    return
  fi

  if brew list --cask "$pkg" >/dev/null 2>&1; then
    log "$pkg already installed, skip." "$green"
    return
  fi

  log "Installing $pkg..." "$yellow"
  brew install --cask "$pkg"
}

ensure_line() {
  local file="$1"
  local line="$2"

  touch "$file"
  grep -qxF "$line" "$file" || echo "$line" >> "$file"
}

replace_in_file() {
  local file="$1"
  local from="$2"
  local to="$3"

  [[ -f "$file" ]] || return

  if [[ "$OS" == "macos" ]]; then
    sed -i '' "s#${from}#${to}#g" "$file"
  else
    sed -i "s#${from}#${to}#g" "$file"
  fi
}

get_ip() {
  if [[ ! -f ~/.ip.txt ]]; then
    install_pkg curl
    log "保存本机 ip 到 ~/.ip.txt" "$yellow"
    curl -s http://ip-api.com/json/ -o ~/.ip.txt
  fi
}

in_china() {
  [[ -f ~/.ip.txt ]] && grep -q "China" ~/.ip.txt
}

refresh_system_packages() {
  if [[ "$OS" != "linux" ]]; then
    return
  fi

  if [[ "$PKG_MANAGER" == "apt" ]] && in_china; then
    log "检测到 IP 位于国内，更新 apt 源为 tuna" "$yellow"
    if [[ ! -f ~/oh-my-tuna.py ]]; then
      cp "$SCRIPT_DIR/data/oh-my-tuna.py" ~/oh-my-tuna.py
    fi
    install_pkg python3
    sudo python3 ~/oh-my-tuna.py --global
  fi

  case "$PKG_MANAGER" in
    apt)
      sudo apt-get update
      sudo apt-get dist-upgrade -y
      sudo apt-get autoremove -y --purge
      ;;
    dnf)
      sudo dnf makecache
      sudo dnf upgrade -y
      sudo dnf autoremove -y || true
      ;;
    yum)
      sudo yum makecache
      sudo yum update -y
      ;;
  esac
}

linux_pkg_name() {
  local logical="$1"

  case "$logical" in
    xauth)
      echo "xauth"
      ;;
    openssh)
      if [[ "$PKG_MANAGER" == "apt" ]]; then
        echo "openssh-client"
      else
        echo "openssh-clients"
      fi
      ;;
    vim_gui)
      if [[ "$PKG_MANAGER" == "apt" ]]; then
        echo "vim-gtk"
      else
        echo "vim-X11"
      fi
      ;;
    pip3)
      if [[ "$PKG_MANAGER" == "apt" ]]; then
        echo "python3-pip"
      else
        echo "python3-pip"
      fi
      ;;
    zh_lang_pack)
      if [[ "$PKG_MANAGER" == "apt" ]]; then
        echo "language-pack-zh-hans"
      else
        echo "glibc-langpack-zh"
      fi
      ;;
    locales)
      if [[ "$PKG_MANAGER" == "apt" ]]; then
        echo "locales"
      else
        echo "glibc-common"
      fi
      ;;
    manpages_zh)
      if [[ "$PKG_MANAGER" == "apt" ]]; then
        echo "manpages-zh"
      else
        echo "man-pages-zh-CN"
      fi
      ;;
    noto_cjk)
      if [[ "$PKG_MANAGER" == "apt" ]]; then
        echo "fonts-noto-cjk"
      elif [[ "$PKG_MANAGER" == "dnf" ]]; then
        echo "google-noto-sans-cjk-ttc-fonts"
      else
        echo "google-noto-cjk-fonts"
      fi
      ;;
    locate)
      if [[ "$PKG_MANAGER" == "apt" ]]; then
        if apt-cache show plocate >/dev/null 2>&1; then
          echo "plocate"
        else
          echo "mlocate"
        fi
      else
        echo "mlocate"
      fi
      ;;
    bat)
      if [[ "$PKG_MANAGER" == "apt" ]]; then
        echo "batcat"
      else
        echo "bat"
      fi
      ;;
    tldr)
      echo "tealdeer"
      ;;
    *)
      echo "$logical"
      ;;
  esac
}

install_ssh_dependencies() {
  if [[ "$OS" == "macos" ]]; then
    install_pkg openssh ssh
    return
  fi

  install_pkg "$(linux_pkg_name openssh)" ssh
  install_pkg "$(linux_pkg_name xauth)"
}

set_ssh() {
  mkdir -p ~/.ssh
  install_ssh_dependencies

  if [[ ! -f ~/.ssh/authorized_keys ]] || ! grep -q "1752862657@qq.com" ~/.ssh/authorized_keys; then
    log "设置 ssh 公钥" "$yellow"
    cat "$SCRIPT_DIR/data/id_rsa.pub" >> ~/.ssh/authorized_keys
  fi

  if [[ ! -f ~/.ssh/config ]]; then
    log "设置 ssh config" "$yellow"
    cp "$SCRIPT_DIR/data/ssh_config" ~/.ssh/config
  fi

  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/authorized_keys ~/.ssh/config 2>/dev/null || true
}

install_zsh() {
  install_pkg zsh

  if [[ "$SHELL" != *"zsh" ]]; then
    log "Changing default shell to zsh" "$yellow"
    chsh -s "$(command -v zsh)"
    if [[ "$OS" == "linux" ]]; then
      sudo chsh -s "$(command -v zsh)" root || true
    fi
  fi

  if [[ ! -d ~/.oh-my-zsh ]]; then
    log "Installing oh-my-zsh" "$yellow"
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [[ ! -d "$zsh_custom/themes/spaceship-prompt" ]]; then
    log "Installing spaceship-prompt" "$yellow"
    git clone https://github.com/denysdovhan/spaceship-prompt.git "$zsh_custom/themes/spaceship-prompt"
  fi
  ln -snf "$zsh_custom/themes/spaceship-prompt/spaceship.zsh-theme" "$zsh_custom/themes/spaceship.zsh-theme"

  if [[ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]]; then
    log "Installing zsh-autosuggestions" "$yellow"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
  fi

  if [[ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]]; then
    log "Installing zsh-syntax-highlighting" "$yellow"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting"
  fi

  if [[ ! -f ~/.zshrc ]]; then
    cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
  fi

  replace_in_file ~/.zshrc 'ZSH_THEME="robbyrussell"' 'ZSH_THEME="spaceship"'
  replace_in_file ~/.zshrc 'plugins=(git)' 'plugins=(git extract emoji z zsh-autosuggestions zsh-syntax-highlighting)'

  ensure_line ~/.zshrc 'bindkey \^U backward-kill-line'
  ensure_line ~/.zshrc 'setopt nonomatch'

  if [[ "$OS" == "macos" ]]; then
    ensure_line ~/.zshrc 'SPACESHIP_USER_SHOW=always'
    ensure_line ~/.zshrc 'SPACESHIP_HOST_SHOW=always'
  fi
}

configure_pyenv_shell() {
  ensure_line ~/.zshrc '# ---- pyenv ----'
  ensure_line ~/.zshrc 'export PYENV_ROOT="$HOME/.pyenv"'
  ensure_line ~/.zshrc 'export PATH="$PYENV_ROOT/bin:$PATH"'
  ensure_line ~/.zshrc 'eval "$(pyenv init -)"'
  ensure_line ~/.zshrc 'eval "$(pyenv virtualenv-init -)"'
}

install_pyenv() {
  if [[ "$OS" == "macos" ]]; then
    install_pkg pyenv
    install_pkg pyenv-virtualenv
    configure_pyenv_shell
    return
  fi

  install_pkg git

  if [[ ! -d "$HOME/.pyenv" ]]; then
    log "Installing pyenv" "$yellow"
    git clone https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
  else
    log "pyenv already installed, skip." "$green"
  fi

  if [[ ! -d "$HOME/.pyenv/plugins/pyenv-virtualenv" ]]; then
    log "Installing pyenv-virtualenv" "$yellow"
    git clone https://github.com/pyenv/pyenv-virtualenv.git "$HOME/.pyenv/plugins/pyenv-virtualenv"
  else
    log "pyenv-virtualenv already installed, skip." "$green"
  fi

  configure_pyenv_shell
}

install_vim() {
  local vim_cmd="vim"

  if [[ "$OS" == "macos" ]]; then
    install_pkg macvim mvim
    vim_cmd="mvim -v"
  else
    install_pkg "$(linux_pkg_name vim_gui)" vim
  fi

  mkdir -p ~/.vim/undo ~/.vim/autoload

  if [[ ! -f ~/.vim/autoload/plug.vim ]]; then
    log "Setting up plug.vim" "$yellow"
    cp "$SCRIPT_DIR/data/plug.vim" ~/.vim/autoload/plug.vim
  fi

  if [[ ! -f ~/.vimrc ]] || ! diff -q ~/.vimrc "$SCRIPT_DIR/data/.vimrc" >/dev/null 2>&1; then
    log "Setting up .vimrc" "$yellow"
    cp "$SCRIPT_DIR/data/.vimrc" ~/.vimrc
    if [[ -t 0 && -t 1 ]]; then
      eval "$vim_cmd -u ~/.vimrc -i NONE -c 'PlugInstall' -c 'qa'"
    else
      log "Skipping PlugInstall in non-interactive mode. Run :PlugInstall inside Vim later." "$magenta"
    fi
  fi
}

configure_macos_cpp_toolchain() {
  if [[ "$OS" != "macos" ]]; then
    return
  fi

  mkdir -p ~/.local/bin
  mkdir -p ~/.config/clangd
  mkdir -p ~/Library/Preferences/clangd

  ensure_line ~/.zshrc 'export PATH="$HOME/.local/bin:$PATH"'
  ensure_line ~/.zshrc 'alias gcc=/opt/homebrew/bin/gcc-15'
  ensure_line ~/.zshrc 'alias g++=/opt/homebrew/bin/g++-15'
  ensure_line ~/.zshrc 'alias cc=/opt/homebrew/bin/gcc-15'
  ensure_line ~/.zshrc 'alias c++=/opt/homebrew/bin/g++-15'
  ensure_line ~/.zshrc 'export CC=/opt/homebrew/bin/gcc-15'
  ensure_line ~/.zshrc 'export CXX=/opt/homebrew/bin/g++-15'

  cat > ~/.local/bin/clangd-gcc <<'EOF'
#!/bin/bash
exec /usr/bin/clangd \
  --query-driver=/opt/homebrew/bin/g++-15,/opt/homebrew/bin/gcc-15 \
  "$@"
EOF
  chmod +x ~/.local/bin/clangd-gcc

  cat > ~/.config/clangd/config.yaml <<'EOF'
CompileFlags:
  Add:
    - -std=gnu++17
    - -nostdinc++
    - -isystem
    - /opt/homebrew/include/c++/15
    - -isystem
    - /opt/homebrew/include/c++/15/aarch64-apple-darwin25
    - -isystem
    - /opt/homebrew/include/c++/15/backward
EOF

  cat > ~/Library/Preferences/clangd/config.yaml <<'EOF'
CompileFlags:
  Add:
    - -std=gnu++17
    - -nostdinc++
    - -isystem
    - /opt/homebrew/include/c++/15
    - -isystem
    - /opt/homebrew/include/c++/15/aarch64-apple-darwin25
    - -isystem
    - /opt/homebrew/include/c++/15/backward
EOF
}

install_macos_cpp_toolchain() {
  if [[ "$OS" != "macos" ]]; then
    return
  fi

  install_pkg gcc g++-15
  configure_macos_cpp_toolchain
  log "Configured macOS C/C++ toolchain to use Homebrew GCC and clangd with GCC headers." "$green"
}

install_git() {
  install_pkg git

  local desired_alias_lg="log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
  local desired_email="1752862657@qq.com"
  local desired_name="buzhibujue"
  local desired_credential_helper="store"

  if [[ "$(git config --global --get alias.lg || true)" == "$desired_alias_lg" ]] &&
    [[ "$(git config --global --get user.email || true)" == "$desired_email" ]] &&
    [[ "$(git config --global --get user.name || true)" == "$desired_name" ]] &&
    [[ "$(git config --global --get credential.helper || true)" == "$desired_credential_helper" ]]; then
    log "git already configured, skip." "$green"
    return
  fi

  log "Setting up git" "$yellow"
  git config --global alias.lg "$desired_alias_lg"
  git config --global user.email "$desired_email"
  git config --global user.name "$desired_name"
  git config --global credential.helper "$desired_credential_helper"
}

config_proxy() {
  if ! in_china; then
    return
  fi

  if [[ "$OS" == "linux" ]]; then
    install_pkg "$(linux_pkg_name pip3)" pip3
  else
    install_pkg python python3
    ensure_line ~/.zshrc 'export PATH="/opt/homebrew/opt/python/libexec/bin:$PATH"'
  fi

  if command -v pip3 >/dev/null 2>&1; then
    pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
  fi
}

install_tldr() {
  if [[ "$OS" == "macos" ]]; then
    install_pkg tlrc tldr
  else
    install_pkg "$(linux_pkg_name tldr)" tldr
  fi

  if ! command -v tldr >/dev/null 2>&1; then
    log "tldr command not found after installation, skip config." "$magenta"
    return
  fi

  mkdir -p ~/.config/tldr
  tldr --gen-config > "$(tldr --config-path)"
  replace_in_file "$(tldr --config-path)" '^languages = \[\]' 'languages = ["zh"]'
}

set_locale_linux() {
  install_pkg "$(linux_pkg_name zh_lang_pack)"
  install_pkg "$(linux_pkg_name locales)" locale-gen
  install_pkg "$(linux_pkg_name manpages_zh)"
  install_pkg "$(linux_pkg_name noto_cjk)"

  if [[ "$PKG_MANAGER" == "apt" ]]; then
    ensure_line ~/.zshrc "alias man='man -M /usr/share/man/zh_CN'"
  fi

  local changed=0

  if [[ "$PKG_MANAGER" == "apt" ]] && ! diff -q /etc/locale.gen "$SCRIPT_DIR/data/locale.gen" >/dev/null 2>&1; then
    log "更换 /etc/locale.gen" "$yellow"
    sudo cp "$SCRIPT_DIR/data/locale.gen" /etc/locale.gen
    sudo locale-gen
    changed=1
  fi

  if [[ "$PKG_MANAGER" == "apt" ]] && ! diff -q /etc/default/locale "$SCRIPT_DIR/data/locale" >/dev/null 2>&1; then
    log "更换 /etc/default/locale" "$yellow"
    sudo cp "$SCRIPT_DIR/data/locale" /etc/default/locale
    changed=1
  fi

  if [[ "$PKG_MANAGER" != "apt" ]]; then
    ensure_line ~/.zshrc 'export LC_ALL=zh_CN.UTF-8'
    ensure_line ~/.zshrc 'export LANG=zh_CN.UTF-8'
  fi

  if [[ "$changed" -eq 1 ]]; then
    log "locale 已更新，建议手动重启系统使配置完全生效。" "$magenta"
  fi
}

set_locale_macos() {
  ensure_line ~/.zshrc 'export LC_ALL=zh_CN.UTF-8'
  ensure_line ~/.zshrc 'export LANG=zh_CN.UTF-8'
}

set_locale() {
  if [[ "$OS" == "macos" ]]; then
    set_locale_macos
  else
    set_locale_linux
  fi
}

install_screen() {
  install_pkg screen
  ensure_line ~/.screenrc 'term screen-256color'
}

install_bat() {
  if [[ "$OS" == "macos" ]]; then
    install_pkg bat
    ensure_line ~/.zshrc 'alias cat=bat'
    return
  fi

  if command -v bat >/dev/null 2>&1; then
    log "bat already installed, skip." "$green"
  else
    local bat_pkg
    bat_pkg="$(linux_pkg_name bat)"
    install_pkg "$bat_pkg"
    if [[ "$bat_pkg" == "batcat" ]]; then
      mkdir -p ~/.local/bin
      ln -snf /usr/bin/batcat ~/.local/bin/bat
    fi
  fi
  ensure_line ~/.zshrc 'alias cat=bat'
}

install_locate() {
  if [[ "$OS" == "macos" ]]; then
    return
  fi

  install_pkg "$(linux_pkg_name locate)" locate
}

install_fonts() {
  if [[ "$OS" != "macos" ]]; then
    return
  fi

  install_cask font-jetbrains-mono-nerd-font
}

install_iterm2() {
  if [[ "$OS" != "macos" ]]; then
    return
  fi

  install_cask iterm2
}

install_iterm2_colorscheme() {
  if [[ "$OS" != "macos" ]]; then
    return
  fi

  local scheme_name="One Half Dark"
  local scheme_file="One%20Half%20Dark.itermcolors"
  local scheme_url="https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/schemes/${scheme_file}"
  local tmp_file
  local iterm_plist="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
  tmp_file="$(mktemp "/tmp/${scheme_name}.itermcolors.XXXXXX")"

  if [[ ! -f "$iterm_plist" ]]; then
    log "iTerm2 preferences plist not found, skip colorscheme import." "$magenta"
    return
  fi

  if /usr/libexec/PlistBuddy -c "Print \"Custom Color Presets:${scheme_name}\"" "$iterm_plist" >/dev/null 2>&1; then
    log "iTerm2 colorscheme ${scheme_name} already imported, skip." "$green"
    return
  fi

  log "Downloading iTerm2 colorscheme ${scheme_name}" "$yellow"
  if curl -fsSL "$scheme_url" -o "$tmp_file"; then
    if ! /usr/libexec/PlistBuddy -c 'Print "Custom Color Presets"' "$iterm_plist" >/dev/null 2>&1; then
      /usr/libexec/PlistBuddy -c 'Add "Custom Color Presets" dict' "$iterm_plist"
    fi

    /usr/libexec/PlistBuddy \
      -c "Add \"Custom Color Presets:${scheme_name}\" dict" \
      -c "Merge \"$tmp_file\" \"Custom Color Presets:${scheme_name}\"" \
      "$iterm_plist"
    rm -f "$tmp_file"
    log "Imported iTerm2 colorscheme ${scheme_name}." "$green"
  else
    rm -f "$tmp_file"
    log "无法下载 iTerm2 colorscheme ${scheme_name}，已跳过，不影响其余安装。" "$magenta"
    log "可稍后手动导入主题，或更新 install.sh 中的下载地址后重试。" "$magenta"
  fi
}

main() {
  detect_platform
  ensure_homebrew
  get_ip
  refresh_system_packages
  set_ssh
  install_macos_cpp_toolchain
  install_vim
  install_git
  install_zsh
  install_pyenv
  config_proxy
  install_screen
  install_locate
  install_bat
  install_tldr
  install_fonts
  install_iterm2
  install_iterm2_colorscheme
  set_locale

  log "All setup complete! Please restart your terminal or run 'source ~/.zshrc'." "$green"
}

main
