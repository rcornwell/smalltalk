/*
 *
 *  SmallEdit
 *
 *  Simple Smalltalk editor.
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
 * $Id: smalledit.h,v 1.1 2002/02/17 13:46:24 rich Exp $
 *
 * $Log: smalledit.h,v $
 * Revision 1.1  2002/02/17 13:46:24  rich
 * Initial revision
 *
 *
 *
 */ 

#define VERSION "1.0.0"

#define APPNAME "Smalledit"

#define IDM_NEW		10
#define IDM_OPEN	11
#define IDM_SAVE	12
#define IDM_SAVEAS	13
#define IDM_PRINT	14
#define IDM_EXIT	15

#define IDM_UNDO	20
#define IDM_CUT		21
#define IDM_COPY	22
#define IDM_PASTE	23
#define IDM_CLEAR	24
#define IDM_SELALL	25

#define IDM_FIND	30
#define IDM_NEXT	31
#define IDM_REPLACE	32

#define IDM_HELP	40
#define IDM_ABOUT	41

#define IDM_DELETE	50
#define IDM_RENAME	51
#define IDM_CLEARALL	52
#define IDM_SELECTALL	53

#define IDI_TOOL	104
#define IDD_TOOLBAR	30
#define IDD_FNAME	31
#define IDD_EDIT	32

#define IDS_SAVEFILE	1
#define IDS_READERR	2
#define IDS_WRITERR	3
#define IDS_PRINTERR	4
#define IDS_HELPERR	5
#define	IDS_TEXTNOTFND	6

#define SMALLEDIT	1

#define IDS_TNEW	IDM_NEW+120
#define IDS_TOPEN	IDM_OPEN+120
#define IDS_TSAVE	IDM_SAVE+120
#define IDS_TSAVEAS	IDM_SAVEAS+120
#define IDS_TPRINT	IDM_PRINT+120
#define IDS_TEXIT	IDM_EXIT+120

#define IDS_TUNDO	IDM_UNDO+120
#define IDS_TCUT	IDM_CUT+120
#define IDS_TCOPY	IDM_COPY+120
#define IDS_TPASTE	IDM_PASTE+120
#define IDS_TCLEAR	IDM_CLEAR+120
#define IDS_TSELALL	IDM_SELALL+120

#define IDS_TFIND	IDM_FIND+120
#define IDS_TNEXT	IDM_NEXT+120
#define IDS_TREPLACE	IDM_REPLACE+120

#define IDS_THELP	IDM_HELP+120
#define IDS_TABOUT	IDM_ABOUT+120
