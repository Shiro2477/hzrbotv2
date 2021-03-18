#!/bin/bash
#created : 

# initialisasi var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0'`;
MYIP2="s/xxxxxxxxx/$MYIP/g";

# detail nama perusahaan
country=ID
state=Takengon
locality=Aceh Tengah
organization=hzrossh
organizationalunit=HzroSSH
commonname=hzrossh.site
email=admin@hzrossh.site

# go to root
cd

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# set time GMT +7 jakarta
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
/etc/init.d/ssh restart

# Edit file /etc/systemd/system/rc-local.service
cat > /etc/systemd/system/rc-local.service <<-END
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END

# nano /etc/rc.local
cat > /etc/rc.local <<-END
#!/bin/sh -e
# rc.local
# By default this script does nothing.
exit 0
END

# Ubah izin akses
chmod +x /etc/rc.local

# enable rc local
systemctl enable rc-local
systemctl start rc-local.service

echo "=================  install neofetch  ===================="
echo "========================================================="
# install neofetch
apt-get update -y
apt-get -y install gcc
apt-get -y install make
apt-get -y install cmake
apt-get -y install git
apt-get -y install screen
apt-get -y install unzip
apt-get -y install curl
git clone https://github.com/dylanaraps/neofetch
cd neofetch
make install
make PREFIX=/usr/local install
make PREFIX=/boot/home/config/non-packaged install
make -i install
apt-get -y install neofetch
cd
echo "clear" >> .bashrc
echo "neofetch" >> .bashrc

# instal php5.6 ubuntu 16.04 64bit
apt-get -y update

# set repo webmin
#sh -c 'echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list'
#wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -

# setting port ssh
cd
sed -i '/Port 22/a Port 143' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
/etc/init.d/ssh restart

echo "================  install Dropbear ======================"
echo "========================================================="

# install dropbear
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=180/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 110 "/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
/etc/init.d/ssh restart
/etc/init.d/dropbear restart

echo "=================  install Squid3  ======================"
echo "========================================================="

# setting dan install vnstat debian 9 64bit
apt-get -y install vnstat
systemctl start vnstat
systemctl enable vnstat
chkconfig vnstat on
chown -R vnstat:vnstat /var/lib/vnstat

# install squid3
cd
apt-get -y install squid3
wget -O /etc/squid/squid.conf "https://auto.hzrossh.com/squid3.conf"
sed -i $MYIP2 /etc/squid/squid.conf;
/etc/init.d/squid restart

echo "=================  install Webmin  ======================"
echo "========================================================="

# install webmin
cd
wget http://prdownloads.sourceforge.net/webadmin/webmin_1.910_all.deb
dpkg --install webmin_1.910_all.deb;
apt-get -y -f install;
sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
rm -f webmin_1.910_all.deb
/etc/init.d/webmin restart

echo "=================  install Lolcat  ======================"
echo "========================================================="

apt-get -y install ruby
gem install lolcat

echo "=================  install stunnel  ====================="
echo "========================================================="

# install stunnel
apt-get install stunnel4 -y
cat > /etc/stunnel/stunnel.conf <<-END
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
[dropbear]
accept = 222
connect = 127.0.0.1:22
[dropbear]
accept = 442
connect = 127.0.0.1:180
[dropbear]
accept = 777
connect = 127.0.0.1:110

END

echo "=================  membuat Sertifikat OpenSSL ======================"
echo "========================================================="
#membuat sertifikat
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

# konfigurasi stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
/etc/init.d/stunnel4 restart

# common password debian 
wget -O /etc/pam.d/common-password "https://auto.hzrossh.com/common-password-deb9"
chmod +x /etc/pam.d/common-password

#instal sslh
cd
apt-get -y install sslh

#configurasi sslh
wget -O /etc/default/sslh "https://auto.hzrossh.com/sslh-conf"
service sslh restart

echo "================= Install PPTP  ======================"
apt-get -y install pptpd
cat > /etc/ppp/pptpd-options <<END
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
ms-dns 8.8.8.8
ms-dns 8.8.4.4
proxyarp
nodefaultroute
lock
nobsdcomp
END
echo "option /etc/ppp/pptpd-options" > /etc/pptpd.conf
echo "logwtmp" >> /etc/pptpd.conf
echo "localip 10.1.0.1" >> /etc/pptpd.conf
echo "remoteip 10.1.0.5-100" >> /etc/pptpd.conf
cat >> /etc/ppp/ip-up <<END
ifconfig ppp0 mtu 1400
END
mkdir /var/lib/queenssh
/etc/init.d/pptpd restart

echo "=================  Install badVPn (VC and Game) ======================"
echo "========================================================="

# buat directory badvpn

