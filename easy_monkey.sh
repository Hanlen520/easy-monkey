#!/usr/bin/env bash
# Author: Shengjie.Liu
# Date: 2019-05-14
# Version: 3.3
# Description: script of monkey
# How to use: sh +x easy_monkey.sh <package_name>

function init_data() {
    if [[ ! -d ${OUTPUT} ]]; then
        mkdir -p ${OUTPUT}
    fi
    if [[ ! -d ${CURRENT_OUTPUT} ]]; then
        mkdir -p ${CURRENT_OUTPUT}
    fi
    if [[ ! -d ${TEMP_FILE} ]]; then
        mkdir -p ${TEMP_FILE}
    fi
    touch ${OUTPUT_RESULT}
    touch ${CPUINFO_FILE}
    touch ${CPUTIME_FILE}
    touch ${CPUINFO_CSV}
    touch ${CPUINFO_BK_CSV}
}

# process id
function getPid() {
    adb shell ps | grep ${1} | tr -d $'\r' | awk '{print $2}' | head -n 1
}

# cpu kernel
function getCpuKer() {
    adb shell cat /proc/cpuinfo | grep "processor" > ${TEMP_FILE}/processor_count
    cpu_ker_count=`awk 'END{print NR}' ${TEMP_FILE}/processor_count`
    echo ${cpu_ker_count}
}

# process cpu time
function processCpuTime() {
    adb shell cat /proc/${1}/stat > ${TEMP_FILE}/process_cpu_time
    utime=$(cat ${TEMP_FILE}/process_cpu_time | awk '{print $14}')
    stime=$(cat ${TEMP_FILE}/process_cpu_time | awk '{print $15}')
    cutime=$(cat ${TEMP_FILE}/process_cpu_time | awk '{print $16}')
    cstime=$(cat ${TEMP_FILE}/process_cpu_time | awk '{print $17}')
    result=`expr ${utime} + ${stime} + ${cutime} + ${cstime}`
    echo ${result}
}

# total cpu time
function totalCpuTime() {
    adb shell cat /proc/stat > ${TEMP_FILE}/total_cpu_time
    cat ${TEMP_FILE}/total_cpu_time | grep "cpu" | head -n 1 > ${TEMP_FILE}/total_cpu
    user=$(cat ${TEMP_FILE}/total_cpu | awk '{print $2}')
    nice=$(cat ${TEMP_FILE}/total_cpu | awk '{print $3}')
    system=$(cat ${TEMP_FILE}/total_cpu | awk '{print $4}')
    idle=$(cat ${TEMP_FILE}/total_cpu | awk '{print $5}')
    iowait=$(cat ${TEMP_FILE}/total_cpu | awk '{print $6}')
    irq=$(cat ${TEMP_FILE}/total_cpu | awk '{print $7}')
    softirq=$(cat ${TEMP_FILE}/total_cpu | awk '{print $8}')
    result=`expr ${user} + ${nice} + ${system} + ${idle} + ${iowait} + ${irq} + ${softirq}`
    echo ${result}
}

# cpu usage rate
function getCpuRate() {
    process_cpu_time1=`processCpuTime ${1}`
    total_cpu_time1=`totalCpuTime`
    sleep 1s
    process_cpu_time2=`processCpuTime ${1}`
    total_cpu_time2=`totalCpuTime`
    process_cpu_time3=$(( ${process_cpu_time2} - ${process_cpu_time1} ))
    total_cpu_time3=$(( ${total_cpu_time2} - ${total_cpu_time1} ))
    cpu_rate=$(bc <<< "scale=3;(${process_cpu_time3}/${total_cpu_time3})*${2}*100")
    result=$(echo "scale=0;${cpu_rate}/1" | bc -l)
    echo ${result}
}

# 通过关键字"FATAL"筛选log文件
function fatal_filter() {
    grep -A 2 "FATAL" < log.txt > fatalfilter
    grep $1 < fatalfilter > pkgfilter
    grep -C 1 $1 < fatalfilter > fatal_result
}

# 添加空行
function addEmptyLines() {
    echo | tee -a ${OUTPUT_RESULT}
}

