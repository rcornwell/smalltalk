/*
 * Smalltalk interpreter: Main routine.
 *
 * $Log: smalltalk.c,v $
 * Revision 1.3  2000/02/02 16:07:38  rich
 * Don't need to include primitive.h
 *
 * Revision 1.2  2000/02/01 18:10:03  rich
 * Fixed image load code.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#ifndef lint
static char        *rcsid =
	"$Id: smalltalk.c,v 1.3 2000/02/02 16:07:38 rich Exp rich $";
#endif

#ifdef _WIN32

#include <stddef.h>
#include <windows.h>
#endif

#ifdef unix
#include <stdio.h>
#endif

#include "smalltalk.h"
#include "about.h"
#include "object.h"
#include "interp.h"
#include "fileio.h"
#include "dump.h"

char               *imagename = NULL;
char               *loadfile = NULL;
int                 defotsize = 512;

static int          getnum(char *, int *);

#ifdef _WIN32
static void         CreateWindows(HINSTANCE, HWND, LPARAM);
static void         DoWinCommand(HINSTANCE, HWND, WPARAM);
static LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
static char        *szAppName = "SmallTalk";
static char        *getarg(char **);
static int          parseCmd(char *);

/*
 * Create main window.
 */
int                 WINAPI
WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
		    PSTR szCmdLine, int iCmdShow)
{
    HWND                hwnd;
    HACCEL              hAccel;
    MSG                 msg;
    WNDCLASSEX          wndclass;

   /* Initialize class structure */
    wndclass.cbSize = sizeof(wndclass);
    wndclass.style = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc = WndProc;
    wndclass.cbClsExtra = 0;
    wndclass.cbWndExtra = 0;
    wndclass.hInstance = hInstance;
    wndclass.hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(SMALLTALK));
    wndclass.hCursor = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = (HBRUSH) GetStockObject(WHITE_BRUSH);
    wndclass.lpszMenuName = szAppName;
    wndclass.lpszClassName = szAppName;
    wndclass.hIconSm = LoadIcon(hInstance, MAKEINTRESOURCE(SMALLTALK));

   /* Create Window */
    RegisterClassEx(&wndclass);

    hwnd = CreateWindow(szAppName, "Smalltalk", WS_OVERLAPPEDWINDOW,
			CW_USEDEFAULT, CW_USEDEFAULT, 500, 400,
			NULL, NULL, hInstance, szCmdLine);

   /* Initialize rest */
    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    hAccel = LoadAccelerators(hInstance, MAKEINTRESOURCE(SMALLTALK));

   /* Make window loop */
    while (GetMessage(&msg, NULL, 0, 0)) {
	TranslateMessage(&msg);
	DispatchMessage(&msg);
    }
    return msg.wParam;
}

/*
 * Main window proceedure.
 */
static LRESULT      CALLBACK
WndProc(HWND hwnd, UINT iMsg, WPARAM wParam, LPARAM lParam)
{
    static HINSTANCE    hInst;

    switch (iMsg) {
    case WM_CREATE:
	hInst = ((LPCREATESTRUCT) lParam)->hInstance;

       /* Process the arguments */
	if (!parseCmd(GetCommandLine())) {
	    SendMessage(hwnd, WM_CLOSE, 0, 0);
	    return 0;
	}

	CreateWindows(hInst, hwnd, lParam);

       /* If there is a image file, load it */
	if (imagename != NULL)
	    load_file(imagename);
	else {
	   /* Build new system */
	    smallinit(defotsize);
	   /* Compile into system */
	    if (loadfile != NULL)
		parsefile(loadfile);
	}

	return 0;

    case WM_COMMAND:
	DoWinCommand(hInst, hwnd, wParam);

	return 0;

#if 0
    case WM_CLOSE:
	return 0;
#endif

    case WM_DESTROY:
    	close_files();
	PostQuitMessage(0);
	return 0;

    }
    return DefWindowProc(hwnd, iMsg, wParam, lParam);
}

