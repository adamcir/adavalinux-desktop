CC ?= cc
CFLAGS ?= -std=c11 -Wall -Wextra -Werror -O2
CPPFLAGS ?= -D_DEFAULT_SOURCE -D_POSIX_C_SOURCE=200809L
LDFLAGS ?=
LDLIBS ?= -lX11

BUILD_DIR := build
PACKAGE_DIR := packages
VERSION := 0.1.0

.PHONY: all clean package

all: $(BUILD_DIR)/usr/bin/adavalinux-panel $(BUILD_DIR)/usr/bin/adavalinux-session \
	$(BUILD_DIR)/usr/bin/adavalinux-greeter $(BUILD_DIR)/usr/bin/adavalinux-display-manager \
	$(BUILD_DIR)/etc/pam.d/adavalinux-greeter $(BUILD_DIR)/usr/share/adavalinux/themes/default/theme.conf \
	$(BUILD_DIR)/usr/share/X11/xkb/rules/evdev $(BUILD_DIR)/usr/bin/xkbcomp

$(BUILD_DIR)/usr/bin/adavalinux-panel: adavalinux-panel.c
	mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) -o $@ $< $(LDLIBS)

$(BUILD_DIR)/usr/bin/adavalinux-session: adavalinux-session
	mkdir -p $(dir $@)
	install -m 0755 $< $@

$(BUILD_DIR)/usr/bin/adavalinux-greeter: adavalinux-greeter.c pam_compat.h
	mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) -o $@ adavalinux-greeter.c -l:libpam.so.0 -lX11

$(BUILD_DIR)/usr/bin/adavalinux-display-manager: adavalinux-display-manager
	mkdir -p $(dir $@)
	install -m 0755 $< $@

$(BUILD_DIR)/etc/pam.d/adavalinux-greeter: pam.d/adavalinux-greeter
	mkdir -p $(dir $@)
	install -m 0644 $< $@

$(BUILD_DIR)/usr/share/adavalinux/themes/default/theme.conf: themes/default/theme.conf
	mkdir -p $(dir $@)
	install -m 0644 $< $@

$(BUILD_DIR)/usr/share/X11/xkb/rules/evdev:
	test -f /usr/share/X11/xkb/rules/evdev
	mkdir -p $(BUILD_DIR)/usr/share/X11
	cp -aL /usr/share/X11/xkb $(BUILD_DIR)/usr/share/X11/

$(BUILD_DIR)/usr/bin/xkbcomp:
	test -x /usr/bin/xkbcomp
	test -f /usr/lib/x86_64-linux-gnu/libxkbfile.so.1
	mkdir -p $(BUILD_DIR)/usr/bin $(BUILD_DIR)/usr/lib/x86_64-linux-gnu
	install -m 0755 /usr/bin/xkbcomp $@
	cp -aL /usr/lib/x86_64-linux-gnu/libxkbfile.so.1 $(BUILD_DIR)/usr/lib/x86_64-linux-gnu/
	cp -aL /usr/lib/x86_64-linux-gnu/libXau.so.6 $(BUILD_DIR)/usr/lib/x86_64-linux-gnu/
	cp -aL /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 $(BUILD_DIR)/usr/lib/x86_64-linux-gnu/

package: all
	rm -rf $(BUILD_DIR)/package-root out
	mkdir -p $(BUILD_DIR)/package-root/adavalinux-desktop-$(VERSION)
	cp -a $(BUILD_DIR)/usr $(BUILD_DIR)/etc $(BUILD_DIR)/package-root/adavalinux-desktop-$(VERSION)/
	cp $(PACKAGE_DIR)/adavalinux-desktop/syspckg-info $(PACKAGE_DIR)/adavalinux-desktop/syspckg-deps $(PACKAGE_DIR)/adavalinux-desktop/install.sh $(BUILD_DIR)/package-root/adavalinux-desktop-$(VERSION)/
	mkdir -p $(BUILD_DIR)/package-root/adavalinux-theme-default-$(VERSION)/usr/share/adavalinux/themes/default
	cp themes/default/theme.conf $(BUILD_DIR)/package-root/adavalinux-theme-default-$(VERSION)/usr/share/adavalinux/themes/default/
	cp $(PACKAGE_DIR)/adavalinux-theme-default/syspckg-info $(BUILD_DIR)/package-root/adavalinux-theme-default-$(VERSION)/
	mkdir -p out
	tar -C $(BUILD_DIR)/package-root -cJf out/adavalinux-desktop-$(VERSION).syspckg adavalinux-desktop-$(VERSION)
	tar -C $(BUILD_DIR)/package-root -cJf out/adavalinux-theme-default-$(VERSION).syspckg adavalinux-theme-default-$(VERSION)

clean:
	rm -rf $(BUILD_DIR) out
