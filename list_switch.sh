MODDIR=${0%/*}
find /sys/*/* -type f -iname "input_suspend" -o -type f -iname "*disable*_charge*" -o -type f -iname "*charge*_disable*" -o -type f -iname "*disable*_charging*" -o -type f -iname "*stop_charge*" -o -type f -iname "*stop_charging*" | egrep -i -v 'limit|max|float|step|reverse' | sed -n 's/$/,start=0,stop=1/g;p' > "$MODDIR/list_switch"
find /sys/*/* -type f -iname "*charging_enable*" -o -type f -iname "*enable*_charge*" -o -type f -iname "*charge*_enable*" -o -type f -iname "*enable*_charging*" -o -type f -iname "*charge*_control*" -o -type f -iname "*charging*_state*" | egrep -i -v 'limit|prohibit|prevent|disable|stop|restrict|reverse|max|float|step' | sed -n 's/$/,start=1,stop=0/g;p' >> "$MODDIR/list_switch"
find /sys/*/* -type f -iname "*charging_enable*" -o -type f -iname "*enable*_charge*" -o -type f -iname "*charge*_enable*" -o -type f -iname "*enable*_charging*" -o -type f -iname "*charge*_control*" | egrep -i 'prohibit|prevent|disable|stop|restrict' | egrep -i -v 'limit|max|float|step|reverse' | sed -n 's/$/,start=0,stop=1/g;p' >> "$MODDIR/list_switch"
# ##
