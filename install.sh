#!/bin/bash
#author: buzhibujue

get_ip(){
  if ! test -e ~/.ip.txt
  then
    echo 保存本机ip 到 ~/.ip.txt
    curl -s http://ip-api.com/json/ -o ~/.ip.txt
  fi
}

in_china(){
  if grep "China" ~/.ip.txt > /dev/null
  then
    return 0
  else
    return 1
  fi
}

install(){
  if [[ $(command -v $1) ]]
  then
    echo $1 already Install, skip.
  else 
    echo $1 haven\'t install.
    sudo apt-get install $1 -y
  fi
}

config_apt(){
  if in_china
  then
    echo '检测到 ip 位于国内，更新 apt 源为 tuna 中'
    if ! test -e ~/oh-my-tuna.py 
    then
      cp ./data/oh-my-tuna.py ~/oh-my-tuna.py
    fi
    sudo python3 ~/oh-my-tuna.py --global
  fi
  #sudo apt-get update
  #sudo apt-get upgrade -y
}

set_ssh(){
  install xauth
  if ! test -e ~/.ssh/authorized_keys ||  [[ $(grep "1752862657@qq.com" ~/.ssh/authorized_keys) == "" ]]
  then
    echo '设置 ssh 密钥中'
    cat ./data/id_rsa.pub >> ~/.ssh/authorized_keys
  fi
  if ! test -e ~/.ssh/config
  then
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
  if [[ $SHELL != "/bin/zsh" ]]
  then
    echo "changing to zsh"
    chsh -s /bin/zsh
    sudo chsh -s /bin/zsh root
  fi
  if ! test -d ~/.oh-my-zsh
  then
    echo Installing oh-my-zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
  if ! test -d "$ZSH_CUSTOM/themes/spaceship-prompt"
  then
    echo Installing spaceship-prompt
    git clone https://github.com/denysdovhan/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt"
    sudo ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
  fi

  if ! test -d ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
  then
    echo Installing zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
  fi
  if ! test -e ~/.zshrc; then cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc;fi
  if [[ !$( grep "spaceship" ~/.zshrc) ]]; then sed -i 's#ZSH_THEME="robbyrussell"#ZSH_THEME="spaceship"#g' ~/.zshrc;fi
  if [[ !$( grep "extract emoji z zsh-autosuggestions" ~/.zshrc) ]]; then sed -i 's#plugins=(git)#plugins=(git extract emoji z zsh-autosuggestions)#g' ~/.zshrc;fi
}

install_vim(){
  if [[ $(command -v $gvim) ]]
  then
  install vim-gtk
  fi
  if ! test -e ~/.vim/autoload/plug.vim 
  then
    echo Downloading plug.vim
    mkdir -p ~/.vim/autoload
    cp ./data/plug.vim ~/.vim/autoload/plug.vim
  fi
  if ! test -e ~/.vimrc || ! diff ~/.vimrc ./data/.vimrc > /dev/null
  then
   cp ./data/.vimrc ~/.vimrc
    vim -es -u ~/.vimrc -i NONE -c "PlugInstall" -c "qa"
  fi
}

install_git(){
  install git
  git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
  git config --global user.email "1752862657@qq.com"
  git config --global user.name "buzhibujue"
  git config --global credential.helper store
}

config_proxy(){
  if ! in_china ; then return ; fi
  echo 配置 proxy中
  git config --global http.proxy http://127.0.0.1:7890
  git config --global https.proxy http://127.0.0.1:7890

  if ! (grep 'export http_proxy=http://127.0.0.1:7890' ~/.zshrc  > /dev/null)
  then
    echo 更换系统默认代理中
    echo -e "export http_proxy=http://127.0.0.1:7890\nexport https_proxy=http://127.0.0.1:7890" >>  ~/.zshrc
  fi

  if ! test -e /usr/bin/clash
  then
   cp ./data/clash /usr/bin/clash
  fi

  if ! test -e /etc/systemd/system/clash.service
  then
    echo 正在配置 clash 服务
    sudo cp ./data/clash.service /etc/systemd/system/clash.service
    sudo sed -i "s#/home/oj#$HOME#g" /etc/systemd/system/clash.service
    systemctl daemon-reload
  fi

  if ! test -d  ~/.config/clash || ! test -e ~/.config/clash/config.yaml
  then
    cp ./data/clash.yaml ~/.config/clash/config.yaml
  fi

  if [[ $( systemctl is-enabled  clash | grep enabled ) == "" ]]
  then
    echo 正在配置 clash 开机自启动
    sudo systemctl enable clash
    sudo systemctl start clash
  fi

}

set_locale(){
  if grep "en_US" /etc/default/locale > /dev/null
  then
    sudo sed -i "s/en_US/zh_CN/g" /etc/default/locale
    sudo locale-gen zh_CN.UTF-8
  fi
}

main(){
  get_ip
  in_china
  path=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
  config_apt

  set_ssh

  set_locale

  install_vim
  install_git

  install_zsh

  config_proxy
}

main
