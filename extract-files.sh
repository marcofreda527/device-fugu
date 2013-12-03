#!/bin/bash

# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SOC=sp7710ga
GONK=gonk
DEVICE=${SOC}_${GONK}
COMMON=common
MANUFACTURER=sprd

if [[ -z "${ANDROIDFS_DIR}" && -d ../../../backup-${DEVICE}/system ]]; then
    ANDROIDFS_DIR=../../../backup-${DEVICE}
fi

if [[ ! -d ../../../backup-${DEVICE}/system  && -z "${ANDROIDFS_DIR}" ]]; then
    echo Backing up system partition to backup-${DEVICE}
    mkdir -p ../../../backup-${DEVICE} &&
    adb pull /system ../../../backup-${DEVICE}/system
fi

if [[ -z "${ANDROIDFS_DIR}" ]]; then
    echo Pulling files from device
    DEVICE_BUILD_ID=`adb shell cat /system/build.prop | grep ro.build.display.id | sed -e 's/ro.build.display.id=//' | tr -d '\n\r'`
else
    echo Pulling files from ${ANDROIDFS_DIR}
    DEVICE_BUILD_ID=`cat ${ANDROIDFS_DIR}/system/build.prop | grep ro.build.display.id | sed -e 's/ro.build.display.id=//' | tr -d '\n\r'`
fi

BASE_PROPRIETARY_DEVICE_DIR=vendor/$MANUFACTURER/proprietories/$SOC
PROPRIETARY_DEVICE_DIR=../../../vendor/$MANUFACTURER/proprietories/$SOC

echo BASE_PROPRIETARY_DEVICE_DIR=$BASE_PROPRIETARY_DEVICE_DIR
echo PROPRIETARY_DEVICE_DIR=$PROPRIETARY_DEVICE_DIR

mkdir -p $PROPRIETARY_DEVICE_DIR
PROPRIETARY_BLOBS_LIST=$PROPRIETARY_DEVICE_DIR/vendor-blobs.mk

for NAME in audio hw wifi etc egl etc lib bin xbin usr scripts system/lib system/bin
do
    mkdir -p $PROPRIETARY_DEVICE_DIR/$NAME
done

(cat << EOF) | sed s/__COMMON__/$COMMON/g | sed s/__MANUFACTURER__/$MANUFACTURER/g > $PROPRIETARY_BLOBS_LIST
# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Prebuilt libraries that are needed to build open-source libraries

# All the blobs
PRODUCT_COPY_FILES += \\
EOF

# copy_file
# pull file from the device and adds the file to the list of blobs
#
# $1 = src name
# $2 = dst name
# $3 = directory path on device
# $4 = directory name in $PROPRIETARY_DEVICE_DIR
copy_file()
{
    echo Pulling \"$1\"
    if [[ -z "${ANDROIDFS_DIR}" ]]; then
        adb pull /$3/$1 $PROPRIETARY_DEVICE_DIR/$4/$2
    else
           # Hint: Uncomment the next line to populate a fresh ANDROIDFS_DIR
           #       (TODO: Make this a command-line option or something.)
           # adb pull /$3/$1 ${ANDROIDFS_DIR}/$3/$1
        cp ${ANDROIDFS_DIR}/$3/$1 $PROPRIETARY_DEVICE_DIR/$4/$2
    fi

    if [[ -f $PROPRIETARY_DEVICE_DIR/$4/$2 ]]; then
        echo   $BASE_PROPRIETARY_DEVICE_DIR/$4/$2:$3/$2 \\ >> $PROPRIETARY_BLOBS_LIST
    else
        echo Failed to pull $1. Giving up.
        exit -1
    fi
}

# copy_files
# pulls a list of files from the device and adds the files to the list of blobs
#
# $1 = list of files
# $2 = directory path on device
# $3 = directory name in $PROPRIETARY_DEVICE_DIR
copy_files()
{
    for NAME in $1
    do
        copy_file "$NAME" "$NAME" "$2" "$3"
    done
}

DEVICE_PROP_LIBS="
	libomx_avcdec_hw_sprd.so      
	libomx_m4vh263dec_sw_sprd.so  
	libril_sp.so
	libomx_avcdec_sw_sprd.so      
	libomx_m4vh263enc_hw_sprd.so  
	libstagefright_sprd_soft_h264dec.so
	libomx_m4vh263dec_hw_sprd.so  
	libreference-ril_sp.so        
	libstagefright_sprd_soft_mpeg4dec.so
	"	
