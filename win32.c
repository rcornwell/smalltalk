/*
 * Smalltalk interpreter: Windows 32 interface.
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
 * $Log: win32.c,v $
 * Revision 1.3  2002/02/07 04:21:05  rich
 * Added code to request size of window to be last window size.
 * Added code to change current working directory.
 *
 * Revision 1.2  2001/09/17 20:19:55  rich
 * Got display and cursor support working.
 *
 * Revision 1.1  2001/08/18 16:22:56  rich
 * Initial revision
 *
 *
 */

#ifdef WIN32
/* System stuff */
#include <time.h>

#include "smalltalk.h"
#include "object.h"
#include "interp.h"
#include "smallobjs.h"
#include "system.h"
#include "graphic.h"
#include "fileio.h"
#include "about.h"

static void         DoWinCommand(HINSTANCE, HWND, WPARAM);
static LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
static void	    fill_buffer(char c);
static char        *szAppName = "SmallTalk";
static HWND         hwnd = NULL;
static HBITMAP      dispmap = NULL;
static HCURSOR	    cursor = NULL;
static int	    bmsize;
static int	    foundevents;
uint32_t           *display_bits = NULL;
static int	    display_rows;
static int	    display_cols;
static uint32_t    *display_image = NULL;
static int	    needconsole = 1;

static unsigned char reverse_map[256] = {
/* 0,  1,   2,    3,   4,   5,   6,   7,   8,   9,   A,   B,  C,  D,  E,  F */
0xFF,0x7F,0xBF,0x3F,0xDF,0x5F,0x9F,0x1F,0xEF,0x6F,0xAF,0x2F,0xCF,0x4F,0x8F,0x0F,
0xF7,0x77,0xB7,0x37,0xD7,0x57,0x97,0x17,0xE7,0x67,0xA7,0x27,0xC7,0x47,0x87,0x07,
0xFB,0x7B,0xBB,0x3B,0xDB,0x5B,0x9B,0x1B,0xEB,0x6B,0xAB,0x2B,0xCB,0x4B,0x8B,0x0B,
0xF3,0x73,0xB3,0x33,0xD3,0x53,0x93,0x13,0xE3,0x63,0xA3,0x23,0xC3,0x43,0x83,0x03,
0xFD,0x7D,0xBD,0x3D,0xDD,0x5D,0x9D,0x1D,0xED,0x6D,0xAD,0x2D,0xCD,0x4D,0x8D,0x0D,
0xF5,0x75,0xB5,0x35,0xD5,0x55,0x95,0x15,0xE5,0x65,0xA5,0x25,0xC5,0x45,0x85,0x05,
0xF9,0x79,0xB9,0x39,0xD9,0x59,0x99,0x19,0xE9,0x69,0xA9,0x29,0xC9,0x49,0x89,0x09,
0xF1,0x71,0xB1,0x31,0xD1,0x51,0x91,0x11,0xE1,0x61,0xA1,0x21,0xC1,0x41,0x81,0x01,
0xFE,0x7E,0xBE,0x3E,0xDE,0x5E,0x9E,0x1E,0xEE,0x6E,0xAE,0x2E,0xCE,0x4E,0x8E,0x0E,
0xF6,0x76,0xB6,0x36,0xD6,0x56,0x96,0x16,0xE6,0x66,0xA6,0x26,0xC6,0x46,0x86,0x06,
0xFA,0x7A,0xBA,0x3A,0xDA,0x5A,0x9A,0x1A,0xEA,0x6A,0xAA,0x2A,0xCA,0x4A,0x8A,0x0A,
0xF2,0x72,0xB2,0x32,0xD2,0x52,0x92,0x12,0xE2,0x62,0xA2,0x22,0xC2,0x42,0x82,0x02,
0xFC,0x7C,0xBC,0x3C,0xDC,0x5C,0x9C,0x1C,0xEC,0x6C,0xAC,0x2C,0xCC,0x4C,0x8C,0x0C,
0xF4,0x74,0xB4,0x34,0xD4,0x54,0x94,0x14,0xE4,0x64,0xA4,0x24,0xC4,0x44,0x84,0x04,
0xF8,0x78,0xB8,0x38,0xD8,0x58,0x98,0x18,0xE8,0x68,0xA8,0x28,0xC8,0x48,0x88,0x08,
0xF0,0x70,0xB0,0x30,0xD0,0x50,0x90,0x10,0xE0,0x60,0xA0,0x20,0xC0,0x40,0x80,0x00,
};

