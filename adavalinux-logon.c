#include <gtk/gtk.h>

#include "pam_compat.h"

#include <dlfcn.h>
#include <fcntl.h>
#include <grp.h>
#include <pwd.h>
#include <shadow.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

struct credentials {
    const char *user;
    const char *password;
};

struct login_ui {
    GtkWidget *window;
    GtkWidget *user_entry;
    GtkWidget *password_entry;
    GtkWidget *status;
};

static void log_auth_message(const char *message, const char *user, int status)
{
    FILE *log = fopen("/var/log/adavalinux-logon.log", "a");
    if (log == NULL)
        return;
    fprintf(log, "%s user=%s status=%d\n", message, user != NULL ? user : "(null)", status);
    fclose(log);
}

static int conversation(int count, const struct pam_message **messages,
                        struct pam_response **responses, void *data)
{
    const struct credentials *credentials = data;
    struct pam_response *reply = calloc((size_t)count, sizeof(*reply));
    if (reply == NULL)
        return PAM_CONV_ERR;

    for (int i = 0; i < count; i++) {
        const char *value = NULL;
        if (messages[i]->msg_style == PAM_PROMPT_ECHO_ON)
            value = credentials->user;
        else if (messages[i]->msg_style == PAM_PROMPT_ECHO_OFF)
            value = credentials->password;

        if (value != NULL && (reply[i].resp = strdup(value)) == NULL) {
            for (int j = 0; j < i; j++)
                free(reply[j].resp);
            free(reply);
            return PAM_CONV_ERR;
        }
    }

    *responses = reply;
    return PAM_SUCCESS;
}

/*
 * PAM is the preferred authentication path.  Minimal AdavaLinux systems can
 * nevertheless have a working BusyBox/TTY login while pam_unix cannot be
 * loaded from the package layout.  In that case verify the same /etc/shadow
 * password directly.  The display manager runs this program as root.
 */
static int shadow_authenticate(const char *user, const char *password)
{
    struct passwd *account = getpwnam(user);
    if (account == NULL || account->pw_uid < 1000)
        return 0;

    const char *hash = account->pw_passwd;
    if (hash == NULL)
        return 0;

    if (strcmp(hash, "x") == 0) {
        struct spwd *shadow = getspnam(user);
        if (shadow == NULL || shadow->sp_pwdp == NULL)
            return 0;
        hash = shadow->sp_pwdp;
    }

    if (hash[0] == '\0' || hash[0] == '!' || hash[0] == '*')
        return 0;

    void *crypt_library = dlopen("libcrypt.so.1", RTLD_NOW | RTLD_LOCAL);
    if (crypt_library == NULL)
        crypt_library = dlopen("libcrypt.so", RTLD_NOW | RTLD_LOCAL);
    if (crypt_library == NULL) {
        log_auth_message("shadow auth: libcrypt unavailable", user, -1);
        return 0;
    }

    typedef char *(*crypt_function)(const char *, const char *);
    dlerror();
    crypt_function crypt_password = (crypt_function)dlsym(crypt_library, "crypt");
    const char *symbol_error = dlerror();
    if (symbol_error != NULL || crypt_password == NULL) {
        log_auth_message("shadow auth: crypt symbol unavailable", user, -1);
        dlclose(crypt_library);
        return 0;
    }

    char *candidate = crypt_password(password, hash);
    int ok = candidate != NULL && strcmp(candidate, hash) == 0;
    dlclose(crypt_library);

    log_auth_message(ok ? "shadow auth succeeded" : "shadow auth failed", user, ok ? 0 : 1);
    return ok;
}

/*
 * Returns 1 when the password is valid.  A non-NULL PAM handle means the
 * session should also be opened/closed through PAM.  If PAM is broken but
 * /etc/shadow authentication succeeds, the handle remains NULL and the XFCE
 * session is started directly.
 */
static int authenticate(const char *user, const char *password, pam_handle_t **out_handle)
{
    *out_handle = NULL;

    struct credentials credentials = { user, password };
    struct pam_conv conv = { conversation, &credentials };
    pam_handle_t *handle = NULL;

    int status = pam_start("adavalinux-logon", user, &conv, &handle);
    if (status == PAM_SUCCESS)
        status = pam_authenticate(handle, 0);
    if (status == PAM_SUCCESS)
        status = pam_acct_mgmt(handle, 0);

    if (status == PAM_SUCCESS) {
        log_auth_message("PAM authentication succeeded", user, status);
        *out_handle = handle;
        return 1;
    }

    log_auth_message("PAM authentication failed; trying shadow fallback", user, status);
    if (handle != NULL)
        (void)pam_end(handle, status);

    return shadow_authenticate(user, password);
}