static void
CreateWindows(HINSTANCE hInst, HWND hwnd, LPARAM lParam)
{

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

/*
 * Grab next argument from command string.
 */
static char        *
getarg(char **str)
{
    char               *ptr = *str;
    char                c;
    char               *arg;

   /* Skip leading blanks */
    while (*ptr == ' ' || *ptr == '\t')
	ptr++;
    if (*ptr == '\0')
	return NULL;

   /* Pointer to start of argument */
    arg = ptr;

   /* For "'d strings, skip till end of string */
    if (*arg == '"') {
	for (arg = ++ptr; *ptr != '"' && *ptr != '\0'; ptr++) ;
    } else {
       /* Otherwise, skip till next white space */
	for (; *ptr != ' ' && *ptr != '\t' && *ptr != '\n'
	     && *ptr != '\r' && *ptr != '\0'; ptr++) ;
    }

   /* Save current character */
    c = *ptr;

   /* Terminate and advance if not at end of string */
    if (c != '\0')
	*ptr++ = '\0';
   /* Skip trailing cr-nl pair */
    if (c == '\n' || c == '\r') {
	if ((*ptr == '\r' || *ptr == '\n') && *ptr != c)
	    ptr++;
    }
   /* Save current location */

    *str = ptr;
    return arg;
}

/*
 * Scan command line arguments and collect options.
 */
static int
parseCmd(char *cmdstr)
{
    char               *arg;
    char                msgbuff[MAX_PATH];

   /* Skip command name */
    getarg(&cmdstr);

   /* Get rest of arguments */
    while ((arg = getarg(&cmdstr)) != NULL) {
	if (*arg == '-') {
	    while (*++arg != '\0') {
		switch (*arg) {
		case 'i':	/* Image file name */
		case 'I':
		    if (imagename != NULL)
			goto error;
		    imagename = getarg(&cmdstr);
		    break;
		case 'o':	/* Object table size */
		case 'O':
		    if (!getnum(getarg(&cmdstr), &defotsize))
			goto error;
		    break;
		case 'g':	/* Grow size */
		case 'G':
		    if (!getnum(getarg(&cmdstr), &growsize))
			goto error;
		    break;
		default:
		    goto error;
		}
	    }
	} else {
	    if (loadfile != NULL)
	        goto error;
	    loadfile = arg;
	}
    }

    return 1;

  error:

    LoadString(GetModuleHandle(NULL), IDS_INVARG, msgbuff, sizeof(msgbuff));
    strcat(msgbuff, arg);
    MessageBox(NULL, msgbuff, szAppName, MB_OK | MB_ICONERROR);
    return 0;

}

#endif
#ifdef unix

int
main(int argc, char *argv[])
{
    char               *str;

   /* Process arguments */
    while ((str = *++argv) != NULL) {
	if (*str == '-') {
	    while (*++str != '\0') {
		switch (*str) {
		case 'i':	/* Image file name */
		    if (imagename != NULL)
			goto error;
		    imagename = *++argv;
		    break;
		case 'o':	/* Object table size */
		    if (!getnum(*++argv, &defotsize))
			goto error;
		    break;
		case 'g':	/* Grow size */
		    if (!getnum(*++argv, &growsize)) 
		        goto error;
		    break;
		default:
		    goto error;
		}
	    }
	} else {
	    if (loadfile != NULL)
	        goto error;
	    loadfile = str;
	}
    }

   /* If there is a image file, load it */
    if (imagename != NULL) {
	load_file(imagename);
    } else {
       /* Build new system */
        smallinit(defotsize);
       /* Compile into system */
	if (loadfile != NULL)
	    parsefile(loadfile);
    }
    close_files();
    return 0;

  error:
    fprintf(stderr, "Invalid argument: %s", str);
    return 0;
}
#endif

static int
getnum(char *str, int *value)
{
    int                 temp = 0;

    while (*str != '\0') {
	if (*str >= '0' && *str <= '9')
	    temp = (temp * 10) + (*str++ - '0');
	else
	    return FALSE;
    }
    *value = temp;
    return TRUE;
}