#define ID_TICKTIMER	1

/* Create main window. */
int                 WINAPI
WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
	PSTR szCmdLine, int iCmdShow) {
    char		**argv;
    int			argc;

    argv = CommandLineToArgvW(GetCommandLine(), &argc);
    if (argv != NULL) {
	main(argc, argv);
	GlobalFree(argv);
    }
}

/* Initialize the system */
int
initSystem()
{
    /* Initialize the event queues. */
    init_event(&input_queue);
    init_event(&asyncsigs);

    return 1;
}

/* Shutdown the system */
void
endSystem()
{
    if (cursor != NULL)
	DestroyCursor(cursor);
}


/* Become the cursor */
Objptr
BeCursor(Objptr op)
{
    int                 height, width;
    int			cheight, cwidth;
    int                 rwidth;
    int                 i, j;
    Objptr              offset;
    int                 hot_x, hot_y;
    unsigned char       *main_bits, *mask_bits;
    unsigned char       *src_ptr, *dst_ptr, *msk_ptr;
    unsigned char       *bits, *mask;
    HINSTANCE           hInst;

    /* Remove old cursor if there is one */
    if (cursor != NULL) {
	DestroyCursor(cursor);
	cursor = NULL;
    }

    /* Set new cursor */
    cursor_object = op;
    rootObjects[CURSOBJ] = op;

    /* If cursor is NilPtr, just return it */
    if (op == NilPtr) 
	return op;

    /* Get max size */
    cwidth = GetSystemMetrics(SM_CXCURSOR);
    cheight = GetSystemMetrics(SM_CYCURSOR);

    /* Extract cursor information */
    height = get_integer(op, FORM_HEIGHT);
    width = get_integer(op, FORM_WIDTH);
    rwidth = ((width & 0x1f) == 0) ? width : ((width | 0x1f) + 1);
    offset = get_pointer(op, FORM_OFFSET);
    hot_x = get_integer(offset, XINDEX);
    hot_y = get_integer(offset, YINDEX);
    offset = get_pointer(op, FORM_BITMAP);
    main_bits = (unsigned char *) (get_object_base(offset) +
				   (fixed_size(offset) * sizeof(Objptr)));
    offset = get_pointer(get_pointer(op, FORM_MASK), FORM_BITMAP);
    mask_bits = (unsigned char *) (get_object_base(offset) +
				   (fixed_size(offset) * sizeof(Objptr)));


    /* Create local space for cursor */
    i = (cwidth / 8) * cheight;
    if ((bits = (unsigned char *) malloc(i)) == NULL)
	return cursor_object;
    if ((mask = (unsigned char *) malloc(i)) == NULL) {
	free(bits);
	return op;
    }

    src_ptr = main_bits;
    msk_ptr = mask_bits;
    dst_ptr = bits;
    for(i = 0; i < cheight; i++ ) {
	if (i < height) {
	   for(j = 0; j < rwidth; j+= 8 ) {
	      if (j <= cwidth) 
		   *dst_ptr++ = reverse_map[*src_ptr]^(~reverse_map[*msk_ptr]);
	      src_ptr++;
	      msk_ptr++;
	   }
	} else 
	   j = 0;

	for(; j < cwidth; j += 8)
	   *dst_ptr++ = 0xff;
    }

    /* now build mask */
    src_ptr = mask_bits;
    dst_ptr = mask;
    for(i = 0; i < cheight; i++ ) {
	if (i < height) {
	   for(j = 0; j < rwidth; j+= 8 ) {
	      if (j <= cwidth) 
		   *dst_ptr++ = ~reverse_map[*src_ptr];
	      src_ptr++;
	   }
	} else 
	   j = 0;

	for(; j < cwidth; j += 8)
	   *dst_ptr++ = 0x00;
    }

    /* Create a new cursor */
    hInst = GetModuleHandle(NULL);
    cursor = CreateCursor(hInst, hot_x, hot_y, cwidth, cheight, bits, mask);

    /* Free temp stuff */
    free(bits);
    free(mask);
    return op;
}


