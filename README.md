# redmine_ejabberd
redmine的xmpp插件

## 部署方式

只部署聊天机器人
```
cd docker && docker-compose up
```

带redmine(后台插件部分记得配置url为http://chat:8080/)
```
cd docker && docker-compose -f docker-compse-with-redmine.yml up
```

## 聊天指令
* 和redmine（假设聊天机器人帐号的名字是这个)说: *redmine help* 机器人会告诉你如何使用
* 给虚心好学的同学: 看[Notifications的帮助](ruby/redmine_ejabberd_notifications/README.markdown)，里面的三种操作(添加，修改状态，创建问题)都已经实现了。

 
## 简介
前端时间，公司进来了不少新人，然后，简单的几个项目流程弄的一塌糊涂，然后我就搭建了个redmine来进行项目管理。为了更方便及时的转发消息，就安装了插件[Notifications](https://github.com/redmine-xmpp/notifications)，我们的内部聊天服务器使用的使ejabberd。

目的是很好，但配置上之后，出现各种故障，比如机器人莫名下线，大部分消息不发送出去，或者部分发送。我边学ruby边打补丁，花费了大量精力依然无法搞定，于是产生了另外写一个类似的插件。

这个插件分为两个部分，一部分是redmine标准的插件方式，使用ruby语言，放在ruby目录中，我几乎不会ruby语言，因此，简单的修改了Notifications的插件，去除无用的代码，仅保留通知相关的内容;另外一部分使用elixir语言，负责接收消息，转发消息等内容，是一个独立的聊天机器人程序。

整个操作的流程是这样的：如果在redmine进行了问题的提交等操作，则通过ruby语言的插件将内容转发到elixir语言的机器人程序上，这个机器人程序接收标准的http post消息(监听在8080端口)，由聊天机器人进行消息转发;而如果使通过聊天机器人来进行问题的更新等操作的话，聊天机器人在收到指定指令后，会进行解析并且使用redmine标准的rest api发送出去。

聊天指令格式和Notifications插件完全相同，但已经将相关缺失的指令部分实现了。至于不同的部分，对于项目名称，不仅仅支持使用标识，还支持使用名称，人员名称，可以使用对方登录的用户名，或者显示的名称，对于显示的名称，代码里默认使按照中国人的习惯来进行的，即lastname.firstname的格式,项目的状态只能使用问题状态显示出来的名字，这样会比使用1，2，3这样不知所云的状态id好些。

## 感谢

项目中使用了若干开源的代码，不一一列举，有些我也不知道是所什么用的，这里仅列出部分

* notifications  我使用的ruby代码和指令格式都是参照它的
* elixir  我用来写erlang的最爱，自从学了它，我几乎没有再使用erlang原生写代码了
* cowboy  项目里使用它来监听http请求，标准的服务
* hedwig   聊天机器人框架，我用的hedwig_xmpp是它的xmpp部分的接口，因此，如果我们添加上其他的对接部分，几乎可以快速支持其他的聊天软件

## 关于许可内容

项目自身内的代码，随便你用，想怎么改就怎么改，我也懒的理会。
