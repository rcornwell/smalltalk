/*
 * Smalltalk interpreter: File IO routines.
 *
 * $Log: $
 *
 */

#ifndef lint
static char        *rcsid =
	"$Id: $";

#endif

#ifdef unix
/* System stuff */
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <malloc.h>
#include <memory.h>
#endif

#ifdef _WIN32
#include <stddef.h>
#include <windows.h>
#endif

#include "object.h"
#include "smallobjs.h"
#include "fileio.h"
#include "primitive.h"

struct file_buffer *files = NULL;

Objptr
new_file(char *name, char *mode)
{
    Objptr              fp;
    Objptr		files;

    /* Locate file name vector */
    files = FindSelectorInDictionary(SmalltalkPointer,
				internString("sourceFiles"));
    if (files == NilPtr)
	return NilPtr;

    /* Get array of files */
    files = get_pointer(files, ASSOC_VALUE);
    if (files == NilPtr)
	return NilPtr;

    fp = create_new_object(ArrayClass, 3);
    Set_object(files, 0, fp);		/* File zero is main source file */
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
    char                c;
    int                 len, pos, left, size;
    int                 skip = FALSE;
    Objptr              temp;
    struct file_buffer *fp;

   /* Find file buffer */
    for (fp = files; fp != NULL; fp = fp->file_next)
	if (fp->file_oop == op)
	    break;

   /* Exit, if none or not reading */
    if (fp == NULL || (fp->file_flags & FILE_READ) == 0)
	return NULL;

   /* Get position of smalltalk file */
    temp = get_pointer(op, FILEPOS);
    if (!is_integer(temp))
	return NULL;
    pos = as_integer(temp);

    len = fp->file_end - fp->file_buffer - 1;
    if ((buffer = (char *) malloc(BUFSIZE + 1)) == NULL)
	return NULL;

    size = left = BUFSIZE;
    ptr = buffer;

    while (1) {
       /* Check if we have to move buffer */
	if (pos < fp->file_pos || pos > (fp->file_pos + len)) {
	    if ((fp->file_flags & (FILE_WRITE | FILE_DIRTY)) ==
		(FILE_WRITE | FILE_DIRTY) && len > 0) {
		file_seek(fp->file_id, fp->file_pos);
		file_write(fp->file_id, fp->file_buffer, len);
		fp->file_flags &= ~FILE_DIRTY;
	    }
	    file_seek(fp->file_id, fp->file_pos = pos);
	    fp->file_offset = fp->file_buffer;
	    len = file_read(fp->file_id, fp->file_buffer, BUFSIZE);
	    if (len < 0) {
		fp->file_end = fp->file_buffer;
		if (ptr == buffer) {
			free(buffer);
			return NULL;
		}
		break;
	    }
	    fp->file_end = fp->file_buffer + len;
	}
	if (len <= 0) {
	    free(buffer);
	    return NULL;
	}
       /* Get next char */
	c = (int) *fp->file_offset++;
	pos++;

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
 
    while(ptr[-1] == '\n' || ptr[-1] == '\r' || ptr[-1] == ' ' || 
		ptr[-1] == '\t') {
	if (ptr == buffer)
		break;
	else
	    ptr--;
    }

    *ptr++ = '\0';
   /* Restore position */
    Set_integer(op, FILEPOS, pos);

    while (peek_for(op, '\r') || peek_for(op, '\n'));
    return buffer;
}

/*
 * Peek for next character on a stream.
 */
int 
peek_for(Objptr op, char c)
{
    int                 len, pos;
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
    len = fp->file_end - fp->file_buffer;

   /* Check if we have to move buffer */
    if (pos < fp->file_pos || pos > (fp->file_pos + len)) {
        if ((fp->file_flags & (FILE_WRITE | FILE_DIRTY)) ==
	    (FILE_WRITE | FILE_DIRTY) && len > 0) {
	    file_seek(fp->file_id, fp->file_pos);
	    file_write(fp->file_id, fp->file_buffer, len);
	    fp->file_flags &= ~FILE_DIRTY;
        }
        file_seek(fp->file_id, fp->file_pos = pos);
        fp->file_offset = fp->file_buffer;
        len = file_read(fp->file_id, fp->file_buffer, BUFSIZE);
        if (len < 0) {
	    fp->file_end = fp->file_buffer;
    	    return FALSE;
        }
        fp->file_end = fp->file_buffer + len;
    }

    /* Get next char */
    if (c == *fp->file_offset) {
	/* Advance if character matches */
        Set_integer(op, FILEPOS, ++pos);
	fp->file_offset++;
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
    fp->file_offset = fp->file_end = fp->file_buffer;
    fp->file_pos = -1;
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
    if (fp->file_flags & FILE_APPEND)
	fp->file_pos = file_size(fp->file_id);
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
    int                 len;

    lfp = NULL;
    for (fp = files; fp != NULL; fp = fp->file_next) {
	if (fp->file_oop == op)
	    break;
	lfp = fp;
    }
    if (fp == NULL)
	return;
    len = fp->file_end - fp->file_buffer;
    if (((fp->file_flags & (FILE_WRITE | FILE_DIRTY)) ==
	 (FILE_WRITE | FILE_DIRTY)) && len > 0) {
	file_seek(fp->file_id, fp->file_pos);
	file_write(fp->file_id, fp->file_buffer, len);
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
 * Read the next character off a file stream.
 */
int
read_buffer(Objptr op, int *c)
{
    struct file_buffer *fp;
    Objptr              temp;
    int                 pos;
    int                 len;

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

    len = fp->file_end - fp->file_buffer;

   /* Check if we have to move buffer */
    if (pos < fp->file_pos || pos > (fp->file_pos + len)) {
	if ((fp->file_flags & (FILE_WRITE | FILE_DIRTY)) ==
	    (FILE_WRITE | FILE_DIRTY) && len > 0) {
	    file_seek(fp->file_id, fp->file_pos);
	    file_write(fp->file_id, fp->file_buffer, len);
	    fp->file_flags &= ~FILE_DIRTY;
	}
	file_seek(fp->file_id, fp->file_pos = pos);
	fp->file_offset = fp->file_buffer;
	len = file_read(fp->file_id, fp->file_buffer, BUFSIZE);
	if (len < 0) {
	    fp->file_end = fp->file_buffer;
	    return FALSE;
	}
	fp->file_end = fp->file_buffer + len;
    }
    if (len <= 0)
	return FALSE;
   /* Get next char */
    *c = (int) *fp->file_offset++;
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
    int                 len;

   /* Look it up */
    for (fp = files; fp != NULL; fp = fp->file_next)
	if (fp->file_oop == op)
	    break;

    if (fp == NULL)
	return 0;

    len = file_size(fp->file_id);
    if ((fp->file_flags & (FILE_WRITE | FILE_DIRTY)) ==
	(FILE_WRITE | FILE_DIRTY) && len == fp->file_pos)
	len += fp->file_end - fp->file_buffer;
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
    int                 len;

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
    len = fp->file_end - fp->file_buffer;
   /* Check if we have to move buffer */
    if (pos < fp->file_pos || fp->file_pos > (pos + BUFSIZE) ||
	len >= (BUFSIZE - 1)) {
	if ((fp->file_flags & (FILE_WRITE | FILE_DIRTY)) ==
	    (FILE_WRITE | FILE_DIRTY) && len > 0) {
	    file_seek(fp->file_id, fp->file_pos);
	    file_write(fp->file_id, fp->file_buffer, len);
	    fp->file_flags &= ~FILE_DIRTY;
	}
	file_seek(fp->file_id, fp->file_pos = pos);
	fp->file_offset = fp->file_buffer;
	len = file_read(fp->file_id, fp->file_buffer, BUFSIZE);
	if (len < 0) {
	    fp->file_end = fp->file_offset;
	    return FALSE;
	}
	fp->file_end = fp->file_offset + len;
    }
    if (fp->file_offset == fp->file_end)
	fp->file_end++;
    *fp->file_offset++ = c;
    fp->file_flags |= FILE_DIRTY;
    pos++;
    Set_integer(op, FILEPOS, pos);
    return TRUE;
}

#ifdef unix
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
    fprintf(stderr, str);
    fputc('\n', stderr);
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


#endif

#ifdef _WIN32
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
			OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
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
    DWORD               did;

    WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), str, strlen(str), &did, 0);
    WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), "\r\n", 2, &did, 0);
       
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

#endif
