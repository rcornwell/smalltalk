/*
 * Smalltalk interpreter: X Windows interface.
 *
 * Copyright 1999-2017 Richard P. Cornwell.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the the Artistic License (2.0). You may obtain a copy
 * of the full license at:
 *
 * http://www.perlfoundation.org/artistic_license_2_0
 *
 * Any use, modification, and distribution of the Standard or Modified
 * Versions is governed by this Artistic License. By using, modifying or
 * distributing the Package, you accept this license. Do not use, modify, or
 * distribute the Package, if you do not accept this license.
 *
 * If your Modified Version has been derived from a Modified Version made by
 * someone other than you, you are nevertheless required to ensure that your
 * Modified Version complies with the requirements of this license.
 *
 * This license does not grant you the right to use any trademark, service
 * mark, tradename, or logo of the Copyright Holder.
 *
 * Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
 * AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
 * YOUR LOCAL LAW.  UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
 * CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
 * CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Log: xwin.c,v $
 * Revision 1.10 2020/07/12 16:00:00  rich
 * Support for 64 bit compiler.
 * Coverity cleanup.
 *
 * Revision 1.5  2002/02/17 13:41:59  rich
 * Added translation of arrow keys into character codes.
 *
 * Revision 1.4  2002/02/07 04:21:05  rich
 * Added code to request size of window to be last window size.
 * Added code to change current working directory.
 *
 * Revision 1.3  2002/01/29 16:40:38  rich
 * Fixed bugs in saving images under unix.
 *   By makeing timer events post only when system requests them.
 *
 * Revision 1.2  2001/08/29 20:16:35  rich
 * Added graphics support.
 * Added timer support.
 * Added signal blocking around system calls.
 *
 * Revision 1.1  2001/08/18 16:23:10  rich
 * Initial revision
 *
 *
 */


#ifndef WIN32

/* System stuff */
#include <dirent.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#ifdef sun
#include <sys/filio.h>
#endif
#include <sys/timeb.h>
#include <time.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <stdint.h>

#include <X11/X.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>

/* Local stuff */
#include "smalltalk.h"
#include "object.h"
#include "interp.h"
#include "smallobjs.h"
#include "system.h"
#include "fileio.h"
#include "graphic.h"

static void         process_time();
static void         processX();
static Display     *display;
static Cursor       cursor = -1;
static int          screen;
static Visual      *visual;
static Window       window;
static Window       root;
static XImage      *display_image;
static GC           gc;
static uint32_t     fg, bg;
static XColor       blk, wht;
static int          xconn = -1;
static int          buttons = 0;

static int          fill_buffer();
static void         timer_handler(int);
uint32_t           *display_bits = NULL;

/* Initialize the system. */
int
initSystem()
{
    struct sigaction    sa, osa;
    struct itimerval    tv, otv;

    /* Initialize event queues */
    init_event(&input_queue);
    init_event(&asyncsigs);

    sigemptyset(&sa.sa_mask);
    sa.sa_handler = timer_handler;
    sa.sa_flags = SA_NOMASK;
    sigaction(SIGALRM, &sa, &osa);
    tv.it_interval.tv_usec = 50000;
    tv.it_interval.tv_sec = 0;
    tv.it_value.tv_usec = 50000;
    tv.it_value.tv_sec = 0;

    setitimer(ITIMER_REAL, &tv, &otv);
    return 1;
}

static int	time_events = 0;
/* Handle the alarm timer */
void
timer_handler(int sig)
{
    time_events += 20;
}

/* Shutdown the system. */
void
endSystem()
{
    struct sigaction    sa, osa;
    struct itimerval    tv, otv;

    tv.it_interval.tv_usec = 0;
    tv.it_interval.tv_sec = 0;
    tv.it_value.tv_usec = 0;
    tv.it_value.tv_sec = 0;
    setitimer(ITIMER_REAL, &tv, &otv);
    sa.sa_handler = SIG_IGN;
    sa.sa_flags = SA_NOMASK;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGALRM, &sa, &osa);

    if (display_image != (XImage *) NULL) {
	XDestroyImage(display_image);
	display_image = (XImage *) NULL;
	display_bits = NULL;
    }
    if (xconn >= 0) {
	XCloseDisplay(display);
	xconn = -1;
    }
}

