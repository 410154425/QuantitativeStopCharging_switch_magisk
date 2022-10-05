MODDIR=${0%/*}
config_conf="$(cat "$MODDIR/config.conf" | egrep -v '^#')"
dumpsys_battery="$(dumpsys battery)"
battery_level="$(cat '/sys/class/power_supply/battery/capacity')"
temperature="$(cat '/sys/class/power_supply/battery/temp' | cut -c '1-2')"
power_stop="$(echo "$config_conf" | egrep '^power_stop=' | sed -n 's/power_stop=//g;$p')"
power_start="$(echo "$config_conf" | egrep '^power_start=' | sed -n 's/power_start=//g;$p')"
temperature_switch="$(echo "$config_conf" | egrep '^temperature_switch=' | sed -n 's/temperature_switch=//g;$p')"
temperature_switch_stop="$(echo "$config_conf" | egrep '^temperature_switch_stop=' | sed -n 's/temperature_switch_stop=//g;$p')"
temperature_switch_start="$(echo "$config_conf" | egrep '^temperature_switch_start=' | sed -n 's/temperature_switch_start=//g;$p')"
off_qsc=0
if [ -f "$MODDIR/off_qsc" -o -f "$MODDIR/disable" ]; then
	off_qsc=1
	power_stop="110"
	power_start="105"
	temperature_switch="0"
fi
log_log=0
cpu_log=0
if [ ! -n "$battery_level" ]; then
	battery_level="$(echo "$dumpsys_battery" | egrep 'level: ' | sed -n 's/.*level: //g;$p')"
	if [ ! -n "$battery_level" ]; then
		echo "$(date +%F_%T) 无法获取电量，请联系作者适配" > "$MODDIR/log.log"
		sed -i 's/\[.*\]/\[ 无法获取电量，请联系作者适配 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		exit 0
	fi
fi
if [ ! -n "$temperature" ]; then
	temperature="$(echo "$dumpsys_battery" | egrep 'temperature: ' | sed -n 's/.*temperature: //g;$p' | cut -c '1-2')"
	if [ ! -n "$temperature" ]; then
		echo "$(date +%F_%T) 无法获取温度，请联系作者适配" > "$MODDIR/log.log"
		sed -i 's/\[.*\]/\[ 无法获取温度，请联系作者适配 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		exit 0
	fi
fi
if [ ! -f "$MODDIR/list_switch" ]; then
	if [ -f "$MODDIR/list_switch.sh" ]; then
		chmod 0755 "$MODDIR/list_switch.sh"
		"$MODDIR/list_switch.sh" > /dev/null 2>&1
		echo "$(date +%F_%T) 缺少列表文件，正在创建，请稍等" > "$MODDIR/log.log"
		exit 0
	else
		echo "$(date +%F_%T) list_switch.sh文件不存在，请重新安装模块重启" > "$MODDIR/log.log"
		exit 0
	fi
fi
dumpsys_charging="$(dumpsys deviceidle get charging)"
if [ "$dumpsys_charging" = "true" ]; then
	log_n="$(cat "$MODDIR/log.log" | wc -l)"
	if [ "$log_n" -gt "30" ]; then
		sed -i '1,5d' "$MODDIR/log.log" > /dev/null 2>&1
	fi
	if [ "$temperature_switch" = "1" ]; then
		if [ "$temperature_switch_stop" -gt "$temperature_switch_start" -a "$temperature" -ge "$temperature_switch_stop" ]; then
			touch "$MODDIR/temp_switch" > /dev/null 2>&1
			cpu_log=1
		fi
	fi
	if [ "$power_stop" -gt "$power_start" -a "$battery_level" -ge "$power_stop" ]; then
		switch_stop_mode=1
	fi
	if [ "$switch_stop_mode" = "1" -o "$cpu_log" = "1" ]; then
		if [ "$cpu_log" = "0" ]; then
			if [ ! -f "$MODDIR/power_switch" ]; then
				power_stop_time="$(echo "$config_conf" | egrep '^power_stop_time=' | sed -n 's/power_stop_time=//g;$p')"
				if [ "$power_stop_time" -gt "0" ]; then
					echo "$(date +%F_%T) 电量$battery_level 延时功能 继续充电$power_stop_time秒 倒计时中" >> "$MODDIR/log.log"
					sleep "$power_stop_time"
				fi
			fi
		fi
		sleep 5
		switch_list="$(cat "$MODDIR/list_switch")"
		switch_list="$switch_list /sys/class/power_supply/battery/batt_slate_mode,start=0,stop=1 /sys/class/power_supply/battery/store_mode,start=0,stop=1 /sys/class/power_supply/idt/pin_enabled,start=1,stop=0 /sys/kernel/debug/google_charger/chg_suspend,start=0,stop=1 /sys/kernel/debug/google_charger/chg_mode,start=1,stop=0 /proc/driver/charger_limit_enable,start=0,stop=1 /proc/driver/charger_limit,start=100,stop=1 /proc/mtk_battery_cmd/current_cmd,start=0_0,stop=0_1 /proc/mtk_battery_cmd/en_power_path,start=1,stop=0"
		for i in $switch_list ; do
			power_switch_route="$(echo "$i" | sed -n 's/,start=.*//g;$p')"
			if [ -f "$power_switch_route" ]; then
				chmod 0644 "$power_switch_route"
				power_switch_stop="$(echo "$i" | sed -n 's/.*,stop=//g;s/_/ /g;$p')"
				echo "$power_switch_stop" > "$power_switch_route"
				log_log=1
			fi
		done
		touch "$MODDIR/power_switch" > /dev/null 2>&1
		if [ "$log_log" = "1" ]; then
			if [ "$cpu_log" = "1" ]; then
				echo "$(date +%F_%T) 电量$battery_level 触发开关温控：停止充电 温度$temperature" >> "$MODDIR/log.log"
			else
				echo "$(date +%F_%T) 电量$battery_level 停止充电" >> "$MODDIR/log.log"
			fi
		fi
	fi
	if [ ! -f "$MODDIR/power_on" ]; then
		rm -f "$MODDIR/power_off" > /dev/null 2>&1
		touch "$MODDIR/power_on" > /dev/null 2>&1
		if [ "$off_qsc" = "1" ]; then
			sed -i 's/\[.*\]/\[ 模块已关闭 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		else
			sed -i 's/\[.*\]/\[ 充电中 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		fi
	fi
else
	if [ -f "$MODDIR/power_switch" ]; then
		if [ "$battery_level" -le "$power_start" -o -f "$MODDIR/temp_switch" ]; then
			if [ "$temperature_switch" = "1" -a -f "$MODDIR/temp_switch" ]; then
				if [ -n "$temperature_switch_start" -a "$temperature" -gt "$temperature_switch_start" ]; then
					exit 0
				else
					cpu_log=1
				fi
			fi
			sleep 5
			switch_list="$(cat "$MODDIR/list_switch")"
			switch_list="$switch_list /sys/class/power_supply/battery/batt_slate_mode,start=0,stop=1 /sys/class/power_supply/battery/store_mode,start=0,stop=1 /sys/class/power_supply/idt/pin_enabled,start=1,stop=0 /sys/kernel/debug/google_charger/chg_suspend,start=0,stop=1 /sys/kernel/debug/google_charger/chg_mode,start=1,stop=0 /proc/driver/charger_limit_enable,start=0,stop=1 /proc/driver/charger_limit,start=100,stop=1 /proc/mtk_battery_cmd/current_cmd,start=0_0,stop=0_1 /proc/mtk_battery_cmd/en_power_path,start=1,stop=0"
			for i in $switch_list ; do
				power_switch_route="$(echo "$i" | sed -n 's/,start=.*//g;$p')"
				if [ -f "$power_switch_route" ]; then
					chmod 0644 "$power_switch_route"
					power_switch_start="$(echo "$i" | sed -n 's/.*,start=//g;s/,stop=.*//g;s/_/ /g;$p')"
					echo "$power_switch_start" > "$power_switch_route"
					log_log=1
				fi
			done
			rm -f "$MODDIR/temp_switch" > /dev/null 2>&1
			rm -f "$MODDIR/power_switch" > /dev/null 2>&1
			if [ "$log_log" = "1" ]; then
				if [ "$cpu_log" = "1" ]; then
					echo "$(date +%F_%T) 电量$battery_level 触发开关温控：恢复充电 温度$temperature" >> "$MODDIR/log.log"
				else
					echo "$(date +%F_%T) 电量$battery_level 恢复充电" >> "$MODDIR/log.log"
				fi
			fi
		fi
	fi
	if [ ! -f "$MODDIR/power_off" ]; then
		rm -f "$MODDIR/power_on" > /dev/null 2>&1
		touch "$MODDIR/power_off" > /dev/null 2>&1
		if [ "$off_qsc" = "1" ]; then
			sed -i 's/\[.*\]/\[ 模块已关闭 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		else
			sed -i 's/\[.*\]/\[ 未充电 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		fi
	fi
fi
#version=2022100500
# ##
