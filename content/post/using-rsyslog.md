---
title: "Log Forwarding with Rsyslog"
date: 2018-12-29T17:48:39+08:00
featuredImage: "/img/logs.jpg"
author: "theYapper"
tags: ["aws", "rsyslog"]

---


Recently, I had some trouble running some experiments with Rsyslog at my organization's internal systems. I was even having trouble with basic networking between two Linux systems and exchanging syslogs. I guess when you don't have full control over systems, you can't really fully troubleshoot. 

Enter AWS to the rescue. In less than 30 minutes, I was able to confirm my setup and extend my experiments. In this post, I will just document the basic networking setup between two Linux systems that act as Rsyslog client and server. 

My setup consists of two Linux servers on AWS EC2:

1. Rsyslog Client - RHEL 7.5 HVM AMI 
2. Rsyslog Server - Ubuntu 18.04 HVM AMI  

#### Installation

Rsyslog is installed by default on both the above sytems. If for some reason it isn't, you can install by running the following commands. Install and make sure Rsyslog is running: 

###### On RHEL, 
```
$ yum -y install rsyslog
$ service syslog status
● rsyslog.service - System Logging Service
   Loaded: loaded (/lib/systemd/system/rsyslog.service; enabled; vendor preset: enabled)
   Active: active (running) since Sat 2018-12-29 11:17:36 UTC; 5min ago
     Docs: man:rsyslogd(8)
           http://www.rsyslog.com/doc/
 Main PID: 730 (rsyslogd)
    Tasks: 10 (limit: 1152)
   CGroup: /system.slice/rsyslog.service
           └─730 /usr/sbin/rsyslogd -n
```


###### On Ubuntu, 
```
$ sudo apt-get install rsyslog
$ sudo systemctl status rsyslog
Redirecting to /bin/systemctl status rsyslog.service
● rsyslog.service - System Logging Service
   Loaded: loaded (/usr/lib/systemd/system/rsyslog.service; enabled; vendor preset: enabled)
   Active: active (running) since Sat 2018-12-29 11:17:25 UTC; 7min ago
     Docs: man:rsyslogd(8)
           http://www.rsyslog.com/doc/
 Main PID: 1071 (rsyslogd)
   CGroup: /system.slice/rsyslog.service
           └─1071 /usr/sbin/rsyslogd -n
```

#### Rsyslog Server Setup 

The Rsyslog server is an Ubuntu 18.04 system. The basic server setup is about configuring Rsyslog to accept remote log messages using TCP or UDP. Per the Rsyslog manual, when it attempts to send log messages out it first tries to send over UDP and then TCP. Some sysadmins choose to enable both the TCP and UDP directives. We will do the same here. 

Rsyslog configuration can be accessed at: `/etc/rsyslog.conf` 

For the basic setup, we just need to enable the following modules:
```
# provides UDP syslog reception
module(load="imudp")
input(type="imudp" port="514")

# provides TCP syslog reception
module(load="imtcp")
input(type="imtcp" port="514")

```

If you are using a different Linux distribution, similar TCP/UDP settings would need to be enabled. 

You could (optionally) setup a template and file location to store the received syslogs. However, if you don't then it gets sent to a default location under `/var/log/`.

Once the setup is complete, restart the rsyslog service. 

```
$ sudo systemctl restart rsyslog
```

Next step is to verify that the receiving ports are open.

```
$ ss -tunelp | grep 514
udp   UNCONN  4992    0                     0.0.0.0:514           0.0.0.0:*      ino:17019 sk:1 <->
udp   UNCONN  0       0                        [::]:514              [::]:*      ino:17020 sk:4 v6only:1 <->
tcp   LISTEN  0       25                    0.0.0.0:514           0.0.0.0:*      ino:17093 sk:5 <->
tcp   LISTEN  0       25                       [::]:514              [::]:*      ino:17094 sk:8 v6only:1 <->
```

If you do have firewall setups, you may want to allow tcp and udp on 514. However, as I'm using AWS EC2, I can control these settings with AWS's networking controls. 

