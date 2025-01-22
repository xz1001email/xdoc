## **CAN帧类型**

![](/home/xiao/repo/xdoc/can/can_frame.png)



## **数据帧**

 ![](/home/xiao/repo/xdoc/can/data_frame.png)

## **远程帧**

 ![](/home/xiao/repo/xdoc/can/remote_frame.png)



## **字段解析**

![](/home/xiao/repo/xdoc/can/frame_parse.png)



## **CAN总线的仲裁过程**

![](/home/xiao/repo/xdoc/can/can_abitration.png)

## **电平**

![](/home/xiao/repo/xdoc/can/can_level.png)

1. CAN的显性和隐形的定义
2. 因为CAN总线上有很多设备，且采用 & 的关系来决定高低。所以当一个设备为低时，其他设备为高，&之后，这个电平就能凸显出来。
3. 所以0是显性电平、1是隐形电平
4. 远程帧中的SRR永远是1, 这保证了标准帧远程帧比扩展帧的远程帧有更高的优先级