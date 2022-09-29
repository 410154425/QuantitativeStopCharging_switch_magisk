until [ -d "${0%/*}/" ] ; do
	sleep 5
done
sleep 5
MODDIR=${0%/*}
chmod 0755 "$MODDIR/up"
chmod 0755 "$MODDIR/qsc_switch.sh"
chmod 0755 "$MODDIR/upqsc.sh"
chmod 0755 "$MODDIR/list_switch.sh"
chmod 0755 "$MODDIR/testing.sh"
chmod 0644 "$MODDIR/config.conf"
sleep 1
up=1
echo "#执行该脚本，跳转微信网页给作者投币捐赠" > "$MODDIR/.投币捐赠.sh"
echo "am start -n com.tencent.mm/.plugin.webview.ui.tools.WebViewUI -d https://payapp.weixin.qq.com/qrpay/order/home2?key=idc_CHNDVI_dHFNbTNZIWMMKIEdzUZtCA-- >/dev/null 2>&1" >> "$MODDIR/.投币捐赠.sh"
echo "echo \"\"" >> "$MODDIR/.投币捐赠.sh"
echo "echo \"正在跳转QSC定量停充捐赠页面，请稍等。。。\"" >> "$MODDIR/.投币捐赠.sh"
chmod 0755 "$MODDIR/.投币捐赠.sh"
"$MODDIR/list_switch.sh" > /dev/null 2>&1
rm -f "$MODDIR/power_on" > /dev/null 2>&1
rm -f "$MODDIR/power_off" > /dev/null 2>&1
while :; do
if [ "$up" = "20" -o "$up" = "7200" ]; then
	"$MODDIR/up" > /dev/null 2>&1 &
	up=21
fi
"$MODDIR/qsc_switch.sh" > /dev/null 2>&1
up="$(( $up + 1 ))"
sleep 3
done
