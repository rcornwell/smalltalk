
/*
 * Smalltalk interpreter: Global Definitions.
 *
 * $Id: smalltalk.h,v 1.2 2000/02/01 18:10:04 rich Exp rich $
 *
 * $Log: smalltalk.h,v $
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
void                parsefile(char *);

#endif