#### Rsyslog Client Setup 

The Rsyslog client is an RHEL 7.5 system. The basic client setup just requires the IP address/hostname and port of the server to be configured. 


To enable this we access the config file at `/etc/rsyslog.conf` and enable the following setting: 

```
*. * @ip-address-of-rsyslog-server:514
```

This will enable sending of logs over UDP. To send over TCP, use `@@` instead of `@`. 

Once the setup is complete, restart the service. 

```
sudo service rsyslog restart
```
And that's it. 

#### Testing 

The final step is to ensure that you are able to send these logs out now. 
You can use a simple utility such as `logger` for this purpose. 

On the Rsyslog client, 
```
$ logger "Test message from Yapper...."
$ sudo tail /var/log/messages
Dec 29 14:14:45 ip-172-31-23-211 dbus[459]: [system] Successfully activated service 'org.freedesktop.nm_dispatcher'
Dec 29 14:14:45 ip-172-31-23-211 systemd: Started Network Manager Script Dispatcher Service.
Dec 29 14:14:45 ip-172-31-23-211 nm-dispatcher: req:1 'dhcp4-change' [eth0]: new request (4 scripts)
Dec 29 14:14:45 ip-172-31-23-211 nm-dispatcher: req:1 'dhcp4-change' [eth0]: start running ordered scripts...
Dec 29 14:26:21 ip-172-31-23-211 rsyslogd: [origin software="rsyslogd" swVersion="8.24.0" x-pid="1071" x-info="http://www.rsyslog.com"] exiting on signal 15.
Dec 29 14:26:21 ip-172-31-23-211 systemd: Stopping System Logging Service...
Dec 29 14:26:21 ip-172-31-23-211 systemd: Starting System Logging Service...
Dec 29 14:26:21 ip-172-31-23-211 rsyslogd: [origin software="rsyslogd" swVersion="8.24.0" x-pid="8838" x-info="http://www.rsyslog.com"] start
Dec 29 14:26:21 ip-172-31-23-211 systemd: Started System Logging Service.
Dec 29 14:29:01 ip-172-31-23-211 ec2-user: Test message from Yapper....
```

I can verify that the random message is being logged under the `/var/log/messages` folder. 

On the Rsyslog server, 
```
$ tail /var/log/syslog
Dec 29 14:14:45 ip-172-31-23-211 nm-dispatcher: req:1 'dhcp4-change' [eth0]: start running ordered scripts...
Dec 29 14:17:01 ip-172-31-14-196 CRON[2326]: (root) CMD (   cd / && run-parts --report /etc/cron.hourly)
Dec 29 14:17:28 ip-172-31-14-196 systemd-timesyncd[443]: Network configuration changed, trying to establish connection.
Dec 29 14:17:28 ip-172-31-14-196 systemd-timesyncd[443]: Synchronized to time server 91.189.89.198:123 (ntp.ubuntu.com).
Dec 29 14:26:21 ip-172-31-23-211 rsyslogd: [origin software="rsyslogd" swVersion="8.24.0" x-pid="1071" x-info="http://www.rsyslog.com"] exiting on signal 15.
Dec 29 14:26:21 ip-172-31-23-211 systemd: Stopping System Logging Service...
Dec 29 14:26:21 ip-172-31-23-211 systemd: Starting System Logging Service...
Dec 29 14:26:21 ip-172-31-23-211 rsyslogd: [origin software="rsyslogd" swVersion="8.24.0" x-pid="8838" x-info="http://www.rsyslog.com"] start
Dec 29 14:26:21 ip-172-31-23-211 systemd: Started System Logging Service.
Dec 29 14:29:01 ip-172-31-23-211 ec2-user: Test message from Yapper....
```

I can verify that the same message is being received under the `/var/log/syslog` folder. 

That's it folks. In a matter of minutes, I'm able to confirm that the setup works. Now depending on the requirements of the organization, specific types of logs files can be configured to be forwarded from the Rsyslog client to Rsyslog server. 

Happy log forwarding! 

-theYapper
