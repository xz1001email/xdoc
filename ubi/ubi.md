## UBI NOTE

- #### 层次关系

![](/home/xiao/work/repo/git-config/ubi/image/ubi.jpg)

- #### 烧写镜像

  1. ubifs.img 烧写建议使用ubiformat，可以保留erase count。

  2. 如果没有条件使用ubiformat，可以使用nandwrite，但是erase count也会擦除。

  3. flashcp 也会擦除erase count， 并且不会跳过坏块，当nand有坏块时不能正常工作。

  4. nand空白页的概念：所谓空白页，是指page和obb都是0xFF，只有在block erase的后，page和obb都是0xFF。当page中写入数据，带硬件ECC的nand会自动在obb生成ECC校验，即使写入page的数据全是0xFF，ECC也不会是0xFF。

  5. 使用nandwrite或者flashcp 可能带来一些问题，当写入ubi.img后，PEB中可能有些空白页，在烧录重启后ubifs会往里面写入一些数据。但是nandwrite 烧录的过程会把ubi.img中的空白也写入。导致ubifs第二次写这个page，显然nand page 第二次写入肯定会发生错误，应该只有erase后才能写入。

  6. 为了解决nandwrite 导致 page 二次写入的问题，可以在mkfs.ubifs 的时候使用 -F 标志，在超级块中写入标志，ubifs工作时将扫描flash，规避这个问题，但会导致第一次启动较慢。http://www.linux-mtd.infradead.org/faq/ubifs.html#L_free_space_fixup

  

参考1：http://www.linux-mtd.infradead.org/faq/ubifs.html#L_free_space_fixup

参考2：https://linuxlink.timesys.com/docs/wiki/engineering/HOWTO_Use_UBIFS

参考3：https://www.kernel.org/doc/html/latest/filesystems/ubifs.html#:~:text=UBI%20is%20a%20separate%20software%20layer%20which%20may,a%20higher%20level%20abstraction%20than%20a%20MTD%20device.