
#!/bin/bash
#
# Original script by fornesia, rzengineer and fawzya 
# Mod by Wangzki
# 
# ==================================================

MYIP=$(wget -qO- ipv4.icanhazip.com);

# initialisasi var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";

#detail nama perusahaan
country=ID
state=Manila
locality=Manila
organization=WANG
organizationalunit=IT
commonname=wang@wang.com
email=wang@wang.com

# go to root
cd

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# install wget and curl
apt-get update;apt-get -y install wget curl;

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Manila /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service ssh restart

# set repo
cat > /etc/apt/sources.list <<END2
deb http://security.debian.org/ jessie/updates main contrib non-free
deb-src http://security.debian.org/ jessie/updates main contrib non-free
deb http://http.us.debian.org/debian jessie main contrib non-free
deb http://packages.dotdeb.org jessie all
deb-src http://packages.dotdeb.org jessie all
END2
wget "http://www.dotdeb.org/dotdeb.gpg"
cat dotdeb.gpg | apt-key add -;rm dotdeb.gpg

sh -c 'echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list'
wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -

# update
apt-get update; apt-get -y upgrade;

# install webserver
apt-get -y install nginx

# install essential package
apt-get -y install nano iptables dnsutils openvpn screen whois ngrep unzip unrar

echo 'echo -e "welcome to the server $HOSTNAME" | lolcat' >> .bashrc
echo 'echo -e "Script mod by Wangzki"' >> .bashrc
echo 'echo -e "Type menu to display a list of commands"' >> .bashrc
echo 'echo -e ""' >> .bashrc

# install webserver
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/wangzki03/VPSauto/master/nginx.conf"
mkdir -p /home/vps/public_html
echo "<pre>Setup by Wangzki</pre>" > /home/vps/public_html/index.html
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/wangzki03/VPSauto/master/vps.conf"
service nginx restart

# install openvpn
wget -O /etc/openvpn/openvpn.tar "https://raw.githubusercontent.com/wangzki03/VPSauto/master/openvpn-debian.tar"
cd /etc/openvpn/
tar xf openvpn.tar
wget -O /etc/openvpn/1194.conf "https://raw.githubusercontent.com/wangzki03/VPSauto/master/1194.conf"
service openvpn restart
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
iptables -t nat -I POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE
iptables-save > /etc/iptables_yg_baru_dibikin.conf
wget -O /etc/network/if-up.d/iptables "https://raw.githubusercontent.com/wangzki03/VPSauto/master/iptables"
chmod +x /etc/network/if-up.d/iptables
service openvpn restart

# konfigurasi openvpn
cd /etc/openvpn/
wget -O /etc/openvpn/client.ovpn "https://raw.githubusercontent.com/wangzki03/VPSauto/master/client-1194.conf"
sed -i $MYIP2 /etc/openvpn/client.ovpn;
cp client.ovpn /home/vps/public_html/

# install badvpn
cd
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/wangzki03/VPSauto/master/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/wangzki03/VPSauto/master/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

# setting port ssh
cd
sed -i 's/Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 444' /etc/ssh/sshd_config
service ssh restart

# install dropbear
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 109"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
service ssh restart
service dropbear restart

# install squid3
cd
apt-get -y install squid3
wget -O /etc/squid3/squid.conf "https://raw.githubusercontent.com/wangzki03/VPSauto/master/squid3.conf"
sed -i $MYIP2 /etc/squid3/squid.conf;
service squid3 restart

# install webmin
cd
apt-get -y install webmin
sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
service webmin restart

# install stunnel
apt-get install stunnel4 -y
cat > /etc/stunnel/stunnel.conf <<-END
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1


[dropbear]
accept = 443
connect = 127.0.0.1:143 

END

#membuat sertifikat
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

#konfigurasi stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
/etc/init.d/stunnel4 restart

# teks berwarna
apt-get -y install ruby
gem install lolcat

# install fail2banapt-get -y install fail2ban;
service fail2ban restart 

# install ddos deflate
cd
apt-get -y install dnsutils dsniff
wget https://raw.githubusercontent.com/wangzki03/VPSauto/master/ddos-deflate-master.zip 
unzip ddos-deflate-master.zip
cd ddos-deflate-master
./install.sh
rm -rf /root/ddos-deflate-master.zip 

# bannerrm /etc/issue.net
wget -O /etc/issue.net "https://raw.githubusercontent.com/wangzki03/VPSauto/master/issue.net"
sed -i 's@#Banner@Banner@g' /etc/ssh/sshd_config
sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/issue.net"@g' /etc/default/dropbear
service ssh restart
service dropbear restart

