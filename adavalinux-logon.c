#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/cursorfont.h>
#include <X11/keysym.h>

#include "pam_compat.h"

#include <pwd.h>
#include <grp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

struct credentials {
    const char *user;
    const char *password;
};

static int conversation(int count, const struct pam_message **messages,
                        struct pam_response **responses, void *data) {
    const struct credentials *credentials = data;
    struct pam_response *reply = calloc((size_t)count, sizeof(*reply));
    if (reply == NULL) return 19;
    for (int i = 0; i < count; ++i) {
        const char *value = NULL;
        if (messages[i]->msg_style == PAM_PROMPT_ECHO_ON) value = credentials->user;
        if (messages[i]->msg_style == PAM_PROMPT_ECHO_OFF) value = credentials->password;
        if (value != NULL) {
            reply[i].resp = strdup(value);
            if (reply[i].resp == NULL) {
                for (int j = 0; j < i; ++j) free(reply[j].resp);
                free(reply);
                return 19;
            }
        }
    }
    *responses = reply;
    return PAM_SUCCESS;
}

static int authenticate(const char *user, const char *password) {
    struct credentials credentials = { user, password };
    struct pam_conv conv = { conversation, &credentials };
    pam_handle_t *handle = NULL;
    int status = pam_start("adavalinux-logon", user, &conv, &handle);
    if (status == PAM_SUCCESS) status = pam_authenticate(handle, 0);
    if (status == PAM_SUCCESS) status = pam_acct_mgmt(handle, 0);
    if (handle != NULL) (void)pam_end(handle, status);
    return status == PAM_SUCCESS;
}

static int start_session(const char *user) {
    struct passwd *account = getpwnam(user);
    if (account == NULL || account->pw_uid < 1000) return 0;
    pid_t pid = fork();
    if (pid < 0) return 0;
    if (pid == 0) {
        (void)initgroups(account->pw_name, account->pw_gid);
        if (setgid(account->pw_gid) != 0 || setuid(account->pw_uid) != 0) _exit(126);
        (void)setenv("HOME", account->pw_dir, 1);
        (void)setenv("USER", account->pw_name, 1);
        (void)setenv("SHELL", account->pw_shell, 1);
        execl("/usr/bin/adavalinux-session", "adavalinux-session", (char *)NULL);
        _exit(127);
    }
    int status = 0;
    return waitpid(pid, &status, 0) > 0 && WIFEXITED(status) && WEXITSTATUS(status) == 0;
}

static void draw(Display *display, Window window, GC gc, int field,
                 const char *user, const char *password, const char *status) {
    const unsigned long white = WhitePixel(display, DefaultScreen(display));
    const unsigned long black = BlackPixel(display, DefaultScreen(display));
    char hidden[128];
    size_t password_len = strlen(password);
    if (password_len >= sizeof(hidden)) password_len = sizeof(hidden) - 1;
    memset(hidden, '*', password_len);
    hidden[password_len] = '\0';

    XSetForeground(display, gc, white);
    XFillRectangle(display, window, gc, 0, 0, 520, 320);
    XSetForeground(display, gc, black);
    XDrawString(display, window, gc, 40, 42, "AdavaLinux Logon", 16);
    XDrawString(display, window, gc, 40, 90, "User:", 5);
    XDrawString(display, window, gc, 140, 90, user, (int)strlen(user));
    XDrawString(display, window, gc, 40, 140, "Password:", 9);
    XDrawString(display, window, gc, 140, 140, hidden, (int)strlen(hidden));

    XSetLineAttributes(display, gc, 2, LineSolid, CapButt, JoinMiter);
    XDrawRectangle(display, window, gc, 132, 70, 340, 28);
    XDrawRectangle(display, window, gc, 132, 120, 340, 28);
    XDrawRectangle(display, window, gc, 190, 180, 140, 38);
    XDrawString(display, window, gc, 230, 205, "Login", 5);
    XDrawString(display, window, gc, 40, 270, status, (int)strlen(status));
    if (field == 0) XDrawRectangle(display, window, gc, 132, 70, 340, 28);
    else XDrawRectangle(display, window, gc, 132, 120, 340, 28);
    XFlush(display);
}