copy_files "$DEVICE_PROP_LIBS" "system/lib" "system/lib"

DEVICE_PROP_BINS="
	akmd8963
	phoneserver
	rild_sp
	sprd_monitor
	"
copy_files "$DEVICE_PROP_BINS" "system/bin" "system/bin"

#device/sprd/
DEVICE_SCRIPTS="
	ext_symlink.sh
	ext_chown.sh
	ext_data.sh
	ext_kill.sh
	"
copy_files "$DEVICE_SCRIPTS" "system/bin" "scripts"

COMMON_HW="
	gps.default.so
	audio.primary.sc7710.so
	sensors.sc7710.so
	lights.sc7710.so
	camera.sc7710.so
	gralloc.sc7710.so
	fm.sc7710.so
	"
copy_files "$COMMON_HW" "system/lib/hw" "hw"

#hardware/broadcom/wlan/bcmdhd
COMMON_BCM="
	bcmdhd.cal
	fw_bcmdhd_p2p.bin
	fw_bcmdhd_apsta.bin
	fw_bcmdhd.bin
	sdio-g-mfgtest.bin
	wpa_supplicant.conf
	"
copy_files "$COMMON_BCM" "system/etc/wifi" "wifi"

COMMON_ETC="
	gps.conf
	u-blox.conf
	slog.conf.user
	slog.conf
	audio_para
	audio_hw.xml
	audio_policy.conf
	codec_pga.xml
	tiny_hw.xml
	devicevolume.xml
	formatvolume.xml
	apns-conf.xml
	media_profiles.xml
	media_codecs.xml
	tiny_hw.xml
	adb.iso
	"
copy_files "$COMMON_ETC" "system/etc" "etc"

#mali
COMMON_EGL="
	egl.cfg
	libEGL_mali.so
	libGLESv1_CM_mali.so
	libGLESv2_mali.so
	"
copy_files "$COMMON_EGL" "system/lib/egl" "egl"

COMMON_BINS="
	vhub
	mplayer
	bluetoothd
	calibration_init
	cpu
	engappclient
	enghardwaretest
	engmoded
	engmodemclient
	engpcclient
	engservice
	engsetmacaddr
	gsnap
	lookat
	mcom_monitor
	nvitemd
	slog
	slogctl
	tar
	tcp
	vlog-iq
	vlog-sv
	wl
	"
copy_files "$COMMON_BINS" "system/bin" "bin"

XBINS="
	bonnie
	busybox
	copybw
	gsnap.save_anr_tombstones.sh
	iperf
	logs4android.sh
	logs4modem.sh
	memverify
	utest_spipe
	zram.sh
	"
copy_files "$XBINS" "system/xbin" "xbin"

COMMON_LIBS="
	libMali.so
	libomx_avcdec_hw_sprd.so
	libomx_m4vh263dec_sw_sprd.so
	libril_sp.so
	libomx_avcdec_sw_sprd.so
	libomx_m4vh263enc_hw_sprd.so
	libstagefright_sprd_soft_h264dec.so
	libomx_m4vh263dec_hw_sprd.so
	libreference-ril_sp.so
	libstagefright_sprd_soft_mpeg4dec.so
	libUMP.so
	libaudioutils.so
	libeng_wifi_ptest.so
	libengclient.so
	libjniNtvDev.so
	libmbbms_tel_jni.so
	libmorpho_facesolid.so
	libstagefrighthw.so
	libvbeffect.so
	libvbpga.so
	"
copy_files "$COMMON_LIBS" "system/lib" "lib"

KERNEL_KO="
	ansi_cprng.ko
	ft5306_ts.ko
	ltr_558als.ko
	mali.ko
	mmc_test.ko
	oprofile.ko
	ump.ko
	"
copy_files "$KERNEL_KO" "system/lib/modules" "lib"

SYSTEM_KEY="
	sprd-keypad.kl
	headset-keyboard.kl
	"
copy_files "$SYSTEM_KEY" "system/usr/keylayout" "usr"

SYSTEM_IDC="
	ft5x0x_ts.idc
	"
copy_files "$SYSTEM_IDC" "system/usr/idc" "usr"

