#!/bin/bash
#Author: Chan
#Note: 脚本在已有证书工作目录根目录执行，可以快速创建用户证书及服务器证书。
workdir=`pwd`
#检查工作目录是否已经存在,如果存在，则退出
root_ca=$workdir/root/ca/certs/ca.root.crt.pem
int_ca=$workdir/root/intca/certs/ca.intca.crt.pem
crt_cnf=$workdir/root/intca/openssl_csr_san.cnf
if [[ ! -f "$root_ca" || ! -f "$int_ca" || ! -f "$crt_cnf" ]]; then
  echo "提示：中间证书文件及配置文件不存在，退出脚本。请检查工作目录是否完整"
  exit 1
fi
#创建CSR
echo "##########################################################"
echo "原则上不需要修改Subject C/O/L等参数，只需要提供CN即可"
echo "##########################################################"
echo "如果是服务器使用，CN和DNS按照FQDN方式输入,DNS可使用通配符"
echo "##########################################################"
echo "如果是用户使用，CN按照用户名String方式输入"
echo "##########################################################"
read -p "需要生成用户证书还是服务器证书？[1:用户|2:服务器]:" cert_type
loop=0
while [ $loop -eq 0 ]; do
  if [ $cert_type -eq "1" ]; then
    echo "######################################################"
    echo "现在，我们将生成用户证书"
	echo "######################################################"
    read -p "请输入CN用户名:" cn_username
	echo "DNS.1 = $cn_username" >> $workdir/root/intca/openssl_csr_san.cnf
	echo "######################################################"
	echo "Step1.创建用户私钥文件并生成CSR"
	echo "######################################################"
    openssl req -out $workdir/root/intca/csr/$cn_username.csr.pem -newkey rsa:2048 -nodes -keyout $workdir/root/intca/private/$cn_username.key.pem -config $workdir/root/intca/openssl_csr_san.cnf
    echo "######################################################"
	echo "Step2.使用中间证书签发用户CSR"
	echo "######################################################"
	openssl ca -config $workdir/root/intca/openssl_intca.cnf -extensions usr_cert -days 365 -notext -md sha512 -in $workdir/root/intca/csr/$cn_username.csr.pem -out $workdir/root/intca/certs/$cn_username.crt.pem
    echo "######################################################"
	echo "Step3.生成PKCS12格式证书文件"   
	echo "######################################################"
	cat $workdir/root/intca/private/$cn_username.key.pem  $workdir/root/intca/certs/$cn_username.crt.pem > $workdir/root/intca/pkcs12/$cn_username.txt
	openssl pkcs12 -export -in $workdir/root/intca/pkcs12/$cn_username.txt -out $workdir/root/intca/pkcs12/$cn_username.p12
	echo "######################################################"
	echo "Step4.清除配置中的临时信息"  
	echo "######################################################"
	sed -i '/DNS/d' $workdir/root/intca/openssl_csr_san.cnf
	echo "######################################################"
	echo "证书在目录$workdir/root/intca/certs/$cn_username.crt.pem"
	echo "######################################################"
	echo "私钥在目录$workdir/root/intca/private/$cn_username.key.pem"
    echo "######################################################"
	echo "PKCS12格式证书在目录$workdir/root/intca/pkcs12/$cn_username.p12"
    loop=1
  elif [ $cert_type -eq "2" ]; then
    echo "######################################################"
    echo "现在我们将生成服务器证书"
	echo "######################################################"
	read -p "请输入服务器FQDN（建议）或IP地址:" cn_servername
	declare -i dns_count=0
	san_loop=0
	echo "######################################################"
	echo "接下来请留意是否需要为服务器证书添加可选名称(域名/IP/通配符)"
	while [ $san_loop -eq 0 ]; do
	  echo "######################################################"
	  read -p "是否需要添加可选DNS名称？[Y/N]:" add_dns
	  if [[ "$add_dns" == "Y" || "$add_dns" == "y" ]]; then
	    dns_count=$(( dns_count+1 ))
		read -p "请输入证书可选DNS名称:" san_dns
	    echo "DNS.$dns_count = $san_dns" >> $workdir/root/intca/openssl_csr_san.cnf
	  else
	    san_loop=1
	  fi
	done
	echo "######################################################"
	echo "Step1.生成服务器私钥以及CSR文件"
	echo "######################################################"
    openssl req -out $workdir/root/intca/csr/$cn_servername.csr.pem -newkey rsa:2048 -nodes -keyout $workdir/root/intca/private/$cn_servername.key.pem -config $workdir/root/intca/openssl_csr_san.cnf
    echo "######################################################"
	echo "Stap2.使用中间证书签发服务器CSR"
	echo "######################################################"
	openssl ca -config $workdir/root/intca/openssl_intca.cnf -extensions server_cert -days 365 -notext -md sha512 -in $workdir/root/intca/csr/$cn_servername.csr.pem -out $workdir/root/intca/certs/$cn_servername.crt.pem
    echo "######################################################"
	echo "清理配置文件中的临时信息"
	echo "######################################################"
	sed -i '/DNS/d' $workdir/root/intca/openssl_csr_san.cnf
    echo "######################################################"
    echo "证书在目录:$workdir/root/intca/certs/$cn_servername.crt.pem"
	echo "######################################################"
	echo "私钥在目录:$workdir/root/intca/private/$cn_servername.key.pem"
	echo "######################################################"
    loop=1
  else
    read -p "需要生成用户证书还是服务器证书？[1:用户|2:服务器]:" cert_type
    loop=0
  fi
done