/* Become display object */
Objptr
BeDisplay(Objptr op)
{
    if (display_object == op)
	return op;
    display_object = op;
    rootObjects[DISPOBJ] = op;	/* Very bad if it gets freed */
    if (hwnd == NULL) {
	WNDCLASSEX          wndclass;
	HINSTANCE           hInst;
	Objptr		    temp;
	int		    crow, ccol;

	/* Initialize the input event queue */
	init_event(&input_queue);

	hInst = GetModuleHandle(NULL);

	/* Initialize class structure */
	wndclass.cbSize = sizeof(wndclass);
	wndclass.style = CS_HREDRAW | CS_VREDRAW;
	wndclass.lpfnWndProc = WndProc;
	wndclass.cbClsExtra = 0;
	wndclass.cbWndExtra = 0;
	wndclass.hInstance = hInst;
	wndclass.hIcon = LoadIcon(hInst, MAKEINTRESOURCE(SMALLTALK));
	wndclass.hCursor = LoadCursor(NULL, IDC_ARROW);
	wndclass.hbrBackground = (HBRUSH) GetStockObject(WHITE_BRUSH);
	wndclass.lpszMenuName = szAppName;
	wndclass.lpszClassName = szAppName;
	wndclass.hIconSm = LoadIcon(hInst, MAKEINTRESOURCE(SMALLTALK));

	/* Create Window */
	RegisterClassEx(&wndclass);

	/* Grab current old size of window */
        temp = get_pointer(display_object, FORM_HEIGHT);
	crow = (is_integer(temp)) ? as_integer(temp) : 512;

	temp = get_pointer(display_object, FORM_WIDTH);
	ccol = (is_integer(temp)) ? as_integer(temp) : 512;

	hwnd = CreateWindow(szAppName, "Smalltalk", WS_OVERLAPPEDWINDOW,
			    CW_USEDEFAULT, CW_USEDEFAULT, ccol, crow,
			    NULL, NULL, hInst, (PSTR) NULL);

	/* Initialize rest */
	ShowWindow(hwnd, SW_SHOWNORMAL);
	UpdateWindow(hwnd);
    }
    return op;
}

/* Copy the display image from display_bits to dislay_image */
static void
copyimage(HDC hdc, int x, int y, int w, int h)
{
    HDC                 hdcMem;
    int                 nBytes;
    int			nRows;
    unsigned char      *src_ptr, *dest_ptr;
    int                 row, index, delta;

    /* Clip dimensions to within screen. */
    if (x < 0)
        x = 0;
    if (y < 0)
        y = 0;
    if (x > display_cols)
	x = display_cols;
    if (y > display_rows)
	y = display_rows;
    if ((x + w - 1) > display_cols)
	w = display_cols - x - 1;
    if ((y + h - 1) > display_rows)
	h = display_rows - y - 1;

    /* Merge masks if needed */
    nBytes = 1 + ((w - 1 + x) / 32) - (x / 32);

    /* Calculate starting offsets and increments */
    row = (display_cols + 30 /* - 1 + 31 */ ) / 32;
    index = (y * row) + (x / 32);
    dest_ptr = (unsigned char *)&display_image[index];
    src_ptr = (unsigned char *)&display_bits[index];
    delta = row - nBytes;

    /* Convert delta and nBytes to bytecounts */
    nBytes *= 4;
    delta *= 4;

    /* Interloop */
    for (nRows = h; nRows > 0; nRows--) {	/* Vertical loop */
	int		word;

	word = nBytes;
        while(word > 0) {	/* Horizontal loop */
	    switch(word & 0x1F) {
	    case 0:
		   word--;
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 31:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 30:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 29:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 28:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 27:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 26:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 25:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 24:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 23:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 22:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 21:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 20:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 19:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 18:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 17:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 16:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 15:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 14:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 13:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 12:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 11:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 10:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 9:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 8:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 7:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 6:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 5:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 4:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 3:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 2:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    case 1:
		   *dest_ptr++ = reverse_map[*src_ptr++];
	    }
	    word -= word & 0x1f;
	}
	dest_ptr += delta;
	src_ptr += delta;
    }

    /* Update the image */
    SetMapMode(hdc, MM_TEXT);
    hdcMem = CreateCompatibleDC(hdc);
    SelectObject(hdcMem, dispmap);
    SetBitmapBits(dispmap, bmsize, display_image);

    BitBlt(hdc, x, y, w, h, hdcMem, x, y, SRCCOPY);
    DeleteDC(hdcMem);
}


