
/*
 * Small Edit
 *
 * Tiny editor for smalltalk programs.
 *
 * Copyright 1999 Richard P. Cornwell All Rights Reserved,
 *
 * The software is provided "as is", without warranty of any kind, express
 * or implied, including but not limited to the warranties of
 * merchantability, fitness for a particular purpose and non-infringement.
 * In no event shall Richard Cornwell be liable for any claim, damages
 * or other liability, whether in an action of contract, tort or otherwise,
 * arising from, out of or in connection with the software or the use or other
 * dealings in the software.
 *
 * Permission to use, copy, and distribute this software and its
 * documentation for non commercial use is hereby granted,
 * provided that the above copyright notice appear in all copies and that
 * both that copyright notice and this permission notice appear in
 * supporting documentation.
 *
 * The sale, resale, or use of quick installer for profit without the
 * express written consent of the author Richard Cornwell is forbidden.
 * Please see attached License file for information about using this
 * package in commercial applications, or for commercial software distribution.
 *
 */

/*
 *
 * $Log: smalledit.c,v $
 * Revision 1.1  2002/02/17 13:43:17  rich
 * Initial revision
 *
 *
 */

static char 
__attribute__((unused)) rcsid[] =
"$Id: smalledit.c,v 1.1 2002/02/17 13:43:17 rich Exp $";

#include <stddef.h>
#include <windows.h>
#include <CommCtrl.h>
#include <stdio.h>
#include <string.h>

#include "smalledit.h"
#include "about.h"

#define UNTITLED "(untitled)"
#define MAX_STRING_LEN   256

static OPENFILENAME ofn;
HWND                hDlgModeless = 0;
HINSTANCE           hInst;
BOOL                userAbort;
HWND                hDlgPrint;
LOGFONT             logfont;
char                szAppName[] = APPNAME;
static char         szFindText[MAX_STRING_LEN];
static char         szReplText[MAX_STRING_LEN];
char                editFileName[MAX_PATH];
BOOL                editNeedSave = FALSE;
char                szTitleName[100];
int                 runprint = FALSE;
TBBUTTON            tb_buttons[] = {
    {STD_FILENEW, IDM_NEW, TBSTATE_ENABLED, TBSTYLE_BUTTON, {0, 0}, 0, -1},
    {STD_FILEOPEN, IDM_OPEN, TBSTATE_ENABLED, TBSTYLE_BUTTON, {0, 0}, 0, -1},
    {STD_FILESAVE, IDM_SAVE, TBSTATE_ENABLED, TBSTYLE_BUTTON, {0, 0}, 0, -1},
    {0, 0, TBSTATE_ENABLED, TBSTYLE_SEP, {0, 0}, 0, 0},
    {STD_PRINT, IDM_PRINT, TBSTATE_ENABLED, TBSTYLE_BUTTON, {0, 0}, 0, -1},
    {0, 0, TBSTATE_ENABLED, TBSTYLE_SEP, {0, 0}, 0, 0},
    {STD_FIND, IDM_FIND, TBSTATE_ENABLED, TBSTYLE_BUTTON, {0, 0}, 0, -1},
    {STD_REPLACE, IDM_NEXT, TBSTATE_ENABLED, TBSTYLE_BUTTON, {0, 0}, 0, -1},
    {0, 0, TBSTATE_ENABLED, TBSTYLE_SEP, {0, 0}, 0, 0},
    {STD_CUT, IDM_CUT, TBSTATE_ENABLED, TBSTYLE_BUTTON, {0, 0}, 0, -1},
    {STD_PASTE, IDM_PASTE, TBSTATE_ENABLED, TBSTYLE_BUTTON, {0, 0}, 0, -1},
    {STD_COPY, IDM_COPY, TBSTATE_ENABLED, TBSTYLE_BUTTON, {0, 0}, 0, -1},
    {STD_UNDO, IDM_UNDO, TBSTATE_ENABLED, TBSTYLE_BUTTON, {0, 0}, 0, -1},
};