echo "================= Disable badVPN V 1  ======================"
#cd /usr/bin
#mkdir build
#cd /usr/bin/build
#wget https://github.com/idtunnel/sshtunnel/raw/main/debian9/badvpn/badvpn-update.zip
#unzip badvpn-update
#cmake -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_TUN2SOCKS=1 -DBUILD_UDPGW=1
#make install
#make -i install

# aut start badvpn
#sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 > /dev/null &' /etc/rc.local
#screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 > /dev/null &
cd
#cd /usr/bin/build

#sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 > /dev/null &' /etc/rc.local#
#screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 > /dev/null &
#auto badvpn

# set permition rc.local badvpn
#chmod +x /usr/local/bin/badvpn-udpgw
#chmod +x /usr/local/share/man/man7/badvpn.7
#chmod +x /usr/local/bin/badvpn-tun2socks
#chmod +x /usr/local/share/man/man8/badvpn-tun2socks.8
#chmod +x /etc/rc.local
#chmod +x /usr/bin/build


echo "================= Auto Installer Disable badVPN V 2  ======================"
#wget https://raw.githubusercontent.com/idtunnel/UDPGW-SSH/main/badudp2.sh
#chmod +x badudp2.sh
#bash badudp2.sh

echo "================= Auto Installer Disable badVPN V 3  ======================"
# buat directory badvpn
cd /usr/bin
mkdir build
cd build
wget https://github.com/ambrop72/badvpn/archive/1.999.130.tar.gz
tar xvzf 1.999.130.tar.gz
cd badvpn-1.999.130
cmake -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_TUN2SOCKS=1 -DBUILD_UDPGW=1
make install
make -i install

# auto start badvpn single port
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 1000 --max-connections-for-client 10' /etc/rc.local
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500 --max-connections-for-client 20 &
cd

# auto start badvpn second port
#cd /usr/bin/build/badvpn-1.999.130
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10' /etc/rc.local
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500 --max-connections-for-client 20 &
cd

# auto start badvpn second port
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7400 --max-clients 1000 --max-connections-for-client 10' /etc/rc.local
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7400 --max-clients 500 --max-connections-for-client 20 &
cd

# permition
chmod +x /usr/local/bin/badvpn-udpgw
chmod +x /usr/local/share/man/man7/badvpn.7
chmod +x /usr/local/bin/badvpn-tun2socks
chmod +x /usr/local/share/man/man8/badvpn-tun2socks.8
chmod +x /usr/bin/build
chmod +x /etc/rc.local

# Custom Banner SSH
wget -O /etc/issue.net "https://auto.hzrossh.com/issue.net"
chmod +x /etc/issue.net

echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
echo "DROPBEAR_BANNER="/etc/issue.net"" >> /etc/default/dropbear

# install fail2ban
apt-get -y install fail2ban
service fail2ban restart

# Instal DDOS Flate
if [ -d '/usr/local/ddos' ]; then
	echo; echo; echo "Please un-install the previous version first"
	exit 0
else
	mkdir /usr/local/ddos
fi
clear
echo; echo 'Installing DOS-Deflate 0.6'; echo
echo; echo -n 'Downloading source files...'
wget -q -O /usr/local/ddos/ddos.conf http://www.inetbase.com/scripts/ddos/ddos.conf
echo -n '.'
wget -q -O /usr/local/ddos/LICENSE http://www.inetbase.com/scripts/ddos/LICENSE
echo -n '.'
wget -q -O /usr/local/ddos/ignore.ip.list http://www.inetbase.com/scripts/ddos/ignore.ip.list
echo -n '.'
wget -q -O /usr/local/ddos/ddos.sh http://www.inetbase.com/scripts/ddos/ddos.sh
chmod 0755 /usr/local/ddos/ddos.sh
cp -s /usr/local/ddos/ddos.sh /usr/local/sbin/ddos
echo '...done'
echo; echo -n 'Creating cron to run script every minute.....(Default setting)'
/usr/local/ddos/ddos.sh --cron > /dev/null 2>&1
echo '.....done'
echo; echo 'Installation has completed.'
echo 'Config file is at /usr/local/ddos/ddos.conf'
echo 'Please send in your comments and/or suggestions to zaf@vsnl.com'

# download script
cd /usr/bin
wget -O menu "https://auto.hzrossh.com/menu.sh"
wget -O usernew "https://auto.hzrossh.com/usernew.sh"
wget -O trial "https://auto.hzrossh.com/trial.sh"
wget -O hapus "https://auto.hzrossh.com/hapus.sh"
wget -O cek "https://auto.hzrossh.com/user-login.sh"
wget -O member "https://auto.hzrossh.com/user-list.sh"
wget -O jurus69 "https://auto.hzrossh.com/restart.sh"
wget -O speedtest "https://auto.hzrossh.com/speedtest_cli.py"
wget -O info "https://auto.hzrossh.com/info.sh"
wget -O about "https://auto.hzrossh.com/about.sh"
wget -O delete "https://auto.hzrossh.com/delete.sh"
wget -O renew "https://auto.hzrossh.com/renew"
wget -O pass "https://auto.hzrossh.com/cekpass"