void
UpdateDisplay(Copy_bits blit_data)
{
    HDC                 hdc = GetDC(hwnd);

    copyimage(hdc, blit_data->dx, blit_data->dy, blit_data->w, blit_data->h);
    ReleaseDC(hwnd, hdc);
}


/*
 * Wait until an interesting event occurs.
 * If suspend is true and there are no interesting events, go to sleep.
 */
int 
WaitEvent(int suspend)
{
    MSG                 msg;
    HANDLE		handle[2];
    int			nhandle = 0;

    /* Drain any console input first */
    foundevents = 0;
    if (needconsole == 0) {
	DWORD		events;
	INPUT_RECORD	inrec;
        HANDLE		in = GetStdHandle(STD_INPUT_HANDLE);
	while (PeekConsoleInput(in, &inrec, 1, &events)) {
	    if (events > 0) {
		if (ReadConsoleInput(in, &inrec, 1, &events)) {
		    /* Process input */
		    if (inrec.EventType == KEY_EVENT &&
			inrec.Event.KeyEvent.bKeyDown &&
			inrec.Event.KeyEvent.uChar.AsciiChar != 0) {
		        fill_buffer(inrec.Event.KeyEvent.uChar.AsciiChar);
		        foundevents = 1;
		    }
		}
	    } else
		break;
	}
        handle[nhandle++] = in;
    }

    /* Process any outstanding windows input */
    while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
	if (msg.message == WM_QUIT) {
		running = 0;
		return 0;
	}
	TranslateMessage(&msg);
	DispatchMessage(&msg);
    }

    if (hwnd != NULL)
	handle[nhandle++] = hwnd;

    if (suspend && !foundevents) {
	MsgWaitForMultipleObjects(nhandle, handle, FALSE, 50, 
		QS_ALLEVENTS | QS_ALLINPUT);
    }
    return 1;
}

/*
 * Main window proceedure.
 */