# download script
cd /usr/bin
wget -O menu "https://raw.githubusercontent.com/wangzki03/VPSauto/master/menu.sh"
wget -O usernew "https://raw.githubusercontent.com/wangzki03/VPSauto/master/usernew.sh"
wget -O banner "https://raw.githubusercontent.com/wangzki03/VPSauto/master/servermsg.sh"
wget -O delete "https://raw.githubusercontent.com/wangzki03/VPSauto/master/hapus.sh"
wget -O check "https://raw.githubusercontent.com/wangzki03/VPSauto/master/user-login.sh"
wget -O member "https://raw.githubusercontent.com/wangzki03/VPSauto/master/user-list.sh"
wget -O restart "https://raw.githubusercontent.com/wangzki03/VPSauto/master/resvis.sh"
wget -O speedtest "https://raw.githubusercontent.com/wangzki03/VPSauto/master/speedtest_cli.py"
wget -O info "https://raw.githubusercontent.com/wangzki03/VPSauto/master/info.sh"
wget -O about "https://raw.githubusercontent.com/wangzki03/VPSauto/master/about.sh"

echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/reboot

chmod +x menu
chmod +x usernew
chmod +x banner
chmod +x delete
chmod +x check
chmod +x member
chmod +x restart
chmod +x speedtest
chmod +x info
chmod +x about

# finishing
cd
chown -R www-data:www-data /home/vps/public_html
service nginx start
service openvpn restart
service cron restart
service ssh restart
service dropbear restart
service squid3 restart
service webmin restart
rm -rf ~/.bash_history && history -c
echo "unset HISTFILE" >> /etc/profile

# install neofetch
echo "deb http://dl.bintray.com/dawidd6/neofetch jessie main" | tee -a /etc/apt/sources.list
curl "https://bintray.com/user/downloadSubjectPublicKey?username=bintray"| apt-key add -
apt-get update
apt-get install neofetch

echo "deb http://dl.bintray.com/dawidd6/neofetch jessie main" | tee -a /etc/apt/sources.list
curl "https://bintray.com/user/downloadSubjectPublicKey?username=bintray"| apt-key add -
apt-get update
apt-get install neofetch