/* Become the cursor */
Objptr
BeCursor(Objptr op)
{
    int                 height, width;
    int                 rwidth;
    Objptr              offset;
    int                 hot_x, hot_y;
    Pixmap              main_pix, mask_pix;
    uint32_t           *main_bits, *mask_bits;
    XImage             *main_img, *main_subimg;
    XImage             *mask_img, *mask_subimg;
    GC                  main_gc, mask_gc;
    sigset_t            hold, old;

    /* Remove old cursor first */
    if (op == NilPtr) {
	cursor_object = op;
	rootObjects[CURSOBJ] = op;
	if (cursor != -1) {
	    XUndefineCursor(display, window);
	    XFreeCursor(display, cursor);
	}
	return op;
    }

    /* Extract cursor information */
    height = get_integer(op, FORM_HEIGHT);
    width = get_integer(op, FORM_WIDTH);
    rwidth = ((width & 0x1f) == 0) ? width : ((width | 0x1f) + 1);
    offset = get_pointer(op, FORM_OFFSET);
    hot_x = get_integer(offset, XINDEX);
    hot_y = get_integer(offset, YINDEX);
    offset = get_pointer(op, FORM_BITMAP);
    main_bits = (uint32_t *) (get_object_base(offset) +
				   (fixed_size(offset) * sizeof(Objptr)));

    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    main_img =
	XCreateImage(display, visual, 1, XYBitmap, 0, (char *) main_bits,
		     rwidth, height, 32, 0);
    main_subimg = XSubImage(main_img, 0, 0, width, height);

    main_pix = XCreatePixmap(display, window, width, height, 1);
    main_gc = XCreateGC(display, main_pix, 0, 0);
    XSetForeground(display, main_gc, fg);
    XSetBackground(display, main_gc, bg);
    XSetFunction(display, main_gc, GXcopyInverted);
    XPutImage(display, main_pix, main_gc, main_subimg, 0, 0, 0, 0,
	      width, height);

    /* now biuld mask */
    offset = get_pointer(get_pointer(op, FORM_MASK), FORM_BITMAP);
    mask_bits = (uint32_t *) (get_object_base(offset) +
				   (fixed_size(offset) * sizeof(Objptr)));

    mask_img =
	XCreateImage(display, visual, 1, XYBitmap, 0, (char *) mask_bits,
		     rwidth, height, 32, 0);
    mask_subimg = XSubImage(mask_img, 0, 0, width, height);

    mask_pix = XCreatePixmap(display, window, width, height, 1);
    mask_gc = XCreateGC(display, mask_pix, 0, 0);
    XSetForeground(display, mask_gc, fg);
    XSetBackground(display, mask_gc, bg);
    XSetFunction(display, mask_gc, GXcopy);
    XPutImage(display, mask_pix, mask_gc, mask_subimg, 0, 0, 0, 0, width,
	      height);

    /* Remove old cursor first */
    cursor_object = op;
    rootObjects[CURSOBJ] = op;
    if (cursor != -1) {
	XUndefineCursor(display, window);
	XFreeCursor(display, cursor);
    }

    /* Create a new one */
    cursor = XCreatePixmapCursor(display, main_pix, mask_pix, &blk, &wht,
				 hot_x, hot_y);
    XDefineCursor(display, window, cursor);
    XFlush(display);

    /* Free temp stuff */
#if 0
    XDestroyImage(main_subimg);
    XDestroyImage(main_img);
    XDestroyImage(mask_subimg);
    XDestroyImage(mask_img);
#endif
    XFreePixmap(display, mask_pix);
    XFreePixmap(display, main_pix);
    XFreeGC(display, main_gc);
    XFreeGC(display, mask_gc);
    sigprocmask(SIG_UNBLOCK, &hold, &old);
    return op;
}

