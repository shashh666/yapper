---
title: "Forwarding Windows logs using NXLog"
date: 2019-01-02T11:05:02+08:00
featuredImage: ""
author: "theYapper"
tags: ["logs", "nxlog", "syslogs"]

---

Alright, so my experiment with forwarding Syslogs has lead me down the path of testing it on Windows systems as well. 

One of the simplest ways of forwarding logs from Windows systems to a Syslog server is by using NXLog.

#### Installation

NXLog client would need to be installed on your Windows system. It is best to download the community edition at their official [site](https://nxlog.co/products/nxlog-community-edition/download). 

Installation is a simple process. You just have to execute the `msi` file and follow the instructions. I won't go through that process here. 

#### NXLog Setup

Let's jump into the setup. NXLog set up requires some changes to the configuration file which is usually located at the default location:  `Program Files (x86)\nxlog\conf\`. Before editing, make sure you have the permissions to edit this file and update it with the diretives mentioned below. 

At a bare minimum, you need to take care of the following: 

##### 1. Define File Locations 

To start things off, we must first define the location of nxlog executable, config file, log file and the supporting modules. The default NXLog configuration file comes with some of these already pre-defined. It is a good idea to review and make the necessary changes. 
Here's my file: 

```
define ROOT		C:\Progam Files (x86)\nxlog
define CERTDIR	%ROOT%\cert
define CONFDIR	%ROOT%\conf
define LOGDIR	%ROOT%\data
define LOGFILE	%LOGDIR%\nxlog.log
LOGFile %LOGFILE%

ModuleDir	%ROOT%\modules
CacheDir	%ROOT%\data
Pidfile		%ROOT%\data\nxlog.pid
SpoolDir	%ROOT%\data
```

The NXLog documentation does a fantastic job at defining all the available directives and modules and how you can use them to define an effective `nxlog.conf` file. Instead of re-inventing the wheel, I would encourage you to go through [it](https://nxlog.co/documentation/nxlog-user-guide-full#syslog) when you have the time.

##### 2. Enable the syslog module 

In order to collect and forward syslogs, you need to enable the syslog extension which can be accessed via: 

```
<Extension _syslog>
	Module 	xm_syslog
</Extension>
```

##### 3. Enable json module 

This is an optional module. It is a good idea to structure data before forwarding and most logging platforms these days support ingestion in json format. You can transform the syslogs into json using: 

```
<Extension json>
	Module 	xm_json
</Extension>
```

##### 4. Define monitoring files/log sources 

Since I'm only testing things out, I will only define the bare essentials in my configuration. By default, Windows logs event logs and these can be easily picked up and forwarded. The NXLog documentation also has a section on how to set this up. It is linked [here](https://nxlog.co/documentation/nxlog-user-guide-full#sending_eventlog). 

Here's what this section of my configuration looks like: 

```
<Input eventlog>
	# Uncomment for Windows Vista/2008 or later 
  	Module im_msvistalog
 	 # Uncomment for Windows 2000 or later
 	 # Module im_mseventlog
	Exec 	Exec $Message = replace($Message, "\r\n", " "); to_json();
</Input>
```

##### 5. Define output location 

This is basically the location/port of your syslog server where you would like to forward your logs. Since I am forwarding using json format, I'd like to use the reliable TCP protocol to forward my logs. This can be achieved using: 

```
<Output out>
	Module om_tcp 
	Host <ip address/hostname of the receiving server>
	Port 514
</Output>
```

##### 6. Connect the pieces together

Connecting all the pieces defined above together requires defining a route indicates which one of the input streams you'd like to forward on the defined output stream. 

```
<Route 1>
	Path eventlog => out
</Route>
```

You can also define multiple routes if you'd like to setup different routes for different types of files/log sources. 

Save changes in the `\nxlog\conf\nxlog.conf` file and restart the `nxlog` service from `services.msc` . 

<img src="/img/nxlog.png" width="500">

#### Testing

I would recommend following a couple of steps here. 

##### Step 1: Check for errors
This can be done by checking the `nxlog.log` file that we'd created earlier at `C:\Progam Files (x86)\nxlog\data\`. 

If there are no errors, you would see something like this: 

<img src="/img/nxlogfile.png" width="500">

If there are errors, you will have sufficient information in the log file to troubleshoot. 

##### Step 2: Check for logs

The final step is to ensure that you are able to receive logs by monitoring the Rsyslog server input. 

I have described how to setup an Rsyslog server in my previous [post](/post/using-rsyslog/#rsyslog-server-setup). 

If everything goes well, the final output on the Rsyslog server would look like: 

```
$ tail -f /var/log/syslog
Jan  2 08:15:53 ip-172-31-18-235.ap-southeast-1.compute.internal  {"EventTime":"2019-01-02 08:15:51","Hostname":"WIN-ENU956P6HR0","Keywords":-9187343239835811840,"EventType":"INFO","SeverityValue":2,"Severity":"INFO","EventID":7036,"SourceName":"Service Control Manager","ProviderGuid":"{555908D1-A6D7-4695-8E1E-26931D2012F4}","Version":0,"Task":0,"OpcodeValue":0,"RecordNumber":80664,"ProcessID":664,"ThreadID":3524,"Channel":"System","Message":"The nxlog service entered the running state.","param1":"nxlog","param2":"running","EventReceivedTime":"2019-01-02 08:15:53","SourceModuleName":"eventlog","SourceModuleType":"im_msvistalog"}
```

And that's it. There are a few issues that you may run into while you are trying to set this up. The NXLog documentation that I've linked in a couple of places will help you get through them. 

Happy log forwarding!


-theYapper
