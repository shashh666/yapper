---
title: "S3 Static Web Hosting Root Object"
date: 2018-11-12T15:35:05+08:00
featuredImage: "/img/break.png"
author: "theYapper"
#tags: ["aws", "s3", "troubleshooting"]
---

## The Effect

AWS S3 makes is it quite easy to host a static website. Combined with a CloudFront distribution, you have a great way to serve a highly available static website. 

However, if you are not careful you may end up deploying a site that would break every time you tried to navigate its pages and present a beautiful page like this.

![like this](/img/break.png)

When I was building this site and ran into this issue, I ended up spending a couple of hours racking my brain trying to figure out the root of the problem. 

## The Cause 

Eventually, I realized that the issue was with the CloudFront origin name. It is rather easy in S3 to specify the default root object for subdirectories. Things change while using CloudFront. </br>
For instance: </br>
A request to `https://www.yapper.io/tags/` should go to `https://www.yapper.io/tags/index.html` and fetch the contents. But instead you get an error as shown at the top of this page. </br>

This happens if you choose the CloudFront origin from the list of S3 buckets presented by default. 

![cf-origin](/img/cf-origin.jpeg)

## The Solution

This solution here is to make CloudFront treat the S3 files as a static site. This can be done by grabbing the S3 static web hosting endpoint url and using the endpoint as the CloudFront origin. 

![s3-endpoint](/img/s3-endpoint.png)

Once you have taken care of the origin, CloudFront will internally treat the S3 files as a static web hosting files and look for the root file in a sub-directory to display its contents. 

Happy hosting! 
