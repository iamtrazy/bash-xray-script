# Bash|Xray-Script

* UPDATE 12/05/2021 - please don't use pointdns as your domain provider. Use duckdns instead
* UPDATE 21/05/2021 - added xray-nodomain script (see usage and installation below)


![logo](https://telegra.ph/file/4e19dd26926234ca32b68.jpg)



Xray-Script එක Use කරල ඔයාට High speed Network Connection එකක් / Low ping / Full stable Connection එකක් අත්විදින්න පුලුවන් ...


Manage Script

## :heavy_exclamation_mark: Requerimientos

* Ubuntu 20.04 or Ubuntu-latest Os එක සහිත Vps එකක්.
* UUID එකක් (V2rayN මගින් හෝ http://uuidgenerator.net මගින් UUID එකක් Genarate කරගන්න).
* DNS එකක් (DuckDns |Freenome).
* DuckDns Use කරනවනම් ipv4 එකට ඔයාගෙ Vps එකෙ ip එක දාන්න Freenome site එකෙන් ගන්නවනම් Cloudflare Add කරන්න ඔනෙ).
* DNS use නොකර Ip එකෙන් direct connect කරගන්න xray-nodomain ස්ක්‍රිප්ට් එක භාවිතා කරන්න.

------------------------------------------
## :book: Installation - Without a Doamin

1)apt-get update -y && apt-get upgrade -y

2)sudo reboot (update එකෙන් පසු restart කිරීමට)

4)sudo git clone https://github.com/iamtrazy/bash-xray-script

5)cd bash-xray-script

6)sudo chmod 777 xray-nodomain.sh

7)sudo ./xray-nodomain.sh

------------------------------------------
## :book: Installation

1)apt-get update -y && apt-get upgrade -y

2)sudo reboot

3)sudo ufw disable

4)sudo git clone https://github.com/iamtrazy/bash-xray-script

5)cd bash-xray-script

6)sudo chmod 777 xray.sh

7)sudo ./xray.sh

8)UUID එකයි ඔයාගෙ DNS එකයි installation එක අතර තුරදි ඉල්ලයි එතකොට දෙන්න 

------------------------------------------

## :book: How To Connect

1)Android User කෙනෙක්නම් V2rayNG Download කරගන්න (
https://github.com/2dust/v2rayNG)

2)Windows User කෙනෙක්නම් V2rayN හො Netch Software දෙක Download කරගන්න

![logo](https://telegra.ph/file/372eb568ce7a7776aa8c4.jpg)

* AlterId   =   4

* Http Port =  80

* Xtls port = 443

## :book: Unistallation (Remove xray-core and all modified config files from the server) *will not remove BBR

1) sudo rm  -rf  ~/bash-xray-script

2) sudo git clone https://github.com/iamtrazy/bash-xray-script

3) cd bash-xray-script

4) sudo chmod 777 remove-xray.sh

5) sudo ./remove-xray.sh

## :octocat: Credits

1. https://github.com/teddysun - BBR autoscript
2. Team Rezoth - Contributor
3. @Savinda1 - for the awesome readme file 😎


☆ https://t.me/rezoth_tm ☆
