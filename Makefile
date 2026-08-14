CC ?= cc
CFLAGS ?= -std=c11 -Wall -Wextra -Werror -O2
CPPFLAGS ?= -D_DEFAULT_SOURCE -D_POSIX_C_SOURCE=200809L
LDFLAGS ?=
LDLIBS ?= -lX11
PKG_CONFIG ?= pkg-config
GTK_CFLAGS := $(shell $(PKG_CONFIG) --cflags gtk+-3.0)
GTK_LIBS := $(shell $(PKG_CONFIG) --libs gtk+-3.0)

BUILD_DIR := build
PACKAGE_DIR := packages
VERSION := 0.1.0

.PHONY: all clean package

all: $(BUILD_DIR)/usr/bin/adavalinux-session \
	$(BUILD_DIR)/usr/bin/adavalinux-xfce-start \
	$(BUILD_DIR)/usr/bin/adavalinux-xrefresh \
	$(BUILD_DIR)/usr/bin/adavalinux-logon \
	$(BUILD_DIR)/usr/bin/adavalinux-x-ready \
	$(BUILD_DIR)/usr/bin/adavalinux-display-manager \
	$(BUILD_DIR)/etc/pam.d/adavalinux-logon

$(BUILD_DIR)/usr/bin/adavalinux-session: adavalinux-session
	mkdir -p $(dir $@)
	install -m 0755 $< $@

$(BUILD_DIR)/usr/bin/adavalinux-xfce-start: adavalinux-xfce-start
	mkdir -p $(dir $@)
	install -m 0755 $< $@

$(BUILD_DIR)/usr/bin/adavalinux-lightdm: adavalinux-lightdm
	mkdir -p $(dir $@)
	install -m 0755 $< $@

$(BUILD_DIR)/usr/bin/adavalinux-xrefresh: adavalinux-xrefresh.c
	mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) -o $@ $< -lX11 $(LDLIBS)

$(BUILD_DIR)/usr/bin/adavalinux-logon: adavalinux-logon.c pam_compat.h
	mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(GTK_CFLAGS) $(LDFLAGS) -o $@ adavalinux-logon.c -l:libpam.so.0 $(GTK_LIBS)

$(BUILD_DIR)/usr/bin/adavalinux-x-ready: adavalinux-x-ready.c
	mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) -o $@ $< $(LDLIBS)

$(BUILD_DIR)/usr/bin/adavalinux-display-manager: adavalinux-display-manager
	mkdir -p $(dir $@)
	install -m 0755 $< $@

$(BUILD_DIR)/etc/pam.d/adavalinux-logon: pam.d/adavalinux-logon
	mkdir -p $(dir $@)
	install -m 0644 $< $@

$(BUILD_DIR)/usr/share/adavalinux/themes/default/theme.conf: themes/default/theme.conf
	mkdir -p $(dir $@)
	install -m 0644 $< $@

$(BUILD_DIR)/etc/X11/xorg.conf: xorg.conf
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

package: all $(BUILD_DIR)/etc/X11/xorg.conf
	rm -rf $(BUILD_DIR)/package-root out
	mkdir -p $(BUILD_DIR)/package-root/adavalinux-desktop-$(VERSION)
	cp $(PACKAGE_DIR)/adavalinux-desktop/syspckg-info $(PACKAGE_DIR)/adavalinux-desktop/syspckg-deps $(PACKAGE_DIR)/adavalinux-desktop/install.sh $(PACKAGE_DIR)/adavalinux-desktop/remove.sh $(BUILD_DIR)/package-root/adavalinux-desktop-$(VERSION)/
	mkdir -p $(BUILD_DIR)/package-root/adavalinux-desktop-$(VERSION)/usr/bin
	cp $(BUILD_DIR)/usr/bin/adavalinux-session $(BUILD_DIR)/usr/bin/adavalinux-xfce-start \
		$(BUILD_DIR)/usr/bin/adavalinux-xrefresh $(BUILD_DIR)/usr/bin/adavalinux-logon \
		$(BUILD_DIR)/usr/bin/adavalinux-x-ready \
		$(BUILD_DIR)/usr/bin/adavalinux-display-manager $(BUILD_DIR)/package-root/adavalinux-desktop-$(VERSION)/usr/bin/
	mkdir -p $(BUILD_DIR)/package-root/adavalinux-desktop-$(VERSION)/etc/pam.d
	cp $(BUILD_DIR)/etc/pam.d/adavalinux-logon $(BUILD_DIR)/package-root/adavalinux-desktop-$(VERSION)/etc/pam.d/adavalinux-logon
	mkdir -p $(BUILD_DIR)/package-root/adavalinux-desktop-$(VERSION)/etc/X11
	cp $(BUILD_DIR)/etc/X11/xorg.conf $(BUILD_DIR)/package-root/adavalinux-desktop-$(VERSION)/etc/X11/xorg.conf
	if [ -d font-dejavu-package/font-dejavu-2.37/usr/share/fonts/truetype/dejavu ]; then \
		mkdir -p $(BUILD_DIR)/package-root/adavalinux-desktop-$(VERSION)/usr/share/fonts/truetype/dejavu; \
		cp -a font-dejavu-package/font-dejavu-2.37/usr/share/fonts/truetype/dejavu/*.ttf \
			$(BUILD_DIR)/package-root/adavalinux-desktop-$(VERSION)/usr/share/fonts/truetype/dejavu/; \
	fi
	mkdir -p out
	tar -C $(BUILD_DIR)/package-root -cJf out/adavalinux-desktop-$(VERSION).syspckg adavalinux-desktop-$(VERSION)

clean:
	rm -rf $(BUILD_DIR) out
