/*
 * Smalltalk interpreter: File IO routines.
 *
 * $Log: fileio.c,v $
 * Revision 1.4  2001/01/13 15:53:03  rich
 * Added routine to check if files are still accessible, and close them
 *   if they are no longer usable.
 * Increased buffer size to 8k.
 *
 * Revision 1.3  2000/02/02 16:05:02  rich
 * Don't need to include primitive.h
 *
 * Revision 1.2  2000/02/01 18:09:50  rich
 * error now exits on windows.
 * Added fill_buffer and flush_buffer for stdin and stdout support.
 * Fixed bugs in buffering.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#ifndef lint
static char        *rcsid =
	"$Id: fileio.c,v 1.4 2001/01/13 15:53:03 rich Exp rich $";

#endif

#include "smalltalk.h"

/* System stuff */
#ifndef WIN32
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#ifdef sun
#include <sys/filio.h>
#endif
#endif

#include "object.h"
#include "smallobjs.h"
#include "fileio.h"

struct file_buffer *files = NULL;

Objptr
new_file(char *name, char *mode)
{
    Objptr              fp;

    /* Locate file name vector */
    fp = FindSelectorInDictionary(SmalltalkPointer,
				internString("initSourceFile"));
    if (fp == NilPtr)
	return NilPtr;

    fp = get_pointer(fp, ASSOC_VALUE);
    if (fp == NilPtr)
      return NilPtr;

    Set_object(fp, FILENAME, MakeString(name));
    Set_object(fp, FILEMODE, MakeString(mode));;
    Set_integer(fp, FILEPOS, 0);

   /* Try opening it */
    if (open_buffer(fp)) {
	object_incr_ref(fp);
	return fp;
    } else
	return NilPtr;
}

/*
 * Read in the next code chunk.
 */
char               *
get_chunk(Objptr op)
{
    char               *buffer;
    char               *ptr;
    int 	        c;
    int                 left, size;
    int                 skip = FALSE;

    if ((buffer = (char *) malloc(BUFSIZE + 1)) == NULL)
	return NULL;

    size = left = BUFSIZE;
    ptr = buffer;

    while (1) {
	if (!read_buffer(op, &c)) 
	    break;

       /* Handle end of string character */
	if (skip) {
	    skip = FALSE;
	    if (c != '!')
		break;
	    *ptr++ = c;
	    left--;
	} else {
	    if (c == '!')
		skip = TRUE;
	    else {
		*ptr++ = c;
		left--;
	    }
	}

       /* Check if buffer full */
	if (left == 0) {
	    if ((buffer = (char *) realloc(buffer, size + BUFSIZE + 1)) == NULL)
		return NULL;
	    left = BUFSIZE;
	    ptr = &buffer[size];
	    size += BUFSIZE;
	}
    }
 
    while(ptr != buffer && (ptr[-1] == '\n' || ptr[-1] == '\r' || 
		ptr[-1] == ' ' || ptr[-1] == '\t')) 
	ptr--;

    *ptr++ = '\0';

    while (peek_for(op, '\r') || peek_for(op, '\n'));
    return buffer;
}

/*
 * Peek for next character on a stream.
 */
int 
peek_for(Objptr op, char c)
{
    int                 pos;
    Objptr              temp;
    struct file_buffer *fp;

   /* Find file buffer */
    for (fp = files; fp != NULL; fp = fp->file_next)
	if (fp->file_oop == op)
	    break;

   /* Exit, if none or not reading */
    if (fp == NULL || (fp->file_flags & FILE_READ) == 0)
	return FALSE;

   /* Get position of smalltalk file */
    temp = get_pointer(op, FILEPOS);
    if (!is_integer(temp))
	return FALSE;
    pos = as_integer(temp);

   /* Check if we have to move buffer */
    if (pos < fp->file_pos || pos >= (fp->file_pos + fp->file_len)) {
        if ((fp->file_flags & (FILE_WRITE | FILE_DIRTY)) ==
	    (FILE_WRITE | FILE_DIRTY) && fp->file_len > 0) {
	    file_seek(fp->file_id, fp->file_pos);
	    file_write(fp->file_id, fp->file_buffer, fp->file_len);
	    fp->file_flags &= ~FILE_DIRTY;
        }
        file_seek(fp->file_id, fp->file_pos = pos);
        fp->file_len = file_read(fp->file_id, fp->file_buffer, BUFSIZE);
        if (fp->file_len < 0) {
    	    return FALSE;
        }
    }

    /* Get next char */
    if (c == fp->file_buffer[pos - fp->file_pos]) {
	/* Advance if character matches */
	pos++;
        Set_integer(op, FILEPOS, pos);
	return TRUE;
    }
 
    return FALSE;
}

