#!/bin/bash

function TIME() {
  case $1 in
    r) export Color="\e[31m";;
    g) export Color="\e[32m";;
    b) export Color="\e[34m";;
    y) export Color="\e[33m";;
    z) export Color="\e[35m";;
    l) export Color="\e[36m";;
  esac
echo -e "\e[36m\e[0m ${Color}${2}\e[0m"
}

source /etc/os-release
if [[ ! "${UBUNTU_CODENAME}" =~ (bionic|focal|jammy) ]]; then
  TIME r "请使用Ubuntu 22.04 LTS位系统"
  exit 1
fi

if [[ $EUID -eq 0 ]]; then
  TIME r "警告：请勿使用root用户编译，换一个普通用户吧~~"
  exit 1
fi

export GITHUB_WORKSPACE="/home/$USER"
export HOME_PATH="${GITHUB_WORKSPACE}/openwrt"
export OPERATES_PATH="${GITHUB_WORKSPACE}/operates"
export GITHUB_ENV="${GITHUB_WORKSPACE}/compile"
export BENDI_VERSION="1"
install -m 0755 /dev/null $GITHUB_ENV

Google_Check=$(curl -I -s --connect-timeout 8 google.com -w %{http_code} | tail -n1)
if [ ! "${Google_Check}" == 301 ]; then
  TIME r "提醒：编译之前请自备梯子，编译全程都需要稳定翻墙的梯子~~"
  exit 1
fi
if [[ `sudo grep -c "sudo ALL=(ALL:ALL) NOPASSWD:ALL" /etc/sudoers` -eq '0' ]]; then
  sudo sed -i 's?%sudo.*?%sudo ALL=(ALL:ALL) NOPASSWD:ALL?g' /etc/sudoers
fi

cd $GITHUB_WORKSPACE

function Ben_diskcapacity() {
Cipan_Size="$(df -hT $PWD|awk 'NR==2'|awk '{print $(3)}')"
Cipan_Used="$(df -hT $PWD|awk 'NR==2'|awk '{print $(4)}')"
Cipan_Avail="$(df -hT $PWD|awk 'NR==2'|awk '{print $(5)}' |cut -d 'G' -f1)"
TIME y "磁盘总量为[${Cipan_Size}]，已用[${Cipan_Used}]，可用[${Cipan_Avail}G]"
if [[ "${Cipan_Avail}" -lt "20" ]];then
  TIME r "敬告：可用空间小于[ 20G ]编译容易出错,建议可用空间大于20G,是否继续?"
  read -p " 直接回车退出编译，按[Y/y]回车则继续编译： " KJYN
  case ${KJYN} in
  [Yy]) 
    TIME y  "可用空间太小严重影响编译,请满天神佛保佑您成功吧！"
    sleep 2
  ;;
  *)
    TIME y  "您已取消编译,请清理Ubuntu空间或增加硬盘容量..."
    exit 0
  ;;
  esac
fi
}

