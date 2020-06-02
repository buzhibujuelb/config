#!/bin/sh
#author: buzhibujue

config_apt(){
  if [[ "$(curl http://pv.sohu.com/cityjson?ie=utf-8)" == "*CN*" ]]
  then
    echo '检测到 ip 位于国内，更新 apt 源中'
    wget https://tuna.moe/oh-my-tuna/oh-my-tuna.py
    sudo python3 oh-my-tuna.py --global
  fi
}

set_ssh(){
  if test -e "~/.ssh/authorized_keys"
  then
    echo. SSH 已配置。
  else
    echo '设置 ssh 密钥中'
    bash <(curl -Ls git.io/ikey.sh) -g liubei121212 -d
  fi
}

install_chrome(){
  echo 'Installing chrome.'
  sudo wget https://repo.fdzh.org/chrome/google-chrome.list -P /etc/apt/sources.list.d/
  wget -q -O - https://dl.google.com/linux/linux_signing_key.pub  | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install google-chrome-stable -y
}

install_zsh(){
  echo 'Installing zsh.'
  sudo apt-get install zsh -y
  chsh -s /bin/zsh
  if grep "bash" /etc/passwd
  then
    echo "/etc/passwd 文件中仍有 bash 更改中"
    sudo sed -i 's#/bin/bash#/bin/zsh#g' /etc/passwd
  fi
  if test -d "~/.oh-my-zsh"
  then
    echo 已经安装 oh-my-zsh
  else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  if test -d "$ZSH_CUSTOM/themes/spaceship-prompt"
  then
    echo 已经安装 spaceship-prompt
  else
    git clone https://github.com/denysdovhan/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt"
    ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
  fi

  if test -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
  then
    echo 已经安装 zsh-autosuggestions
  else
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
  fi
  ln -sf .zshrc ~/.zshrc
}

install_vim(){
  echo 'Installing zsh.'
  sudo apt-get install vim -y
  ln -sf .vimrc ~/.vimrc
}

main(){
  config_apt

  sudo apt-get update
  sudo apt-get upgrade -y

  set_ssh

  install_zsh

  install_vim

}

main