/* Become display object */
Objptr
BeDisplay(Objptr op)
{
    if (display_object == op)
	return op;

    /* If setting display to NilPtr, free our work */
    if (op == NilPtr) {
	if (display_image != (XImage *) NULL) {
	    XDestroyImage(display_image);
	    display_image = (XImage *) NULL;
	    display_bits = NULL;
	}
	if (xconn >= 0) {
	    XCloseDisplay(display);
	    xconn = -1;
	}
	display_object = op;
	rootObjects[DISPOBJ] = op;	/* Very bad if it gets freed */
	return op;
    }

    if (display_object == NilPtr) {
	XSetWindowAttributes attributes;
	uint32_t            attr_mask;
	XSizeHints          sizehints;
	char               *dispenv;
	int                 event_mask;
	char               *prog = "smalltalk";
	sigset_t            hold, old;
	Objptr		    temp;

	/* Prevent signals while processing events */
	sigemptyset(&hold);
	sigaddset(&hold, SIGALRM);
	sigprocmask(SIG_BLOCK, &hold, &old);

	if ((dispenv = getenv("DISPLAY")) == NULL)
	    error("Unable to find DISPLAY variable");
	display = XOpenDisplay(dispenv);
	screen = DefaultScreen(display);
	root = DefaultRootWindow(display);

	/* Set up hints */
	sizehints.x = 0;
	sizehints.y = 0;
	sizehints.width = 1024;
	sizehints.height = 1024;
	sizehints.flags = USSize;

	if (geometry != NULL) {
            int              x, y;
	    unsigned int     width, height, mask;

	    mask = XParseGeometry(geometry, &x, &y, &width, &height);
	    if (mask & XValue) {
		sizehints.x = x;
		sizehints.flags |= USPosition;
	    }
	    if (mask & YValue) {
		sizehints.y = y;
		sizehints.flags |= USPosition;
	    }
	    if (mask & WidthValue)
		sizehints.width = width;
	    if (mask & HeightValue)
		sizehints.height = height;
	}

	temp = get_pointer(display_object, FORM_WIDTH);
	if (is_integer(temp))
	    sizehints.width = as_integer(temp);
        temp = get_pointer(display_object, FORM_HEIGHT);
	if (is_integer(temp))
	    sizehints.height = as_integer(temp);

	fg = WhitePixel(display, screen);
	bg = BlackPixel(display, screen);

	visual = CopyFromParent;

	attributes.event_mask = ExposureMask;
	attributes.border_pixel = bg;
	attributes.background_pixel = fg;

	attr_mask = CWEventMask | CWBackPixel | CWBorderPixel;

	window = XCreateWindow(display, root, sizehints.x, sizehints.y,
			       sizehints.width, sizehints.height, 1,
			       CopyFromParent, InputOutput, visual,
			       attr_mask, &attributes);
	XSetStandardProperties(display, window, prog, prog, None, NULL, 0,
			       &sizehints);

	gc = XCreateGC(display, window, 0, 0);
	XSetForeground(display, gc, fg);
	XSetBackground(display, gc, bg);
	XSetFunction(display, gc, GXcopyInverted);

	blk.pixel = fg;
	wht.pixel = bg;

	XQueryColor(display, DefaultColormap(display, screen), &blk);
	XQueryColor(display, DefaultColormap(display, screen), &wht);

	event_mask = ExposureMask | KeyPressMask | PointerMotionMask |
	    ButtonPressMask | ButtonReleaseMask | StructureNotifyMask;
	XSelectInput(display, window, event_mask);

	XMapRaised(display, window);
	XFlush(display);

	display_image = (XImage *) NULL;
	/* Collect connection number for waiting */
	xconn = XConnectionNumber(display);

	display_object = op;
	rootObjects[DISPOBJ] = op;	/* Very bad if it gets freed */

	sigprocmask(SIG_UNBLOCK, &hold, &old);

	while (display_image == (XImage *) NULL)
	    WaitEvent(1);
    }
    display_object = op;
    rootObjects[DISPOBJ] = op;	/* Very bad if it gets freed */
    return op;
}

/* Update the section of the display that has changed */
void
UpdateDisplay(Copy_bits bits)
{
    XPutImage(display, window, gc, display_image,
	      bits->dx, bits->dy, bits->dx, bits->dy, bits->w, bits->h);
    XFlush(display);
}

/*
 * Wait for an external event. if suspend flag is true, we halt until
 * something interesting happens.
 */
int
WaitEvent(int suspend)
{
    fd_set              chk_bits;
    int                 high = 0;
    struct timeval      timeout;

    FD_ZERO(&chk_bits);
    FD_SET(0, &chk_bits);
    if (xconn >= 0) {
	FD_SET(xconn, &chk_bits);
	high = xconn;
    }
    timeout.tv_sec = 1;
    timeout.tv_usec = 0;
    process_time();
    if (select(high + 1, &chk_bits, NULL, NULL, &timeout) > 0) {
	process_time();
	if (FD_ISSET(0, &chk_bits))
	    fill_buffer();
	if (xconn >= 0 && FD_ISSET(xconn, &chk_bits))
	    processX();
    }
    return 1;
}