# 输出内存csv文件
function report_with_colon() {
    sh +x report.sh ${1}
    mv logs/csv/t_u.csv ${2}/meminfo.csv
    rm -r logs
}

# Same as above
function report_without_colon() {
    sh +x report_no_colon.sh ${1}
    mv logs/csv/t_u.csv ${2}/meminfo.csv
    rm -r logs
}

# 调用report脚本，输出csv文件
function report_memory_info() {
    TOTAL_TIME=$(cat ${1} | grep "TOTAL:" -c)
    if [[ ${TOTAL_TIME} != 0 ]]; then
        report_with_colon ${1} ${2}
    else
        report_without_colon ${1} ${2}
    fi
}

WORKSPACE=`pwd`
OUTPUT=${WORKSPACE}/output_monkey
CURRENT_TIME=`date +%Y%m%d%H%M`
#monkey seed value
SEED_VALUE=${CURRENT_TIME}
# output directory
CURRENT_OUTPUT=${OUTPUT}/${CURRENT_TIME}
# monkey report
OUTPUT_RESULT=${CURRENT_OUTPUT}/result_monkey.txt
# temporary folder
TEMP_FILE=${CURRENT_OUTPUT}/temp
# CPU file
CPUINFO_FILE=${TEMP_FILE}/cpuinfo.txt
CPUTIME_FILE=${TEMP_FILE}/cputime.txt
# CSV file
CPUINFO_CSV=${CURRENT_OUTPUT}/cpuinfo.csv
CPUINFO_BK_CSV=${TEMP_FILE}/cpuinfo_bk.csv

# initialize folder and file
init_data

# phone info(brand/model/system version)
brand=$(adb shell getprop ro.product.brand | sed 's/ //g' | tr -d $'\r')
model=$(adb shell getprop ro.product.model | sed 's/ //g' | tr -d $'\r')
release=$(adb shell getprop ro.build.version.release | sed 's/ //g' | tr -d $'\r')
release_one=$(echo ${release} | awk -F. '{print $1}')

# screen resolution/density
if [[ ${release_one} > 4 ]]; then
	density=$(adb shell wm density | tr -d $'\r' | awk '{print $3}')
	size=$(adb shell wm size | tr -d $'\r' | awk '{print $3}')
	display="${size}/${density}dpi"
else
	size=`adb shell dumpsys window displays | grep "init" | tr -d $'\r' | awk '{print $1}' | cut -d"=" -f 2`
	density=`adb shell dumpsys window displays | grep "init" | tr -d $'\r' | awk '{print $2}'`
	display="${size}/${density}"
fi

echo "手机型号：${brand} ${model} ${release} ${display}" | tee -a ${OUTPUT_RESULT}

package_name=${1}
echo "应用包名：${package_name}" | tee -a ${OUTPUT_RESULT}

version=$(adb shell dumpsys package ${package_name} | grep versionName | sed 's/ //g' | tr -d $'\r' | cut -d"=" -f 2)
echo "应用版本：${version}" | tee -a ${OUTPUT_RESULT}
echo "Monkey Seed Value: ${SEED_VALUE}" | tee -a ${OUTPUT_RESULT}

echo "开始时间：`date "+%Y-%m-%d %H:%M:%S"`" | tee -a ${OUTPUT_RESULT}
# 在所有界面隐藏状态栏和导航栏
adb shell settings put global policy_control immersive.full=*

# 未设置各类型事件百分比
# adb shell monkey -p ${package_name} --ignore-crashes --ignore-timeouts --ignore-security-exceptions \
# -s 1024 --throttle 200 -v ${extime} 1>${CURRENT_OUTPUT}/monkey_log.txt 2>${CURRENT_OUTPUT}/error.txt

## 设置各类型事件百分比
#adb shell monkey -p ${package_name} --pct-touch 40 --pct-motion 25 --pct-appswitch 10 --pct-rotation 5 \
#--ignore-crashes --ignore-timeouts --ignore-security-exceptions \
#-s 1024 --throttle 200 -v ${extime} 1>${CURRENT_OUTPUT}/monkey_log.txt 2>${CURRENT_OUTPUT}/error.txt