static int start_session(pam_handle_t *handle, const char *user)
{
    struct passwd *account = getpwnam(user);
    if (account == NULL || account->pw_uid < 1000)
        return 0;

    pid_t pid = fork();
    if (pid < 0)
        return 0;

    if (pid == 0) {
        int log_fd = open("/var/log/adavalinux-logon.log",
                          O_WRONLY | O_CREAT | O_APPEND, 0644);
        if (log_fd >= 0) {
            (void)dup2(log_fd, STDOUT_FILENO);
            (void)dup2(log_fd, STDERR_FILENO);
            if (log_fd > STDERR_FILENO)
                (void)close(log_fd);
        }

        if (handle != NULL) {
            if (pam_setcred(handle, PAM_ESTABLISH_CRED) != PAM_SUCCESS ||
                pam_open_session(handle, 0) != PAM_SUCCESS)
                _exit(126);
        }

        if (initgroups(account->pw_name, account->pw_gid) != 0 ||
            setgid(account->pw_gid) != 0 || setuid(account->pw_uid) != 0)
            _exit(126);

        if (chdir(account->pw_dir) != 0)
            _exit(126);

        (void)setenv("HOME", account->pw_dir, 1);
        (void)setenv("USER", account->pw_name, 1);
        (void)setenv("LOGNAME", account->pw_name, 1);
        (void)setenv("SHELL", account->pw_shell, 1);

        execl("/usr/bin/adavalinux-session", "adavalinux-session", (char *)NULL);
        _exit(127);
    }

    int status = 0;
    int session_ok = waitpid(pid, &status, 0) == pid &&
                     WIFEXITED(status) && WEXITSTATUS(status) == 0;

    if (handle != NULL) {
        (void)pam_close_session(handle, 0);
        (void)pam_setcred(handle, PAM_DELETE_CRED);
    }

    return session_ok;
}

static void show_status(struct login_ui *ui, const char *message)
{
    gtk_label_set_text(GTK_LABEL(ui->status), message);
    gtk_widget_set_visible(ui->status, TRUE);
}

static void submit_login(struct login_ui *ui)
{
    const char *user = gtk_entry_get_text(GTK_ENTRY(ui->user_entry));
    const char *password = gtk_entry_get_text(GTK_ENTRY(ui->password_entry));

    if (user[0] == '\0' || password[0] == '\0') {
        show_status(ui, "Enter both user name and password.");
        return;
    }

    pam_handle_t *handle = NULL;
    if (!authenticate(user, password, &handle)) {
        gtk_entry_set_text(GTK_ENTRY(ui->password_entry), "");
        show_status(ui, "Incorrect user name or password.");
        gtk_widget_grab_focus(ui->password_entry);
        return;
    }

    gtk_widget_hide(ui->window);
    while (gtk_events_pending())
        gtk_main_iteration();
    gdk_display_flush(gdk_display_get_default());

    if (!start_session(handle, user)) {
        gtk_widget_show_all(ui->window);
        gtk_entry_set_text(GTK_ENTRY(ui->password_entry), "");
        show_status(ui, "Unable to start the desktop session.");
        gtk_widget_grab_focus(ui->password_entry);
    } else {
        gtk_widget_show_all(ui->window);
        gtk_entry_set_text(GTK_ENTRY(ui->password_entry), "");
        gtk_widget_grab_focus(ui->password_entry);
    }

    if (handle != NULL)
        (void)pam_end(handle, PAM_SUCCESS);
}

static void on_login_clicked(GtkButton *button, gpointer data)
{
    (void)button;
    submit_login(data);
}

static void on_password_activate(GtkEntry *entry, gpointer data)
{
    (void)entry;
    submit_login(data);
}

static void set_arrow_cursor(GtkWidget *widget, gpointer data)
{
    (void)data;

    GdkWindow *window = gtk_widget_get_window(widget);
    if (window == NULL)
        return;

    GdkDisplay *display = gdk_window_get_display(window);
    GdkCursor *cursor = gdk_cursor_new_for_display(display, GDK_LEFT_PTR);
    if (cursor != NULL) {
        gdk_window_set_cursor(window, cursor);
        g_object_unref(cursor);
    }
}