int main(void) {
    Display *display = XOpenDisplay(NULL);
    if (display == NULL) {
        fputs("adavalinux-logon: cannot open X display\n", stderr);
        return 1;
    }
    int screen = DefaultScreen(display);
    Window root = RootWindow(display, screen);
    Window window = XCreateSimpleWindow(display, root,
        (DisplayWidth(display, screen) - 520) / 2,
        (DisplayHeight(display, screen) - 320) / 2,
        520, 320, 1, BlackPixel(display, screen), WhitePixel(display, screen));
    XStoreName(display, window, "AdavaLinux Logon");
    XClassHint class_hint = { "AdavaLinuxLogon", "AdavaLinux" };
    XSetClassHint(display, window, &class_hint);
    XSizeHints size_hints = { .flags = PMinSize | PMaxSize,
                              .min_width = 520, .min_height = 320,
                              .max_width = 520, .max_height = 320 };
    XSetWMNormalHints(display, window, &size_hints);
    Atom wm_delete = XInternAtom(display, "WM_DELETE_WINDOW", False);
    XSetWMProtocols(display, window, &wm_delete, 1);
    Cursor cursor = XCreateFontCursor(display, XC_left_ptr);
    XDefineCursor(display, window, cursor);
    XSelectInput(display, window, ExposureMask | KeyPressMask | ButtonPressMask | FocusChangeMask);
    XMapRaised(display, window);
    XSetInputFocus(display, window, RevertToParent, CurrentTime);

    GC gc = XCreateGC(display, window, 0, NULL);
    char user[64] = "";
    char password[128] = "";
    char status[128] = "Enter your user name and password";
    int field = 0;
    int running = 1;

    while (running) {
        XEvent event;
        XNextEvent(display, &event);
        if (event.type == Expose) {
            draw(display, window, gc, field, user, password, status);
        } else if (event.type == FocusIn) {
            XSetInputFocus(display, window, RevertToParent, CurrentTime);
        } else if (event.type == ClientMessage && (Atom)event.xclient.data.l[0] == wm_delete) {
            running = 0;
        } else if (event.type == ButtonPress) {
            int y = event.xbutton.y;
            if (y >= 65 && y <= 105) field = 0;
            else if (y >= 115 && y <= 155) field = 1;
            else if (y >= 175 && y <= 225) {
                if (field == 0) field = 1;
                else if (user[0] != '\0' && authenticate(user, password) && start_session(user)) {
                    running = 0;
                } else {
                    password[0] = '\0';
                    snprintf(status, sizeof(status), "%s", "Authentication failed");
                }
            }
            draw(display, window, gc, field, user, password, status);
        } else if (event.type == KeyPress) {
            char text[32];
            KeySym key;
            int count = XLookupString(&event.xkey, text, sizeof(text), &key, NULL);
            char *value = field == 0 ? user : password;
            size_t value_size = field == 0 ? sizeof(user) : sizeof(password);
            if (key == XK_Escape) running = 0;
            else if (key == XK_Tab || key == XK_Return) {
                if (field == 0) field = 1;
                else if (key == XK_Return && user[0] != '\0' && authenticate(user, password) && start_session(user)) running = 0;
            } else if (key == XK_BackSpace) {
                size_t length = strlen(value);
                if (length > 0) value[length - 1] = '\0';
            } else if (count > 0 && text[0] >= 32 && text[0] < 127) {
                size_t length = strlen(value);
                if (length + (size_t)count < value_size) {
                    memcpy(value + length, text, (size_t)count);
                    value[length + (size_t)count] = '\0';
                }
            }
            draw(display, window, gc, field, user, password, status);
        }
    }
    XFreeCursor(display, cursor);
    XFreeGC(display, gc);
    XDestroyWindow(display, window);
    XCloseDisplay(display);
    return 0;
}