# 调用python脚本，执行adb shell monkey命令，同时抓取cpu和memory的信息
python monkey.py ${package_name} ${SEED_VALUE}
# restart adb server
adb start-server
echo "结束时间：`date "+%Y-%m-%d %H:%M:%S"`" | tee -a ${OUTPUT_RESULT}
# 恢复状态栏和导航栏的显示
adb shell settings put global policy_control null

sleep 5s
# screen shot after the monkey done
adb exec-out screencap -p > ${CURRENT_OUTPUT}/end.png

# quit this app, back to home
count=1
while (( ${count}<=10 )); do
    adb shell input keyevent 4
    let "count++"
done
# press home key in case of back key that didn't work
adb shell input keyevent 3

echo "正在获取内存TOTAL值和CPU使用率..."
# monkey跑完后的3、5、10分钟各取一次cpu值，超过40%可到输出文件夹里查看allcpuinfo.txt文件以排查问题
# process id
pid=`getPid ${package_name}`
# cpu kernel
cpu_ker=`getCpuKer`
# start dump cpn usage rate
echo "TIME FLAG:"  `date "+%Y-%m-%d %H:%M:%S"` >> ${CPUTIME_FILE}
cpuinfo=`getCpuRate ${pid} ${cpu_ker}`
echo ${cpuinfo} >> ${CPUINFO_FILE}
#monkey跑完后的30分钟，记录内存TOTAL值
int=0
while(( $int<=29 ))
do
    case ${int} in
    3)  echo "TIME FLAG:"  `date "+%Y-%m-%d %H:%M:%S"` >> ${CPUTIME_FILE}
        cpuinfo3=`getCpuRate ${pid} ${cpu_ker}`
        echo ${cpuinfo3} >> ${CPUINFO_FILE}
    ;;
    5)  echo "TIME FLAG:"  `date "+%Y-%m-%d %H:%M:%S"` >> ${CPUTIME_FILE}
        cpuinfo5=`getCpuRate ${pid} ${cpu_ker}`
        echo ${cpuinfo5} >> ${CPUINFO_FILE}
    ;;
    10)   echo "TIME FLAG:"  `date "+%Y-%m-%d %H:%M:%S"` >> ${CPUTIME_FILE}
          cpuinfo10=`getCpuRate ${pid} ${cpu_ker}`
          echo ${cpuinfo10} >> ${CPUINFO_FILE}
    ;;
    esac
    echo "TIME FLAG:"  `date "+%Y-%m-%d %H:%M:%S"` >> meminfo.txt
    adb shell dumpsys meminfo ${package_name} >> meminfo.txt
    sleep 60s
    let "int++"
done

echo "CPU走势：${cpuinfo}%（monkey结束时）-> ${cpuinfo3}%（3分钟后）-> ${cpuinfo5}%（5分钟后）-> ${cpuinfo10}%（10分钟后）" \
| tee -a ${OUTPUT_RESULT}

