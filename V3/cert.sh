#! /bin/bash
function cert() {
  echo -e "-----------------------------------"
  echo -e "[1] ACME一键申请证书"
  echo -e "[2] 手动上传证书"
  echo -e "-----------------------------------"
  echo -e "说明: 仅用于落地机配置，默认使用的gost内置的证书可能带来安全问题，使用自定义证书提高安全性"
  echo -e "     配置后对本机所有tls/wss解密生效，无需再次设置"
  read -p "请选择证书生成方式: " numcert

  if [ "$numcert" == "1" ]; then
    check_sys
    if [[ ${release} == "centos" ]]; then
      yum install -y socat
    else
      apt-get install -y socat
    fi
    read -p "请输入ZeroSSL的账户邮箱(至 zerossl.com 注册即可)：" zeromail
    read -p "请输入解析到本机的域名：" domain
    curl https://get.acme.sh | sh
    "$HOME"/.acme.sh/acme.sh --set-default-ca --server zerossl
    "$HOME"/.acme.sh/acme.sh --register-account -m "${zeromail}" --server zerossl
    echo -e "ACME证书申请程序安装成功"
    echo -e "-----------------------------------"
    echo -e "[1] HTTP申请（需要80端口未占用）"
    echo -e "[2] Cloudflare DNS API 申请（需要输入APIKEY）"
    echo -e "-----------------------------------"
    read -p "请选择证书申请方式: " certmethod
    if [ "certmethod" == "1" ]; then
      echo -e "请确认本机${Red_font_prefix}80${Font_color_suffix}端口未被占用, 否则会申请失败"
      if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force; then
        echo -e "SSL 证书生成成功，默认申请高安全性的ECC证书"
        if [ ! -d "$HOME/gost_cert" ]; then
          mkdir $HOME/gost_cert
        fi
        if "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath $HOME/gost_cert/cert.pem --keypath $HOME/gost_cert/key.pem --ecc --force; then
          echo -e "SSL 证书配置成功，且会自动续签，证书及秘钥位于用户目录下的 ${Red_font_prefix}gost_cert${Font_color_suffix} 目录"
          echo -e "证书目录名与证书文件名请勿更改; 删除 gost_cert 目录后用脚本重启,即自动启用gost内置证书"
          echo -e "-----------------------------------"
        fi
      else
        echo -e "SSL 证书生成失败"
        exit 1
      fi
    else
      read -p "请输入Cloudflare账户邮箱：" cfmail
      read -p "请输入Cloudflare Global API Key：" cfkey
      export CF_Key="${cfkey}"
      export CF_Email="${cfmail}"
      if "$HOME"/.acme.sh/acme.sh --issue --dns dns_cf -d "${domain}" --standalone -k ec-256 --force; then
        echo -e "SSL 证书生成成功，默认申请高安全性的ECC证书"
        if [ ! -d "$HOME/gost_cert" ]; then
          mkdir $HOME/gost_cert
        fi
        if "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath $HOME/gost_cert/cert.pem --keypath $HOME/gost_cert/key.pem --ecc --force; then
          echo -e "SSL 证书配置成功，且会自动续签，证书及秘钥位于用户目录下的 ${Red_font_prefix}gost_cert${Font_color_suffix} 目录"
          echo -e "证书目录名与证书文件名请勿更改; 删除 gost_cert 目录后使用脚本重启, 即重新启用gost内置证书"
          echo -e "-----------------------------------"
        fi
      else
        echo -e "SSL 证书生成失败"
        exit 1
      fi
    fi

  elif [ "$numcert" == "2" ]; then
    if [ ! -d "$HOME/gost_cert" ]; then
      mkdir $HOME/gost_cert
    fi
    echo -e "-----------------------------------"
    echo -e "已在用户目录建立 ${Red_font_prefix}gost_cert${Font_color_suffix} 目录，请将证书文件 cert.pem 与秘钥文件 key.pem 上传到该目录"
    echo -e "证书与秘钥文件名必须与上述一致，目录名也请勿更改"
    echo -e "上传成功后，用脚本重启gost会自动启用，无需再设置; 删除 gost_cert 目录后用脚本重启,即重新启用gost内置证书"
    echo -e "-----------------------------------"
  else
    echo "type error, please try again"
    exit
  fi
}