static void         CreateWindows(HINSTANCE, HWND, LPARAM);
static void         DoWinCommand(HINSTANCE, HWND, WPARAM, int *);
static void         FileInitialize(HWND);
static BOOL         FileRead(HWND, char *);
static BOOL         FileWrite(HWND, char *);
static HWND         FindFindDlg(HWND);
static HWND         FindReplaceDlg(HWND);
static BOOL         FindFindText(HWND, int *, LPFINDREPLACE);
static BOOL         FindNextText(HWND, int *);
static BOOL         FindReplaceText(HWND, int *, LPFINDREPLACE);
static BOOL         FindValidFind(void);
static LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
static BOOL CALLBACK PrintDlgProc(HWND, UINT, WPARAM, LPARAM);
static BOOL CALLBACK AbortProc(HDC, int);
static BOOL         PrntPrintFile(HINSTANCE, HWND, HWND, LPSTR);
void                DoCaption(HWND, char *);
void                OkMessage(HWND, int, char *);
int                 AskAboutSave(HWND, char *);


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
    wndclass.hIcon = LoadIcon(hInstance, MAKEINTRESOURCE(SMALLEDIT));
    wndclass.hCursor = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = (HBRUSH) GetStockObject(WHITE_BRUSH);
    wndclass.lpszMenuName = szAppName;
    wndclass.lpszClassName = szAppName;
    wndclass.hIconSm = LoadIcon(hInstance, MAKEINTRESOURCE(SMALLEDIT));

   /* Create Window */
    RegisterClassEx(&wndclass);

    hwnd = CreateWindow(szAppName, "Small Edit", WS_OVERLAPPEDWINDOW,
			CW_USEDEFAULT, CW_USEDEFAULT, 500, 400,
			NULL, NULL, hInstance, szCmdLine);

   /* Initialize rest */
    InitCommonControls();
    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    hAccel = LoadAccelerators(hInstance, MAKEINTRESOURCE(SMALLEDIT));

   /* Make window loop */
    while (GetMessage(&msg, NULL, 0, 0)) {
	if (!(hDlgModeless != 0 && IsDialogMessage(hDlgModeless, &msg))) {
	    if (!TranslateAccelerator(hwnd, hAccel, &msg)) {
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	    }
	}
    }
    return msg.wParam;
}

/*
 * Set the caption on the main window.
 */
void
DoCaption(HWND hwnd, char *szTitleName)
{
    char                szCaption[100];

    wsprintf(szCaption, "%s - %-80s", szAppName,
	     szTitleName[0] ? szTitleName : UNTITLED);
    SetWindowText(hwnd, szCaption);
}

/*
 * Display a error message with a ok box.
 */
void
OkMessage(HWND hwnd, int message, char *TitleName)
{
    char                buffer[100];
    char                format[100];

    LoadString(hInst, message, format, sizeof(format));
    wsprintf(buffer, format, TitleName[0] ? TitleName : UNTITLED);

    MessageBox(hwnd, buffer, szAppName, MB_OK | MB_ICONEXCLAMATION);
}

/*
 * Check if user wants to wants to save file.
 */
int
AskAboutSave(HWND hwnd, char *TitleName)
{
    char                buffer[100];
    char                format[100];
    int                 ret;

    LoadString(hInst, IDS_SAVEFILE, format, sizeof(format));
    wsprintf(buffer, format, TitleName[0] ? TitleName : UNTITLED);

    ret = MessageBox(hwnd, buffer, szAppName, MB_YESNOCANCEL | MB_ICONQUESTION);

    if (ret == IDYES && SendMessage(hwnd, WM_COMMAND, IDM_SAVE, 0L))
        ret = IDCANCEL;

    return ret;
}

/*
 * Main window proceedure.
 */
