#!/sbin/sh
#####################
# Xray Customization
#####################
SKIPUNZIP=1
ASH_STANDALONE=1

# prepare xray execute environment
official_xray_link="https://github.com.cnpmjs.org/XTLS/Xray-core/releases"
download_xray_zip="/data/xray/run/xray-core.zip"

if [ $BOOTMODE ! = true ] ; then
    abort "! Please install in Magisk Manager"
fi

# download latest xray core from official link
ui_print "- Connect official xray download link."
if $(curl -V > /dev/null 2>&1) ; then
    command_judgment="true"
    latest_xray_version=`curl -k -s -I "${official_xray_link}/latest" | grep -i location | grep -o "tag.*" | grep -o "v[0-9.]*"`
elif $(wget --help > /dev/null 2>&1) ; then
    command_judgment="false"
    touch ${TMPDIR}/version
    wget --no-check-certificate -O ${TMPDIR}/version "${official_xray_link}/latest"
    latest_xray_version=`cat ${TMPDIR}/version | grep -o "tag.*" | grep -o "v[0-9.]*" | head -n1`
else
    abort "! Please install the busybox module and try again."
fi

if [ "${latest_xray_version}" = "" ] ; then
   abort "Error: Connect official xray download link failed."
fi

# Create working directory
ui_print "- Prepare xray execute environment."
mkdir -p /data/xray
mkdir -p /data/xray/dnscrypt-proxy
mkdir -p /data/xray/run
mkdir -p $MODPATH/scripts
mkdir -p $MODPATH/system/bin
mkdir -p $MODPATH/system/etc

ui_print "- Download latest xray core ${latest_xray_version}-${ARCH}"
case "${ARCH}" in
  arm)
    download_xray_link="${official_xray_link}/download/${latest_xray_version}/xray-linux-arm32-v7a.zip"
    ;;
  arm64)
    download_xray_link="${official_xray_link}/download/${latest_xray_version}/xray-linux-arm64-v8a.zip"
    ;;
  x86)
    download_xray_link="${official_xray_link}/download/${latest_xray_version}/xray-linux-32.zip"
    ;;
  x64)
    download_xray_link="${official_xray_link}/download/${latest_xray_version}/xray-linux-64.zip"
    ;;
esac

if [ ${command_judgment} == "true" ]; then
    curl "${download_xray_link}" -k -L -o "${download_xray_zip}"
else
    wget --no-check-certificate -O "${download_xray_zip}" "${download_xray_link}"
fi

if [ "$?" != "0" ] ; then
   abort "Error: Download xray core failed."
fi

# install xray execute file
ui_print "- Install xray core $ARCH execute files"
unzip -j -o "${ZIPFILE}" -x 'META-INF/*' -d $MODPATH >&2
tar -xf $MODPATH/xray.tar.xz -C $TMPDIR
mv $TMPDIR/xray/scripts/* $MODPATH/scripts
mv $TMPDIR/xray/bin/$ARCH/dnscrypt-proxy $MODPATH/system/bin
unzip -j -o "${download_xray_zip}" "geoip.dat" -d /data/xray
unzip -j -o "${download_xray_zip}" "geosite.dat" -d /data/xray
unzip -j -o "${download_xray_zip}" "xray" -d $MODPATH/system/bin

rm -rf $MODPATH/xray.tar.xz
rm -rf "${download_xray_zip}"
# copy xray data and config
ui_print "- Copy xray config and data files"
[ -f /data/xray/softap.list ] || \
echo "192.168.43.0/24" > /data/xray/softap.list
[ -f /data/xray/resolv.conf ] || \
mv $TMPDIR/xray/etc/resolv.conf /data/xray
mv $TMPDIR/xray/etc/config.json.template /data/xray
[ -f /data/xray/dnscrypt-proxy/dnscrypt-blacklist-domains.txt ] || \
mv $TMPDIR/xray/etc/dnscrypt-proxy/dnscrypt-blacklist-domains.txt /data/xray/dnscrypt-proxy
[ -f /data/xray/dnscrypt-proxy/dnscrypt-blacklist-ips.txt ] || \
mv $TMPDIR/xray/etc/dnscrypt-proxy/dnscrypt-blacklist-ips.txt /data/xray/dnscrypt-proxy
[ -f /data/xray/dnscrypt-proxy/dnscrypt-cloaking-rules.txt ] || \
mv $TMPDIR/xray/etc/dnscrypt-proxy/dnscrypt-cloaking-rules.txt /data/xray/dnscrypt-proxy
[ -f /data/xray/dnscrypt-proxy/dnscrypt-forwarding-rules.txt ] || \
mv $TMPDIR/xray/etc/dnscrypt-proxy/dnscrypt-forwarding-rules.txt /data/xray/dnscrypt-proxy
[ -f /data/xray/dnscrypt-proxy/dnscrypt-proxy.toml ] || \
mv $TMPDIR/xray/etc/dnscrypt-proxy/dnscrypt-proxy.toml /data/xray/dnscrypt-proxy
[ -f /data/xray/dnscrypt-proxy/dnscrypt-whitelist.txt ] || \
mv $TMPDIR/xray/etc/dnscrypt-proxy/dnscrypt-whitelist.txt /data/xray/dnscrypt-proxy
[ -f /data/xray/dnscrypt-proxy/example-dnscrypt-proxy.toml ] || \
mv $TMPDIR/xray/etc/dnscrypt-proxy/example-dnscrypt-proxy.toml /data/xray/dnscrypt-proxy
mv $TMPDIR/xray/etc/dnscrypt-proxy/update-rules.sh /data/xray/dnscrypt-proxy
[ -f /data/xray/config.json ] || \
cp /data/xray/config.json.template /data/xray/config.json
ln -s /data/xray/resolv.conf $MODPATH/system/etc/resolv.conf
# generate module.prop
ui_print "- Generate module.prop"
rm -rf $MODPATH/module.prop
touch $MODPATH/module.prop
echo "id=xray_for_magisk" > $MODPATH/module.prop
echo "name=Xray For Magisk" >> $MODPATH/module.prop
echo -n "version=" >> $MODPATH/module.prop
echo ${latest_xray_version} >> $MODPATH/module.prop
echo "versionCode=$(date +%Y%m%d)" >> $MODPATH/module.prop
echo "author=core:rprx" >> $MODPATH/module.prop
echo "description=Xray core with service scripts for Magisk" >> $MODPATH/module.prop

inet_uid="3003"
net_raw_uid="3004"
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm  $MODPATH/service.sh    0  0  0755
set_perm  $MODPATH/uninstall.sh    0  0  0755
set_perm  $MODPATH/scripts/start.sh    0  0  0755
set_perm  $MODPATH/scripts/xray.inotify    0  0  0755
set_perm  $MODPATH/scripts/xray.service    0  0  0755
set_perm  $MODPATH/scripts/xray.tproxy     0  0  0755
set_perm  $MODPATH/scripts/dnscrypt-proxy.service   0  0  0755
set_perm  $MODPATH/system/bin/xray  ${inet_uid}  ${inet_uid}  0755
set_perm  /data/xray                ${inet_uid}  ${inet_uid}  0755
set_perm  $MODPATH/system/bin/dnscrypt-proxy ${net_raw_uid} ${net_raw_uid} 0755
