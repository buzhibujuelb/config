#!/bin/bash
#author: buzhibujue
set -euo pipefail

red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'


get_ip(){
  if ! test -e ~/.ip.txt
  then
    install curl
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
    sudo apt-get install $1 -y
  fi
}

config_apt(){
  if in_china
  then
    echo -e ${yellow}'检测到 ip 位于国内，更新 apt 源为 tuna 中'${none}
    if ! test -e ~/oh-my-tuna.py 
    then
      cp ./data/oh-my-tuna.py ~/oh-my-tuna.py
    fi
    install python3
    sudo python3 ~/oh-my-tuna.py --global
  fi
  sudo apt-get update
  sudo apt-get dist-upgrade -y
  sudo apt autoremove -y
  sudo apt autopurge -y
}

set_ssh(){
  mkdir -p ~/.ssh
  install xauth
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
  sudo wget https://repo.fdzh.org/chrome/google-chrome.list -P /etc/apt/sources.list.d/
  wget -q -O - https://dl.google.com/linux/linux_signing_key.pub  | sudo apt-key add -
  sudo apt-get update

  install goolge-chrome-stable
}

install_zsh(){
  install zsh
  if [[ $SHELL != *"zsh" ]]
  then
    echo -e ${yellow}Changing to zsh${none}
    chsh -s /bin/zsh
    sudo chsh -s /bin/zsh root
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
    sudo ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
  fi


  if ! test -d ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
  then
    echo -e ${red}Installing zsh-autosuggestions${none}
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
  fi


  if ! test -d ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
  then
    echo -e ${red}Installing zsh-syntax-highlighting${none}
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
  fi

  if ! test -e ~/.zshrc; then cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc;fi
  if ! grep -q "spaceship" ~/.zshrc ; then sed -i 's#ZSH_THEME="robbyrussell"#ZSH_THEME="spaceship"#g' ~/.zshrc;fi
  if ! grep -q "extract emoji z zsh-autosuggestions zsh-syntax-highlighting" ~/.zshrc ; then sed -i 's#plugins=(git)#plugins=(git extract emoji z zsh-autosuggestions zsh-syntax-highlighting)#g' ~/.zshrc;fi
  if ! grep -q "bindkey \\\\^U backward-kill-line" ~/.zshrc ; then echo "bindkey \^U backward-kill-line" >> ~/.zshrc;fi
  if ! grep -q "setopt nonomatch" ~/.zshrc ; then echo "setopt nonomatch" >> ~/.zshrc;fi
}

install_vim(){
  install vim-gtk
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

config_proxy(){
:<<!
  if ! in_china ; then return ; fi
  echo -e ${yellow}配置 proxy中${none}
  git config --global http.proxy http://127.0.0.1:7890
  git config --global https.proxy http://127.0.0.1:7890

  if ! (grep -q 'export http_proxy=http://127.0.0.1:7890' ~/.zshrc )
  then
    echo -e ${yellow}更换系统默认代理中${none}
    echo -e "export http_proxy=http://127.0.0.1:7890\nexport https_proxy=http://127.0.0.1:7890" >>  ~/.zshrc
  fi
  if ! test -e /usr/bin/clash
  then
   sudo cp ./data/clash /usr/bin/clash
  fi

  if ! test -e /etc/systemd/system/clash.service
  then
    echo -e ${yellow}正在配置 clash 服务${none}
    sudo cp ./data/clash.service /etc/systemd/system/clash.service
    sudo sed -i "s#/home/oj#$HOME#g" /etc/systemd/system/clash.service
    systemctl daemon-reload
  fi

  if ! test -d  ~/.config/clash || ! test -e ~/.config/clash/config.yaml
  then
    echo -e ${yellow}正在配置 clash.yaml${none}
    cp ./data/clash.yaml ~/.config/clash/config.yaml
  fi

  if [[ $( systemctl is-enabled  clash | grep enabled ) == "" ]]
  then
    echo -e ${yellow}正在配置 clash 开机自启动${none}
    sudo systemctl enable clash
    sudo systemctl start clash
  fi
!
  install python3-pip

  pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
}

set_locale(){
  install language-pack-zh-hans
  install locales
  install manpages-zh
  if ! ( grep -q "alias man='man -M /usr/share/man/zh_CN'" ~/.zshrc  )
  then
    echo -e ${yellow}正在配置 alias manpages-zh ${none}
    echo -e "alias man='man -M /usr/share/man/zh_CN'" >>  ~/.zshrc
  fi

  flag=false
  if ! diff -q /etc/locale.gen ./data/locale.gen
  then
    echo -e ${red}更换 locale.gen 中${none}
    sudo cp ./data/locale.gen /etc/locale.gen
    sudo locale-gen
    flag=true
  fi
  if ! diff -q /etc/default/locale ./data/locale
  then
    echo -e ${red}更换 locale 中${none}
    sudo cp ./data/locale /etc/default/locale
    flag=true
  fi
  if $flag
  then
    echo -e ${red}即将重启${none}
    sudo reboot
  fi
}

install_screen(){

  install screen
  if ! (grep -q 'term screen-256color' ~/.screenrc )
  then
    echo -e ${yellow}Setting up${none} .screenrc
    echo "term screen-256color" >> ~/.screenrc
  fi

}

install_bat(){
  if [[ ! $(which bat) ]]
  then
    install bat
    mkdir -p ~/.local/bin
    ln -s /usr/bin/batcat ~/.local/bin/bat

  fi
  if ! ( grep -q "alias cat=batcat" ~/.zshrc  )
  then
    echo "alias cat=batcat" >> ~/.zshrc
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

  config_proxy

  install screen

  install locate

  install_bat

  set_locale

}

main