static LRESULT      CALLBACK
WndProc(HWND hwnd, UINT iMsg, WPARAM wParam, LPARAM lParam)
{
    static HINSTANCE    hInst;
    static int          buttons = 0;
    PAINTSTRUCT         ps;
    int                 row, col;

    switch (iMsg) {
    case WM_CREATE:
	hInst = ((LPCREATESTRUCT) lParam)->hInstance;
	display_bits = NULL;
	SetTimer(hwnd, ID_TICKTIMER, 20, NULL);
	return 0;

    case WM_SIZE:
	/* Resize the bitmap */
	row = HIWORD(lParam);
	col = LOWORD(lParam);
	if (row != 0 && col != 0) {
	    int                 crow, ccol;
	    int                 roundcol;
	    uint32_t      	*temp;

	    crow = get_integer(display_object, FORM_HEIGHT);
	    ccol = get_integer(display_object, FORM_WIDTH);
	    if (crow == row && ccol == col && dispmap != NULL)
		return 0;

	    roundcol = (col + 31) & ~0x1f;
	    if (dispmap != NULL)
		DeleteObject(dispmap);
	    bmsize = (roundcol / 8) * row;
	    dispmap = CreateBitmap(roundcol, row, 1, 1, NULL);
	    if ((temp = (uint32_t *)malloc(bmsize)) == NULL)
		break;
	    if (display_bits != NULL)
	        free(display_bits);
	    display_bits = temp;

	    if ((temp = (uint32_t *)malloc(bmsize)) == NULL)
		break;
	    if (display_image != NULL)
	        free(display_image);
	    display_image = temp;

	    display_rows = row;
	    display_cols = col;
	    Set_integer(display_object, FORM_HEIGHT, row);
	    Set_integer(display_object, FORM_WIDTH, col);
	    PostEvent(EVENT_RESIZE, 0);
	    foundevents = 1;
	}
	break;

    case WM_PAINT:
	BeginPaint(hwnd, &ps);
	if (dispmap != NULL) {
    	    copyimage(ps.hdc, ps.rcPaint.left, ps.rcPaint.top,
		   ps.rcPaint.right - ps.rcPaint.left,
		   ps.rcPaint.bottom - ps.rcPaint.top);
	}
	EndPaint(hwnd, &ps);
	return 0;

    case WM_COMMAND:
	DoWinCommand(hInst, hwnd, wParam);
	return 0;

    case WM_LBUTTONDOWN:
	buttons |= 1;
	goto postmouse;

    case WM_MBUTTONDOWN:
	buttons |= 2;
	goto postmouse;

    case WM_RBUTTONDOWN:
	buttons |= 4;
	goto postmouse;

    case WM_LBUTTONUP:
	buttons &= ~1;
	goto postmouse;

    case WM_MBUTTONUP:
	buttons &= ~2;
	goto postmouse;

    case WM_RBUTTONUP:
	buttons &= ~4;

      postmouse:
	col = LOWORD(lParam);
	row = HIWORD(lParam);
	PostEvent(EVENT_MOUSEPOS, ((row & 0xfff) << 12) + (col & 0xfff));
	PostEvent(EVENT_MOUSEBUT, buttons);
	foundevents = 1;
	return 0;

    case WM_MOUSEMOVE:
	if (cursor != NULL)
	    SetCursor(cursor);
	col = LOWORD(lParam);
	row = HIWORD(lParam);
	PostEvent(EVENT_MOUSEPOS, ((row & 0xfff) << 12) + (col & 0xfff));
	foundevents = 1;
	return 0;

    case WM_CHAR:
	PostEvent(EVENT_CHAR, (UCHAR) wParam);
	foundevents = 1;
	return 0;

    case WM_TIMER:
	/* Post one event for each millisecond pasted */
	for (row = 0; row < 20; row++)
	    PostEvent(EVENT_TIMER, 0);
        foundevents = 1;
	return 0;

    case WM_DESTROY:
	KillTimer(hwnd, ID_TICKTIMER);
	if (display_bits != NULL)
	    free(display_bits);
	if (dispmap != NULL)
	    DeleteObject(dispmap);
        running = 0;
	PostQuitMessage(0);
	return 0;

    }
    return DefWindowProc(hwnd, iMsg, wParam, lParam);
}

static void
DoWinCommand(HINSTANCE hInst, HWND hwnd, WPARAM wParam)
{
    char                buffer[MAX_PATH];

    /* Messages from menus */
    switch (LOWORD(wParam)) {
    case IDM_NEW:
	break;

    case IDM_OPEN:
	break;

    case IDM_SAVE:
	/* fall through */
    case IDM_SAVEAS:
	break;

    case IDM_EXIT:
	SendMessage(hwnd, WM_CLOSE, 0, 0);
	break;

    case IDM_HELP:
	/* Convert our module name into a help file name */
	strcpy(buffer, szAppName);
	strcat(buffer, ".HLP");
	WinHelp(hwnd, buffer, HELP_CONTENTS, (DWORD) 0);
	break;

    case IDM_ABOUT:
	AboutBox(hwnd, hInst, szAppName, "#1");
	break;

    }
}

