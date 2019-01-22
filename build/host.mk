#
# Copyright (C) 2007-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /build/LICENSE for more information.
#

TMP_DIR ?= $(TOPDIR)/tmp

# $(warning DUMP=$(DUMP))
# $(warning TARGET_BUILD=$(TARGET_BUILD))
# TARGET_BUILD为空，DUMP为空
#
# $ cat tmp/.host.mk 
# HOST_OS:=Linux
# HOST_ARCH:=x86_64
# GNU_HOST_NAME:=x86_64-linux-gnu
# FIND_L=find -L $(1)
ifeq ($(if $(TARGET_BUILD),,$(DUMP)),)
  -include $(TMP_DIR)/.host.mk
endif

ifneq ($(__host_inc),1)
__host_inc:=1

export PATH:=$(TOPDIR)/out/host/bin:$(PATH)

# set命令显示当前shell的变量，包括当前用户的变量：
# -a：标示已修改的变量，以供输出至环境变量。
# -b：使被中止的后台程序立刻回报执行状态。
# -C：转向所产生的文件无法覆盖已存在的文件。
# -d：Shell预设会用杂凑表记忆使用过的指令，以加速指令的执行。使用-d参数可取消。
# -e：若指令传回值不等于0，则立即退出shell。
# -f：取消使用通配符。
# -h：自动记录函数的所在位置。
# -H Shell：可利用"!"加<指令编号>的方式来执行history中记录的指令。
# -k：指令所给的参数都会被视为此指令的环境变量。
# -l：记录for循环的变量名称。
# -m：使用监视模式。
# -n：只读取指令，而不实际执行。
# -p：启动优先顺序模式。
# -P：启动-P参数后，执行指令时，会以实际的文件或目录来取代符号连接。
# -t：执行完随后的指令，即退出shell。
# -u：当执行时使用到未定义过的变量，则显示错误信息。
# -v：显示shell所读取的输入值。
# -x：执行指令后，会先显示该指令及所下的参数。
try-run = $(shell set -e; \
	TMP_F="$(TMP_DIR)/try-run.$$$$.tmp"; \
	if ($(1)) >/dev/null 2>&1; then echo "$(2)"; else echo "$(3)"; fi; \
	rm -f "$$TMP_F"; \
)

# $(warning HOSTCC=$(HOSTCC))
# $(warning HOST_CFLAGS=$(HOST_CFLAGS))
# HOSTCC、HOST_CFLAGS都空
host-cc-option = $(call try-run, \
	$(HOSTCC) $(HOST_CFLAGS) $(1) -c -xc /dev/null -o "$$TMP_F",$(1),$(2) \
)

# 创建目录$(TMP_DIR)及文件$(TMP_DIR)/.host.mk
# 把HOST_OS/HOST_ARCH/GNU_HOST_NAME/FIND_L变量内容写入.host.mkwen文件
.PRECIOUS: $(TMP_DIR)/.host.mk
$(TMP_DIR)/.host.mk: $(TOPDIR)/build/host.mk
	@mkdir -p $(TMP_DIR)
	@( \
		HOST_OS=`uname`; \
		case "$$HOST_OS" in \
			Linux) HOST_ARCH=`uname -m`;; \
			Darwin) HOST_ARCH=`uname -m`;; \
			*) HOST_ARCH=`uname -p`;; \
		esac; \
		GNU_HOST_NAME=`gcc -dumpmachine`; \
		[ -z "$$GNU_HOST_NAME" -o "$$HOST_OS" = "Darwin" ] && \
			GNU_HOST_NAME=`$(TOPDIR)/scripts/config.guess`; \
		echo "HOST_OS:=$$HOST_OS" > $@; \
		echo "HOST_ARCH:=$$HOST_ARCH" >> $@; \
		echo "GNU_HOST_NAME:=$$GNU_HOST_NAME" >> $@; \
		if gfind -L /dev/null || find -L /dev/null; then \
			echo "FIND_L=find -L \$$(1)" >> $@; \
		else \
			echo "FIND_L=find \$$(1) -follow" >> $@; \
		fi \
	) >/dev/null 2>/dev/null

endif
