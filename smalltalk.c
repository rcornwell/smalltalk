/*
 * Smalltalk interpreter: Main routine.
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
 * $Log: smalltalk.c,v $
 * Revision 1.8  2020/07/12 16:00:00  rich
 * Support for 64 bit compiler.
 * Coverity cleanup.
 *
 * Revision 1.7  2001/08/29 20:16:35  rich
 * Added support for X.
 * Added endSystem() function to cleanup before exiting.
 *
 * Revision 1.6  2001/08/18 16:17:02  rich
 * Moved windows code to win32.c.
 * Made main generic between windows and unix.
 *
 * Revision 1.5  2001/07/31 14:09:49  rich
 * Fixed to compile under cygwin.
 *
 * Revision 1.4  2000/08/27 00:59:21  rich
 * Changed default grow size to 512k.
 *
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


#include <stdint.h>
#include "smalltalk.h"
#include "about.h"
#include "object.h"
#include "interp.h"
#include "fileio.h"
#include "system.h"
#include "dump.h"

char               *imagename = NULL;
char               *loadfile = NULL;
int                 defotsize = 512;
char		   *progname = NULL;
char		   *geometry = NULL;

static int          getnum(char *, int *);

int
main(int argc, char *argv[])
{
    char               *str;

   /* Process arguments */
    progname = *argv;

   /* Remove quotes around name which windows seem to like to 
    * do under Visual C.
    */
    if (*progname == '"') {
	progname++;
	for(str = progname; str[1] != '\0'; str++);
	if (*str == '"')
	    *str = '\0';
    }

    while (--argc > 0) {
	str = *++argv;
	if (*str == '=') {
	    geometry = str;
	} else if (*str == '-') {
	    while (*++str != '\0') {
		switch (*str) {
		case 'i':	/* Image file name */
		    if (imagename != NULL)
			goto error;
		    imagename = *++argv;
		    argc--;
		    break;
		case 'o':	/* Object table size */
		    if (!getnum(*++argv, &defotsize))
			goto error;
		    argc--;
		    break;
		case 'g':	/* Grow size */
		    if (!getnum(*++argv, &growsize)) 
		        goto error;
		    argc--;
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

   /* Do OS specific initialization */
    if (!initSystem()) {
	errorStr("Unable to initialize system", NULL);
	return -1;
    }

   /* Load default files */
    if (imagename == NULL && loadfile == NULL) {
	char		*temp;
	char		*ptr;
	char		*last;
	int		id;

	/* Allocate some work space */
	if ((temp = (char *)malloc(strlen(progname) + 5)) == NULL) {
	   errorStr("Out of memory", NULL);
    	   endSystem();
	   return -1;
	}
	strcpy(temp, progname);
	ptr = &temp[strlen(temp)];
	last = ptr;

	/* Find last chunk of filename */
	while(ptr != temp) {
	    if (*ptr == '.') {
		*ptr = '\0';
	    }
	    if (*ptr == '\\' || *ptr == '/') {
		last = ++ptr;
		/* advance to end of string */
		while (*ptr != '\0')
		    ptr++;
		break;
	    }
	    ptr--;
	}
	strcpy(ptr, ".sti");
	if ((id = file_open(temp, "r", &id)) >= 0) {
		imagename = temp;
	} else {
		strcpy(last, "boot.st");
		if ((id = file_open(temp, "r", &id)) >= 0) {
			loadfile = temp;
		} else {
	    		errorStr("No image found", NULL);
    			endSystem();
	    		return -1;
		}
	}
	file_close(id);
    }

   /* If there is a image file, load it */
    if (imagename != NULL) {
	load_file(imagename);
    } else {
       /* Build new system */
        smallinit(defotsize);
       /* Compile into system */
	if (loadfile != NULL)
	    load_source(loadfile);
	else {
	    errorStr("No image found", NULL);
	    endSystem();
	    return -1;
	}
    }
    endSystem();
    close_files();
    return 0;

  error:
    errorStr("Invalid argument: %s", str);
    return -1;
}

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
