/*
 * Quick Installer.
 *
 * About box displayer.
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
