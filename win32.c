/*
 * Smalltalk interpreter: Windows 32 interface.
 *
 * $Log: $
 *
 */

#ifndef lint
static char        *rcsid = "$Id: $";
#endif

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
static int	    bmsize;
static int	    foundevents;
unsigned long      *display_bits = NULL;
static int	    needconsole = 1;

#define ID_TICKTIMER	1

/* Initialize the system */
int
initSystem()
{
    return 1;
}

/* Become the cursor */
Objptr
BeCursor(Objptr op)
{
    cursor_object = op;
    rootObjects[CURSOBJ] = op;
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

	hwnd = CreateWindow(szAppName, "Smalltalk", WS_OVERLAPPEDWINDOW,
			    CW_USEDEFAULT, CW_USEDEFAULT, 500, 400,
			    NULL, NULL, hInst, (PSTR) NULL);

	/* Initialize rest */
	ShowWindow(hwnd, SW_SHOWNORMAL);
	UpdateWindow(hwnd);
    }
    return op;
}

void
UpdateDisplay(Copy_bits blit_data)
{
    HDC                 hdcMem;
    HDC                 hdc = GetDC(hwnd);

    SetBitmapBits(dispmap, bmsize, display_bits);
    hdcMem = CreateCompatibleDC(hdc);
    SelectObject(hdcMem, dispmap);

    BitBlt(hdc, blit_data->dx, blit_data->dy,
	   blit_data->h, blit_data->w,
	   hdcMem, blit_data->dx, blit_data->dy, SRCINVERT);
    DeleteDC(hdcMem);
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
			char	buffer[1000];
			wsprintf(buffer, "Read '%c'", 
		        	inrec.Event.KeyEvent.uChar.AsciiChar);
			dump_string(buffer);
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
    static BITMAP       bm;

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
	    unsigned long	*temp;
	    unsigned long	*temp2;

	    crow = get_integer(display_object, FORM_HEIGHT);
	    ccol = get_integer(display_object, FORM_WIDTH);
	    if (crow == row && ccol == col)
		return 0;
	    if ((col & 0x1f) != 0)
		roundcol = 1 + (col | 0x1f);
	    else
		roundcol = col;
	    if (dispmap != NULL)
		DeleteObject(dispmap);
	    bmsize = (roundcol / 8) * row;
	    dispmap = CreateBitmap(roundcol, row, 1, 1, NULL);
	    if ((temp = (unsigned long *)malloc(bmsize)) == NULL)
		break;
	    temp2 = display_bits;
#if 0
	    GetObject(dispmap, sizeof(BITMAP), (LPVOID) & bm);
	    display_bits = (unsigned long *) bm.bmBits;
#endif
	    Set_integer(display_object, FORM_HEIGHT, row);
	    Set_integer(display_object, FORM_WIDTH, col);
	    display_bits = temp;
	    PostEvent(EVENT_RESIZE, 0);
	    foundevents = 1;
	    if (temp2 != NULL)
		free(temp2);
	}
	break;

    case WM_PAINT:

	BeginPaint(hwnd, &ps);
	if (dispmap != NULL) {
	    HDC                 hdcMem;

	    SetBitmapBits(dispmap, bmsize, display_bits);

	    hdcMem = CreateCompatibleDC(ps.hdc);
	    SelectObject(hdcMem, dispmap);

	    BitBlt(ps.hdc, ps.rcPaint.top, ps.rcPaint.left,
		   ps.rcPaint.bottom - ps.rcPaint.top,
		   ps.rcPaint.right - ps.rcPaint.left,
		   hdcMem, ps.rcPaint.top, ps.rcPaint.left, SRCINVERT);
	    DeleteDC(hdcMem);
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
	PostEvent(EVENT_MOUSEBUT, buttons);

    case WM_MOUSEMOVE:
	col = LOWORD(lParam);
	row = HIWORD(lParam);
	PostEvent(EVENT_MOUSEPOS, ((col & 0xfff) << 12) + (row & 0xfff));
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

long 
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

long 
file_seek(long id, long pos)
{
    return SetFilePointer((HANDLE) id, pos, NULL, FILE_BEGIN);
}

int 
file_write(long id, char *buffer, long size)
{
    DWORD               did;

    if (!WriteFile((HANDLE) id, buffer, size, &did, 0))
	return -1;
    if (did != size)
	return -1;
    else
	return did;
}

int 
file_read(long id, char *buffer, long size)
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
file_close(long id)
{
    return CloseHandle((HANDLE) id);
}

long 
file_size(long id)
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
    error(buffer);
}


void
dump_string(char *str)
{
    DWORD		did;

    WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), str, strlen(str), &did, 0);
    WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), "\r\n", 2, &did, 0);
}

static void
fill_buffer(char c)
{
    DWORD	did;

    out = GetStdHandle(STD_OUTPUT_HANDLE);
    WriteFile(out, &c, 1, &did, 0);
    if (c == '\r') 
        c = '\n';
    if (console.file_buffer != NULL) {
	if (console.file_len < BUFSIZE)
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

unsigned long
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
    return (unsigned long)mktime(&tm);
}

int
current_mtime()
{
    SYSTEMTIME		st;
    GetSystemTime(&st);
    return st.wMilliseconds; 
}
#endif
