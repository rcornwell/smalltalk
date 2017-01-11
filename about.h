/*
 *
 *  Quick Installer.
 *
 *  About dialog box.
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
 *
 */

/*
 * $Id: about.h,v 1.2 2001/07/31 14:09:47 rich Exp $
 *
 * $Log: about.h,v $
 * Revision 1.2  2001/07/31 14:09:47  rich
 * Fixed for new version of cygwin
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 *
 */

#ifdef WIN32
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