uint32 
file_open(char *name, char *mode, int *flags)
{
    HANDLE              id;

    switch (*mode) {
    case 'r':
	*flags = FILE_READ;
	id = CreateFile(name, GENERIC_READ, FILE_SHARE_READ, NULL,
			OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	break;
    case 'w':
	*flags = FILE_WRITE;
	id = CreateFile(name, GENERIC_WRITE, FILE_SHARE_WRITE, NULL,
			CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
	break;
    case 'm':
    case 'a':
	*flags = FILE_READ | FILE_WRITE;
	id = CreateFile(name, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_WRITE,
			NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
	break;
    default:
	return -1;
    }
    if (id == INVALID_HANDLE_VALUE)
	return -1;
    if (*mode == 'a') {
	*flags |= FILE_APPEND;
        SetFilePointer(id, 0, NULL, FILE_END);
    }
    return (int) id;
}

void 
file_seek(int32_t id, int32_t pos)
{
    (void)SetFilePointer((HANDLE) id, pos, NULL, FILE_BEGIN);
}

int 
file_write(int32_t id, char *buffer, int32_t size)
{
    DWORD               did;

    if (!WriteFile((HANDLE) id, buffer, size, &did, 0))
	return -1;
    if (did != (DWORD)size)
	return -1;
    else
	return did;
}

int 
file_read(int32_t id, char *buffer, int32_t size)
{
    DWORD               did;
    DWORD		position;

    /* Check if we are at end of file before reading. */
    if ((position = SetFilePointer((HANDLE) id, 0, NULL, FILE_CURRENT)) ==
	0xffffffff)
	return -1;
    if (position == GetFileSize((HANDLE) id, NULL))
	return 0;
    if (!ReadFile((HANDLE) id, buffer, size, &did, 0)) 
	return -1;
    else
	return did;
}

int 
file_close(int32_t id)
{
    return CloseHandle((HANDLE) id);
}

int32_t 
file_size(int32_t id)
{
    DWORD               lsize;

    lsize = GetFileSize((HANDLE) id, NULL);
    return lsize;
}

int
file_checkdirect(char *name)
{
    DWORD		type;

    if ((type = GetFileAttributes(name)) == -1)
	return -1;

    return (type & FILE_ATTRIBUTE_DIRECTORY) != 0;
}

Objptr
file_direct(Objptr op)
{
    Objptr		*array;
    Objptr		res;
    int			size;
    int			index;
    WIN32_FIND_DATAA	ffile;
    HANDLE		hFfile;
    char		*name;
    char		buffer[MAX_PATH];
    int			savereclaim = noreclaim;

    name = Cstring(get_pointer(op, FILENAME));
    strcpy(buffer, name);
    strcat(buffer, "/*.*");
    free(name);

    /* Allocate initial buffer */
    size = 1024;
    index = 0;
    if ((array = (Objptr *)malloc(size * sizeof(Objptr))) == NULL) 
	return NilPtr;

    noreclaim = TRUE;
    /* Read in the files */
    if ((hFfile = FindFirstFile(buffer, &ffile)) != NULL) {
	do {
	    array[index++] = MakeString(ffile.cFileName);
	    if (index == size) {
	        size += 1024;
    	        if ((array = (Objptr *)realloc(array, size * sizeof(Objptr)))
			     == NULL) {
		    noreclaim = savereclaim;
		    FindClose(hFfile);
		    return NilPtr;
	        }
	    }
	} while(FindNextFile(hFfile, &ffile));
	FindClose(hFfile);
    }

    /* Now allocate an array that will hold them all */
    if ((res = create_new_object(ArrayClass, index)) == NilPtr) {
	noreclaim = savereclaim;
	free(array);
	return NilPtr;
    }
    size = index;
    for(index = 0; index < size; index++) 
	Set_object(res, index, array[index]);
    free(array);
    noreclaim = savereclaim;
    return res;
}

int
file_delete(Objptr op)
{
    char		*name;
    int			res = TRUE;
    DWORD		type;

    name = Cstring(get_pointer(op, FILENAME));
    if ((type = GetFileAttributes(name)) == -1) {
	free(name);
	return FALSE;
    }
    
    if ((type & FILE_ATTRIBUTE_DIRECTORY) != 0) {
	if (RemoveDirectory(name) == 0)
	    res = FALSE;
    } else {
        if (DeleteFile(name) == 0)
	    res = FALSE;
    }
    free(name);
    return res;
}

int
file_rename(Objptr op, Objptr newop)
{
    char		*name;
    char		*newname;
    int			res = TRUE;

    name = Cstring(get_pointer(op, FILENAME));
    newname = Cstring(newop);
    if (name != NULL && newname != NULL) {
	if (MoveFile(name, newname) == 0)
	    res = FALSE;
    }
    free(newname);
    free(name);
    return res;
}

void
file_cwd(char *name)
{
    SetCurrentDirectory(name);
}
 
void 
error(char *str)
{
    HANDLE	in;
    DWORD	did;
    char	c;

    dump_string(str);
    /* Keep console up until it can be read */
    in = GetStdHandle(STD_INPUT_HANDLE);
    ReadFile(in, &c, 1, &did, 0);
    ExitProcess(-1);
}

void
errorStr(char *str, char *argument)
{
    char	buffer[1024];
    wsprintf(buffer, str, argument);
    dump_string(buffer);
}


void
dump_string(char *str)
{
    DWORD		did;
#if 0

    if (needconsole) {
	if (AllocConsole() == 0)
	   return;
	/* Set console to igrnore mouse/ window events */
    	SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE),
			ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT 
		        | ENABLE_PROCESSED_OUTPUT | ENABLE_WRAP_AT_EOL_OUTPUT );
	needconsole = 0;
    }

    WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), str, strlen(str), &did, 0);
    WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), "\r\n", 2, &did, 0);
