
/*
 * Quick Installer.
 *
 * About box displayer.
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
 * $Log: about.c,v $
 * Revision 1.2  2001/07/31 14:09:47  rich
 * Fixed for new version of cygwin
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

static char
 rcsid[] =
"$Id: about.c,v 1.2 2001/07/31 14:09:47 rich Exp $";

#ifdef WIN32
#include "smalltalk.h"
#include "about.h"

static BOOL CALLBACK AboutDlgProc(HWND, UINT, WPARAM, LPARAM);

struct aboutdata {
    char               *product;
    HICON               icon;
};

static BOOL         CALLBACK
AboutDlgProc(HWND hDlg, UINT iMsg, WPARAM wParam, LPARAM lParam)
{
    char                buffer[MAX_PATH], *ptr;
    char               *query;
    PVOID               verinfo;
    int                 len;
    int                 i;
    struct aboutdata   *pdata;
    PDWORD              translation;

    if (iMsg == WM_INITDIALOG) {
	pdata = (struct aboutdata *) lParam;

	wsprintf(buffer, "About %s...", pdata->product);
	SetWindowText(hDlg, buffer);

	if (pdata->icon != NULL) {
	    SendMessage(GetDlgItem(hDlg, IDA_ICON), STM_SETICON,
			(WPARAM) pdata->icon, 0);
	    SetClassLong(hDlg, GCL_HICON, (int) pdata->icon);
	    SetClassLong(hDlg, GCL_HICONSM, (int) pdata->icon);
	}
       /* Get the module name, then load version information */
	GetModuleFileName(NULL, buffer, sizeof(buffer));
	len = GetFileVersionInfoSize(buffer, 0);
	verinfo = GlobalAlloc(GMEM_FIXED, len);
	GetFileVersionInfo(buffer, 0, len, verinfo);

       /* Get Translation */
	VerQueryValue(verinfo, "\\VarFileInfo\\Translation",
		      (PVOID) & translation, &len);

       /* Load and store version information */
	for (i = IDA_FIRST; i <= IDA_LAST; i++) {
	    wsprintf(buffer, "\\StringFileInfo\\%04x%04x\\",
		     LOWORD(*translation), HIWORD(*translation));
	    ptr = &buffer[strlen(buffer)];
	    GetDlgItemText(hDlg, i, ptr, sizeof(buffer) - (ptr - buffer));
	    if (VerQueryValue(verinfo, buffer, (PVOID) & query, &len)) {
		SetDlgItemText(hDlg, i, query);
		if (i == IDA_PRODUCT) {
		    wsprintf(buffer, "About %s...", query);
		    SetWindowText(hDlg, buffer);
		}
	    } else {
		SetDlgItemText(hDlg, i, "");
		SetDlgItemText(hDlg, i + 10, "");
	    }
	}

	GlobalFree(verinfo);

	return TRUE;
    } else if (iMsg == WM_COMMAND) {
	EndDialog(hDlg, TRUE);
	return TRUE;
    }
    return FALSE;
}

void 
AboutBox(HWND hwnd, HINSTANCE hInst, char *product, char *icon)
{
    struct aboutdata    data;

    data.product = product;
    if (icon != NULL)
	data.icon = LoadIcon(hInst, icon);
    else
	data.icon = NULL;
    DialogBoxParam(hInst, "AboutBox", hwnd, AboutDlgProc,
		   (LPARAM) & data);
}

#endif
