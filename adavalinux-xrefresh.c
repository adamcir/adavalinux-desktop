#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <stdlib.h>

static void refresh_tree(Display *display, Window window) {
    Window root, parent, *children = NULL;
    unsigned int count = 0;
    XWindowAttributes attributes;
    /* InputOnly windows cannot be cleared and make XClearArea fail BadMatch. */
    if (XGetWindowAttributes(display, window, &attributes) &&
        attributes.class == InputOutput)
        XClearArea(display, window, 0, 0, 0, 0, True);
    if (XQueryTree(display, window, &root, &parent, &children, &count)) {
        for (unsigned int i = 0; i < count; ++i)
            refresh_tree(display, children[i]);
        if (children)
            XFree(children);
    }
}

int main(void) {
    const char *name = getenv("DISPLAY");
    Display *display = XOpenDisplay(name && *name ? name : NULL);
    if (!display)
        return 1;
    refresh_tree(display, DefaultRootWindow(display));
    XFlush(display);
    XCloseDisplay(display);
    return 0;
}
