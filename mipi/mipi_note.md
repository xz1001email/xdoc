### 传输模式

LP（Low-Power） 模式：用于传输控制信号，最高速率 10 MHz
HS（High-Speed）模式：用于高速传输数据，速率范围 [80 Mbps， 1Gbps] per Lane
传输的最小单元为 1 个字节，采用小端的方式及 LSB first，MSB last。

Lane States
LP mode 有 4 种状态： LP00、LP01（0）、LP10（1）、LP11 （Dp、Dn）
HS mode 有 2 种状态： HS-0、HS-1
HS 发送器发送的数据 LP 接收器看到的都是 LP00。

### Lane Levels

LP：0~1.2V
HS： 100 ~ 300mV，HS common level = 200mV，swing = 200 mv

### 操作模式

#### clk lane

mipi csi clk 存在两种工作模式，一种是连续时钟模式，传输过程不会切换 LP 状态；
另一种是非连续时钟信号模式，每传输完一帧图像数据，帧 blanking 时将会切换为 LP 状态。
时序图：

![](/home/xiao/work/repo/git-config/mipi/image/LP_TO_HS.png)

从时序图可以看到，clk lane 也会有一个 LP11→LP01→LP00 的时序，从而进入 HS 模式。
如果是连续时钟信号模式，在 sensor 传输的图像数据的过程，帧间隔时，clk lane 不会切换到 LP 状态，即 LP11→LP01→LP00 时序只有一次；
如果是非连续时钟信号模式，每传输完一帧图像数据，都将会从 HS 模式切换回 LP 模式，在传输下一帧图像数据时，再从 LP 模式进入 HS 模式；
如果 camera sensor mipi clk lane 支持非连续时钟模式，建议配置为非连续时钟模式。

#### data lane

在数据线上有 3 种可能的操作模式：Escape mode, High-Speed (Burst) mode and Control mode，下面是从停止状态进入相应模式需要的时序：

Escape mode
进入时序：LP11→LP10→LP00→LP01→LP00
退出时序：LP10→LP11
High-Speed mode
进入时序：LP11→LP01→LP00→SoT(0001_1101)
退出时序：EoT→LP11
时序图如下：
![](/home/xiao/work/repo/git-config/mipi/image/HS_MODE.png)

#### Turnaround

进入时序：LP11→LP10→LP00→LP10→LP00
退出时序：LP00→LP10→LP11

### 时序要求

在调试 DSI 或者 CSI 的时候， HS mode 下的几个时序非常重要：T_LPX，T_HS-SETTLE ≈ T_HS-PREPARE + T_HS-ZERO，T_HS-TRAIL，一般遵循的原则为：Host 端的 T_HS-SETTLE > Slave 端的 T_HS-SETTLE。
![](/home/xiao/work/repo/git-config/mipi/image/HS_MODE_PARA.png)



### 接收器是如何判断数据将要开始传输了呢？

当出现LP11→LP01→LP00时，接收器将会判断，将会有数据达到，同时，使用示波器查看mipi波形，将会发现在PL00（THS-PREPARE）时会有一个小脉冲（峰刺），一般的，在这个小脉冲之后，接收器将会打开比较器（由于在THS-PREPARE会有这个小脉冲的存在，所以在接收器中，会通过设置接收器的settle time，避开这个小脉冲，在这个脉冲之后再打开比较器），准备接收数据。而HS-00011101则表示有效数据开始，同时数据的开头，将会有数据表明将要数据的数据量，所以mipi接收器将会按其数据量接收，直到接收完成。
每根 lane（data lane/clk lane）从 LP 模式切换到 HS 模式都会有 LP11→LP01→LP00 这样的一个时序，同时还要检查 HS-00011101 ，HS-00011101 主要是用于同步，只有前面正确采集到 00011101 ，才能保证 clk 和 data 相位一一对应。

### mipi csi调试：

测量 sensor 有相应的 mipi 信号输出，但是主控并没有接收到数据，通过查看主控的 mipi 寄存器发现，mipi接收器还处于 LP 模式，这种情况一般是mipi没有检测到sensor发送的从 LP 进入 HS 的时序。此时可测量sensor 开始输出图像数据时，clk lane 是否有 LP11→LP01→LP00 这样的一个时序。同时，应该先开 mipi，sensor 再开始 mipi 数据传输
由于THS-PREPARE会有一个小脉冲的存在，所以，主控在接收mipi数据的时候，需要通过设置主控的settle time，这个时间需要在这个小脉冲之后，这样接收才不会有问题
当出现 sensor 有数据输出，但是主控没有接收成功，这个情况一般是 mipi 的时序问题，sensor 端的时序没有和主控端的配合好，这个时候，可以尝试的减小sensor端的THS-PREPARE，增大THS-ZERO和THS-TRAIL
由于一些主控的需求，在一帧数据完成之后，需要一定的时间才可以进行相应的ISP处理，当一帧传输完毕之后的LP11时间达不到主控ISP的时间要求导致ISP报错，可通过调节THS-TRAIL时间，以此得到ISP对帧间的时序长度要求