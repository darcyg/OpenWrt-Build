#
# Copyright (C) 2007-2008 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

ifneq ($(__target_inc),1)
__target_inc=1

# default device type
DEVICE_TYPE?=

# Default packages - the really basic set
DEFAULT_PACKAGES:=base-files libc libgcc busybox dropbear mtd uci opkg netifd fstools uclient-fetch logd
# For nas targets
DEFAULT_PACKAGES.nas:=block-mount fdisk lsblk mdadm
# For router targets
DEFAULT_PACKAGES.router:=dnsmasq iptables ip6tables ppp ppp-mod-pppoe firewall odhcpd odhcp6c
DEFAULT_PACKAGES.bootloader:=

ifneq ($(DUMP),)
  all: dumpinfo
endif

target_conf=$(subst .,_,$(subst -,_,$(subst /,_,$(1))))
ifeq ($(DUMP),)
  PLATFORM_DIR:=$(TOPDIR)/target/allwinner/$(BOARD)
  PLATFORM_COMMON_DIR:=$(TOPDIR)/target/allwinner/$(shell echo -n $(BOARD) | sed -e 's/-.*//g')-common
  SUBTARGET:=$(strip $(foreach subdir,$(patsubst $(PLATFORM_DIR)/%/target.mk,%,$(wildcard $(PLATFORM_DIR)/*/target.mk)),$(if $(CONFIG_TARGET_$(call target_conf,$(BOARD)_$(subdir))),$(subdir))))
else
  PLATFORM_DIR:=${CURDIR}
  ifeq ($(SUBTARGETS),)
    SUBTARGETS:=$(strip $(patsubst $(PLATFORM_DIR)/%/target.mk,%,$(wildcard $(PLATFORM_DIR)/*/target.mk)))
  endif
endif

TARGETID:=$(BOARD)$(if $(SUBTARGET),/$(SUBTARGET))
PLATFORM_SUBDIR:=$(PLATFORM_DIR)$(if $(SUBTARGET),/$(SUBTARGET))

ifneq ($(TARGET_BUILD),1)
  ifndef DUMP
    include $(PLATFORM_DIR)/Makefile
    ifneq ($(PLATFORM_DIR),$(PLATFORM_SUBDIR))
      include $(PLATFORM_SUBDIR)/target.mk
    endif
  endif
else
  ifneq ($(SUBTARGET),)
    -include ./$(SUBTARGET)/target.mk
  endif
endif

# Add device specific packages (here below to allow device type set from subtarget)
DEFAULT_PACKAGES += $(DEFAULT_PACKAGES.$(DEVICE_TYPE))

filter_packages = $(filter-out -% $(patsubst -%,%,$(filter -%,$(1))),$(1))
extra_packages = $(if $(filter wpad-mini wpad nas,$(1)),iwinfo)

define Profile/Default
  NAME:=$(TARGET_BUILD_VARIANT)
  PACKAGES:=
endef

ifndef Profile
define Profile
  $(eval $(call Profile/Default))
  $(eval $(call Profile/$(1)))
  dumpinfo : $(call shexport,Profile/$(1)/Config)
  dumpinfo : $(call shexport,Profile/$(1)/Description)
  DUMPINFO += \
	echo "Target-Profile: $(1)"; \
	echo "Target-Profile-Name: $(NAME)"; \
	echo "Target-Profile-Packages: $(PACKAGES) $(call extra_packages,$(DEFAULT_PACKAGES) $(PACKAGES))"; \
	if [ -f ./config/profile-$(1) ]; then \
		echo "Target-Profile-Kconfig: yes"; \
	fi; \
	echo "Target-Profile-Config: "; \
	echo "$$$$$$$$$(call shvar,Profile/$(1)/Config)"; \
	echo "@@"; \
	echo "Target-Profile-Description:"; \
	echo "$$$$$$$$$(call shvar,Profile/$(1)/Description)"; \
	echo "@@"; \
	echo;
  ifeq ($(CONFIG_TARGET_$(call target_conf,$(BOARD)_$(if $(SUBTARGET),$(SUBTARGET)_))$(1)),y)
    PROFILE=$(1)
  endif
endef
endif

$(eval $(call Profile,$(PRODUCT_BOARD)))

ifeq ($(TARGET_BUILD),1)
  $(eval $(call IncludeProfiles))
else
  ifeq ($(DUMP),)
    $(eval $(call IncludeProfiles))
  endif
endif

ifneq ($(TARGET_BUILD)$(if $(DUMP),,1),)
  include $(BUILD_DIR)/kernel-version.mk
endif

GENERIC_PLATFORM_DIR := $(TOPDIR)/target/allwinner/generic
GENERIC_PATCH_DIR := $(GENERIC_PLATFORM_DIR)/patches$(if $(wildcard $(GENERIC_PLATFORM_DIR)/patches-$(KERNEL_PATCHVER)),-$(KERNEL_PATCHVER))
GENERIC_FILES_DIR := $(foreach dir,$(wildcard $(GENERIC_PLATFORM_DIR)/files $(GENERIC_PLATFORM_DIR)/files-$(KERNEL_PATCHVER)),"$(dir)")

__config_name_list = $(1)/config-$(KERNEL_PATCHVER) $(1)/config-default
__config_list = $(firstword $(wildcard $(call __config_name_list,$(1))))
find_kernel_config=$(if $(__config_list),$(__config_list),$(lastword $(__config_name_list)))

__config_name_list_recovery = $(1)/config-$(KERNEL_PATCHVER)_recovery $(1)/config-default_recovery
__config_list_recovery = $(firstword $(wildcard $(call __config_name_list_recovery,$(1))))
find_kernel_config_recovery=$(if $(__config_list_recovery),$(__config_list_recovery),$(lastword $(__config_name_list_recovery)))

__config_name_list_ramfs = $(1)/config-$(KERNEL_PATCHVER)_ramfs $(1)/config-default_ramfs
__config_list_ramfs = $(firstword $(wildcard $(call __config_name_list_ramfs,$(1))))
find_kernel_config_ramfs=$(if $(__config_list_ramfs),$(__config_list_ramfs),$(lastword $(__config_name_list_ramfs)))

GENERIC_LINUX_CONFIG = $(call find_kernel_config,$(GENERIC_PLATFORM_DIR))
LINUX_TARGET_CONFIG = $(call find_kernel_config,$(PLATFORM_DIR))
ifneq ($(PLATFORM_DIR),$(PLATFORM_SUBDIR))
  LINUX_SUBTARGET_CONFIG = $(call find_kernel_config,$(PLATFORM_SUBDIR))
endif

GENERIC_LINUX_CONFIG_RECOVERY = $(call find_kernel_config_recovery,$(GENERIC_PLATFORM_DIR))
LINUX_TARGET_CONFIG_RECOVERY = $(call find_kernel_config_recovery,$(PLATFORM_DIR))
ifneq ($(PLATFORM_DIR),$(PLATFORM_SUBDIR))
  LINUX_SUBTARGET_CONFIG_RECOVERY = $(call find_kernel_config_recovery,$(PLATFORM_SUBDIR))
endif

GENERIC_LINUX_CONFIG_RAMFS = $(call find_kernel_config_ramfs,$(GENERIC_PLATFORM_DIR))
LINUX_TARGET_CONFIG_RAMFS = $(call find_kernel_config_ramfs,$(PLATFORM_DIR))
ifneq ($(PLATFORM_DIR),$(PLATFORM_SUBDIR))
  LINUX_SUBTARGET_CONFIG_RAMFS = $(call find_kernel_config_ramfs,$(PLATFORM_SUBDIR))
endif

# config file list used for compiling
LINUX_KCONFIG_LIST = $(wildcard $(GENERIC_LINUX_CONFIG) $(LINUX_TARGET_CONFIG) $(LINUX_SUBTARGET_CONFIG) $(TOPDIR)/env/kernel-config)
LINUX_KCONFIG_LIST_RECOVERY = $(wildcard $(GENERIC_LINUX_CONFIG_RECOVERY) $(LINUX_TARGET_CONFIG_RECOVERY) $(LINUX_SUBTARGET_CONFIG_RECOVERY) $(TOPDIR)/env/kernel-config_recovery)
LINUX_KCONFIG_LIST_RAMFS = $(wildcard $(GENERIC_LINUX_CONFIG_RAMFS) $(LINUX_TARGET_CONFIG_RAMFS) $(LINUX_SUBTARGET_CONFIG_RAMFS) $(TOPDIR)/env/kernel-config_ramfs)

# default config list for reconfiguring
# defaults to subtarget if subtarget exists and target does not
# defaults to target otherwise
USE_SUBTARGET_CONFIG = $(if $(wildcard $(LINUX_TARGET_CONFIG)),,$(if $(LINUX_SUBTARGET_CONFIG),1))
USE_SUBTARGET_CONFIG_RECOVERY = $(if $(wildcard $(LINUX_TARGET_CONFIG_RECOVERY)),,$(if $(LINUX_SUBTARGET_CONFIG_RECOVERY),1))
USE_SUBTARGET_CONFIG_RAMFS = $(if $(wildcard $(LINUX_TARGET_CONFIG_RAMFS)),,$(if $(LINUX_SUBTARGET_CONFIG_RAMFS),1))

LINUX_RECONFIG_LIST = $(wildcard $(GENERIC_LINUX_CONFIG) $(LINUX_TARGET_CONFIG) $(if $(USE_SUBTARGET_CONFIG),$(LINUX_SUBTARGET_CONFIG)))
LINUX_RECONFIG_TARGET = $(if $(USE_SUBTARGET_CONFIG),$(LINUX_SUBTARGET_CONFIG),$(LINUX_TARGET_CONFIG))

LINUX_RECONFIG_LIST_RECOVERY = $(wildcard $(GENERIC_LINUX_CONFIG_RECOVERY) $(LINUX_TARGET_CONFIG_RECOVERY) $(if $(USE_SUBTARGET_CONFIG_RECOVERY),$(LINUX_SUBTARGET_CONFIG_RECOVERY)))
LINUX_RECONFIG_TARGET_RECOVERY = $(if $(USE_SUBTARGET_CONFIG_RECOVERY),$(LINUX_SUBTARGET_CONFIG_RECOVERY),$(LINUX_TARGET_CONFIG_RECOVERY))

LINUX_RECONFIG_LIST_RAMFS = $(wildcard $(GENERIC_LINUX_CONFIG_RAMFS) $(LINUX_TARGET_CONFIG_RAMFS) $(if $(USE_SUBTARGET_CONFIG_RAMFS),$(LINUX_SUBTARGET_CONFIG_RAMFS)))
LINUX_RECONFIG_TARGET_RAMFS = $(if $(USE_SUBTARGET_CONFIG_RAMFS),$(LINUX_SUBTARGET_CONFIG_RAMFS),$(LINUX_TARGET_CONFIG_RAMFS))

# select the config file to be changed by kernel_menuconfig/kernel_oldconfig
ifeq ($(CONFIG_TARGET),platform)
  LINUX_RECONFIG_LIST = $(wildcard $(GENERIC_LINUX_CONFIG) $(LINUX_TARGET_CONFIG))
  LINUX_RECONFIG_TARGET = $(LINUX_TARGET_CONFIG)
  LINUX_RECONFIG_LIST_RECOVERY = $(wildcard $(GENERIC_LINUX_CONFIG_RECOVERY) $(LINUX_TARGET_CONFIG_RECOVERY))
  LINUX_RECONFIG_TARGET_RECOVERY = $(LINUX_TARGET_CONFIG_RECOVERY)
  LINUX_RECONFIG_LIST_RAMFS = $(wildcard $(GENERIC_LINUX_CONFIG_RAMFS) $(LINUX_TARGET_CONFIG_RAMFS))
  LINUX_RECONFIG_TARGET_RAMFS = $(LINUX_TARGET_CONFIG_RAMFS)
endif
ifeq ($(CONFIG_TARGET),subtarget)
  LINUX_RECONFIG_LIST = $(wildcard $(GENERIC_LINUX_CONFIG) $(LINUX_TARGET_CONFIG) $(LINUX_SUBTARGET_CONFIG))
  LINUX_RECONFIG_TARGET = $(LINUX_SUBTARGET_CONFIG)
  LINUX_RECONFIG_LIST_RECOVERY = $(wildcard $(GENERIC_LINUX_CONFIG_RECOVERY) $(LINUX_TARGET_CONFIG_RECOVERY) $(LINUX_SUBTARGET_CONFIG_RECOVERY))
  LINUX_RECONFIG_TARGET_RECOVERY = $(LINUX_SUBTARGET_CONFIG_RECOVERY)
  LINUX_RECONFIG_LIST_RAMFS = $(wildcard $(GENERIC_LINUX_CONFIG_RAMFS) $(LINUX_TARGET_CONFIG_RAMFS) $(LINUX_SUBTARGET_CONFIG_RAMFS))
  LINUX_RECONFIG_TARGET_RAMFS = $(LINUX_SUBTARGET_CONFIG_RAMFS)
endif
ifeq ($(CONFIG_TARGET),subtarget_platform)
  LINUX_RECONFIG_LIST = $(wildcard $(GENERIC_LINUX_CONFIG) $(LINUX_SUBTARGET_CONFIG) $(LINUX_TARGET_CONFIG))
  LINUX_RECONFIG_TARGET = $(LINUX_TARGET_CONFIG)
  LINUX_RECONFIG_LIST_RECOVERY = $(wildcard $(GENERIC_LINUX_CONFIG_RECOVERY) $(LINUX_SUBTARGET_CONFIG_RECOVERY) $(LINUX_TARGET_CONFIG_RECOVERY))
  LINUX_RECONFIG_TARGET_RECOVERY = $(LINUX_TARGET_CONFIG_RECOVERY)
  LINUX_RECONFIG_LIST_RAMFS = $(wildcard $(GENERIC_LINUX_CONFIG_RAMFS) $(LINUX_SUBTARGET_CONFIG_RAMFS) $(LINUX_TARGET_CONFIG_RAMFS))
  LINUX_RECONFIG_TARGET_RAMFS = $(LINUX_TARGET_CONFIG_RAMFS)
endif
ifeq ($(CONFIG_TARGET),env)
  LINUX_RECONFIG_LIST = $(LINUX_KCONFIG_LIST)
  LINUX_RECONFIG_TARGET = $(TOPDIR)/env/kernel-config
  LINUX_RECONFIG_LIST_RECOVERY = $(LINUX_KCONFIG_LIST_RECOVERY)
  LINUX_RECONFIG_TARGET_RECOVERY = $(TOPDIR)/env/kernel-config_recovery
  LINUX_RECONFIG_LIST_RAMFS = $(LINUX_KCONFIG_LIST_RAMFS)
  LINUX_RECONFIG_TARGET_RAMFS = $(TOPDIR)/env/kernel-config_ramfs
endif

__linux_confcmd = $(SCRIPT_DIR)/kconfig.pl $(2) $(patsubst %,+,$(wordlist 2,9999,$(1))) $(1)

LINUX_CONF_CMD = $(call __linux_confcmd,$(LINUX_KCONFIG_LIST),)
LINUX_RECONF_CMD = $(call __linux_confcmd,$(LINUX_RECONFIG_LIST),)
LINUX_RECONF_DIFF = $(call __linux_confcmd,$(filter-out $(LINUX_RECONFIG_TARGET),$(LINUX_RECONFIG_LIST)),'>')

LINUX_CONF_CMD_RECOVERY = $(call __linux_confcmd,$(LINUX_KCONFIG_LIST_RECOVERY),)
LINUX_RECONF_CMD_RECOVERY = $(call __linux_confcmd,$(LINUX_RECONFIG_LIST_RECOVERY),)
LINUX_RECONF_DIFF_RECOVERY = $(call __linux_confcmd,$(filter-out $(LINUX_RECONFIG_TARGET),$(LINUX_RECONFIG_LIST_RECOVERY)),'>')

LINUX_CONF_CMD_RAMFS = $(call __linux_confcmd,$(LINUX_KCONFIG_LIST_RAMFS),)
LINUX_RECONF_CMD_RAMFS = $(call __linux_confcmd,$(LINUX_RECONFIG_LIST_RAMFS),)
LINUX_RECONF_DIFF_RAMFS = $(call __linux_confcmd,$(filter-out $(LINUX_RECONFIG_TARGET),$(LINUX_RECONFIG_LIST_RAMFS)),'>')

ifeq ($(DUMP),1)
  BuildTarget=$(BuildTargets/DumpCurrent)

  ifneq ($(BOARD),)
    TMP_CONFIG:=$(TMP_DIR)/.kconfig-$(call target_conf,$(TARGETID))
    $(TMP_CONFIG): $(LINUX_KCONFIG_LIST)
		$(LINUX_CONF_CMD) > $@ || rm -f $@
    -include $(TMP_CONFIG)
    .SILENT: $(TMP_CONFIG)
    .PRECIOUS: $(TMP_CONFIG)

    ifneq ($(CONFIG_OF),)
      FEATURES += dt
    endif
    ifneq ($(CONFIG_GENERIC_GPIO)$(CONFIG_GPIOLIB),)
      FEATURES += gpio
    endif
    ifneq ($(CONFIG_PCI),)
      FEATURES += pci
    endif
    ifneq ($(CONFIG_PCIEPORTBUS),)
      FEATURES += pcie
    endif
    ifneq ($(CONFIG_USB)$(CONFIG_USB_SUPPORT),)
      ifneq ($(CONFIG_USB_ARCH_HAS_HCD)$(CONFIG_USB_EHCI_HCD),)
        FEATURES += usb
      endif
    endif
    ifneq ($(CONFIG_PCMCIA)$(CONFIG_PCCARD),)
      FEATURES += pcmcia
    endif
    ifneq ($(CONFIG_VGA_CONSOLE)$(CONFIG_FB),)
      FEATURES += display
    endif
    ifneq ($(CONFIG_RTC_CLASS),)
      FEATURES += rtc
    endif
    FEATURES += $(foreach v,v4 v5 v6 v7,$(if $(findstring -march=arm$(v),$(CFLAGS)),arm_$(v)))

    # remove duplicates
    FEATURES:=$(sort $(FEATURES))
  endif
  CPU_CFLAGS = -Os -pipe
  ifneq ($(findstring mips,$(ARCH)),)
    ifneq ($(findstring mips64,$(ARCH)),)
      CPU_TYPE ?= mips64
    else
      CPU_TYPE ?= mips32
    endif
    CPU_CFLAGS += -mno-branch-likely
    CPU_CFLAGS_mips32 = -mips32 -mtune=mips32
    CPU_CFLAGS_mips32r2 = -mips32r2 -mtune=mips32r2
    CPU_CFLAGS_mips64 = -mips64 -mtune=mips64 -mabi=64
    CPU_CFLAGS_24kc = -mips32r2 -mtune=24kc
    CPU_CFLAGS_24kec = -mips32r2 -mtune=24kec
    CPU_CFLAGS_34kc = -mips32r2 -mtune=34kc
    CPU_CFLAGS_74kc = -mips32r2 -mtune=74kc
    CPU_CFLAGS_octeon = -march=octeon -mabi=64
    CPU_CFLAGS_dsp = -mdsp
    CPU_CFLAGS_dsp2 = -mdspr2
  endif
  ifeq ($(ARCH),i386)
    CPU_TYPE ?= i486
    CPU_CFLAGS_i486 = -march=i486
    CPU_CFLAGS_pentium4 = -march=pentium4
    CPU_CFLAGS_geode = -march=geode -mmmx -m3dnow
  endif
  ifneq ($(findstring arm,$(ARCH)),)
    CPU_TYPE ?= xscale
    CPU_CFLAGS_arm920t = -march=armv4t -mtune=arm920t
    CPU_CFLAGS_arm926ej-s = -march=armv5te -mtune=arm926ej-s
    CPU_CFLAGS_arm1136j-s = -march=armv6 -mtune=arm1136j-s
    CPU_CFLAGS_arm1176jzf-s = -march=armv6 -mtune=arm1176jzf-s
    CPU_CFLAGS_cortex-a5 = -march=armv7-a -mtune=cortex-a5
    CPU_CFLAGS_cortex-a7 = -march=armv7-a -mtune=cortex-a7
    CPU_CFLAGS_cortex-a8 = -march=armv7-a -mtune=cortex-a8
    CPU_CFLAGS_cortex-a9 = -march=armv7-a -mtune=cortex-a9
    CPU_CFLAGS_cortex-a15 = -march=armv7-a -mtune=cortex-a15
    CPU_CFLAGS_fa526 = -march=armv4 -mtune=fa526
    CPU_CFLAGS_mpcore = -march=armv6k -mtune=mpcore
    CPU_CFLAGS_xscale = -march=armv5te -mtune=xscale
    ifeq ($(CONFIG_SOFT_FLOAT),)
      CPU_CFLAGS_neon = -mfpu=neon
      CPU_CFLAGS_vfp = -mfpu=vfp
      CPU_CFLAGS_vfpv3 = -mfpu=vfpv3-d16
      CPU_CFLAGS_neon-vfpv4 = -mfpu=neon-vfpv4
    endif
  endif
  ifeq ($(ARCH),powerpc)
    CPU_CFLAGS_603e:=-mcpu=603e
    CPU_CFLAGS_8540:=-mcpu=8540
    CPU_CFLAGS_405:=-mcpu=405
    CPU_CFLAGS_440:=-mcpu=440
  endif
  ifeq ($(ARCH),sparc)
    CPU_TYPE = sparc
    CPU_CFLAGS_ultrasparc = -mcpu=ultrasparc
  endif
  ifeq ($(ARCH),aarch64)
    CPU_TYPE ?= armv8-a
    CPU_CFLAGS_armv8-a = -mcpu=armv8-a
  endif
  ifeq ($(ARCH),arc)
    CPU_TYPE ?= arc700
    CPU_CFLAGS += -matomic
    CPU_CFLAGS_arc700 = -marc700
    CPU_CFLAGS_archs = -marchs
  endif
  DEFAULT_CFLAGS=$(strip $(CPU_CFLAGS) $(CPU_CFLAGS_$(CPU_TYPE)) $(CPU_CFLAGS_$(CPU_SUBTYPE)))
endif

define BuildTargets/DumpCurrent
  .PHONY: dumpinfo
  dumpinfo : export DESCRIPTION=$$(Target/Description)
  dumpinfo:
	 @echo 'Target: $(TARGETID)'; \
	 echo 'Target-Board: $(BOARD)'; \
	 echo 'Target-Name: $(BOARDNAME)$(if $(SUBTARGETS),$(if $(SUBTARGET),))'; \
	 echo 'Target-Path: $(subst $(TOPDIR)/,,$(PWD))'; \
	 echo 'Target-Arch: $(ARCH)'; \
	 echo 'Target-Arch-Packages: $(if $(TARGET_ARCH_PACKAGES),$(TARGET_ARCH_PACKAGES),$(BOARD))'; \
	 echo 'Target-Features: $(FEATURES)'; \
	 echo 'Target-Depends: $(DEPENDS)'; \
	 echo 'Target-Optimization: $(if $(CFLAGS),$(CFLAGS),$(DEFAULT_CFLAGS))'; \
	 echo 'CPU-Type: $(CPU_TYPE)$(if $(CPU_SUBTYPE),+$(CPU_SUBTYPE))'; \
	 echo 'Linux-Version: $(LINUX_VERSION)'; \
	 echo 'Linux-Release: $(LINUX_RELEASE)'; \
	 echo 'Linux-Kernel-Arch: $(LINUX_KARCH)'; \
	$(if $(SUBTARGET),,$(if $(DEFAULT_SUBTARGET), echo 'Default-Subtarget: $(DEFAULT_SUBTARGET)'; )) \
	 echo 'Target-Description:'; \
	 echo "$$$$DESCRIPTION"; \
	 echo '@@'; \
	 echo 'Default-Packages: $(DEFAULT_PACKAGES) $(call extra_packages,$(DEFAULT_PACKAGES))'; \
	 $(DUMPINFO)
	$(if $(SUBTARGET),,@$(foreach SUBTARGET,$(SUBTARGETS),$(SUBMAKE) -s DUMP=1 SUBTARGET=$(SUBTARGET); ))
endef

include $(BUILD_DIR)/kernel.mk
ifeq ($(TARGET_BUILD),1)
  include $(BUILD_DIR)/kernel-build.mk
  BuildTarget?=$(BuildKernel)
endif

endif #__target_inc