static void process_time()
{
    sigset_t            hold, old;

    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    while(time_events-- > 0)
       PostEvent(EVENT_TIMER, 0);

    sigprocmask(SIG_UNBLOCK, &hold, &old);
}
 
/* Process X events */
static void
processX()
{
    XEvent              ev;
    char                keybuffer[20];
    int                 crow, ccol;
    int                 roundcol;
    int                 bmsize;
    int                 i, j;
    sigset_t            hold, old;

    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    while (XPending(display)) {
	KeySym	keypress;

	XNextEvent(display, &ev);

	switch (ev.type) {
	case KeyPress:
	    PostEvent(EVENT_MOUSEPOS, ((ev.xkey.y & 0xfff) << 12) +
		      (ev.xkey.x & 0xfff));
	    i = XLookupString(&ev.xkey, keybuffer,
			      sizeof(keybuffer), &keypress, NULL);
	    if (i == 0) {
		char c = 0;
		switch(keypress) {
		/* Cursor control & motion */
		case XK_Home:
			c = 0x80;
			break;
 		case XK_Left:
			c = 0x81;
			break;
 		case XK_Up:
			c = 0x82;
			break;
 		case XK_Right:
			c = 0x83;
			break;
 		case XK_Down:
			c = 0x84;
			break;
 		case XK_Page_Up:
			c = 0x85;
			break;
 		case XK_Page_Down:
			c = 0x86;
			break;
 		case XK_End:
			c = 0x87;
			break;
 		case XK_Begin:
			c = 0x88;
			break;
		default:
			break;
		}
		if (c != 0) 
			keybuffer[i++] = c;
	    }
	    for (j = 0; j < i; j++) 
		PostEvent(EVENT_CHAR, keybuffer[j]);
	    break;

	case ButtonPress:
	    buttons |= (1 << (ev.xbutton.button - 1));
	    PostEvent(EVENT_MOUSEBUT, buttons);
	    PostEvent(EVENT_MOUSEPOS, ((ev.xbutton.y & 0xfff) << 12) +
		      (ev.xbutton.x & 0xfff));
	    break;

	case ButtonRelease:
	    buttons &= ~(1 << (ev.xbutton.button - 1));
	    PostEvent(EVENT_MOUSEBUT, buttons);
	    PostEvent(EVENT_MOUSEPOS, ((ev.xbutton.y & 0xfff) << 12) +
		      (ev.xbutton.x & 0xfff));
	    break;

	case MotionNotify:
	    PostEvent(EVENT_MOUSEPOS, ((ev.xmotion.y & 0xfff) << 12) +
		      (ev.xmotion.x & 0xfff));
	    break;

	case ConfigureNotify:
	    crow = get_integer(display_object, FORM_HEIGHT);
	    ccol = get_integer(display_object, FORM_WIDTH);
	    if (display_bits != NULL && crow == ev.xconfigure.height
		&& ccol == ev.xconfigure.width)
		break;

	    if ((ev.xconfigure.width & 0x1f) != 0)
		roundcol = 1 + (ev.xconfigure.width | 0x1f);
	    else
		roundcol = ev.xconfigure.width;
	    if (display_image != (XImage *) NULL)
		XDestroyImage(display_image);
	    bmsize = (roundcol / 8) * ev.xconfigure.height;
	    if ((display_bits = (uint32_t *) malloc(bmsize)) == NULL)
		break;
	    display_image = XCreateImage(display, visual, 1, XYBitmap,
					 0, (char *) display_bits,
					 roundcol, ev.xconfigure.height,
					 32, 0);
	    Set_integer(display_object, FORM_HEIGHT, ev.xconfigure.height);
	    Set_integer(display_object, FORM_WIDTH, ev.xconfigure.width);
	    PostEvent(EVENT_RESIZE, 0);
	    break;

	case Expose:
	    if (display_image == NULL)
		break;
	    XPutImage(display, window, gc, display_image,
		      ev.xexpose.x, ev.xexpose.y,
		      ev.xexpose.x, ev.xexpose.y,
		      ev.xexpose.width, ev.xexpose.height);

	    break;

	default:
	    break;
	}
    }
    sigprocmask(SIG_UNBLOCK, &hold, &old);
}