wget -O pptp "https://auto.hzrossh.com/add-pptp.sh"
wget -O delete-pptp "https://auto.hzrossh.com/delete-pptp.sh"
wget -O alluser-pptp "https://auto.hzrossh.com/alluser-pptp.py"
wget -O login-pptp "https://auto.hzrossh.com/login-pptp.sh"
wget -O expire-pptp "https://auto.hzrossh.com/expire-pptp.sh"
wget -O detail-pptp "https://auto.hzrossh.com/detail-pptp.sh"

echo "0 0 * * * root /usr/bin/expire-pptp" > /etc/cron.d/expire-pptp
echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/reboot

chmod +x menu
chmod +x usernew
chmod +x pptp
chmod +x delete-pptp
chmod +x alluser-pptp
chmod +x login-pptp
chmod +x expire-pptp
chmod +x detail-pptp
chmod +x trial
chmod +x hapus
chmod +x cek
chmod +x member
chmod +x jurus69
chmod +x speedtest
chmod +x info
chmod +x about
chmod +x delete
chmod +x renew
chmod +x pass

cd
echo "================  install OPENVPN ======================"
echo "========================================================="
#install openvpn debian 9 ( openvpn port 1194 dan 443 )
#wget https://auto.hzrossh.com/openvpn.sh && chmod +x openvpn.sh && bash openvpn.sh

# finishing
cd
chown -R www-data:www-data /home/vps/public_html
/etc/init.d/ssh restart
/etc/init.d/dropbear restart
/etc/init.d/stunnel4 restart
service squid restart
service pptpd restart
/etc/init.d/nginx restart
/etc/init.d/openvpn restart
cd
# auto Delete Acount SSH Expired
#wget -O /usr/local/bin/userdelexpired "https://www.dropbox.com/s/cwe64ztqk8w622u/userdelexpired?dl=1" && chmod +x /usr/local/bin/userdelexpired

rm -rf ~/.bash_history && history -c
echo "unset HISTFILE" >> /etc/profile

# info
clear
echo "Autoscript Include:" | tee log-install.txt
echo "===========================================" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Service"  | tee -a log-install.txt
echo "-------"  | tee -a log-install.txt
echo "OpenSSH   : 22,143"  | tee -a log-install.txt
echo "Dropbear  : 180,110"  | tee -a log-install.txt
echo "SSL       : 442,443"  | tee -a log-install.txt
echo "Squid3    : 80,8080,3128 (limit to IP SSH)"  | tee -a log-install.txt
echo "badvpn    : badvpn-udpgw port 7300"  | tee -a log-install.txt
echo "nginx     : 81"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Script"  | tee -a log-install.txt
echo "------"  | tee -a log-install.txt
echo "menu      : Menampilkan daftar perintah yang tersedia"  | tee -a log-install.txt
echo "usernew   : Membuat Akun SSH"  | tee -a log-install.txt
echo "trial     : Membuat Akun Trial"  | tee -a log-install.txt
echo "hapus     : Menghapus Akun SSH"  | tee -a log-install.txt
echo "cek       : Cek User Login"  | tee -a log-install.txt
echo "member    : Cek Member SSH"  | tee -a log-install.txt
echo "jurus69   : Restart Service dropbear, squid3, stunnel4, vpn, ssh)"  | tee -a log-install.txt
echo "reboot    : Reboot VPS"  | tee -a log-install.txt
echo "speedtest : Speedtest VPS"  | tee -a log-install.txt
echo "info      : Menampilkan Informasi Sistem"  | tee -a log-install.txt
echo "delete    : auto Delete user expired"  | tee -a log-install.txt
echo "about     : Informasi tentang script auto install"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt

echo "Fitur lain"  | tee -a log-install.txt
echo "----------"  | tee -a log-install.txt
echo "Timezone  : Asia/Jakarta (GMT +7)"  | tee -a log-install.txt
echo "IPv6      : [off]"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Modified by hidessh"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Log Instalasi --> /root/log-install.txt"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "VPS AUTO REBOOT TIAP JAM 12 MALAM"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "==========================================="  | tee -a log-install.txt

rm -f /root/openssh.sh


#echo "==================== Restart Service ===================="
#echo "========================================================="
#/etc/init.d/ssh restart
#/etc/init.d/dropbear restart
#/etc/init.d/stunnel4 restart
#/etc/init.d/squid restart
#/etc/init.d/nginx restart
#/etc/init.d/php5.6-fpm restart
#/etc/init.d/openvpn restart

# Delete script
#rm -f /root/openvpn.sh