static LRESULT      CALLBACK
WndProc(HWND hwnd, UINT iMsg, WPARAM wParam, LPARAM lParam)
{
    static HINSTANCE    hInst;
    HWND                hwndEdit;
    HWND                hwndTool;
    static int          iOffset;
    static UINT         iMsgFindReplace;
    RECT                rect;

    switch (iMsg) {
    case WM_CREATE:
	hInst = ((LPCREATESTRUCT) lParam)->hInstance;

	CreateWindows(hInst, hwnd, lParam);
	iMsgFindReplace = RegisterWindowMessage(FINDMSGSTRING);

	return 0;

    case WM_SETFOCUS:
	hwndEdit = GetDlgItem(hwnd, IDD_EDIT);
	SetFocus(hwndEdit);
	return 0;

    case WM_SIZE:
	hwndTool = GetDlgItem(hwnd, IDD_TOOLBAR);

	SendMessage(hwndTool, TB_AUTOSIZE, 0, 0);
	MoveWindow(hwndTool, 0, 0, LOWORD(lParam), HIWORD(lParam), TRUE);
	GetClientRect(hwndTool, &rect);
	rect.bottom += 3;

	hwndEdit = GetDlgItem(hwnd, IDD_EDIT);
	MoveWindow(hwndEdit, 0, rect.bottom, LOWORD(lParam),
		   HIWORD(lParam) - rect.bottom, TRUE);
	return 0;

    case WM_INITMENUPOPUP:
	hwndEdit = GetDlgItem(hwnd, IDD_EDIT);
	switch (lParam) {
	case 1:		/* Edit menu */

	   /* Enable Undo if edit control can do it */

	    if (SendMessage(hwndEdit, EM_CANUNDO, 0, 0L))
		EnableMenuItem((HMENU) wParam, IDM_UNDO, MF_ENABLED);
	    else
		EnableMenuItem((HMENU) wParam, IDM_UNDO, MF_GRAYED);

	   /* Enable Paste if text is in the clipboard */

	    if (IsClipboardFormatAvailable(CF_TEXT))
		EnableMenuItem((HMENU) wParam, IDM_PASTE, MF_ENABLED);
	    else
		EnableMenuItem((HMENU) wParam, IDM_PASTE, MF_GRAYED);

	   /* Enable Cut, Copy, and Del if text is selected */
	    {
		int                 iSelBeg, iSelEnd, iEnable;

		SendMessage(hwndEdit, EM_GETSEL, (WPARAM) & iSelBeg,
			    (LPARAM) & iSelEnd);

		iEnable = iSelBeg != iSelEnd ? MF_ENABLED : MF_GRAYED;

		EnableMenuItem((HMENU) wParam, IDM_CUT, iEnable);
		EnableMenuItem((HMENU) wParam, IDM_COPY, iEnable);
		EnableMenuItem((HMENU) wParam, IDM_CLEAR, iEnable);
	    }
	    break;

	case 2:		/* Search menu */

	   /* Enable Find, Next, and Replace if modeless */
	   /*   dialogs are not already active */

	    {
		int                 iEnable;

		iEnable = hDlgModeless == NULL ? MF_ENABLED : MF_GRAYED;

		EnableMenuItem((HMENU) wParam, IDM_FIND, iEnable);
		EnableMenuItem((HMENU) wParam, IDM_NEXT, iEnable);
		EnableMenuItem((HMENU) wParam, IDM_REPLACE, iEnable);
	    }
	    break;
	}
	return 0;

    case WM_COMMAND:
       /* Messages from edit control */
	if (lParam && LOWORD(wParam) == IDD_EDIT) {
	    switch (HIWORD(wParam)) {
	    case EN_UPDATE:
		editNeedSave = TRUE;
		break;

	    case EN_ERRSPACE:
	    case EN_MAXTEXT:
		MessageBox(hwnd, "Edit control out of space.",
			   szAppName, MB_OK | MB_ICONSTOP);
		break;
	    }
	} else
	    DoWinCommand(hInst, hwnd, wParam, &iOffset);

	return 0;

    case WM_NOTIFY:
	/* Process notifies... tooltips for now only */
	{
	LPNMHDR	pnmh = (LPNMHDR)lParam;
	
	    if (pnmh->code == TTN_NEEDTEXT) {
	        LPTOOLTIPTEXT lpttt = (LPTOOLTIPTEXT) lParam;

	        LoadString(hInst, lpttt->hdr.idFrom + 120, lpttt->szText, 
			sizeof(lpttt->szText));
	        return 0;
	    }
	}
	break;

    case WM_CLOSE:
	if (!editNeedSave || IDCANCEL != AskAboutSave(hwnd, szTitleName)) {
	    DestroyWindow(hwnd);
	}

	return 0;

    case WM_QUERYENDSESSION:
	if (!editNeedSave || IDCANCEL != AskAboutSave(hwnd, szTitleName)) {
	    return 1;
	}

	return 0;

    case WM_DESTROY:
	PostQuitMessage(0);
	return 0;

       /* Process "Find-Replace" iMsgs */

    default:
	if (iMsg == iMsgFindReplace) {
	    LPFINDREPLACE       pfr = (LPFINDREPLACE) lParam;

	    hwndEdit = GetDlgItem(hwnd, IDD_EDIT);

	    if (pfr->Flags & FR_DIALOGTERM)
		hDlgModeless = NULL;

	    if (pfr->Flags & FR_FINDNEXT)
		if (!FindFindText(hwndEdit, &iOffset, pfr))
		    OkMessage(hwnd, IDS_TEXTNOTFND, "\0");

	    if (pfr->Flags & FR_REPLACE || pfr->Flags & FR_REPLACEALL)
		if (!FindReplaceText(hwndEdit, &iOffset, pfr))
		    OkMessage(hwnd, IDS_TEXTNOTFND, "\0");

	    if (pfr->Flags & FR_REPLACEALL)
		while (FindReplaceText(hwndEdit, &iOffset, pfr)) ;

	    return 0;

	}
	break;
    }
    return DefWindowProc(hwnd, iMsg, wParam, lParam);
}

