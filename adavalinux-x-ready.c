#include <X11/Xlib.h>

int main(void) {
    Display *display = XOpenDisplay(NULL);
    if (display == NULL) {
        return 1;
    }
    XCloseDisplay(display);
    return 0;
}
