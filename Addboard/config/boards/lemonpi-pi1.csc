# Rockchip RK3588 octa core 16/32GB RAM SoC Type-C 2x GBE 2x USB3.0 WiFi/BT NVMe eMMC
BOARD_NAME="LemonPi Pi1"
BOARDFAMILY="rockchip-rk3588"
BOARD_MAINTAINER="YANXIAOXIH"
BOOTCONFIG="lemonpi_pi1_defconfig"
BOOT_SOC="rk3588"
KERNEL_TARGET="legacy,vendor,edge"
FULL_DESKTOP="yes"
BOOT_LOGO="desktop"
BOOT_FDT_FILE="rockchip/rk3588-lemonpi-pi1.dtb"
BOOT_SCENARIO="spl-blobs"
BOOT_SUPPORT_SPI="yes"
BOOT_SPI_RKSPI_LOADER="yes"
IMAGE_PARTITION_TABLE="gpt"

function post_family_tweaks__lemonpi_pi1_naming_audios() {
	display_alert "$BOARD" "Renaming lemonpi-pi1 audios" "info"

	sed -i '22i VENDORTEMP="${BOARD_NAME}" ' $SDCARD/etc/update-motd.d/10-armbian-header

	mkdir -p $SDCARD/etc/udev/rules.d/
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-hdmi1-sound", ENV{SOUND_DESCRIPTION}="HDMI1 Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-hdmiin-sound", ENV{SOUND_DESCRIPTION}="HDMI-In Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-es8388-sound", ENV{SOUND_DESCRIPTION}="ES8388 Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	return 0
}

function post_family_config_branch_legacy__lemonpi_pi1_use_mainline_uboot() {
	if [[ $BRANCH == "legacy" ]]; then
		OOTSCRIPT='boot-rk35xx.cmd:boot.cmd'
		BOOTDIR='u-boot-rockchip64'
		declare -g KERNEL_MAJOR_MINOR="6.1"   # Major and minor versions of this kernel.
		declare -g -i KERNEL_GIT_CACHE_TTL=120 # 2 minutes; this is a high-traffic repo
		KERNELSOURCE='https://github.com/CNflysky/linux-rockchip.git'
		KERNELBRANCH='branch:rk-6.1-rkr4.1'
		KERNELPATCHDIR='rk35xx-vendor-6.1'
		LINUXCONFIG='linux-rk35xx-vendor'
		LINUXFAMILY=rk35xx
	fi
}