static void install_css(void)
{
    static const char css[] =
        "#logon-window {"
        "  background-image: linear-gradient(135deg, #f5a623 0%, #f7c65b 42%, #c8ee7d 72%, #a8df67 100%);"
        "}"
        ".login-card {"
        "  background: rgba(250, 252, 247, 0.94);"
        "  border-radius: 18px;"
        "  padding: 34px;"
        "  box-shadow: 0 10px 28px rgba(0, 0, 0, 0.22);"
        "}"
        ".login-title { font-size: 30px; font-weight: bold; color: #25321e; }"
        ".login-subtitle { color: #556149; }"
        ".login-error { color: #b42318; font-weight: bold; }"
        "entry { padding: 11px; min-height: 24px; }"
        "button { padding: 10px 20px; }";

    GtkCssProvider *provider = gtk_css_provider_new();
    gtk_css_provider_load_from_data(provider, css, -1, NULL);
    gtk_style_context_add_provider_for_screen(
        gdk_screen_get_default(),
        GTK_STYLE_PROVIDER(provider),
        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    g_object_unref(provider);
}

int main(int argc, char **argv)
{
    gtk_init(&argc, &argv);
    install_css();

    struct login_ui ui = {0};
    ui.window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_widget_set_name(ui.window, "logon-window");
    gtk_window_set_title(GTK_WINDOW(ui.window), "AdavaLinux Logon");
    gtk_window_set_decorated(GTK_WINDOW(ui.window), FALSE);
    gtk_window_set_resizable(GTK_WINDOW(ui.window), TRUE);
    gtk_window_set_position(GTK_WINDOW(ui.window), GTK_WIN_POS_CENTER);
    gtk_window_fullscreen(GTK_WINDOW(ui.window));
    gtk_window_set_keep_above(GTK_WINDOW(ui.window), TRUE);

    g_signal_connect(ui.window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
    g_signal_connect(ui.window, "realize", G_CALLBACK(set_arrow_cursor), NULL);

    GtkWidget *background = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_widget_set_hexpand(background, TRUE);
    gtk_widget_set_vexpand(background, TRUE);
    gtk_container_add(GTK_CONTAINER(ui.window), background);

    GtkWidget *card = gtk_box_new(GTK_ORIENTATION_VERTICAL, 14);
    gtk_style_context_add_class(gtk_widget_get_style_context(card), "login-card");
    gtk_widget_set_size_request(card, 460, -1);
    gtk_widget_set_halign(card, GTK_ALIGN_CENTER);
    gtk_widget_set_valign(card, GTK_ALIGN_CENTER);
    gtk_container_set_border_width(GTK_CONTAINER(card), 26);
    gtk_box_pack_start(GTK_BOX(background), card, TRUE, FALSE, 0);

    GtkWidget *title = gtk_label_new("Welcome to AdavaLinux");
    gtk_style_context_add_class(gtk_widget_get_style_context(title), "login-title");
    gtk_widget_set_halign(title, GTK_ALIGN_START);
    gtk_box_pack_start(GTK_BOX(card), title, FALSE, FALSE, 0);

    GtkWidget *subtitle = gtk_label_new("Sign in to start your XFCE desktop.");
    gtk_style_context_add_class(gtk_widget_get_style_context(subtitle), "login-subtitle");
    gtk_widget_set_halign(subtitle, GTK_ALIGN_START);
    gtk_box_pack_start(GTK_BOX(card), subtitle, FALSE, FALSE, 0);

    ui.user_entry = gtk_entry_new();
    gtk_entry_set_placeholder_text(GTK_ENTRY(ui.user_entry), "User name");
    gtk_box_pack_start(GTK_BOX(card), ui.user_entry, FALSE, FALSE, 6);

    ui.password_entry = gtk_entry_new();
    gtk_entry_set_placeholder_text(GTK_ENTRY(ui.password_entry), "Password");
    gtk_entry_set_visibility(GTK_ENTRY(ui.password_entry), FALSE);
    gtk_entry_set_invisible_char(GTK_ENTRY(ui.password_entry), 0x2022);
    gtk_box_pack_start(GTK_BOX(card), ui.password_entry, FALSE, FALSE, 0);

    ui.status = gtk_label_new("");
    gtk_style_context_add_class(gtk_widget_get_style_context(ui.status), "login-error");
    gtk_widget_set_halign(ui.status, GTK_ALIGN_START);
    gtk_box_pack_start(GTK_BOX(card), ui.status, FALSE, FALSE, 0);

    GtkWidget *button = gtk_button_new_with_label("Log in");
    gtk_widget_set_halign(button, GTK_ALIGN_END);
    gtk_box_pack_end(GTK_BOX(card), button, FALSE, FALSE, 8);

    g_signal_connect(button, "clicked", G_CALLBACK(on_login_clicked), &ui);
    g_signal_connect(ui.password_entry, "activate", G_CALLBACK(on_password_activate), &ui);

    gtk_widget_show_all(ui.window);
    gtk_widget_set_visible(ui.status, FALSE);
    gtk_widget_grab_focus(ui.user_entry);
    gtk_main();
    return 0;
}