/* Wrapper to local file operations */
int32_t
file_open(char *name, char *mode, int *flags)
{
    int                 fmode = 0;
    int                 id;
    sigset_t            hold, old;

    switch (*mode) {
    case 'r':
	fmode = O_RDONLY;
	*flags = FILE_READ;
	break;
    case 'w':
	fmode = O_WRONLY | O_CREAT;
	*flags = FILE_WRITE;
	break;
    case 'a':
	fmode = O_RDWR | O_CREAT | O_APPEND;
	*flags = FILE_READ | FILE_WRITE;
	break;
    case 'm':
	fmode = O_RDWR | O_CREAT;
	*flags = FILE_READ | FILE_WRITE;
	break;
    default:
	return -1;
    }
    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    if ((id = open(name, fmode, 0660)) < 0) {
	sigprocmask(SIG_UNBLOCK, &hold, &old);
	return -1;
    }
    sigprocmask(SIG_UNBLOCK, &hold, &old);
    if (*mode == 'a') {
	lseek(id, 0, SEEK_END);
	*flags |= FILE_APPEND;
    }
    return id;

}

void
file_seek(int32_t id, int32_t pos)
{
    sigset_t            hold, old;

    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    (void)lseek(id, pos, SEEK_SET);
    sigprocmask(SIG_UNBLOCK, &hold, &old);
}

int
file_write(int32_t id, char *buffer, int32_t size)
{
    int                 ret;
    sigset_t            hold, old;

    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    ret = write(id, buffer, size);
    sigprocmask(SIG_UNBLOCK, &hold, &old);
    return ret;
}

int
file_read(int32_t id, char *buffer, int32_t size)
{
    int                 ret;
    sigset_t            hold, old;

    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    ret = read(id, buffer, size);
    sigprocmask(SIG_UNBLOCK, &hold, &old);
    return ret;
}

int
file_close(int32_t id)
{
    return close(id);
}

int32_t
file_size(int32_t id)
{
    struct stat         statbuf;
    sigset_t            hold, old;

    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    if (fstat(id, &statbuf) < 0) {
	sigprocmask(SIG_UNBLOCK, &hold, &old);
	return -1;
    }
    sigprocmask(SIG_UNBLOCK, &hold, &old);
    return statbuf.st_size;
}

int
file_checkdirect(char *name)
{
    struct stat         statbuf;
    sigset_t            hold, old;

    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    if (stat(name, &statbuf) < 0) {
	sigprocmask(SIG_UNBLOCK, &hold, &old);
	return -1;
    }

    sigprocmask(SIG_UNBLOCK, &hold, &old);
    return S_ISDIR(statbuf.st_mode);
}

Objptr
file_direct(Objptr op)
{
    Objptr             *array;
    Objptr              res;
    int                 size;
    int                 index;
    struct dirent      *dirbuf;
    DIR                *dirp;
    char               *name;
    int                 savereclaim = noreclaim;
    sigset_t            hold, old;

    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    name = Cstring(get_pointer(op, FILENAME));
    if ((dirp = opendir(name)) == NULL) {
	free(name);
	sigprocmask(SIG_UNBLOCK, &hold, &old);
	return NilPtr;
    }

    /* Can free name since we don't need it anymore */
    free(name);

    /* Allocate initial buffer */
    size = 1024;
    index = 0;
    if ((array = (Objptr *) malloc(size * sizeof(Objptr))) == NULL) {
	closedir(dirp);
	sigprocmask(SIG_UNBLOCK, &hold, &old);
	return NilPtr;
    }

    noreclaim = TRUE;
    /* Read in the files */
    while ((dirbuf = readdir(dirp)) != NULL) {
	array[index++] = MakeString(dirbuf->d_name);
	if (index == size) {
	    size += 1024;
	    if ((array = (Objptr *) realloc(array, size * sizeof(Objptr)))
		== NULL) {
		noreclaim = savereclaim;
		closedir(dirp);
		sigprocmask(SIG_UNBLOCK, &hold, &old);
		return NilPtr;
	    }
	}
    }

    closedir(dirp);

    /* Now allocate an array that will hold them all */
    if ((res = create_new_object(ArrayClass, index)) == NilPtr) {
	noreclaim = savereclaim;
	free(array);
	sigprocmask(SIG_UNBLOCK, &hold, &old);
	return NilPtr;
    }
    size = index;
    for (index = 0; index < size; index++)
	Set_object(res, index, array[index]);
    free(array);
    noreclaim = savereclaim;
    sigprocmask(SIG_UNBLOCK, &hold, &old);
    return res;
}

