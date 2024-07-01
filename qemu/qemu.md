
### start kernel
```
#test run kernel
qemu-system-aarch64 -M virt -cpu cortex-a53 -kernel arch/arm64/boot/Image.gz -nographic -append "console=ttyAMA0"
```
### gdb kernel
```
# -s              shorthand for -gdb tcp::1234
# -S              freeze CPU at startup (use 'c' to start execution)
qemu-system-aarch64 -M virt -cpu cortex-a53 -kernel arch/arm64/boot/Image.gz -s -S -nographic -append "console=ttyAMA0"

#start gdb
/usr/local/linaro-aarch64-2018.08-gcc8.2/./bin/aarch64-linux-gnu-gdb
(gdb) file vmlinux           
(gdb) target remote :1234
(gdb) break start_kernel     # 有些文档建议使用 hb 硬件断点，我在本地测试使用 break 也是 ok 的
(gdb) c   					 # 启动调试，则内核会停止在 start_kernel 函数处

```

### qemu exit
```
qemu don't support ctrl+c

# exit qemu like this
ctrl + a
c
q

```
