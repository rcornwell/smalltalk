/*
 * Smalltalk interpreter: Main routine.
 *
 * $Log: smalltalk.c,v $
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

#ifndef lint
static char        *rcsid =
	"$Id: smalltalk.c,v 1.5 2001/07/31 14:09:49 rich Exp rich $";
#endif

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

static int          getnum(char *, int *);

int
main(int argc, char *argv[])
{
    char               *str;

   /* Process arguments */
    progname = *argv;
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
		last = ptr;
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
	    parsefile(loadfile);
	else {
	    errorStr("No image found", NULL);
	    return -1;
	}
    }
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
