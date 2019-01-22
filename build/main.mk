# Makefile for OpenWrt
#
# Copyright (C) 2007 OpenWrt.org
# Copyright (C) 2016 tracewong
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

TOPDIR:=${CURDIR}
# LC_ALL=C 是为了去除所有本地化的设置，让命令能正确执行。
LC_ALL:=C
LANG:=C
TZ:=UTC
export TOPDIR LC_ALL LANG TZ

empty:=
space:= $(empty) $(empty)

# $(if CONDITION,THEN-PART[,ELSE-PART])
#
# $(findstring FIND,IN) 
# 如果在“IN”之中存在“FIND” ，则返回“FIND”，否则返回空
$(if $(findstring $(space),$(TOPDIR)),$(error ERROR: The path to the OpenWrt directory must not include any spaces))

# 执行make时，若无任何目标指定，则默认目标是world
world:

include $(TOPDIR)/build/host.mk

# 执行make时，无参数指定，则会进入第一个分支。如果执行命令make OPENWRT_BUILD=1，则直接进入第二个分支
ifneq ($(OPENWRT_BUILD),1)
  _SINGLE=export MAKEFLAGS=$(space);

  override OPENWRT_BUILD=1
  export OPENWRT_BUILD
  GREP_OPTIONS=
  export GREP_OPTIONS
  include $(TOPDIR)/build/debug.mk
  include $(TOPDIR)/build/depends.mk
  include $(TOPDIR)/build/toplevel.mk
else
  include rules.mk
  include $(BUILD_DIR)/depends.mk
  include $(BUILD_DIR)/subdir.mk
  include target/Makefile
  include package/Makefile
  include tools/Makefile
  include toolchain/Makefile

$(toolchain/stamp-install): $(tools/stamp-install)
$(target/stamp-compile): $(toolchain/stamp-install) $(tools/stamp-install) $(COMPILE_DIR)/.prepared
$(package/stamp-compile): $(target/stamp-compile) $(package/stamp-cleanup)
$(package/stamp-install): $(package/stamp-compile)
$(target/stamp-install): $(package/stamp-compile) $(package/stamp-install)

printdb:
	@true

prepare: $(target/stamp-compile)

clean: FORCE
	-@$(FIND) $(TARGET_OUT_DIR) -name ".built*" -exec rm {} \;
	-@$(FIND) $(TARGET_OUT_DIR) -name ".configured*" -exec rm {} \;
	-@$(FIND) $(TARGET_OUT_DIR) -name ".dep_*" -exec rm {} \;
	-@$(FIND) $(TARGET_OUT_DIR) -name ".prepared*" -exec rm {} \;

dirclean: clean
	rm -rf $(STAGING_DIR_HOST) $(TOOLCHAIN_DIR) $(COMPILE_DIR_HOST) $(COMPILE_DIR_TOOLCHAIN)
	rm -rf $(TMP_DIR)

ifndef DUMP_TARGET_DB
$(COMPILE_DIR)/.prepared: Makefile
	@mkdir -p $$(dirname $@)
	@touch $@

tmp/.prereq_packages: .config
	unset ERROR; \
	for package in $(sort $(prereq-y) $(prereq-m)); do \
		$(_SINGLE)$(NO_TRACE_MAKE) -s -r -C package/$$package prereq || ERROR=1; \
	done; \
	if [ -n "$$ERROR" ]; then \
		echo "Package prerequisite check failed."; \
		false; \
	fi
	touch $@
endif

# check prerequisites before starting to build
prereq: $(target/stamp-prereq) tmp/.prereq_packages
	@if [ ! -f "$(BUILD_DIR)/site/$(ARCH)" ]; then \
		echo 'ERROR: Missing site config for architecture "$(ARCH)" !'; \
		echo '       The missing file will cause configure scripts to fail during compilation.'; \
		echo '       Please provide a "$(BUILD_DIR)/site/$(ARCH)" file and restart the build.'; \
		exit 1; \
	fi

prepare: .config $(tools/stamp-install) $(toolchain/stamp-install)
world: prepare $(target/stamp-compile) $(package/stamp-compile) $(package/stamp-install) $(target/stamp-install) FORCE
	$(_SINGLE)$(SUBMAKE) -r package/index

.PHONY: clean dirclean prereq prepare world package/symlinks package/symlinks-install package/symlinks-clean

endif
