# -*- coding: UTF-8 -*-
from time import sleep
import os
from threading import *
import sys
import time

# version: 20190514
# 此脚本用作：
#   1、执行adb shell monkey命令
#   2、执行adb logcat命令
#   3、执行adb shell dumpsys命令
#   4、执行adb shell top命令

packageName = ""
seedValue = ""


class MyThread(Thread):
    def __init__(self, func, args, name):
        super(MyThread, self).__init__()
        self.func = func
        self.args = args
        self.name = name

    def run(self):
        # print "Starting" + self.name + time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
        self.func(*self.args)
        # print "Exiting" + self.name + time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())


# Before running monkey, clear the log in the phone
def clearLogcat():
    os.popen("adb logcat -c")


# Get logs when monkey test is running
def logcat():
    os.popen('adb logcat -v time > log.txt')


# Run monkey test command
def runmonkey():
    os.popen('adb shell monkey -p %s '
             '--pct-touch 40 --pct-motion 20 --pct-appswitch 10 --pct-rotation 5 --pct-syskeys 5 '
             '--ignore-crashes --ignore-timeouts --ignore-security-exceptions --ignore-native-crashes -s %s '
             '--throttle 200 -v -v -v 5400 '
             '1>monkey_log.txt 2>error.txt' % (packageName, seedValue))


# Kill adb process
# then dumpMemoryInfo thread, dumpCpuInfo thread and adb logcat thread are stop too.
def killadb():
    os.popen('adb kill-server')


# Dump memory information where monkey test is running
# 1 per 60 seconds
def dumpMemoryInfo():
    os.popen('echo "TIME FLAG:"  `date "+%Y-%m-%d %H:%M:%S"` >> meminfo.txt')
    os.popen('adb shell dumpsys meminfo %s >> meminfo.txt' % packageName)
    sleep(60)


# dump cpu infomation where monkey test is running
def dumpCpuInfo():
    os.popen('echo "TIME FLAG:"  `date "+%Y-%m-%d %H:%M:%S"` >> allcpuinfo.txt')
    os.popen('adb shell top -n 1 >> allcpuinfo.txt')
    os.popen('echo "" >> allcpuinfo.txt')


def main():
    global t2
    clearLogcat()
    # 开一个抓取log的线程
    t = MyThread(logcat, (), logcat.__name__)
    t.start()
    for i in range(0, 9):
        # 开一个跑monkey的线程
        t2 = MyThread(runmonkey, (), runmonkey.__name__)
        t2.start()
        # 当monkey在跑时，拉内存和CPU的数据
        while t2.isAlive():
            dumpMemoryInfo()
            dumpCpuInfo()
    if not t2.isAlive():
        # 判断log抓取的线程是否活着。若活着，则通过线程t3断掉；若死了，则补充抓取log
        if not t.isAlive():
            os.popen('adb logcat -d -v long "AndroidRuntime:E" "*:S" > log_add.txt')
        t3 = MyThread(killadb, (), killadb.__name__)
        t3.start()


if __name__ == "__main__":
    packageName = sys.argv[1]
    seedValue = sys.argv[2]
    main()