static void
CreateWindows(HINSTANCE hInst, HWND hwnd, LPARAM lParam)
{
    char               *ptr;
    HWND                hwndEdit;
    HWND                hwndTool;
    int                 newfile;
    TBADDBITMAP         tb;

   /* Process argumentes */
    newfile = FALSE;
    ptr = (PSTR) (((LPCREATESTRUCT) lParam)->lpCreateParams);
    while (*ptr != '\0') {
	for (; *ptr == ' '; ptr++) ;	/* Skip blanks */
	if (*ptr == '-') {
	    for (++ptr; *ptr != ' ' && *ptr != '\0'; ptr++) {
		switch (*ptr) {
		case 'p':
		    runprint = TRUE;
		    break;
		case 'n':
		    newfile = TRUE;
		    break;
		}
	    }
	} else
	    break;
    }

   /* Process Filename */
    lstrcpy(editFileName, ptr);
    if (*editFileName != '\0') {
	char               *p;

       /* Strip off leading and trailing quotes */
	for (p = editFileName; *p != '\0'; p++) {
	    if (*p == '"' && p[1] == '\0') {
		*p = '\0';
		break;
	    }
	}
	if (*(p = editFileName) == '"') {
	    for (; *p != '\0'; p++)
		*p = p[1];
	}
    }
   /* Create the toolbar */
    hwndTool = CreateToolbarEx(hwnd,
	  CCS_TOP | WS_VISIBLE | WS_CHILD | WS_CLIPSIBLINGS | TBSTYLE_TOOLTIPS,
	  IDD_TOOLBAR, 0, HINST_COMMCTRL, IDB_STD_SMALL_COLOR,
	  tb_buttons, 11, 0, 0, 0, 0, sizeof(TBBUTTON));
    tb.hInst = hInst;
    tb.nID = IDI_TOOL;

   /* Create the edit control child window */
    hwndEdit = CreateWindow("edit", NULL,
			WS_CHILD | WS_VISIBLE | WS_HSCROLL | WS_VSCROLL |
			    WS_BORDER | ES_LEFT | ES_MULTILINE |
			  ES_NOHIDESEL | ES_AUTOHSCROLL | ES_AUTOVSCROLL,
			0, 0, 0, 0, hwnd, (HMENU) IDD_EDIT, hInst, NULL);

    /*    SendMessage(hwndEdit, EM_LIMITTEXT, 32000, 0L); */

   /* Initialize common dialog box stuff */

    FileInitialize(hwnd);

    if (!FileRead(hwndEdit, editFileName)) {
	if (newfile)
	    OkMessage(hwnd, IDS_READERR, szTitleName);
	else
	    GetFileTitle(editFileName, szTitleName, sizeof(szTitleName));
    } else
	GetFileTitle(editFileName, szTitleName, sizeof(szTitleName));
    DoCaption(hwnd, szTitleName);
    if (runprint)
	if (!PrntPrintFile(hInst, hwnd, hwndEdit, szTitleName))
	    OkMessage(hwnd, IDS_PRINTERR, szTitleName);
    if (runprint)
	SendMessage(hwnd, WM_CLOSE, 0, 0);
}

