
/*
 *
 *  Quick Installer.
 *
 *  About dialog box.
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
 * $Id: $
 *
 * $Log: $
 *
 *
 */

#ifdef _WIN32
#define IDA_PRODUCT	10
#define IDA_COMPANY	11
#define IDA_COPY	12
#define IDA_VERSION	13
#define IDA_EMAIL	14
#define IDA_ICON	15

#define IDA_FIRST	IDA_PRODUCT
#define IDA_LAST	IDA_EMAIL

#ifdef RC_INVOKED
AboutBox            DIALOG 20, 20, 160, 70
                    STYLE WS_POPUP | WS_DLGFRAME
                    CAPTION "About..."
                    FONT 8, "MS Shell Dlg"
                    BEGIN
                    LTEXT "Product:", IDA_PRODUCT + 10, 30, 1, 50, 8
                    LTEXT "ProductName", IDA_PRODUCT, 70, 1, 100, 8
                    LTEXT "Company:", IDA_COMPANY + 10, 30, 10, 50,
                    8
                    LTEXT "CompanyName", IDA_COMPANY, 70, 10, 100, 8
                    LTEXT "Copyright:", IDA_COPY + 10, 30, 20, 50, 8
                    LTEXT "LegalCopyright", IDA_COPY, 70, 20, 100, 8
                    LTEXT "Version:", IDA_VERSION + 10, 30, 30, 50,
                    8
                    LTEXT "ProductVersion", IDA_VERSION, 70, 30, 100,
                    8
                    LTEXT "Email:", IDA_EMAIL + 10, 30, 40, 50, 8
                    LTEXT "Email", IDA_EMAIL, 70, 40, 100, 8
                    ICON "#1", IDA_ICON, 1, 1
                    DEFPUSHBUTTON "OK", IDOK, 64, 53, 32, 14, WS_GROUP
                    END
#else
void                AboutBox(HWND, HINSTANCE, char *, char *);

#endif
#endif
