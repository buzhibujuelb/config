#!/bin/bash
#author: buzhibujue

red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'


get_ip(){
  if ! test -e ~/.ip.txt
  then
    echo 保存本机ip 到 ~/.ip.txt
    curl -s http://ip-api.com/json/ -o ~/.ip.txt
  fi
}

in_china(){
  if grep -q "China" ~/.ip.txt 
  then
    return 0
  else
    return 1
  fi
}

install(){
  if [[ $( dpkg-query --list | grep $1 ) ]]
  then
    echo -e $1 ${green}already install, skip.${none}
  else 
    echo -e $1 ${red}haven\'t install.${none}
    apt-get install $1 -y
  fi
}

config_apt(){
  if ! (grep -q "ustc.edu.cn" $PREFIX/etc/apt/sources.list)
  then
    echo -e "deb https://mirrors.ustc.edu.cn/termux stable main" > $PREFIX/etc/apt/sources.list
  fi
  pkg update
}

set_ssh(){
  if ! test -e ~/.ssh/authorized_keys ||  ! (grep -q "1752862657@qq.com" ~/.ssh/authorized_keys)
  then
    echo -e  ${red}设置 ssh 密钥中${none}
    cat ./data/id_rsa.pub >> ~/.ssh/authorized_keys
  fi
  if ! test -e ~/.ssh/config
  then
    echo -e  ${red}设置 ssh config${none}
    cp ./data/ssh_config ~/.ssh/config
  fi

}

install_chrome(){
  wget https://repo.fdzh.org/chrome/google-chrome.list -P /etc/apt/sources.list.d/
  wget -q -O - https://dl.google.com/linux/linux_signing_key.pub  | apt-key add -
  apt-get update

  install goolge-chrome-stable
}

install_zsh(){
  install zsh
  if [[ $SHELL != "/data/data/com.termux/files/usr/bin/zsh" ]]
  then
    echo -e ${yellow}Changing to zsh${none}
    chsh -s zsh
    chsh -s zsh root
  fi
  if ! test -d ~/.oh-my-zsh
  then
    echo -e ${red}Installing oh-my-zsh${none}
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
  if ! test -d "$ZSH_CUSTOM/themes/spaceship-prompt"
  then
    echo -e ${red}Installing spaceship-prompt${none}
    git clone https://github.com/denysdovhan/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt"
    ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
  fi

  if ! test -d ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
  then
    echo -e ${red}Installing zsh-autosuggestions${none}
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
  fi
  if ! test -e ~/.zshrc; then cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc;fi
  if ! grep -q "spaceship" ~/.zshrc ; then sed -i 's#ZSH_THEME="robbyrussell"#ZSH_THEME="spaceship"#g' ~/.zshrc;fi
  if ! grep -q "extract emoji z zsh-autosuggestions" ~/.zshrc ; then sed -i 's#plugins=(git)#plugins=(git extract emoji z zsh-autosuggestions)#g' ~/.zshrc;fi
  if ! grep -q "bindkey \\\\^U backward-kill-line" ~/.zshrc ; then echo "bindkey \^U backward-kill-line" >> ~/.zshrc;fi
}

install_vim(){
  install vim
  if ! test -e ~/.vim/autoload/plug.vim 
  then
    echo -e ${yellow}Setting up${none} plug.vim
    mkdir -p ~/.vim/autoload
    cp ./data/plug.vim ~/.vim/autoload/plug.vim
  fi
  if ! test -e ~/.vimrc || ! diff -q ~/.vimrc ./data/.vimrc
  then
    echo -e ${yellow}Setting up${none} .vimrc
   cp ./data/.vimrc ~/.vimrc
    vim -es -u ~/.vimrc -i NONE -c "PlugInstall" -c "qa"
  fi
}

install_git(){
  install git
  echo -e ${yellow}Setting up${none} git
  git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
  git config --global user.email "1752862657@qq.com"
  git config --global user.name "buzhibujue"
  git config --global credential.helper store
}

install_screen(){

  install screen
  if ! (grep -q 'term screen-256color' ~/.screenrc )
  then
    echo -e ${yellow}Setting up${none} .screenrc
    echo "term screen-256color" >> ~/.screenrc
  fi

}

main(){
  get_ip
  path=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
  config_apt

  set_ssh

  install_vim

  install_git

  install_zsh

  install screen

  install mlocate

}

main