static void
DoWinCommand(HINSTANCE hInst, HWND hwnd, WPARAM wParam, int *iOffset)
{
    HWND                hwndEdit = GetDlgItem(hwnd, IDD_EDIT);
    char                buffer[MAX_PATH];

   /* Messages from menus */
    switch (LOWORD(wParam)) {
    case IDM_NEW:
	if (editNeedSave && IDCANCEL == AskAboutSave(hwnd, szTitleName))
	    break;

	SetWindowText(hwndEdit, "\0");
	editFileName[0] = '\0';
	szTitleName[0] = '\0';
	DoCaption(hwnd, szTitleName);
	editNeedSave = FALSE;
	break;

    case IDM_OPEN:
       /* Check if we need to save current one */
	if (editNeedSave && IDCANCEL == AskAboutSave(hwnd, szTitleName))
	    break;

       /* Setup for browse */
	ofn.hwndOwner = hwnd;
	ofn.lpstrFile = editFileName;
	ofn.lpstrFileTitle = szTitleName;
	ofn.Flags = OFN_HIDEREADONLY | OFN_CREATEPROMPT | OFN_EXPLORER;

       /* Get file name and open */
	if (GetOpenFileName(&ofn)) {
	    if (!FileRead(hwndEdit, editFileName)) {
		OkMessage(hwnd, IDS_READERR, szTitleName);
		editFileName[0] = '\0';
		szTitleName[0] = '\0';
	    }
	}
	DoCaption(hwnd, szTitleName);
	editNeedSave = FALSE;
	break;

    case IDM_SAVE:
	if (editFileName[0]) {
	    if (FileWrite(hwndEdit, editFileName))
		editNeedSave = FALSE;
	    else
		OkMessage(hwnd, IDS_WRITERR, szTitleName);
	    break;
	}
       /* fall through */
    case IDM_SAVEAS:
	ofn.hwndOwner = hwnd;
	ofn.lpstrFile = editFileName;
	ofn.lpstrFileTitle = szTitleName;
	ofn.Flags = OFN_OVERWRITEPROMPT;

	if (GetSaveFileName(&ofn)) {
	    DoCaption(hwnd, szTitleName);

	    if (FileWrite(hwndEdit, editFileName))
		editNeedSave = FALSE;
	    else
		OkMessage(hwnd, IDS_WRITERR, szTitleName);
	}
	break;

    case IDM_PRINT:
	if (!PrntPrintFile(hInst, hwnd, hwndEdit, szTitleName))
	    OkMessage(hwnd, IDS_PRINTERR, szTitleName);
	break;

    case IDM_EXIT:
	SendMessage(hwnd, WM_CLOSE, 0, 0);
	break;

    case IDM_UNDO:
	SendMessage(hwndEdit, WM_UNDO, 0, 0);
	break;

    case IDM_CUT:
	SendMessage(hwndEdit, WM_CUT, 0, 0);
	break;

    case IDM_COPY:
	SendMessage(hwndEdit, WM_COPY, 0, 0);
	break;

    case IDM_PASTE:
	SendMessage(hwndEdit, WM_PASTE, 0, 0);
	break;

    case IDM_CLEAR:
	SendMessage(hwndEdit, WM_CLEAR, 0, 0);
	break;

    case IDM_SELALL:
	SendMessage(hwndEdit, EM_SETSEL, 0, -1);
	break;

    case IDM_FIND:
	SendMessage(hwndEdit, EM_GETSEL, (WPARAM) NULL, (LPARAM) iOffset);
	hDlgModeless = FindFindDlg(hwnd);
	break;

    case IDM_NEXT:
	SendMessage(hwndEdit, EM_GETSEL, (WPARAM) NULL, (LPARAM) iOffset);

	if (FindValidFind())
	    FindNextText(hwndEdit, iOffset);
	else
	    hDlgModeless = FindFindDlg(hwnd);

	break;

    case IDM_REPLACE:
	SendMessage(hwndEdit, EM_GETSEL, (WPARAM) NULL, (LPARAM) iOffset);
	hDlgModeless = FindReplaceDlg(hwnd);
	break;

    case IDM_HELP:
       /* Convert our module name into a help file name */
	strcpy(buffer, szAppName);
	strcat(buffer, ".HLP");
	if (!WinHelp(hwnd, buffer, HELP_CONTENTS, (DWORD) 0))
	    OkMessage(hwnd, IDS_HELPERR, "\0");
	break;

    case IDM_ABOUT:
	AboutBox(hwnd, hInst, szAppName, "#1");
	break;

    }
}

/*
 * Set up for calling file dialog box.
 */
