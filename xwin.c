/*
 * Smalltalk interpreter: X Windows interface.
 *
 * $Log: $
 *
 */

#ifndef lint
static char        *rcsid = "$Id: $";
#endif

#ifndef WIN32

/* System stuff */
#include <dirent.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#ifdef sun
#include <sys/filio.h>
#endif
#include <sys/timeb.h>
#include <time.h>
#include <unistd.h>

/* Local stuff */
#include "smalltalk.h"
#include "object.h"
#include "interp.h"
#include "smallobjs.h"
#include "system.h"
#include "fileio.h"
#include "graphic.h"

static int	    fill_buffer();
unsigned long      *display_bits;

/* Initialize the system. */
int
initSystem()
{
    return 1;
}

/* Become the cursor */
Objptr
BeCursor(Objptr op)
{
    cursor_object = op;
    rootObjects[CURSOBJ] = op;
    return op;
}

/* Become display object */
Objptr
BeDisplay(Objptr op)
{
    if (display_object == op)
	return op;
    display_object = op;
    rootObjects[DISPOBJ] = op;	/* Very bad if it gets freed */
    return op;
}

/* Update the section of the display that has changed */
void
UpdateDisplay(Copy_bits bits)
{
}

/*
 * Wait for an external event. if suspend flag is true, we halt until
 * something interesting happens.
 */
int
WaitEvent(int suspend)
{
    fd_set		chk_bits;
    struct timeval	timeout;

    FD_ZERO(&chk_bits);
    FD_SET(0, &chk_bits);
    timeout.tv_sec = 1;
    timeout.tv_usec = 0;
    if (select(1, &chk_bits, NULL, NULL, &timeout)) {
	if (FD_ISSET(0, &chk_bits))
	    fill_buffer();
    }
    return 1;
}

/* Wrapper to local file operations */
long 
file_open(char *name, char *mode, int *flags)
{
    int                 fmode = 0;
    int                 id;

    switch (*mode) {
    case 'r':
	fmode = O_RDONLY;
	*flags = FILE_READ;
	break;
    case 'w':
	fmode = O_WRONLY|O_CREAT;
	*flags = FILE_WRITE;
	break;
    case 'a':
	fmode = O_RDWR|O_CREAT|O_APPEND;
	*flags = FILE_READ | FILE_WRITE;
	break;
    case 'm':
	fmode = O_RDWR|O_CREAT;
	*flags = FILE_READ | FILE_WRITE;
	break;
    default:
	return -1;
    }
    if ((id = open(name, fmode, 0660)) < 0)
	return -1;
    if (*mode == 'a') {
	lseek(id, 0, SEEK_END);
	*flags |= FILE_APPEND;
    }
    return id;

}

long 
file_seek(long id, long pos)
{
    return lseek(id, pos, SEEK_SET);
}

int 
file_write(long id, char *buffer, long size)
{
    return write(id, buffer, size);
}

int 
file_read(long id, char *buffer, long size)
{
    return read(id, buffer, size);
}

int 
file_close(long id)
{
    return close(id);
}

long 
file_size(long id)
{
    struct stat        statbuf;

    if (fstat(id, &statbuf) < 0)
	return -1;
    return statbuf.st_size;
}

int
file_checkdirect(char *name)
{
    struct stat		statbuf;

    if (stat(name, &statbuf) < 0)
	return -1;

    return S_ISDIR(statbuf.st_mode);
}

