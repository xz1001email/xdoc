# git list

## git clone
```
git clone repo
git clone --depth repo
```

### git stash
```
#仅暂存修改，不暂存缓冲区
git stash -k

```

### git config 

```
git config --global user.name "xiao"
git config --global user.email "xiao@163.com"

```

### git ssh key
```
#add sshkey and copy to github
#then cp id_rsa.pub to github
cd ~
ssh-keygen -t rsa -C "email@163.com"
cd ~/.ssh
ssh-add id_rsa

#test ssh key
ssh -T git@github.com
```

### create repo
```
git init .
echo "gitstart" >README.md
git add README.md
git commit -m "fisrt commit"
```
### down respo from github
```
git clone git@github.com:xxx/vimrc.git

```

### push to github
```
git remote add origin "git@github.com:xxx/vimrc.git"
git push -u origin master

git remote add origin git@github.com:xz1001email/msgpack.git
git push -u origin master

```

### recover version before
``` 
#find commit id
git log 
git reset --hard e7a5e492c742a7b68c07f124edd4b713122c0666

```

### update local repo from remote
```
git fetch
git pull
```

### 修改最后一次提交用户名
```
git config --global user.name "Your Name"
git config --global user.email you@example.com
git commit --amend --reset-author

```

### 分支
```
#拉取分支
git remote show origin
git fetch origin

#检出远程分支
git checkout -b feature-fpga origin/feature-fpga

#合并分支
git merge up/feature-fpga

```

### submodule
```
#将一个单独的repo作为当前repo的子模块
git submodule add -b GD_NAND_512 ssh://git@192.168.50.50:10022/system/genius_tools.git
#多出2个文件，直接提交就锁定的子模块的commit

#clone一个带有submodule的repo有2中方式
#方式1
git clone repo --recurse-submodules

#方式2
git submodule init
git submodule update

#submodule的repo和正常的repo一样，单独自己维护, 该repo也并不清楚自己是别人的子模块
#主模块只管理子模块的commit，从而锁定总版本的commit

```