static void
FileInitialize(HWND hwnd)
{
    static char         szFilter[] = "Smalltalk Files (*.st)\0*.st\0" \
    "Smalltalk Change Files (*.stc)\0*.*.stc\0" \
    "All Files (*.*)\0*.*\0\0";

    ofn.lStructSize = sizeof(OPENFILENAME);
    ofn.hwndOwner = hwnd;
    ofn.hInstance = NULL;
    ofn.lpstrFilter = szFilter;
    ofn.lpstrCustomFilter = NULL;
    ofn.nMaxCustFilter = 0;
    ofn.nFilterIndex = 0;
    ofn.lpstrFile = NULL;	/* Set in Open and Close functions */
    ofn.nMaxFile = 100;
    ofn.lpstrFileTitle = NULL;	/* Set in Open and Close functions */
    ofn.nMaxFileTitle = 100;
    ofn.lpstrInitialDir = NULL;
    ofn.lpstrTitle = NULL;
    ofn.Flags = 0;		/* Set in Open and Close functions */
    ofn.nFileOffset = 0;
    ofn.nFileExtension = 0;
    ofn.lpstrDefExt = "st";
    ofn.lCustData = 0L;
    ofn.lpfnHook = NULL;
    ofn.lpTemplateName = NULL;
}

/*
 * Read the file into the edit buffer.
 */
static              BOOL
FileRead(HWND hwndEdit, char *FileName)
{
    HANDLE              file;
    BY_HANDLE_FILE_INFORMATION finfo;
    char               *buffer, *buffer2;
    char	       *ptr, *ptr2;
    DWORD               got;
    int			lines;

   /* Open file */
    if ((file = CreateFile(FileName, GENERIC_READ, 0, NULL, OPEN_EXISTING,
		   FILE_ATTRIBUTE_NORMAL, NULL)) == INVALID_HANDLE_VALUE)
	return FALSE;

   /* Collect size */
    GetFileInformationByHandle(file, &finfo);
    if (finfo.nFileSizeHigh != 0) {
	CloseHandle(file);
	return FALSE;
    }
   /*
    * If file is empty and wizard is not set... ask if we should run the
    * wizard
    */
    if (finfo.nFileSizeLow == 0) {
	SetWindowText(hwndEdit, "");
	CloseHandle(file);
	return TRUE;
    }
   /* Allocate temp space for file */
    buffer = (char *) GlobalAlloc(GMEM_FIXED, finfo.nFileSizeLow + 1);
    if (NULL == buffer) {
	CloseHandle(file);
	return FALSE;
    }
   /* Read file into buffer */
    if (!ReadFile(file, buffer, finfo.nFileSizeLow, &got, NULL) &&
	got != finfo.nFileSizeLow) {
	CloseHandle(file);
	GlobalFree(buffer);
	return FALSE;
    }
    CloseHandle(file);

   /* Set editor to point at buffer */
    buffer[finfo.nFileSizeLow] = '\0';

   /* Count number of new line characters in file */
    for(lines=0, ptr = buffer; *ptr != '\0'; ptr++)
	if (*ptr == '\n' && ptr[1] != '\r')
	   lines++;

   /* Allocate temp space for file */
    buffer2 = (char *) GlobalAlloc(GMEM_FIXED, strlen(buffer) + lines + 1);
    if (NULL == buffer2) {
	GlobalFree(buffer);
	return FALSE;
    }

   /* Now copy buffer adding in cr's as we go */
    for(ptr = buffer, ptr2 = buffer2; *ptr != '\0'; ptr++) {
	if (*ptr == '\n' && ptr[1] != '\r') 
	   *ptr2++ = '\r';
	*ptr2++ = *ptr;
    }
    *ptr2++ = '\0';
     
    GlobalFree(buffer);
    SetWindowText(hwndEdit, buffer2);
    GlobalFree(buffer2);
    return TRUE;
}

/*
 * Save the file out to disk.
 */
static              BOOL
FileWrite(HWND hwndEdit, char *FileName)
{
    HANDLE              file;
    int                 length;
    char               *buffer;
    char	       *ptr, *ptr2;
    DWORD               did;

    if ((file = CreateFile(FileName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS,
		   FILE_ATTRIBUTE_NORMAL, NULL)) == INVALID_HANDLE_VALUE)
	return FALSE;

    length = GetWindowTextLength(hwndEdit);

    if (NULL == (buffer = (char *) GlobalAlloc(GMEM_FIXED, length + 1))) {
	CloseHandle(file);
	return FALSE;
    }
    GetWindowText(hwndEdit, buffer, length + 1);

    /* Scan buffer, and remove cr in nl/cr pairs */
    for(ptr = ptr2 = buffer; *ptr != '\0'; ptr++) {
	if (*ptr == '\r' && ptr[1] == '\n')
	   ptr++;
	*ptr2++ = *ptr;
    }
    *ptr2++ = '\0';
    length = strlen(buffer);

    if (!WriteFile(file, buffer, length, &did, NULL) && did != length) {
	CloseHandle(file);
	GlobalFree(buffer);
	return FALSE;
    }
    CloseHandle(file);
    GlobalFree(buffer);
    return TRUE;
}

