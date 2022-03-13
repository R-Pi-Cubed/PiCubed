# PiCubed - Minecraft Server Installation Assistant

[![Discord](https://img.shields.io/discord/871022128684736592?logo=discord)](https://discord.gg/8NGy57hfYW) [![Youtube](https://img.shields.io/badge/YouTube-FF0000?style=flat-square&logo=youtube&logoColor=white)](https://www.youtube.com/channel/UCn-oPwEFQJxfj8omsKbffCg) [![Twitter URL](https://img.shields.io/twitter/follow/CybrHare?style=flat-square&logo=twitter)](https://twitter.com/cybrhare)

## PiCubed - A Paper Minecraft Java server install assistant for Raspberry Pi.

PiCubed will assist you in the installation of a Paper Minecraft Java Server. **It will NOT do everything for you.**

*"Give a man a fish, you feed him for a day. Teach a man to fish, you feed him for a lifetime"*

PiCubed makes the assumption that you are tinkering with a Raspberry Pi because you are the type of person that, well likes to tinker and know a little more about what's going on under the hood. If you are ready to learn a little more and put in a little more effort then this script if for you. If not, thank you for looking. We'll still be here if you want to learn a little more later. In all reality though running a Minecraft server, even a small one for you and a couple of friends, will require you to learn a few things about the process.

Please refer to [docs.picubed.me](https://docs.picubed.me) for detailed information and instructions on how to get your server up and running.

## Before you get started

This script will assist you to install a Minecraft **Server** on a Raspberry Pi. It will **NOT** provide you with a Minecraft client to use to play on the server. If you have not yet done so you will need to purchase a copy of Minecraft. That copy you purchase is called the client. Also note that this server will only work for a PC version of Minecraft. This is referred to as Java Minecraft. Minecraft comes in 2 versions. The Java version is the original version and is typically thought of when talking about a PC version of Minecraft. Then there is the Bedrock version. Bedrock is the version of Minecraft that is on gaming consoles like the XBox and mobile devices like cell phones and tablets. These versions are not compatible and don't usually play well together. So the bad news is that if you are playing Minecraft on your Playstation this script won't work for you to create a server for you and your friends. At least not for now. Maybe in the future. The good news though is that as of March 2022 if you play Minecraft on the PC you automatically get both versions of Minecraft. You can find out more about that on the official [Minecraft Website.](https://www.minecraft.net)

## Performance and expectations

*"You have chosen the way of pain"*

You are going to be told all types of things when you ask someone about setting up a Minecraft server on a Raspberry Pi.

Most of those things are wrong.

It is indeed shocking just how much inaccurate, old and biased information there is about the subject of setting up a Minecraft server on a Pi. That is indeed one of the reasons for this repository. Question everything you read. That includes anything you read here. **If you see something that seems inaccurate please point it out**.

A Raspberry Pi can absolutley run a Minecraft server for you and a few friends. It can do just about anything that an expensive hosting service can do. The limitation is scale. You will not be hosting a server for 100 of your classmates all online at once. Even 10 may be a stretch. You can add google style maps, discord webhooks to message you activity on your server or plugins to add mobhead drops. But as your server complexity grows so must your knowledge. Manage your expectations and have realistic goals and you will be happy with your server for years to come.

## What you need to get started

Obviously you are going to need a Raspberry Pi. That said your experience will be effected by the model you use. Give yourself the best chance and use the best Pi available. At the time of writing this that is the [Raspberry Pi 4b with 8gb of ram](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/). Minecraft is a ram hog and the latest versions need more ram to function properly. Older model Pi or models with less ram will work with varying degrees of success. Slower processor speeds of older Pi and the ability to overclock your Pi will also have an effect on your servers performance.

Speaking of overclocking. To get the best performance out of your Pi it will need to be oveclocked. Overclocking is telling the cpu to run faster than it was set to at the factory. The Pi can handle a little overclocking easily but it produces heat. A Pi CPU begins to throttle it's speed if it reaches 80°C. To keep your Pi cool you will need some active cooling. Active cooling is a fan blowing air across the CPU. The little aluminium fins that come with your Pi won't cut it. You need a fan. There are a lot of cases that come with integrated fans. Get one.

You will need a storage device for your Pi. The Pi comes with an integrated micro SD card slot so at a bare minimum you'll need a fast micro SD card. A micro SD card likely came with your Pi. That card is also likely not very good. Quality micro SD cards are expensive but are still limited in their access speed and durability. For the cost to performance ratio I always suggest purchasing an external SSD for your Pi. It is not complicated to set up. You'll be glad you did later.

Lastly and often overlooked is the power supply. You are going to need a good power supply. Your old IPhone charger is **NOT** a good power supply. In fact the offical Raspberry Pi power supply that delivers 3A is the minimum you should be looking for. It is hard to overstate how important your power supply will be to the final performance of your server. I run my servers on 4A power supplies.

## Log4j vulnerability

You may have heard in the news about a vulnerability in a piece of software called Log4j. There are countless pages of information on it found with a quick internet search so I will only briefly address it here. This vulnerability was actually first discovered by the Minecraft community and the entire community has been quick to resolve the vulnerability. **The latest version of the Minecraft client from Mojang and the latest version of the Paper server have been patched to these vulnerabilities.** Indeed even older versions have been patched but it is best to verify on an idividual basis the status of the patch if you are not using the latest software.