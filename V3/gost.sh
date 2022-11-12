#! /bin/bash
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
shell_version="0.9"
ct_new_ver="3.0.0-rc.0" # 保持3.x最新版
gost_conf_path="/etc/gost/config.yaml"
function checknew() {
  checknew=$(gost -V 2>&1 | awk '{print $2}')
  # check_new_ver
  echo "你的gost版本为:""$checknew"""
  echo -n 是否更新\(y/n\)\:
  read checknewnum
  if test $checknewnum = "y"; then
    cp -r /etc/gost /tmp/
    Install_ct
    rm -rf /etc/gost
    mv /tmp/gost /etc/
    systemctl restart gost
  else
    exit 0
  fi
}
function check_sys() {
  if [[ -f /etc/redhat-release ]]; then
    release="centos"
  elif cat /etc/issue | grep -q -E -i "debian"; then
    release="debian"
  elif cat /etc/issue | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  elif cat /proc/version | grep -q -E -i "debian"; then
    release="debian"
  elif cat /proc/version | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  fi
  bit=$(uname -m)
  if test "$bit" != "x86_64"; then
    echo "请输入你的芯片架构，/386/armv5/armv6/armv7/armv8"
    read bit
  else
    bit="amd64v3"
  fi
}
function Installation_dependency() {
  gzip_ver=$(gzip -V)
  if [[ -z ${gzip_ver} ]]; then
    if [[ ${release} == "centos" ]]; then
      yum update
      yum install -y gzip wget jq
    else
      apt-get update
      apt-get install -y gzip wget jq
    fi
  fi
}
function check_root() {
  [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}
function check_new_ver() {
  # deprecated
  ct_new_ver=$(jq -r 'map(select(.prerelease)) | first | .tag_name' <<< $(curl --silent https://api.github.com/repos/go-gost/gost/releases) | sed 's/v//g')
  if [[ -z ${ct_new_ver} ]]; then
    ct_new_ver="3.0.0-rc.0"
    echo -e "${Error} gost 最新版本获取失败，正在下载v${ct_new_ver}版"
  else
    echo -e "${Info} gost 目前最新版本为 ${ct_new_ver}"
  fi
}
function check_file() {
  if test ! -d "/usr/lib/systemd/system/"; then
    mkdir /usr/lib/systemd/system
    chmod -R 777 /usr/lib/systemd/system
  fi
}
function check_nor_file() {
  rm -rf "$(pwd)"/gost
  rm -rf "$(pwd)"/gost.service
  rm -rf "$(pwd)"/config.yaml
  rm -rf /etc/gost
  rm -rf /usr/lib/systemd/system/gost.service
  rm -rf /usr/bin/gost
}
function Install_ct() {
  check_root
  check_nor_file
  Installation_dependency
  check_file
  check_sys
  # check_new_ver
  rm -rf gost-linux-"$bit"-"$ct_new_ver".gz
  wget --no-check-certificate https://github.com/go-gost/gost/releases/download/v"$ct_new_ver"/gost-linux-"$bit"-"$ct_new_ver".gz
  gunzip gost-linux-"$bit"-"$ct_new_ver".gz
  mv gost-linux-"$bit"-"$ct_new_ver" gost
  mv gost /usr/bin/gost
  chmod -R 777 /usr/bin/gost
  wget --no-check-certificate https://raw.githubusercontent.com/Joseph-ink/Multi-EasyGost/master/V3/gost.service && chmod -R 777 gost.service && mv gost.service /usr/lib/systemd/system
  mkdir /etc/gost && wget --no-check-certificate https://raw.githubusercontent.com/Joseph-ink/Multi-EasyGost/master/V3/config.yaml && mv config.yaml /etc/gost && chmod -R 777 /etc/gost


  systemctl enable gost && systemctl restart gost
  echo "------------------------------"
  if test -a /usr/bin/gost -a /usr/lib/systemctl/gost.service -a /etc/gost/config.yaml; then
    echo "gost安装成功"
    rm -rf "$(pwd)"/gost
    rm -rf "$(pwd)"/gost.service
    rm -rf "$(pwd)"/config.yaml
  else
    echo "gost没有安装成功"
    rm -rf "$(pwd)"/gost
    rm -rf "$(pwd)"/gost.service
    rm -rf "$(pwd)"/config.yaml
    rm -rf "$(pwd)"/gost.sh
  fi
}
function Uninstall_ct() {
  rm -rf /usr/bin/gost
  rm -rf /usr/lib/systemd/system/gost.service
  rm -rf /etc/gost
  rm -rf "$(pwd)"/gost.sh
  echo "gost已经成功删除"
}
function Start_ct() {
  systemctl start gost
  echo "已启动"
}
function Stop_ct() {
  systemctl stop gost
  echo "已停止"
}
function Restart_ct() {
  systemctl restart gost
  echo "已重读配置并重启"
}


cron_restart() {
  echo -e "------------------------------------------------------------------"
  echo -e "gost定时重启任务: "
  echo -e "-----------------------------------"
  echo -e "[1] 配置gost定时重启任务"
  echo -e "[2] 删除gost定时重启任务"
  echo -e "-----------------------------------"
  read -p "请选择: " numcron
  if [ "$numcron" == "1" ]; then
    echo -e "------------------------------------------------------------------"
    echo -e "gost定时重启任务类型: "
    echo -e "-----------------------------------"
    echo -e "[1] 每？小时重启"
    echo -e "[2] 每日？点重启"
    echo -e "-----------------------------------"
    read -p "请选择: " numcrontype
    if [ "$numcrontype" == "1" ]; then
      echo -e "-----------------------------------"
      read -p "每？小时重启: " cronhr
      echo "0 0 */$cronhr * * ? * systemctl restart gost" >>/etc/crontab
      echo -e "定时重启设置成功！"
    elif [ "$numcrontype" == "2" ]; then
      echo -e "-----------------------------------"
      read -p "每日？点重启: " cronhr
      echo "0 0 $cronhr * * ? systemctl restart gost" >>/etc/crontab
      echo -e "定时重启设置成功！"
    else
      echo "type error, please try again"
      exit
    fi
  elif [ "$numcron" == "2" ]; then
    sed -i "/gost/d" /etc/crontab
    echo -e "定时重启任务删除完成！"
  else
    echo "type error, please try again"
    exit
  fi
}

update_sh() {
  ol_version=$(curl -L -s --connect-timeout 5 https://raw.githubusercontent.com/Joseph-ink/Multi-EasyGost/master/V3/gost.sh | grep "shell_version=" | head -1 | awk -F '=|"' '{print $3}')
  if [ -n "$ol_version" ]; then
    if [[ "$shell_version" != "$ol_version" ]]; then
      echo -e "存在新版本，是否更新 [Y/N]?"
      read -r update_confirm
      case $update_confirm in
      [yY][eE][sS] | [yY])
        wget -N --no-check-certificate https://raw.githubusercontent.com/Joseph-ink/Multi-EasyGost/master/V3/gost.sh
        echo -e "更新完成"
        exit 0
        ;;
      *) ;;

      esac
    else
      echo -e "                 ${Green_font_prefix}当前版本为最新版本！${Font_color_suffix}"
    fi
  else
    echo -e "                 ${Red_font_prefix}脚本最新版本获取失败，请检查与github的连接！${Font_color_suffix}"
  fi
}

update_sh
echo && echo -e "                 gost 一键安装配置脚本"${Red_font_prefix}[${shell_version}]${Font_color_suffix}"
  ----------- KANIKIG -----------
  特性: (1)本脚本采用systemd及gost配置文件对gost进行管理
        (2)能够在不借助其他工具(如screen)的情况下实现多条转发规则同时生效
        (3)机器reboot后转发不失效
  功能: (1)tcp+udp不加密转发, (2)中转机加密转发, (3)落地机解密对接转发
  帮助文档：https://github.com/KANIKIG/Multi-EasyGost

 ${Green_font_prefix}1.${Font_color_suffix} 安装 gost
 ${Green_font_prefix}2.${Font_color_suffix} 更新 gost
 ${Green_font_prefix}3.${Font_color_suffix} 卸载 gost
————————————
 ${Green_font_prefix}4.${Font_color_suffix} 启动 gost
 ${Green_font_prefix}5.${Font_color_suffix} 停止 gost
 ${Green_font_prefix}6.${Font_color_suffix} 重启 gost
————————————
 ${Green_font_prefix}7.${Font_color_suffix} gost定时重启配置
————————————" && echo
read -e -p " 请输入数字 [1-9]:" num
case "$num" in
1)
  Install_ct
  ;;
2)
  checknew
  ;;
3)
  Uninstall_ct
  ;;
4)
  Start_ct
  ;;
5)
  Stop_ct
  ;;
6)
  Restart_ct
  ;;
7)
  cron_restart
  ;;
*)
  echo "请输入正确数字 [1-7]"
  ;;
esac