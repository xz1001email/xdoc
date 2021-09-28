# 多用户配置不同的ssh-key

## 1.用户配置

​	git config --global --unset user.name
​	git config --global --unset user.email
​	git config --local user.name xiaozhao
​	git config --local user.email xz1001e_mail@163.com

## 2.生成多个ssh-key

​	ssh-keygen -t rsa -C "xz1001e_mail@163.com"
​	ssh-keygen -t rsa -C "xz1001e_mail@126.com"

## 3.创建~/.ssh/config

​	vi ~/.ssh/config，HostName和Host都设置成域名或者IP，用户默认是git。指定对应的私钥文件，github放置对应的公钥id_rsa.pub
配置文件如下:
 Host 192.168.10.3
 HostName 192.168.10.3
 User git
 IdentityFile /home/xiao/.ssh/gitlab/id_rsa

 Host github.com
 HostName github.com
 User git
 IdentityFile /home/xiao/.ssh/github/id_rsa

### 测试：

#### 1.测试配置文件，通过HOST找对应的用户和密钥测试。
​	ssh -T github.com
​	ssh -T 192.168.10.3

#### 2.单独的密钥测试, 添加私钥到ssh-agent的缓冲区

​	ssh-add的方法也可以配置用户到对应的密钥，但是这临时的，重启需要重新设置。
 	ssh-add ~/.ssh/github/id_rsa
 	ssh -T git@github.com

