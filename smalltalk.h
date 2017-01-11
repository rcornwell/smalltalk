/*
 * Smalltalk interpreter: Global Definitions.
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
 * $Id: smalltalk.h,v 1.5 2002/02/07 04:21:04 rich Exp rich $
 *
 * $Log: smalltalk.h,v $
 * Revision 1.5  2002/02/07 04:21:04  rich
 * Added change file icon to RC file.
 *
 * Revision 1.4  2001/08/29 20:16:35  rich
 * Added support for X.
 *
 * Revision 1.3  2001/07/31 14:09:49  rich
 * Fixed to compile under new cygwin.
 *
 * Revision 1.2  2000/02/01 18:10:04  rich
 * Fixed image load code.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#define VERSION "1.0.0"

#ifdef WIN32
#define IDM_NEW		10
#define IDM_OPEN	11
#define IDM_SAVE	12
#define IDM_SAVEAS	13
#define IDM_EXIT	15

#define IDM_HELP	20
#define IDM_ABOUT	21

/* String definitions */
#define IDS_INVARG	1

#define SMALLTALK	1
#define SMALLIMAGE	2
#define SMALLFILE	3
#define SMALLCHANGE	4

/* System stuff */
#include <stddef.h>
#include <windows.h>
#include <malloc.h>
#define sprintf		wsprintf
#else
/* System stuff */
#include <stdio.h>
#include <unistd.h>
#include <malloc.h>
#include <memory.h>
#endif

#ifndef RC_INVOKED

void                smallinit(int);
void		    load_file(char *);
void                load_source(char *);
extern char	   *geometry;

#endif