/*
 * Build a find dialog box.
 */
static              HWND
FindFindDlg(HWND hwnd)
{
    static FINDREPLACE  fr;	/* must be static for modeless dialog!!! */

    fr.lStructSize = sizeof(FINDREPLACE);
    fr.hwndOwner = hwnd;
    fr.hInstance = NULL;
    fr.Flags = FR_HIDEUPDOWN | FR_HIDEMATCHCASE | FR_HIDEWHOLEWORD;
    fr.lpstrFindWhat = szFindText;
    fr.lpstrReplaceWith = NULL;
    fr.wFindWhatLen = sizeof(szFindText);
    fr.wReplaceWithLen = 0;
    fr.lCustData = 0;
    fr.lpfnHook = NULL;
    fr.lpTemplateName = NULL;

    return FindText(&fr);
}

/*
 * Build a replace dialog box.
 */
static              HWND
FindReplaceDlg(HWND hwnd)
{
    static FINDREPLACE  fr;	/* must be static for modeless dialog!!! */

    fr.lStructSize = sizeof(FINDREPLACE);
    fr.hwndOwner = hwnd;
    fr.hInstance = NULL;
    fr.Flags = FR_HIDEUPDOWN | FR_HIDEMATCHCASE | FR_HIDEWHOLEWORD;
    fr.lpstrFindWhat = szFindText;
    fr.lpstrReplaceWith = szReplText;
    fr.wFindWhatLen = sizeof(szFindText);
    fr.wReplaceWithLen = sizeof(szReplText);
    fr.lCustData = 0;
    fr.lpfnHook = NULL;
    fr.lpTemplateName = NULL;

    return ReplaceText(&fr);
}

/*
 * Find the text.
 */
static              BOOL
FindFindText(HWND hwndEdit, int *piSearchOffset, LPFINDREPLACE pfr)
{
    int                 iLength, iPos;
    PSTR                pstrDoc, pstrPos;

   /* Read in the edit document */

    iLength = GetWindowTextLength(hwndEdit);

    if (NULL == (pstrDoc = (PSTR) GlobalAlloc(GMEM_FIXED, iLength + 1)))
	return FALSE;

    GetWindowText(hwndEdit, pstrDoc, iLength + 1);

   /* Search the document for the find string */

    pstrPos = strstr(pstrDoc + *piSearchOffset, pfr->lpstrFindWhat);
    GlobalFree(pstrDoc);

   /* Return an error code if the string cannot be found */

    if (pstrPos == NULL)
	return FALSE;

   /* Find the position in the document and the new start offset */

    iPos = pstrPos - pstrDoc;
    *piSearchOffset = iPos + strlen(pfr->lpstrFindWhat);

   /* Select the found text */

    SendMessage(hwndEdit, EM_SETSEL, iPos, *piSearchOffset);
    SendMessage(hwndEdit, EM_SCROLLCARET, 0, 0);

    return TRUE;
}

/*
 * Find next text one.
 */
static              BOOL
FindNextText(HWND hwndEdit, int *piSearchOffset)
{
    FINDREPLACE         fr;

    fr.lpstrFindWhat = szFindText;

    return FindFindText(hwndEdit, piSearchOffset, &fr);
}

/*
 * Replace text.
 */
static              BOOL
FindReplaceText(HWND hwndEdit, int *piSearchOffset, LPFINDREPLACE pfr)
{
   /* Find the text */

    if (!FindFindText(hwndEdit, piSearchOffset, pfr))
	return FALSE;

   /* Replace it */

    SendMessage(hwndEdit, EM_REPLACESEL, 0, (LPARAM) pfr->lpstrReplaceWith);

    return TRUE;
}

static              BOOL
FindValidFind(void)
{
    return *szFindText != '\0';
}

static BOOL         CALLBACK
PrintDlgProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg) {
    case WM_INITDIALOG:
	EnableMenuItem(GetSystemMenu(hDlg, FALSE), SC_CLOSE, MF_GRAYED);
	return TRUE;

    case WM_COMMAND:
	userAbort = TRUE;
    }
    return FALSE;
}

