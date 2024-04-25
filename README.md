# Bash-toolbox-for-Huawei-LTE-API

The goal of this project was to securely manage a remote network using SMS. It's only 50 km from me, but I'm lazy(*).

SMS just one more channel to manage my devices, powerful, but with minor drawbacks.
This channel will work everywhere, in airplane (if the air carrier allows it), in the middle of the ocean, ...
In a normal situation, You phone can work with SMS perfectly, in an extreme situation, a satellite messenger
will help you. So, my need is my own, a custom SMS Gateway. And I need access to an SMS API that is... encrypted.

Target hardware: Huawei LTE family, model B535-333 (Soyea)
Software version: 11.0.2.51 (Sweden, Tele2)
This device uses Huawei API (sorry, Soyea API, with removied hilink)
Probably it will work and with other models, where SCRAM login implemented (/api/user/challenge_login)
(Here you can find some information about supported (or not) devices: http://bash4lte.root.sx )

The firmware contains bugs (which I had to adapt to) that may be fixed in the future by manufacturer,
and a couple of lines in my code will have to be changed. I don't want to spend my time to fix errors in firmware,
it's useless, it's much easier to change a couple of lines of my Bash code. I know, I'm lazy(*).
Huawei use Opensource + well documented API in public access, and you don't need to use reverse engineering and other complex tools. 

Functions:
0) SCRAM (Salted Challenge Response Authentication Mechanism), CryptoJS.SCRAM emulation,
main part, all other just example how You can use API.

Examples:

1) Send SMS

2) Forward SMS to (from the box) Telegram, SMS, satellite messenger, syslog.
(You can add any other destination, like Microsoft Teams (webhook), ...)

3) Run any Bash/LTE command by authorized SMS. (for example control AppleHomekit via Homebridge)

4) SMS authorization to execute a command by password (just for testing) or YubiKey OTP (production).
https://developers.yubico.com/OTP/OTPs_Explained.html
There is a theoretical possibility of replacing SMS text somewhere along the way, while maintaining the correct OTP,
replacing only the command. And since OTP is only a password and not a digital signature, you are not protected from this.
You can try to create Your own solution with Signing SMS message, but You are limited, only 160 characters for SMS message.
And You can't use authorization by Sender ID. It can be easy changed by any one, and sometimes our devices are "numberless" :)

5) Example connection information: ./lte-connect-info.sh

6) Example get current Band: ./lte-get-band.sh

7) or set Band 45 (B1+B3+B7): ./lte-set-band.sh

8) Checking for new SMS and processing them: ./check_sms.sh
Crontab example for check_sms:
* * * * * /home/pi/dev/check_sms.sh

9) Satellite messenger support. (A slight change in logic to adapt to "numberless" messengers.)

The code is designed to maximize the life of your SD card.
(Just comment "logger" strings after debuging, all logs going to /var/log/messages)

This is just a set of Bash commands, that creates bridge between the Huawei API and Bash.
You can use full Huawei API withous thinking about SCRAM, HMAC, HMAC-H :), PBKDF2, token rotation and other weird things...
SCRAM login function - this is main project part, giving you full access to the Huawei API.
All these functions will be performed behind the scenes, freeing up your hands for programming.

The code is provided as is. It's full of errors. If I can "inject" code like "; rm -rf /" - anyone can.
This is why you need to use YubiKey OTP... 
This cool, trust me, you don't even have to type the password, just copy/paste NFC OTP.

If you use this it is entirely at your own risk and I make no warranty of any kind.
If you will launch SpaseX rocket with an SMS command ahead of time, this is your personal problem. :D

Huawei API:
http://forum.jdtech.pl/Watek-hilink-api-dla-urzadzen-huawei
I want to say "Thank You" guys for your work:
Dziekuje bardzo, jestes najlepszy!

I searched for a couple of months for the functions I needed, but found nothing.
I'm grateful to people:
https://github.com/tpoechtrager
https://github.com/vzakharchenko
https://github.com/Malaga82

They didn't give me the answer to my questions, but they motivated me to get down to business.
Basic functions (for example, set LTE band) working fine, without problems, with existing software,
but SMS functions are completely encrypted in my device.
In addition, /api/user/hilink_login has been removed.
This became the reason to make new code myself.

