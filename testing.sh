#!/system/bin/sh
#
#如发现模块BUG，执行此脚本文件，把结果截图给作者，谢谢！
#
MODDIR=${0%/*}
#----------
module_version="$(cat "$MODDIR/module.prop" | egrep 'version=' | sed -n 's/.*version=//g;$p')"
Host_version="$(cat "$MODDIR/qsc.sh" | egrep '^#version=' | sed -n 's/.*version=//g;$p')"
state="$(cat "$MODDIR/module.prop" | egrep '^description=' | sed -n 's/.*=\[//g;s/\].*//g;p')"
config_conf="$(cat "$MODDIR/config.conf" | egrep -v '^#')"
dumpsys_battery="$(dumpsys battery)"
battery_level="$(cat '/sys/class/power_supply/battery/capacity')"
temperature="$(cat '/sys/class/power_supply/battery/temp' | cut -c '1-2')"
power_stop="$(echo "$config_conf" | egrep '^power_stop=' | sed -n 's/power_stop=//g;$p')"
power_start="$(echo "$config_conf" | egrep '^power_start=' | sed -n 's/power_start=//g;$p')"
temperature_switch="$(echo "$config_conf" | egrep '^temperature_switch=' | sed -n 's/temperature_switch=//g;$p')"
temperature_switch_stop="$(echo "$config_conf" | egrep '^temperature_switch_stop=' | sed -n 's/temperature_switch_stop=//g;$p')"
temperature_switch_start="$(echo "$config_conf" | egrep '^temperature_switch_start=' | sed -n 's/temperature_switch_start=//g;$p')"
dumpsys_charging="$(dumpsys deviceidle get charging)"
#----------
echo ---------- 适配 ------------
dumpsys battery
echo "$state"
if [ -f "$MODDIR/power_on" ]; then
	power_on="1"
else
	power_on="0"
fi
if [ -f "$MODDIR/power_off" ]; then
	power_off="1"
else
	power_off="0"
fi
if [ -f "$MODDIR/power_switch" ]; then
	power_switch="1"
else
	power_switch="0"
fi
if [ ! -n "$battery_level" ]; then
	battery_level="$(echo "$dumpsys_battery" | egrep 'level: ' | sed -n 's/.*level: //g;$p')"
	if [ ! -n "$battery_level" ]; then
		echo "无法获取电量，请联系作者适配"
	fi
fi
if [ ! -n "$temperature" ]; then
	temperature="$(echo "$dumpsys_battery" | egrep 'temperature: ' | sed -n 's/.*temperature: //g;$p' | cut -c '1-2')"
	if [ ! -n "$temperature" ]; then
		echo "无法获取温度，请联系作者适配"
	fi
fi
echo "停止充电电量$power_stop,恢复充电电量$power_start,开关温控$temperature_switch,停止温度$temperature_switch_stop,恢复温度$temperature_switch_start,电量$battery_level,温度$temperature,power_on$power_on,power_off$power_off,power_switch$power_switch,充电状态$dumpsys_charging"
#----------
echo ---------- 搜索开关 ------------
switch_list="$(cat "$MODDIR/list_switch")"
switch_list="$switch_list /sys/class/power_supply/battery/batt_slate_mode,start=0,stop=1 /sys/class/power_supply/battery/store_mode,start=0,stop=1 /sys/class/power_supply/idt/pin_enabled,start=1,stop=0 /sys/kernel/debug/google_charger/chg_suspend,start=0,stop=1 /sys/kernel/debug/google_charger/chg_mode,start=1,stop=0 /proc/driver/charger_limit_enable,start=0,stop=1 /proc/driver/charger_limit,start=100,stop=1 /proc/mtk_battery_cmd/current_cmd,start=00,stop=01 /proc/mtk_battery_cmd/en_power_path,start=1,stop=0"
for i in $switch_list ; do
	power_switch_route="$(echo "$i" | sed -n 's/,start=.*//g;$p')"
	if [ -f "$power_switch_route" ]; then
		power_switch_data="$(cat "$power_switch_route")"
		power_list="$power_switch_route,$power_switch_data,$power_list"
	fi
done
echo "$power_list"
#----------
echo ---------- 机型 ------------
echo "module.$(echo $module_version | sed -n 's/ //g;$p'),version.$(echo $Host_version | sed -n 's/ //g;$p'),release.$(getprop ro.build.version.release | sed -n 's/ //g;$p'),sdk.$(getprop ro.build.version.sdk | sed -n 's/ //g;$p'),brand.$(getprop ro.product.brand | sed -n 's/ //g;$p'),model.$(getprop ro.product.model | sed -n 's/ //g;$p'),cpu.$(cat '/proc/cpuinfo' | egrep 'Hardware' | sed -n 's/.*://g;s/ //g;$p')"
# ##