#endif
    static int		id = NULL;

    if (id == NULL) {
	id = CreateFile("smalltalk.log", GENERIC_READ | GENERIC_WRITE,
			 FILE_SHARE_WRITE, NULL, OPEN_ALWAYS,
			 FILE_ATTRIBUTE_NORMAL, NULL);
    }
    WriteFile(id, str, strlen(str), &did, 0);
    WriteFile(id, "\r\n", 2, &did, 0);
}

void
dump_char(char c)
{
    DWORD		did;

    if (needconsole) {
	if (AllocConsole() == 0)
	   return;
	/* Set console to igrnore mouse/ window events */
    	SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE),
			ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT 
		        | ENABLE_PROCESSED_OUTPUT | ENABLE_WRAP_AT_EOL_OUTPUT );
	needconsole = 0;
    }

    WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), &c, 1, &did, 0);
}


static void
fill_buffer(char c)
{
    DWORD	did;
    HANDLE	out;

    out = GetStdHandle(STD_OUTPUT_HANDLE);
    WriteFile(out, &c, 1, &did, 0);
    if (c == '\r') {
        c = '\n';
        WriteFile(out, &c, 1, &did, 0);
    }
 
    if (console.file_buffer != NULL) {
	if (c == '\b' && console.file_len > 0) {
	    console.file_len--;
	    WriteFile(out, " \b", 2, &did, 0);
	} else if (console.file_len < BUFSIZE)
	    console.file_buffer[console.file_len++] = c;
	if (console.file_len == BUFSIZE || c == '\n' ||
	    console.file_flags & FILE_CHAR)
	   signal_console(console.file_oop);
    }
}

int
write_console(int stream, char *string)
{
    HANDLE	out;
    DWORD	did;
    char	buf[1024];
    char	*ptr;
    int		len;

    if (needconsole) {
	if (AllocConsole() == 0)
	   return FALSE;
	/* Set console to igrnore mouse/ window events */
    	SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE),
			ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT 
		        | ENABLE_PROCESSED_OUTPUT | ENABLE_WRAP_AT_EOL_OUTPUT );
	needconsole = 0;
    }

    switch (stream) {
    case 1:
            out = GetStdHandle(STD_OUTPUT_HANDLE);
	    break;
    case 2:
            out = GetStdHandle(STD_ERROR_HANDLE);
	    break;
    default:
	    return FALSE;
    }

    ptr = buf;
    len = 0;
    while(*string != '\0') {
	char c = *string++;
	*ptr++ = c;
	len++;
	if (c == '\n') {
	   *ptr++ = '\r';
	   len++;
	}
	if (len >= (sizeof(buf) - 2)) {
            WriteFile(out, buf, len, &did, 0);
	    ptr = buf;
	    len = 0;
	}
    }
    if (len >= 0) 
        WriteFile(out, buf, len, &did, 0);
    return TRUE;
}

uint32_t
current_time()
{
    struct tm		tm;
    SYSTEMTIME		st;

    GetSystemTime(&st);
    tm.tm_year = st.wYear - 1900; 
    tm.tm_mon = st.wMonth - 1; 
    tm.tm_mday = st.wDay; 
    tm.tm_hour = st.wHour; 
    tm.tm_min = st.wMinute; 
    tm.tm_sec = st.wSecond; 
    tm.tm_isdst = -1;
    return (uint32_t)mktime(&tm);
}

int
current_mtime()
{
    SYSTEMTIME		st;
    GetSystemTime(&st);
    return st.wMilliseconds; 
}
#endif