cat ${CPUTIME_FILE} | while read line
do
	echo ${line#*:} >> ${TEMP_FILE}/time
done

linecount=`awk 'END{print NR}' ${CPUINFO_FILE}`

echo "Time,Percent" > ${CPUINFO_CSV}
for ((j=1;j<=${linecount};j++));
do
    value_cpu=`tail -n ${j} ${CPUINFO_FILE} | head -n 1`
    time_cpu=`tail -n ${j} ${TEMP_FILE}/time | head -n 1`
    echo "${time_cpu},${value_cpu}" >> ${CPUINFO_BK_CSV}
done

line_count=`awk 'END{print NR}' ${CPUINFO_BK_CSV}`
for ((k=1;k<=${line_count};k++));
do
	total_line=`tail -n ${k} ${CPUINFO_BK_CSV} | head -n 1`
    echo "${total_line}" >> ${CPUINFO_CSV}
done

# delete temporary folder
rm -r ${TEMP_FILE}

# 生成内存CSV文件
report_memory_info meminfo.txt ${CURRENT_OUTPUT}

function showerror() {
    cat error.txt | grep "CRASH" | tee -a ${OUTPUT_RESULT}
    cat error.txt | grep "ANR" | tee -a ${OUTPUT_RESULT}
}
crashtime=$(cat error.txt | grep "CRASH" -c)
anrtime=$(cat error.txt | grep "ANR" -c)

function showmonkeylogcrash() {
    cat monkey_log.txt | grep "CRASH" | tee -a ${OUTPUT_RESULT}
}
monkeylogcrashtime=$(cat monkey_log.txt | grep "CRASH" -c)

fatal_filter ${package_name}
fataltime=$(cat pkgfilter | grep ${package_name} -c)

function showfatal() {
    cat fatal_result | tee -a ${OUTPUT_RESULT}
}

addEmptyLines
echo "分析结果：" | tee -a ${OUTPUT_RESULT}
echo "------------------------------------" | tee -a ${OUTPUT_RESULT}

echo "关键字 CRASH 共有 ${crashtime} 处（error.txt）" | tee -a ${OUTPUT_RESULT}
echo "关键字 ANR 共有 ${anrtime} 处（error.txt）" | tee -a ${OUTPUT_RESULT}
echo "关键字 CRASH 共有 ${monkeylogcrashtime} 处（monkey_log.txt）" | tee -a ${OUTPUT_RESULT}
echo "关键字 FATAL 共有 ${fataltime} 处（log.txt）" | tee -a ${OUTPUT_RESULT}

addEmptyLines
echo "崩溃日志：" | tee -a ${OUTPUT_RESULT}

if [[ ${crashtime} != 0 || ${anrtime} != 0 ]]; then
    showerror
    addEmptyLines
    echo "详细错误日志请查看 ${CURRENT_OUTPUT}/error.txt" | tee -a ${OUTPUT_RESULT}
elif [[ ${crashtime} == 0 && ${anrtime} == 0 && ${fataltime} != 0 ]]; then
    showfatal
    addEmptyLines
    echo "详细错误日志请查看 ${CURRENT_OUTPUT}/log.txt" | tee -a ${OUTPUT_RESULT}
elif [[ ${crashtime} == 0 && ${anrtime} == 0 && ${fataltime} == 0 && ${monkeylogcrashtime} != 0 ]]; then
    showmonkeylogcrash
    addEmptyLines
    echo "详细错误日志请查看 ${CURRENT_OUTPUT}/monkey_log.txt" | tee -a ${OUTPUT_RESULT}
else
    echo "无" | tee -a ${OUTPUT_RESULT}
    addEmptyLines
fi

echo "详细执行日志请查看 ${CURRENT_OUTPUT}/monkey_log.txt" | tee -a ${OUTPUT_RESULT}
echo "log日志请查看 ${CURRENT_OUTPUT}/log.txt" | tee -a ${OUTPUT_RESULT}
if [[ ${anrtime} != 0 ]]
then
# anr日志
adb pull /data/anr/traces.txt ${CURRENT_OUTPUT}
echo "anr日志请查看 ${CURRENT_OUTPUT}/traces.txt" | tee -a ${OUTPUT_RESULT}
fi
echo "cpu日志请查看 ${CPUINFO_CSV}" | tee -a ${OUTPUT_RESULT}
echo "内存信息请查看 ${CURRENT_OUTPUT}/meminfo.csv" | tee -a ${OUTPUT_RESULT}
echo "报告请查看 ${OUTPUT_RESULT}"

mv error.txt ${CURRENT_OUTPUT}
mv monkey_log.txt ${CURRENT_OUTPUT}
mv log.txt ${CURRENT_OUTPUT}
mv meminfo.txt ${CURRENT_OUTPUT}
mv allcpuinfo.txt ${CURRENT_OUTPUT}
# 如果log_add.txt存在，则移动到输出文件夹
if [[ -f log_add.txt ]]; then
    mv log_add.txt ${CURRENT_OUTPUT}
fi
rm fatalfilter
rm pkgfilter
rm fatal_result