# info
clear
echo "Autoscript Include:" | tee log-install.txt
echo "===========================================" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Service"  | tee -a log-install.txt
echo "-------"  | tee -a log-install.txt
echo "OpenSSH  : 22, 444"  | tee -a log-install.txt
echo "Dropbear : 143, 109"  | tee -a log-install.txt
echo "SSL      : 443"  | tee -a log-install.txt
echo "Squid3   : 8000, 3128 (limit to IP SSH)"  | tee -a log-install.txt
echo "OpenVPN  : TCP 1194 (client config : http://$MYIP:81/client.ovpn)"  | tee -a log-install.txt
echo "badvpn   : badvpn-udpgw port 7300"  | tee -a log-install.txt
echo "nginx    : 81"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Script"  | tee -a log-install.txt
echo "------"  | tee -a log-install.txt
echo "menu (Displays a list of available commands)"  | tee -a log-install.txt
echo "usernew (Creating an SSH Account)"  | tee -a log-install.txt
echo "trial (Create a Trial Account)"  | tee -a log-install.txt
echo "delete (Clearing SSH Account)"  | tee -a log-install.txt
echo "check (Check User Login)"  | tee -a log-install.txt
echo "member (Check Member SSH)"  | tee -a log-install.txt
echo "restart (Restart Service dropbear, webmin, squid3, openvpn and ssh)"  | tee -a log-install.txt
echo "reboot (Reboot VPS)"  | tee -a log-install.txt
echo "speedtest (Speedtest VPS)"  | tee -a log-install.txt
echo "info (System Information)"  | tee -a log-install.txt
echo "about (Information about auto install script)"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Other features"  | tee -a log-install.txt
echo "----------"  | tee -a log-install.txt
echo "Webmin   : http://$MYIP:10000/"  | tee -a log-install.txt
echo "Timezone : Asia/Manila (GMT +7)"  | tee -a log-install.txt
echo "IPv6     : [off]"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Original Script by Fornesia, Rzengineer & Fawzya"  | tee -a log-install.txt
echo "Modified by Wangzki"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Installation Log --> /root/log-install.txt"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "VPS AUTO REBOOT TIME HOURS 12 NIGHT"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "==========================================="  | tee -a log-install.txt
cd
rm -f /root/debian7.sh
Password: IBY484
As Combo: aranaorlando@yahoo.es:IBY484
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: arcilatobar@une.net.co
Password: bealilo5
As Combo: arcilatobar@une.net.co:bealilo5
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: arekusut@hotmail.com
Password: pilunchis79
As Combo: arekusut@hotmail.com:pilunchis79
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: arleyaslan30@gmail.com
Password: claudia150
As Combo: arleyaslan30@gmail.com:claudia150
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: armalo7992@gmail.com
Password: 20003000
As Combo: armalo7992@gmail.com:20003000
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: arman1007@hotmail.com
Password: arman1007
As Combo: arman1007@hotmail.com:arman1007
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: arnoldomen@gmail.com
Password: mishijos02
As Combo: arnoldomen@gmail.com:mishijos02
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: arodrigu59@hotmail.com
Password: 94utyhrn
As Combo: arodrigu59@hotmail.com:94utyhrn
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: arturo.olvera.vega@gmail.com
Password: aov660724
As Combo: arturo.olvera.vega@gmail.com:aov660724
Subscription: Premium
Recurring date: 7/25/18
Status: 
Country: MX
===================
Username: asdrubal_sosa@hotmail.com
Password: 23021974
As Combo: asdrubal_sosa@hotmail.com:23021974
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: Atj967@gmail.com
Password: pegote
As Combo: Atj967@gmail.com:pegote
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: avilacar84@gmail.com
Password: santiago1a
As Combo: avilacar84@gmail.com:santiago1a
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: a-villli@hotmail.com
Password: bebu0102
As Combo: a-villli@hotmail.com:bebu0102
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: Ayde555@hotmail.com
Password: pasonuevo
As Combo: Ayde555@hotmail.com:pasonuevo
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: barreroleonardo2@gmail.com
Password: 12601260
As Combo: barreroleonardo2@gmail.com:12601260
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: basamaro-2010@hotmail.com
Password: lenovoUltrabook1
As Combo: basamaro-2010@hotmail.com:lenovoUltrabook1
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: batistapuello@hotmail.com
Password: 1128045145
As Combo: batistapuello@hotmail.com:1128045145
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: bautistaluisjoseorlando@gmail.com
Password: dianasofia2002
As Combo: bautistaluisjoseorlando@gmail.com:dianasofia2002
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: bcb1993@hotmail.com
Password: mariapaula10
As Combo: bcb1993@hotmail.com:mariapaula10
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: bernardoferro19@gmail.com
Password: rommelww2
As Combo: bernardoferro19@gmail.com:rommelww2
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: bettasdragon@gmail.com
Password: bettasdragon
As Combo: bettasdragon@gmail.com:bettasdragon
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: bettinabaron@yahoo.es
Password: rugerfer
As Combo: bettinabaron@yahoo.es:rugerfer
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: bosita.obm@icloud.com
Password: Bosita.01
As Combo: bosita.obm@icloud.com:Bosita.01
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: bra1918@outlook.com
Password: tvagro98
As Combo: bra1918@outlook.com:tvagro98
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: buitragoa@hotmail.com
Password: anbulo59
As Combo: buitragoa@hotmail.com:anbulo59
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: buitragocar@gmail.com
Password: 0414cabsa
As Combo: buitragocar@gmail.com:0414cabsa
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: c_valencia_b@hotmail.com
Password: anjelika
As Combo: c_valencia_b@hotmail.com:anjelika
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: cabetomolina.m@gmail.com
Password: mijuanes
As Combo: cabetomolina.m@gmail.com:mijuanes
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: caleo369@hotmail.com
Password: soyfeliz69
As Combo: caleo369@hotmail.com:soyfeliz69
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: camcastrov@hotmail.com
Password: tinhorse71
As Combo: camcastrov@hotmail.com:tinhorse71
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: camiloart-14@hotmail.com
Password: 3214585788
As Combo: camiloart-14@hotmail.com:3214585788
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: camilojuan19@gmail.com
Password: 8edevalc
As Combo: camilojuan19@gmail.com:8edevalc
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: candi1727@hotmail.com
Password: comando12345
As Combo: candi1727@hotmail.com:comando12345
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: Canoca19@hotmail.com
Password: jocelial1906
As Combo: Canoca19@hotmail.com:jocelial1906
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: capc1@hotmail.com
Password: 12mamola
As Combo: capc1@hotmail.com:12mamola
Subscription: Premium
Recurring date: 
Status: 
Country: CO
===================
Username: carloscolin@mac.com
Password: camila11
As Combo: carloscolin@mac.com:camila11
Subscription: Premium
Recurring date: 7/5/18
Status: 
Country: MX
===================
Username: carlosrandy@hotmail.com
Password: a123456
As Combo: carlosrandy@hotmail.com:a123456
Subscription: <html>
Recurring date: 
Status: 
Country: 
===================
Username: ccocky5@gmail.com
Password: 12038447
As Combo: ccocky5@gmail.com:12038447
Subscription: Premium
Recurring date: 7/22/18
Status: Premium for Students
Country: MX
===================
Username: chalobarragan@gmail.com
Password: 14081984
As Combo: chalobarragan@gmail.com:14081984
Subscription: Premium
Recurring date: 
Status: 
Country: MX
===================
Username: charly.lemus@hotmail.com
Password: 280109
As Combo: charly.lemus@hotmail.com:280109
Subscription: Premium
Recurring date: 7/5/18
Status: Premium for Students
Country: MX
===================
Username: chendez_@hotmail.com
Password: CARC1978
As Combo: chendez_@hotmail.com:CARC1978
Subscription: Premium
Recurring date: 7/4/18
Status: 
Country: MX
===================
Username: corderovaleria.5@gmail.com
Password: 411047948
As Combo: corderovaleria.5@gmail.com:411047948
Subscription: Premium
Recurring date: 7/20/18
Status: Premium for Students
Country: MX
===================
Username: danielserrano@msn.com
Password: alincodr450path
As Combo: danielserrano@msn.com:alincodr450path
Subscription: Premium
Recurring date: 7/3/18
Status: 
Country: AR
===================
Username: donfabian1218@gmail.com
Password: Adonai1218
As Combo: donfabian1218@gmail.com:Adonai1218
Subscription: <html>
Recurring date: 
Status: 
Country: 
===================
Username: duartesaraid@outlook.com
Password: casacasa
As Combo: duartesaraid@outlook.com:casacasa
Subscription: <html>
Recurring date: 
Status: 
Country: 
===================
Username: eduard626@gmail.com
Password: lalolalo
As Combo: eduard626@gmail.com:lalolalo
Subscription: Premium
Recurring date: 7/11/18
Status: Premium for Students
Country: GB
===================
Username: elsebapili@hotmail.com
Password: Papanoel
As Combo: elsebapili@hotmail.com:Papanoel
Subscription: 
Recurring date: 
Status: 
Country: 
===================
Username: emilianor81@gmail.com
Password: te1sorin0
As Combo: emilianor81@gmail.com:te1sorin0
Subscription: Premium
Recurring date: 7/16/18
Status: 
Country: AR
===================
Username: ferhervias@gmail.com
Password: sexylady
As Combo: ferhervias@gmail.com:sexylady
Subscription: Premium
Recurring date: 7/6/18
Status: Premium for Students
Country: MX
===================
Username: fitzeroa@gmail.com
Password: Katya2001
As Combo: fitzeroa@gmail.com:Katya2001
Subscription: Premium
Recurring date: 7/10/18
Status: 
Country: MX
===================
Username: franco11690@gmail.com
Password: pecesito
As Combo: franco11690@gmail.com:pecesito
Subscription: Premium
Recurring date: 
Status: 
Country: AR
===================
Username: gabychy4@gmail.com
Password: Monopoly04
As Combo: gabychy4@gmail.com:Monopoly04
Subscription: Premium
Recurring date: 
Status: 
Country: MX
===================
Username: gabymendez_99@hotmail.com
Password: girasoles629
As Combo: gabymendez_99@hotmail.com:girasoles629
Subscription: Premium
Recurring date: 
Status: 
Country: MX
===================
Username: garibayy1990@gmail.com
Password: Neto2090
As Combo: garibayy1990@gmail.com:Neto2090
Subscription: Premium
Recurring date: 
Status: 
Country: MX
===================
Username: gerardo_carranco@hotmail.com
Password: Panuco28
As Combo: gerardo_carranco@hotmail.com:Panuco28
Subscription: Premium
Recurring date: 7/2/18
Status: Premium for Students
Country: MX
===================
Username: gisela07_trejo@hotmail.com
Password: ktimporta13
As Combo: gisela07_trejo@hotmail.com:ktimporta13
Subscription: Premium
Recurring date: 7/18/18
Status: Premium for Students
Country: MX
===================
Username: hvallejoa@hotmail.com
Password: ventas07
As Combo: hvallejoa@hotmail.com:ventas07
Subscription: Premium
Recurring date: 
Status: 
Country: MX
===================
Username: info@caminodeljaguel.com.ar
Password: sierjo08
As Combo: info@caminodeljaguel.com.ar:sierjo08
Subscription: <html>
Recurring date: 
Status: 
Country: