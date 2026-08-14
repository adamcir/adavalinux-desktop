#!/usr/bin/env sh
set -eu

grep -Fq '$(BUILD_DIR)/usr/bin/adavalinux-logon' Makefile
grep -Fq '$(BUILD_DIR)/usr/bin/adavalinux-display-manager' Makefile
grep -Fq '$(BUILD_DIR)/usr/bin/adavalinux-x-ready' Makefile
grep -Fq '$(BUILD_DIR)/etc/pam.d/adavalinux-logon' Makefile
grep -Fq 'Xorg "$display" vt1 -nolisten tcp &' adavalinux-display-manager
grep -Fq 'DISPLAY="$display" /usr/bin/adavalinux-logon' adavalinux-display-manager
grep -Fqx '#include <gtk/gtk.h>' adavalinux-logon.c
grep -Fq 'gtk_entry_set_visibility(GTK_ENTRY(ui.password_entry), FALSE)' adavalinux-logon.c
grep -Fq 'gtk_css_provider_load_from_data' adavalinux-logon.c
grep -Fq 'pam_open_session(handle, 0)' adavalinux-logon.c
grep -Fq 'pam_close_session(handle, 0)' adavalinux-logon.c
grep -Fq 'if (chdir(account->pw_dir) != 0)' adavalinux-logon.c
grep -Fq 'gtk_button_new_with_label("Log in")' adavalinux-logon.c
grep -Fq 'gtk_widget_hide(ui->window)' adavalinux-logon.c
grep -Fq 'while (gtk_events_pending())' adavalinux-logon.c
grep -Fq 'gdk_display_flush(gdk_display_get_default())' adavalinux-logon.c
grep -Fq 'gtk_widget_show_all(ui->window)' adavalinux-logon.c
grep -Fq 'gdk_cursor_new_for_display' adavalinux-logon.c
grep -Fq 'GDK_LEFT_PTR' adavalinux-logon.c
grep -Fq 'open("/var/log/adavalinux-logon.log", O_WRONLY | O_CREAT | O_APPEND, 0644)' adavalinux-logon.c
grep -Fq 'dup2(log_fd, STDERR_FILENO)' adavalinux-logon.c

printf '%s\n' 'desktop logon window test passed'
