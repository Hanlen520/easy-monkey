# easy-monkey
monkey test script with integrated log filter, memory, CPU and reports.

1、什么是 Monkey？
Monkey 是谷歌官方的一个工具，内置在 Android 系统中。作用是给模拟器/设备上的应用发送伪随机的事件，例如点击、触摸或滑动，以及系统级的事件（back/home/menu等）。可以利用 Monkey 做安卓应用的压力测试。通过在应用上执行一大串各种类型的事件，模拟用户的无序操作，收集操作日志，从中获取应用 Crash/ANR 的 log。
关于 Monkey 的更多信息，请查看[谷歌官方文档](https://developer.android.com/studio/test/monkey)。

2、如何使用 Monkey 测试安卓应用？
（1）在电脑上打开模拟器/设备通过 USB 线连接至电脑
（2）将待测应用通过 adb install <package_name> 命令安装进模拟器/设备
（3）在终端（Terminal）上输入命令执行脚本：sh +x easy_monkey.sh <package_name>
（4）大概一小时后，monkey 脚本即运行结束，终端上会显示运行结果/报告

3、运行环境要求
- macOS 系统
- Python 2.7

4、Monkey 运行示例
- 手机连接电脑
- 安装应用：adb install <package_name>
- 执行脚本：sh +x easy_monkey.sh <package_name>

5、报告
- Monkey 脚本运行在终端上的结果是一份总体的报告
- 总体报告中的“内存信息请看”部分的地址指向一份 Monkey 运行过程中获取到的应用内存占用统计表，可以通过 Excel 软件将表中数据转成折线图形式展示
- 报告中的信息包含：Crash/ANR、CPU 占有率、内存等等

6、功能
- 获取和展示手机型号和分辨率信息
- 获取和展示应用包名和版本号
- 显示开始时间和结束时间
- 显示 Monkey 跑完后 10 分钟的 CPU 走势
- Log 信息过滤
- 显示 Monkey 从开始到结束后半小时的内存走势