int
file_delete(Objptr op)
{
    char               *name;
    int                 res = TRUE;
    struct stat         statbuf;
    sigset_t            hold, old;

    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    name = Cstring(get_pointer(op, FILENAME));
    if (stat(name, &statbuf) < 0) {
	free(name);
	sigprocmask(SIG_UNBLOCK, &hold, &old);
	return FALSE;
    }

    if (S_ISDIR(statbuf.st_mode)) {
	if (rmdir(name) < 0)
	    res = FALSE;
    } else {
	if (unlink(name) < 0)
	    res = FALSE;
    }
    free(name);
    sigprocmask(SIG_UNBLOCK, &hold, &old);
    return res;
}

int
file_rename(Objptr op, Objptr newop)
{
    char               *name;
    char               *newname;
    int                 res = TRUE;
    sigset_t            hold, old;

    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    name = Cstring(get_pointer(op, FILENAME));
    newname = Cstring(newop);
    if (name != NULL && newname != NULL) {
	if (rename(name, newname) < 0)
	    res = FALSE;
    }
    free(newname);
    free(name);
    sigprocmask(SIG_UNBLOCK, &hold, &old);
    return res;
}

void
file_cwd(const char *name)
{
    (void)chdir(name);
}

void
error(char *str)
{
    dump_string(str);
    endSystem();
    exit(-1);
}

void
errorStr(char *str, char *argument)
{
    fprintf(stderr, str, argument);
    endSystem();
    exit(-1);
}

void
dump_string(char *str)
{
    sigset_t            hold, old;

    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    fputs(str, stderr);
    fputc('\n', stderr);
    sigprocmask(SIG_UNBLOCK, &hold, &old);
}

/*
 * Read as many characters as we can from stdin, return 1 if somebody could
 * have been awakened by our actions.
 */
static int
fill_buffer()
{
    int                 len;
    char               *ptr;
    int                 eolseen = 0;
    sigset_t            hold, old;

    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    /* If we are buffered, only read as much as is ready */
    ioctl(0, FIONREAD, &len);

    /* If nothing to read, return empty buffer */
    if (len == 0 || console.file_buffer == NULL) {
	sigprocmask(SIG_UNBLOCK, &hold, &old);
	return 0;
    }

    /* Don't overfill buffer */
    if ((console.file_len + len) >= BUFSIZE)
	len = BUFSIZE - console.file_len;

    /* Fill the buffer */
    ptr = &console.file_buffer[console.file_len];
    len = read(0, ptr, len);

    sigprocmask(SIG_UNBLOCK, &hold, &old);

    /* If there was an error, return failure. */
    if (len < 0)
	return 0;

    console.file_len += len;

    /* Check if we read a new line */
    for (; len > 0; len--) {
	if (*ptr++ == '\n')
	    eolseen = 1;
    }

    /* Decide if we should signal anybody waiting on console input. */
    if (console.file_len == BUFSIZE || eolseen ||
	console.file_flags & FILE_CHAR) {
	signal_console(console.file_oop);
	return 1;
    }

    return 0;
}

int
write_console(int stream, char *string)
{
    sigset_t            hold, old;

    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    switch (stream) {
    case 1:
	fputs(string, stdout);
	break;
    case 2:
	fputs(string, stderr);
	break;
    default:
	sigprocmask(SIG_UNBLOCK, &hold, &old);
	return FALSE;
    }
    sigprocmask(SIG_UNBLOCK, &hold, &old);
    return TRUE;
}

uint32_t
current_time()
{
    struct timeb        tp;
    sigset_t            hold, old;

    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    ftime(&tp);
    sigprocmask(SIG_UNBLOCK, &hold, &old);
    if (tp.dstflag)
	tp.timezone -= 60;
    tp.time -= 60 * tp.timezone;
    return tp.time;
}

int
current_mtime()
{
    struct timeb        tp;
    sigset_t            hold, old;

    /* Prevent signals while processing events */
    sigemptyset(&hold);
    sigaddset(&hold, SIGALRM);
    sigprocmask(SIG_BLOCK, &hold, &old);

    ftime(&tp);
    sigprocmask(SIG_UNBLOCK, &hold, &old);
    return tp.millitm;
}

#endif
