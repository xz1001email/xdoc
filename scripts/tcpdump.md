## 命令list

### 限制ip包长[40-200]抓包

`tcpdump -i eth0 -nn -X -v 'dst port 8888 && ip[2:2]<200 && ip[2:2]>40'`