/*
 * Open file buffer.
 */
int
open_buffer(Objptr op)
{
    struct file_buffer *fp;
    char               *name;
    char               *mode;

   /* Look it up */
    for (fp = files; fp != NULL; fp = fp->file_next)
	if (fp->file_oop == op)
	    return TRUE;

   /* Did not find it... create one */
    if ((fp = (struct file_buffer *) malloc(sizeof(struct file_buffer)))
	== NULL)
	                    return FALSE;

    fp->file_oop = op;
    if ((fp->file_buffer = (char *) malloc(BUFSIZE)) == NULL) {
	free(fp);
	return FALSE;
    }
    fp->file_len = 0;
    fp->file_pos = 0;
    name = Cstring(get_pointer(op, FILENAME));
    mode = Cstring(get_pointer(op, FILEMODE));
    if ((fp->file_id = file_open(name, mode, &fp->file_flags)) == -1) {
	free(name);
	free(mode);
	free(fp->file_buffer);
	free(fp);
	return FALSE;
    }
    free(name);
    free(mode);
    if (fp->file_flags & FILE_APPEND) {
	fp->file_pos = file_size(fp->file_id);
	Set_integer(op, FILEPOS, fp->file_pos);
    }
    fp->file_next = files;
    files = fp;
    return TRUE;

}

/*
 * Close off a file object.
 */
void
close_buffer(Objptr op)
{
    struct file_buffer *fp, *lfp;

    lfp = NULL;
    for (fp = files; fp != NULL; fp = fp->file_next) {
	if (fp->file_oop == op)
	    break;
	lfp = fp;
    }
    if (fp == NULL)
	return;
    if (((fp->file_flags & (FILE_WRITE | FILE_DIRTY)) ==
	 (FILE_WRITE | FILE_DIRTY)) && fp->file_len > 0) {
	file_seek(fp->file_id, fp->file_pos);
	file_write(fp->file_id, fp->file_buffer, fp->file_len);
    }
    file_close(fp->file_id);
    if (fp->file_buffer != NULL)
	free(fp->file_buffer);
    if (lfp == NULL)
	files = fp->file_next;
    else
	lfp->file_next = fp->file_next;
    free(fp);
}

/*
 * Close off all file objects.
 */
void
close_files()
{
    struct file_buffer *fp, *lfp;

    lfp = NULL;
    for (fp = files; fp != NULL; fp = lfp) {
 	if (((fp->file_flags & (FILE_WRITE | FILE_DIRTY)) ==
	        (FILE_WRITE | FILE_DIRTY)) && fp->file_len > 0) {
	     file_seek(fp->file_id, fp->file_pos);
	     file_write(fp->file_id, fp->file_buffer, fp->file_len);
        }
        file_close(fp->file_id);
        if (fp->file_buffer != NULL)
	    free(fp->file_buffer);
	lfp = fp->file_next;
        free(fp);
    }
    files = NULL;
}

/*
 * Check that all file objects are still accessable in the system.
 */
void
check_files()
{
    struct file_buffer *fp;

    for (fp = files; fp != NULL;) {
	if (!notFree(fp->file_oop) || get_object_refcnt(fp->file_oop) == 0) {
	    close_buffer(fp->file_oop);
	    fp = files;
	} else {
	    fp = fp->file_next;
	}
    }
}


/*
 * Read the next character off a file stream.
 */