function Ben_update() {
if [[ ! -f "/etc/oprelyon" ]]; then
  bash <(curl -fsSL https://github.com/281677160/common/raw/main/custom/ubuntu.sh)
fi
if [[ $? -ne 0 ]];then
  TIME r "依赖安装失败，请检测网络后再次尝试!"
  exit 1
else
  sudo sh -c 'echo openwrt > /etc/oprelyon'
  TIME b "全部依赖安装完毕"
fi
}

function Ben_variable() {
cd ${GITHUB_WORKSPACE}
export FOLDER_NAME="$FOLDER_NAME"
if [[ -f "$OPERATES_PATH/$FOLDER_NAME/settings.ini" ]]; then
  source $OPERATES_PATH/$FOLDER_NAME/settings.ini
fi
export COMPILE_PATH="$OPERATES_PATH/$FOLDER_NAME"
export SOURCE_CODE="${SOURCE_CODE}"
export REPO_BRANCH="${REPO_BRANCH}"
export BUILD_DIY="${COMPILE_PATH}/diy"
export BUILD_FILES="${COMPILE_PATH}/files"
export BUILD_PATCHES="${COMPILE_PATH}/patches"
export BUILD_PARTSH="${COMPILE_PATH}/diy-part.sh"
export BUILD_SETTINGS="${COMPILE_PATH}/settings.ini"
export CONFIG_FILE="${CONFIG_FILE}"
export MYCONFIG_FILE="${COMPILE_PATH}/seed/${CONFIG_FILE}"
curl -fsSL https://github.com/281677160/common/raw/ceshi/custom/first.sh -o first.sh
chmod -R +x first.sh
source first.sh
rm -rf first.sh
source $COMMON_SH && Diy_variable
}

function Ben_xiazai() {
cd ${GITHUB_WORKSPACE}
if [[ ! -d "openwrt" ]]; then
  git clone -b "${REPO_BRANCH}" --single-branch "${REPO_URL}" openwrt
fi
}

function Ben_configuration() {
Menuconfig_Config="true"
cd ${HOME_PATH}
if [[ "${Menuconfig_Config}" == "true" ]]; then
  TIME g "配置机型，插件等..."
  make menuconfig
  if [[ $? -ne 0 ]]; then
    TIME y "SSH工具窗口分辨率太小，无法弹出设置机型或插件的窗口"
    TIME g "请调整SSH工具窗口分辨率后按[Y/y]继续,或者按[N/n]退出编译"
    XUANMA="请输入您的选择"
    while :; do
    read -p " ${XUANMA}：" menu_config
    case ${menu_config} in
    [Yy])
      Ben_configuration
    break
    ;;
    [Nn])
      exit 1
    break
    ;;
    *)
      XUANMA="输入错误,请输入[Y/n]"
    ;;
    esac
    done
  fi
fi
}

function Ben_download() {
TIME y "下载DL文件,请耐心等候..."
cd ${HOME_PATH}
rm -rf ${HOME_PATH}/build_logo/build.log
make -j8 download |& tee ${HOME_PATH}/build_logo/build.log 2>&1
if [[ `grep -c "ERROR" ${HOME_PATH}/build_logo/build.log` -eq '0' ]] || [[ `grep -c "make with -j1 V=s" ${HOME_PATH}/build_logo/build.log` -eq '0' ]]; then
  TIME g "DL文件下载成功"
else
  clear
  echo
  TIME r "下载DL失败，更换节点后再尝试下载？"
  QLMEUN="请更换节点后按[Y/y]回车继续尝试下载DL，或输入[N/n]回车,退出编译"
  while :; do
    read -p " [${QLMEUN}]： " BenDownload
    case ${BenDownload} in
  [Yy])
    Ben_download
  break
  ;;
  [Nn])
    TIME r "退出编译程序!"
    sleep 1
    exit 1
  break
  ;;
  *)
    QLMEUN="请更换节点后按[Y/y]回车继续尝试下载DL，或现在输入[N/n]回车,退出编译"
  ;;
  esac
  done
fi
}



function Ben_menu() {
cd $HOME_PATH
source $COMMON_SH && Diy_menu
}

function Ben_menuconfig() {
cd $HOME_PATH
Ben_configuration
}

function Ben_menu2() {
cd $HOME_PATH
source $COMMON_SH && Diy_menu2
}

function Ben_menu3() {
cd $HOME_PATH
source $COMMON_SH && Diy_menu3
source $GITHUB_ENV
echo "$LINUX_KERNEL"
}

function Ben_menu4() {
cd $HOME_PATH
Ben_download
}

function Diy_main() {
export FOLDER_NAME="Lede"
Ben_diskcapacity
Ben_update
Ben_variable
Ben_xiazai
Ben_menu
Ben_menuconfig
Ben_menu2
Ben_menu3
}

Diy_main