static BOOL         CALLBACK
AbortProc(HDC hPrinterDC, int iCode)
{
    MSG                 msg;

    while (!userAbort && PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
	if (!hDlgPrint || !IsDialogMessage(hDlgPrint, &msg)) {
	    TranslateMessage(&msg);
	    DispatchMessage(&msg);
	}
    }
    return !userAbort;
}

static              BOOL
PrntPrintFile(HINSTANCE hInst, HWND hwnd, HWND hwndEdit,
	      LPSTR szTitleName)
{
    static DOCINFO      di =
    {sizeof(DOCINFO), "", NULL};
    static PRINTDLG     pd;
    BOOL                success;
    LPCTSTR             pstrBuffer;
    int                 yChar, iCharsPerLine, iLinesPerPage, iTotalLines,
                        iTotalPages, iPage, iLine, iLineNum;
    TEXTMETRIC          tm;
    WORD                iColCopy, iNonColCopy;

    pd.lStructSize = sizeof(PRINTDLG);
    pd.hwndOwner = hwnd;
    pd.hDevMode = NULL;
    pd.hDevNames = NULL;
    pd.hDC = NULL;
    pd.Flags = PD_ALLPAGES | PD_COLLATE | PD_RETURNDC;
    pd.nFromPage = 0;
    pd.nToPage = 0;
    pd.nMinPage = 0;
    pd.nMaxPage = 0;
    pd.nCopies = 1;
    pd.hInstance = NULL;
    pd.lCustData = 0L;
    pd.lpfnPrintHook = NULL;
    pd.lpfnSetupHook = NULL;
    pd.lpPrintTemplateName = NULL;
    pd.lpSetupTemplateName = NULL;
    pd.hPrintTemplate = NULL;
    pd.hSetupTemplate = NULL;

    if (!PrintDlg(&pd))
	return TRUE;

    iTotalLines = (short) SendMessage(hwndEdit, EM_GETLINECOUNT, 0, 0L);

    if (iTotalLines == 0)
	return TRUE;

    GetTextMetrics(pd.hDC, &tm);
    yChar = tm.tmHeight + tm.tmExternalLeading;

    iCharsPerLine = GetDeviceCaps(pd.hDC, HORZRES) / tm.tmAveCharWidth;
    iLinesPerPage = GetDeviceCaps(pd.hDC, VERTRES) / yChar;
    iTotalPages = (iTotalLines + iLinesPerPage - 1) / iLinesPerPage;

    pstrBuffer = (LPCTSTR) GlobalAlloc(GMEM_FIXED, iCharsPerLine + 1);

    EnableWindow(hwnd, FALSE);

    success = TRUE;
    userAbort = FALSE;

    hDlgPrint = CreateDialog(hInst, (LPCTSTR) "PrintDlgBox", hwnd,
			     PrintDlgProc);
    SetDlgItemText(hDlgPrint, IDD_FNAME, szTitleName);

    SetAbortProc(pd.hDC, AbortProc);

    if (StartDoc(pd.hDC, &di) > 0) {
	for (iColCopy = 0;
	     iColCopy < ((pd.Flags & PD_COLLATE) ? pd.nCopies : 1);
	     iColCopy++) {
	    for (iPage = 0; iPage < iTotalPages; iPage++) {
		for (iNonColCopy = 0;
		iNonColCopy < ((pd.Flags & PD_COLLATE) ? 1 : pd.nCopies);
		     iNonColCopy++) {
		    if (StartPage(pd.hDC) < 0) {
			success = FALSE;
			break;
		    }
		    for (iLine = 0; iLine < iLinesPerPage; iLine++) {
			iLineNum = iLinesPerPage * iPage + iLine;

			if (iLineNum > iTotalLines)
			    break;

			*(int *) pstrBuffer = iCharsPerLine;

			TextOut(pd.hDC, 0, yChar * iLine, pstrBuffer,
				(int) SendMessage(hwndEdit, EM_GETLINE,
				(WPARAM) iLineNum, (LPARAM) pstrBuffer));
		    }

		    if (EndPage(pd.hDC) < 0) {
			success = FALSE;
			break;
		    }
		    if (userAbort)
			break;
		}
		if (!success || userAbort)
		    break;
	    }

	    if (!success || userAbort)
		break;
	}
    } else
	success = FALSE;

    if (success)
	EndDoc(pd.hDC);

    GlobalFree((LPVOID) pstrBuffer);
    DeleteDC(pd.hDC);
    return success && !userAbort;
}

