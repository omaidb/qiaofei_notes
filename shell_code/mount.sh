#!/bin/bash

get_disk() {
	# 获取用户输入的磁盘信息
	echo "*************************************"
	echo "当前计算机有以下磁盘:                "
	# 保存当前计算机所有磁盘信息
	sudo fdisk -l | grep "Disk /dev" | awk '{print $2}' | sed s'/.$//' >/tmp/disk_list
	# 展示当前计算机所有磁盘
	sudo fdisk -l | grep "Disk /dev"
	echo "*************************************"
	echo "-------------------------------------"
	echo "输入系统安装的磁盘分区,然后按回车    "
	echo "例子: /dev/sda                       "
	read DISK_NAME
}

get_judgment_read() {
	# 查看用户输入的磁盘判断是否正确
	grep -w "$DISK_NAME" /tmp/disk_list >/dev/null
	if [ $? -eq 0 ]; then
		echo "您输入的系统安装的磁盘分区为$DISK_NAME"
	else
		echo "未找到您输入的磁盘"
		sudo rm /tmp/disk_list
		exit
	fi
}

get_chroot() {
	# 将输入的磁盘里面的分区列出来
	sudo mkdir /uos_chroot
	sudo fdisk -l $DISK_NAME | grep "$DISK_NAME" | sed -e '/swap/d' >/tmp/disk_dev_tmp_name
	sudo sed -i '1d' /tmp/disk_dev_tmp_name
	sudo awk '{print $1}' /tmp/disk_dev_tmp_name >/tmp/disk_dev_name
	sudo rm /tmp/disk_dev_tmp_name

	# 判断是全盘安装还是非全盘安装
	sudo blkid | grep "Roota" >/dev/null
	if [ $? -eq 0 ]; then
		echo "全盘安装系统"
		# 全盘分区找到真正的根分区的UUID，然后找到对应磁盘进行挂载
		FLAG=1
		while read line; do
			sudo mount $line /uos_chroot
			if [ -f "/uos_chroot/grub/grub.cfg" ]; then
				BOOT_DEV=$line
				FLAG=0
				break
			else
				sudo umount /uos_chroot
			fi

		done </tmp/disk_dev_name

		# 判断输入的磁盘是否可以挂载到真正的根分区,
		if [ $FLAG -eq 0 ]; then
			# 根据grub.cfg文件找到真正的ROOT_DEV
			ROOT_UUID=$(grep "root=UUID=" /uos_chroot/grub/grub.cfg | sed -e '/deepin-ab-recovery/d' | sed 's/ /\n/g' | grep root=UUID | uniq | awk -F '=' '{print $3}')
			ROOT_DEV=$(sudo blkid | grep "$ROOT_UUID" | awk '{print $1}' | sed s'/.$//')
			sudo umount /uos_chroot
			# 开始挂载/目录
			sudo mount $ROOT_DEV /uos_chroot
			# 开始挂载boot目录
			sudo mount $BOOT_DEV /uos_chroot/boot
			# 判断是否有efi目录
			sudo blkid | grep "EFI" >/dev/null
			if [ $? -eq 0 ]; then
				BOOT_EFI_DEV=$(sudo blkid | grep "EFI" | awk '{print $1}' | sed s'/.$//')
				sudo mount $BOOT_EFI_DEV /uos_chroot/boot/efi
			fi

			# 开始挂载recovery
			RECOVERY_DEV=$(sudo blkid | grep "Backup" | awk '{print $1}' | sed s'/.$//')
			sudo mount $RECOVERY_DEV /uos_chroot/recovery
			# 开始挂载data
			DATA_DEV=$(sudo blkid | grep "_dde_data" | awk '{print $1}' | sed s'/.$//')
			sudo mount $DATA_DEV /uos_chroot/data
			# 挂载系统关键结点
			sudo mount --bind /dev/ /uos_chroot/dev
			sudo mount --bind /dev/pts /uos_chroot/dev//pts
			sudo mount --bind /proc /uos_chroot/proc
			sudo mount --bind /sys /uos_chroot/sys
			# 挂载对应data目录
			if [ $(ls -A /uos_chroot/home | wc -w) -eq 0 ]; then
				mount --bind /uos_chroot/data/home /uos_chroot/home
			fi
			if [ $(ls -A /uos_chroot/opt | wc -w) -eq 0 ]; then
				mount --bind /uos_chroot/data/opt /uos_chroot/opt
			fi
			if [ $(ls -A /uos_chroot/root | wc -w) -eq 0 ]; then
				mount --bind /uos_chroot/data/root /uos_chroot/root
			fi
			if [ $(ls -A /uos_chroot/var | wc -w) -eq 0 ]; then
				mount --bind /uos_chroot/data/var /uos_chroot/var
			fi

			echo "数据已挂载"
			# 进入chroot挂载对应目录
			cd /uos_chroot
			echo "您已经进入chroot环境"
			sudo chroot .
		elif [ $FLAG -eq 1 ]; then
			echo "该磁盘没有系统根目录"
			sudo umont /uos_chroot
			sudo rm -rf /uos_chroot
			exit
		fi

	else
		# 非全盘安装直接进行挂载
		FLAG_NO_DEV=1
		while read line; do
			sudo mount $line /uos_chroot
			if [ -f "/uos_chroot/etc/fstab" ]; then
				FLAG_NO_DEV=0
				break
			elif [ ! -f "/uos_chroot/etc/fstab" ]; then
				sudo umount /uos_chroot
			fi

		done </tmp/disk_dev_name

		if [ $FLAG_NO_DEV -eq 0 ]; then
			# 查看根据/etc/fstab文件挂载
			sudo cat /uos_chroot/etc/fstab | grep "UUID" >/tmp/UUID_LIST
			while read line; do
				DIR_NAME=$(echo $line | awk '{print $2}')
				if [ "$DIR_NAME" = "/" -o "$DIR_NAME" = "none" ]; then
					continue
				fi
				UUID_TMP=$(echo $line | awk '{print $1}' | awk -F '=' '{print $2}')
				DEV_NAME=$(sudo blkid | grep "$UUID_TMP" | awk '{print $1}' | sed s'/.$//')
				sudo mount $DEV_NAME /uos_chroot$DIR_NAME

			done </tmp/UUID_LIST
			# 挂载系统关键结点
			sudo mount --bind /dev/ /uos_chroot/dev
			sudo mount --bind /dev/pts /uos_chroot/dev//pts
			sudo mount --bind /proc /uos_chroot/proc
			sudo mount --bind /sys /uos_chroot/sys
			# 进入chroot挂载对应目录
			cd /uos_chroot
			echo "挂载完毕进入chroot环境"
			sudo chroot .

		elif [ $FLAG_NO_DEV -eq 1 ]; then
			echo "该磁盘没有系统根目录"
			sudo umount /uos_chroot
			sudo rm -rf /uos_chroot
			exit
		fi

	fi
}

main() {
	# 获取磁盘盘符
	get_disk
	# 查看用户输入的磁盘判断是否正确
	get_judgment_read
	# 切根
	get_chroot
}

main
