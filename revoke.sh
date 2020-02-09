#!/bin/bash
#脚本实现对证书的吊销操作，并更新吊销列表
#全局变量
workdir=`pwd`
#吊销模块
function ReVoke()
{
  echo "###################################################################"
  echo `openssl x509 -in $1 -noout -serial -subject`
  read -p "请再次确认证书信息是否无误[Y:确认|N:取消]" rev_confirm
  if [[ "$rev_confirm" == "Y" ||  "$rev_confirm" == "y" ]]; then
    echo $1
    cert_serial=`openssl x509 -in $1 -noout -serial | cut -d '=' -f 2 `
	echo "###################################################################"
	echo "吊销证书$cert_serial"
    openssl ca -config $workdir/root/intca/openssl_intca.cnf -revoke $workdir/root/intca/newcerts/$cert_serial.pem
    openssl ca -config $workdir/root/intca/openssl_intca.cnf -gencrl -out $workdir/root/intca/crl/crl.pem 
    echo "###################################################################"
	echo "以下是最新的CRL信息:"
	echo "###################################################################"
    echo `openssl crl -in $workdir/root/intca/crl/crl.pem -noout -text`
    return 0
  fi
}
#用户交互 
echo "###################################################################"
echo "目前脚本每次只能吊销一个证书"
echo "###################################################################"
read -p "请输入需要吊销的证书CN名称[证书默认都在intca/certs目录下]:"  CertName
crlumber_present=$workdir/root/intca/crlnumber
while [ ! -f $workdir/root/intca/certs/$CertName.crt.pem ]; do
  read -p "证书不存在，请重新输入证书CN:"  CertName
done  
if [ ! -f $crlumber_present ]; then
  echo "###################################################################"  
  echo "crlnumber文件不存在，创建文件"
  echo "01" > $workdir/root/intca/crlnumber
  ReVoke $workdir/root/intca/certs/$CertName.crt.pem
else
  ReVoke $workdir/root/intca/certs/$CertName.crt.pem
fi
