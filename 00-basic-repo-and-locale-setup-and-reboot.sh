#!/bin/sh


apt-get update
apt-get -y install locales
# for Debian 12
## set to India IST timezone -- You can dissable it if needed
timedatectl set-timezone 'Asia/Kolkata'
dpkg-reconfigure -f noninteractive tzdata
export LANG=C
export LC_CTYPE=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i -e 's/en_IN UTF-8/# en_IN UTF-8/' /etc/locale.gen
locale-gen en_US en_US.UTF-8
echo "LANG=en_US.UTF-8" > /etc/environment
echo "LC_ALL=en_US.UTF-8" >> /etc/environment
update-locale LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8

##disable ipv6 as most time not required
sysctl -w net.ipv6.conf.all.disable_ipv6=1 1>/dev/null
sysctl -w net.ipv6.conf.default.disable_ipv6=1 1>/dev/null

## backup existing repo by copy just for safety
mkdir -p /opt/old-config-backup/ 2>/dev/null


## centos like bash ..for all inteactive 
echo "" >> /etc/bash.bashrc
echo "alias cp='cp -i'" >> /etc/bash.bashrc
echo "alias l.='ls -d .* --color=auto'" >> /etc/bash.bashrc
echo "alias ll='ls -l --color=auto'" >> /etc/bash.bashrc
echo "alias ls='ls --color=auto'" >> /etc/bash.bashrc
echo "alias mv='mv -i'" >> /etc/bash.bashrc
echo "alias rm='rm -i'" >> /etc/bash.bashrc
echo "export EDITOR=vi" >> /etc/bash.bashrc
echo "export LC_CTYPE=en_US.UTF-8" >> /etc/bash.bashrc
echo "export LC_ALL=en_US.UTF-8" >> /etc/bash.bashrc
echo "export LANGUAGE=en_US.UTF-8" >> /etc/bash.bashrc

#Setting rc.local, perl, bash, vim basic default config and IST time sync NTP
## copy existing if any... when 
/bin/cp -pR /etc/rc.local /opt/old-config-backup/old-rc.local-`date +%s` 2>/dev/null
## create with default IPV6 disabled
touch /etc/rc.local
printf '%s\n' '#!/bin/bash'  | tee -a /etc/rc.local 1>/dev/null
echo "sysctl -w net.ipv6.conf.all.disable_ipv6=1" >>/etc/rc.local
echo "sysctl -w net.ipv6.conf.default.disable_ipv6=1" >> /etc/rc.local
echo "sysctl vm.swappiness=0" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local
chmod 755 /etc/rc.local
## need like autoexe bat on startup
echo "[Unit]" > /etc/systemd/system/rc-local.service
echo " Description=/etc/rc.local Compatibility" >> /etc/systemd/system/rc-local.service
echo " ConditionPathExists=/etc/rc.local" >> /etc/systemd/system/rc-local.service
echo "" >> /etc/systemd/system/rc-local.service
echo "[Service]" >> /etc/systemd/system/rc-local.service
echo " Type=forking" >> /etc/systemd/system/rc-local.service
echo " ExecStart=/etc/rc.local start" >> /etc/systemd/system/rc-local.service
echo " TimeoutSec=0" >> /etc/systemd/system/rc-local.service
echo " StandardOutput=tty" >> /etc/systemd/system/rc-local.service
echo " RemainAfterExit=yes" >> /etc/systemd/system/rc-local.service
## featured Removed
###echo " SysVStartPriority=99" >> /etc/systemd/system/rc-local.service
echo "" >> /etc/systemd/system/rc-local.service
echo "[Install]" >> /etc/systemd/system/rc-local.service
echo " WantedBy=multi-user.target" >> /etc/systemd/system/rc-local.service

systemctl enable rc-local
systemctl start rc-local

sed -i "s/#RateLimitIntervalSec=30s/RateLimitIntervalSec=0/"  /etc/systemd/journald.conf
sed -i "s/#RateLimitBurst=10000/RateLimitBurst=0/"  /etc/systemd/journald.conf
systemctl restart systemd-journald
systemctl daemon-reload

## make cpan auto yes for pre-requist modules of perl
(echo y;echo o conf prerequisites_policy follow;echo o conf commit)|cpan 1>/dev/null

#Disable vim automatic visual mode using mouse
echo "\"set mouse=a/g" >  ~/.vimrc
echo "syntax on" >> ~/.vimrc
##  for  other new users
echo "\"set mouse=a/g" >  /etc/skel/.vimrc
echo "syntax on" >> /etc/skel/.vimrc

##Comment this if you do not want root login via ssh activated using port 7722
#sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
#sed -i "s/#Port 22/Port 7722/g" /etc/ssh/sshd_config
systemctl restart ssh


##useful simple script to take full etc backup at times for safety
/bin/cp -p files/extra-files/etc-config-backup.sh /bin/

## safe backup
files/extra-files/etc-config-backup.sh

hostname -f
ping `hostname -f` -c 2


apt-get update
apt-get -y full-upgrade