Why Bash and not JS or PHP or any other choise?
If I use extremely unsafe "echo" command in Bash, I'm sure it will work the same way in 10 years. It may acquire new options, but the old ones will work as before.
Without any "deprecated" messages. As few dependencies as possible.
For real connoisseurs, I added an option "deprecated" in my code. :) 
To feel difference between Bash and PHP/...
just try to install YubiKey OTP Validation Server from source provided on https://developers.yubico.com, and count time.
(No, You don't have to do that, we'll take the simple way.)

SMS, like Bash Echo command, is terribly unsafe. Any service provider can store your messages for a long time and feed them to various AIs for analysis (at a minimum).
And You may be unhappy if your little child repeats a SMS command, authorized by password (for example "mycoolpass shutdown everything") 
while learning the copy/paste function on your phone.
This is reason why I integrated YoubiKey OTP (One-Time password) for real paranoids (like me).
If you are just thinking about ordering a YubiKey, take 2 at once (for example 1 Biometric and 1 just with NFC).
You will lose one, with high probability. Mine, for example, is lying around somewhere in London STN :D
But because of this I know how to deal with GPG revocation sertificates and where are they stored on my MacBook.
(I'm not affiliated with Yubico, feel free to change 2-3 lines of code and use your own solution)

Requirements:

Hardware: Piece of hardware with CPU, RAM and several kilobytes of storage, capable to work with a Bash.
Raspberry Pi Zero W (first gen) - huge overdose, but OK, let's stop there.

Software: Raspbian (Bullseye) with Bash 5.1.4 - just fine. 
If you are using older versions of Bash, you may have to change some lines of code. For example "grep -oP".
Python (apt-get install it) functions used in 5 strings of code, You can easy replace it if You need,
but for me it's OK, and I'm lazy(*) :D

Setup:
You should at least edit "configure.me", then run "./run_me_first.sh". If all is ok - fine, You can start programming. 
If not - You will have to edit "functions.bash" to fix the syntax of some commands. 
Do not worry, the code is as simple as possible.

Let's count time and money. 
I'll assume that you have ready RPI+SD card. (~20Eur+10Eur?)

1) Install OS to SD (raspberry pi imager) ~15 min (including password/wifi/ssh/.. setup before writing to SD).
(I don't have an HDMI adapter or adapter for the keyboard, and I'm happy with the setup process)

2) Copy this project to You RPI (git clone or copy/paste or...) - 5 min.

3) Optional. From 5 min to ... If You have YoubiKey, apt-get install yubiserver, don't worry, just a few kilobytes of code, 
and you don't need Nginx/Apache or any heavy libraries.
Add all Your YoubiKeys to yubiserver DB:
Example: yubiserver-admin -y -a nanakos ccicdcfehlvv c6963f285d78 108e504f37fef82s3b6gb3a45708405c
Don't forget about DB permissions: /var/lib/yubiserver/yubiserver.sqlite
(You may need to refer to the OTP documentation if You doing it first time on https://www.yubico.com)
Start yubiserver (no any configuration needed by default).

Just a note. You cannot use Yubico servers to validate your SMS OTP. LTE sometimes goes offline by design.
During this time you will not be able to authorize your command.
But since we all love crypto, and can handle it locally, no problem. At all..

So, a project with a budget starting from ~30 Eur with time spent ~30 min.
(+ you have a full-fledged Debian server with very low energy consumption)

If You liked my code and saved some of your valuable time, You can buy me a coffee :)
Thank you for taking the time to get to know my work.

https://www.buymeacoffee.com/mrgool
TON: UQDYUkEvtdO4jZRwCLYen1H2C2DYIYruazRYARPFBXRwwQ05
BTC: bc1qx6l604eqwn6v6649tlqr8ndz0u96rvq080twg4

(*) The tendency of human nature to seek simpler ways of completing tasks can lead to positive results, stimulating progress and innovation in various fields of activity.


HUAWEI (https://consumer-img.huawei.com/content/dam/huawei-cbg-site/en/mkt/legal/trademark/huawei-drademark.png) 
and HUAWEI Trademark Policy are trademarks of Huawei Technologies Co., Ltd registered in China and other countries.
(I'm not affiliated with HUAWEI)