int
read_buffer(Objptr op, int *c)
{
    struct file_buffer *fp;
    Objptr              temp;
    int                 pos;
    int			offset;

   /* Look it up */
    for (fp = files; fp != NULL; fp = fp->file_next)
	if (fp->file_oop == op)
	    break;

    if (fp == NULL)
	return FALSE;

    if ((fp->file_flags & FILE_READ) == 0)
	return FALSE;

   /* Get position of smalltalk file */
    temp = get_pointer(op, FILEPOS);
    if (!is_integer(temp))
	return FALSE;
    pos = as_integer(temp);

   /* Check if we have to move buffer */
    offset = pos - fp->file_pos;
    if (offset < 0 || offset >= fp->file_len) {
	if ((fp->file_flags & (FILE_WRITE | FILE_DIRTY)) ==
	    (FILE_WRITE | FILE_DIRTY) && fp->file_len > 0) {
	    file_seek(fp->file_id, fp->file_pos);
	    file_write(fp->file_id, fp->file_buffer, fp->file_len + 1);
	    fp->file_flags &= ~FILE_DIRTY;
	}
	fp->file_pos = pos;
	offset = 0;
	file_seek(fp->file_id, fp->file_pos);
	fp->file_len = file_read(fp->file_id, fp->file_buffer, BUFSIZE);
	if (fp->file_len < 0)
	    return FALSE;
    }
    if (fp->file_len <= 0)
	return FALSE;
   /* Get next char */
    *c = (int) fp->file_buffer[offset];
    pos++;
    Set_integer(op, FILEPOS, pos);
    return TRUE;
}

/*
 * Return the size of a file.
 */
int
size_buffer(Objptr op)
{
    struct file_buffer *fp;
    int len;

   /* Look it up */
    for (fp = files; fp != NULL; fp = fp->file_next)
	if (fp->file_oop == op)
	    break;

    if (fp == NULL)
	return 0;

    len = file_size(fp->file_id);
    if ((fp->file_flags & (FILE_WRITE | FILE_DIRTY)) ==
		 (FILE_WRITE | FILE_DIRTY) && 
		(fp->file_len + fp->file_pos) > len)
	len = fp->file_len + fp->file_pos;
    return len;
}

/*
 * Append character onto end of stream.
 */
int
write_buffer(Objptr op, int c)
{
    struct file_buffer *fp;
    Objptr              temp;
    int                 pos;
    int			offset;

   /* Look it up */
    for (fp = files; fp != NULL; fp = fp->file_next)
	if (fp->file_oop == op)
	    break;

    if (fp == NULL)
	return FALSE;

    if ((fp->file_flags & FILE_WRITE) == 0)
	return FALSE;

   /* Get position of smalltalk file */
    temp = get_pointer(op, FILEPOS);
    if (!is_integer(temp))
	return FALSE;
    pos = as_integer(temp);
   /* Check if we have to move buffer */
    offset = pos - fp->file_pos;
    if (offset < 0 || offset >= BUFSIZE || fp->file_len >= BUFSIZE) {
	if ((fp->file_flags & (FILE_WRITE | FILE_DIRTY)) ==
	    (FILE_WRITE | FILE_DIRTY) && fp->file_len > 0) {
	    file_seek(fp->file_id, fp->file_pos);
	    file_write(fp->file_id, fp->file_buffer, fp->file_len);
	    fp->file_flags &= ~FILE_DIRTY;
	}
	fp->file_pos = pos;
	offset = 0;
	file_seek(fp->file_id, fp->file_pos);
	fp->file_len = file_read(fp->file_id, fp->file_buffer, BUFSIZE);
	if (fp->file_len < 0) 
	    return FALSE;
    }
    fp->file_buffer[offset++] = c;
    if (fp->file_len < offset)
	fp->file_len = offset;
    fp->file_flags |= FILE_DIRTY;
    pos++;
    Set_integer(op, FILEPOS, pos);
    return TRUE;
}

#ifndef WIN32
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
    struct stat        stat;

    if (fstat(id, &stat) < 0)
	return -1;
    return stat.st_size;
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

char *
fill_buffer(int stream, int mode)
{
    int len;
    char *buf;
    if (stream != 0)
	return NULL;
    if (mode) 
	len = ioctl(0, FIONREAD, 0);
    else
	len = 8193;
    if ((buf = malloc(len)) == NULL)
	return NULL;
    if (len == 0)
	return buf;
    len = read(0, buf, len - 1);
    if (len < 0) {
	free(buf);
	return NULL;
    }
    buf[len + 1] = '\0';
    return buf;
}

