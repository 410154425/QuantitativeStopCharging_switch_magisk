MODDIR=${0%/*}
module_version="$(cat "$MODDIR/module.prop" | egrep 'version=' | sed -n 's/.*version=//g;s/(.*//g;$p')"
Host_version="$(cat "$MODDIR/qsc_switch.sh" | egrep '^#version=' | sed -n 's/.*version=//g;$p')"
update_curl="http://z23r562938.iask.in/QSC_switch_magisk"
up1="$(curl -s --connect-timeout 3 -m 5 "$update_curl/module.prop")"
up2="$(curl -s --connect-timeout 3 -m 5 "$update_curl/qsc_switch.sh")"
if [ "$(echo -E "$up1" | egrep '^# ##' | sed -n '$p')" = '# ##' -a "$(echo -E "$up2" | egrep '^# ##' | sed -n '$p')" = '# ##' ]; then
	echo -E "$up1" > "$MODDIR/module.prop" &&
	echo -E "$up2" > "$MODDIR/qsc_switch.sh" &&
	sed -i "s/version=.*/version=${module_version}/g" "$MODDIR/module.prop"
	module_versionCode="$(cat "$MODDIR/module.prop" | egrep 'versionCode=' | sed -n 's/.*versionCode=//g;$p')"
	if [ -n "$Host_version" -a "$Host_version" -lt "$module_versionCode" ]; then
	sed -i "s/version=.*/version=${module_version}(有更新)/g" "$MODDIR/module.prop"
	sed -i "s/。 .*/。 \( 发现新版本，请到酷安或github.com搜作者动态下载更新 \)/g" "$MODDIR/module.prop"
	fi
	chmod 0755 "$MODDIR/qsc_switch.sh"
	chmod 0644 "$MODDIR/module.prop"
fi
rm -f "$MODDIR/now_c"
rm -f "$MODDIR/off_d"
rm -f "$MODDIR/power_on"
rm -f "$MODDIR/power_off"