Objptr
file_direct(Objptr op)
{
    Objptr		*array;
    Objptr		res;
    int			size;
    int			index;
    struct dirent	*dirbuf;
    DIR			*dirp;
    char		*name;
    int			savereclaim = noreclaim;

    name = Cstring(get_pointer(op, FILENAME));
    if ((dirp = opendir(name)) == NULL) {
	free(name);
	return NilPtr;
    }

    /* Can free name since we don't need it anymore */
    free(name);

    /* Allocate initial buffer */
    size = 1024;
    index = 0;
    if ((array = (Objptr *)malloc(size * sizeof(Objptr))) == NULL) {
	closedir(dirp);
	return NilPtr;
    }

    noreclaim = TRUE;
    /* Read in the files */
    while ((dirbuf = readdir(dirp)) != NULL) {
	array[index++] = MakeString(dirbuf->d_name);
	if (index == size) {
	    size += 1024;
    	    if ((array = (Objptr *)realloc(array, size * sizeof(Objptr)))
			 == NULL) {
		noreclaim = savereclaim;
		closedir(dirp);
		return NilPtr;
	    }
	}
    }

    closedir(dirp);

    /* Now allocate an array that will hold them all */
    if ((res = create_new_object(ArrayClass, index)) == NilPtr) {
	noreclaim = savereclaim;
	free(array);
	return NilPtr;
    }
    size = index;
    for(index = 0; index < size; index++) 
	Set_object(res, index, array[index]);
    free(array);
    noreclaim = savereclaim;
    return res;
}

int
file_delete(Objptr op)
{
    char		*name;
    int			res = TRUE;
    struct stat		statbuf;


    name = Cstring(get_pointer(op, FILENAME));
    if (stat(name, &statbuf) < 0) {
	free(name);
	return FALSE;
    }

    if (S_ISDIR(statbuf.st_mode)) {
	if (rmdir(name) < 0)
	    res = FALSE;
    } else {
        if (unlink(name) < 0)
	    res = FALSE;
    }
    free(name);
    return res;
}

int
file_rename(Objptr op, Objptr newop)
{
    char		*name;
    char		*newname;
    int			res = TRUE;

    name = Cstring(get_pointer(op, FILENAME));
    newname = Cstring(newop);
    if (name != NULL && newname != NULL) {
	if (rename(name, newname) < 0)
	    res = FALSE;
    }
    free(newname);
    free(name);
    return res;
}

void
error(char *str)
{
    dump_string(str);
    exit(-1);
}

void
errorStr(char *str, char *argument)
{
    fprintf(stderr, str, argument);
    exit (-1);
}

void
dump_string(char *str)
{
       fputs(str, stderr);
       fputc('\n', stderr);
}

/*
 * Read as many characters as we can from stdin, return 1 if somebody could
 * have been awakened by our actions.
 */
static int
fill_buffer()
{
    int		len;
    char	*ptr;
    int		eolseen = 0;

   /* If we are buffered, only read as much as is ready */
    len = ioctl(0, FIONREAD, 0);

   /* If nothing to read, return empty buffer */
    if (len == 0 || console.file_buffer == NULL) 
	return 0;

   /* Don't overfill buffer */
    if ((console.file_len + len) >= BUFSIZE)
	len = BUFSIZE - console.file_len;

   /* Fill the buffer */
    ptr = &console.file_buffer[console.file_len];
    len = read(0, ptr, len);

   /* If there was an error, return failure. */
    if (len < 0) 
	return 0;

    console.file_len += len;

   /* Check if we read a new line */
    for(; len > 0; len--) {
	if (*ptr++ == '\n')
	    eolseen = 1;
    }

   /* Decide if we should signal anybody waiting on console input. */
    if (console.file_len == BUFSIZE || eolseen ||
		console.file_flags & FILE_CHAR) {
	signal_console(console.file_oop);
	return 1;
    }

    return 0;
}

int
write_console(int stream, char *string)
{
    switch (stream) {
    case 1:
	    fputs(string, stdout);
	    break;
    case 2:
	    fputs(string, stderr);
	    break;
    default:
	    return FALSE;
    }
    return TRUE;
}

unsigned long
current_time()
{
	struct timeb	tp;

	ftime(&tp);
	if (tp.dstflag)
	    tp.timezone -= 60;
	tp.time -= 60 * tp.timezone;
	return tp.time;
}

int
current_mtime()
{
	struct timeb	tp;
	ftime(&tp);
	return tp.millitm;
}

#endif