int
flush_buffer(int stream, char *string)
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

#endif

#ifdef WIN32
long 
file_open(char *name, char *mode, int *flags)
{
    HANDLE              id;

    switch (*mode) {
    case 'r':
	*flags = FILE_READ;
	id = CreateFile(name, GENERIC_READ, FILE_SHARE_READ, NULL,
			OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	break;
    case 'w':
	*flags = FILE_WRITE;
	id = CreateFile(name, GENERIC_WRITE, FILE_SHARE_WRITE, NULL,
			CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
	break;
    case 'm':
    case 'a':
	*flags = FILE_READ | FILE_WRITE;
	id = CreateFile(name, GENERIC_WRITE, FILE_SHARE_WRITE, NULL,
			OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
	break;
    default:
	return -1;
    }
    if (id == INVALID_HANDLE_VALUE)
	return -1;
    if (*mode == 'a') {
	*flags |= FILE_APPEND;
	SetEndOfFile(id);
    }
    return (int) id;
}

long 
file_seek(long id, long pos)
{
    return SetFilePointer((HANDLE) id, pos, NULL, FILE_BEGIN);
}

int 
file_write(long id, char *buffer, long size)
{
    DWORD               did;

    WriteFile((HANDLE) id, buffer, size, &did, 0);
    if (did != size)
	return -1;
    else
	return did;
}

int 
file_read(long id, char *buffer, long size)
{
    DWORD               did;

    ReadFile((HANDLE) id, buffer, size, &did, 0);
    if (did == 0)
	return -1;
    else
	return did;
}

int 
file_close(long id)
{
    return CloseHandle((HANDLE) id);
}

long 
file_size(long id)
{
    DWORD               hsize, lsize;

    lsize = GetFileSize((HANDLE) id, &hsize);
    return lsize;
}

void 
error(char *str)
{
    dump_string(str);
    ExitProcess(-1);
}

void
errorStr(char *str, char *argument)
{
    char	buffer[1024];
    wsprintf(buffer, str, argument);
    error(buffer);
}


void
dump_string(char *str)
{
    DWORD		did;

    WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), str, strlen(str), &did, 0);
    WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), "\r\n", 2, &did, 0);
}

static int	needconsole = 1;

char *
fill_buffer(int stream, int mode)
{
    HANDLE	in;
    int         len;
    char        *buf, *ptr;
    char        c;
    DWORD	did;

    if (stream != 0)
	return NULL;

    if (needconsole) {
	if (AllocConsole() == 0)
	   return NULL;
	needconsole = 0;
    }

    in = GetStdHandle(STD_INPUT_HANDLE);
    len = 1024;
    if ((buf = malloc(len)) == NULL)
	return NULL;
    ptr = buf;
    while (len > 0) { 
    	ReadFile(in, &c, 1, &did, 0);
	if (c == '\r') 
	    c = '\n';
	*ptr++ = c;
	len--;
	if (c == '\n')
	   break;
    }
    *ptr = '\0';
    return buf;
}

int
flush_buffer(int stream, char *string)
{
    HANDLE	out;
    DWORD	did;
    char	buf[1024];
    char	*ptr;
    int		len;

    if (needconsole) {
	if (AllocConsole() == 0)
	   return FALSE;
	needconsole = 0;
    }

    switch (stream) {
    case 1:
            out = GetStdHandle(STD_OUTPUT_HANDLE);
	    break;
    case 2:
            out = GetStdHandle(STD_ERROR_HANDLE);
	    break;
    default:
	    return FALSE;
    }

    ptr = buf;
    len = 0;
    while(*string != '\0') {
	char c = *string++;
	*ptr++ = c;
	len++;
	if (c == '\n') {
	   *ptr++ = '\r';
	   len++;
	}
	if (len >= (sizeof(buf) - 2)) {
            WriteFile(out, buf, len, &did, 0);
	    ptr = buf;
	    len = 0;
	}
    }
    if (len >= 0) 
        WriteFile(out, buf, len, &did, 0);
    return TRUE;
}

#endif
