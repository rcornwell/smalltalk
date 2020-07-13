/*
 * Smalltalk interpreter: File IO routines.
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
 * $Log: fileio.c,v $
 * Revision 1.7  2020/07/12 16:00:00  rich
 * Coverity cleanup.
 *
 * Revision 1.6  2001/08/18 16:17:01  rich
 * Moved system specific routines to their own file.
 * Added rest of directory management routines.
 * Made sure write-only files work correctly.
 * Redid console reading routines.
 *
 * Revision 1.5  2001/07/31 14:09:48  rich
 * Fixed to compile with new cygwin
 * Made sure open append mode under windows works correctly.
 * Fixed bugs in write_buffer so it works correctly.
 *
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


#include <stdint.h>
#include "smalltalk.h"
#include "object.h"
#include "smallobjs.h"
#include "fileio.h"
#include "system.h"
#include "interp.h"
#include "parse.h"

struct file_buffer *files = NULL;
struct file_buffer console;

void
load_source(char *str)
{
    Objptr              fp;

    /* Locate file name vector */
    fp = FindSelectorInDictionary(SmalltalkPointer,
				internString("initSourceFile"));
    if (fp == NilPtr) {
	error("Unable to open initial file");
        return;
    }

    fp = get_pointer(fp, ASSOC_VALUE);
    Set_object(fp, FILENAME, MakeString(str));
    Set_object(fp, FILEMODE, MakeString("r"));;
    Set_integer(fp, FILEPOS, 0);

   /* Try opening it */
    if (open_buffer(fp)) {
	object_incr_ref(fp);
    	parsesource(fp);
        close_buffer(fp);
    }
}

void
parsefile(Objptr src)
{
    Objptr              fp;

    /* Locate file name vector */
#if 0
    fp = FindSelectorInDictionary(SmalltalkPointer,
				internString("currentSourceFile"));
    if (fp == NilPtr) {
	error("Unable to open source file");
        return;
    }

    fp = get_pointer(fp, ASSOC_VALUE);
#endif
    fp = create_new_object(FileClass, 0);
#if 0
    AddSelectorToDictionary(SmalltalkPointer,
        create_association(internString("currentSourceFile"), fp));          
#endif
    Set_object(fp, FILENAME, src);
    Set_object(fp, FILEMODE, MakeString("r"));;
    Set_integer(fp, FILEPOS, 0);

   /* Try opening it */
    if (open_buffer(fp)) {
	object_incr_ref(fp);
	parsesource(fp);
	close_buffer(fp);
    } 
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
 * Check if a file is a directory.
 */
int
file_isdirect(Objptr op)
{
    struct file_buffer *fp;
    char               *name;
    int			res;

   /* Look it up */
    for (fp = files; fp != NULL; fp = fp->file_next)
	if (fp->file_oop == op) {
	    /* If it is open is can't be a directory */
	    return FALSE;
	}

   /* Ok did not find it, ask os what type of file it is. */
    name = Cstring(get_pointer(op, FILENAME));
    res = file_checkdirect(name);
    free(name);
    return res;
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
 * Read at least the next len character off a file stream.
 */
int
read_str_buffer(Objptr op, int len, Objptr *res)
{
    struct file_buffer *fp;
    Objptr              temp;
    int                 pos;
    int			offset;
    int			base;

   /* For the moment, set to empty */
    *res = NilPtr;

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

   /* Now adjust len based on how much more is available in file. */
    if (len > fp->file_len) {
	/* only care if we will exceed amount in buffer */
	int	flen = file_size(fp->file_id) - fp->file_pos;
	if ((fp->file_flags & (FILE_WRITE | FILE_DIRTY)) ==
		 (FILE_WRITE | FILE_DIRTY) && 
					fp->file_len > flen)
	   flen = fp->file_len;
	if (len > flen)
	   len = flen;
    }

    if (len <= 0)
	return FALSE;
	  
    /* Now create a object to recieve results of read */ 
    *res = create_new_object(StringClass, len);
    base = fixed_size(*res);
    while (len-- > 0) {
        /* Get next char */
	set_byte(*res, base++, fp->file_buffer[offset++]);
    	pos++;
	/* Check if we need to move buffer */
        if (offset >= fp->file_len) {
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
    }
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
        if (fp->file_flags & FILE_READ) {
	    file_seek(fp->file_id, fp->file_pos);
	    fp->file_len = file_read(fp->file_id, fp->file_buffer, BUFSIZE);
	    if (fp->file_len < 0) 
	        return FALSE;
	} else {
	    fp->file_len = 0;
	}
    }
    fp->file_buffer[offset++] = c;
    if (fp->file_len < offset)
	fp->file_len = offset;
    fp->file_flags |= FILE_DIRTY;
    pos++;
    Set_integer(op, FILEPOS, pos);
    return TRUE;
}

/*
 * Append string of characters onto end of stream.
 */
int
write_str_buffer(Objptr op, char *str, int len)
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
    offset = pos - fp->file_pos;

   /* Process string */
    while(len-- > 0) {
   	/* Check if we have to move buffer */
        if (offset < 0 || offset >= BUFSIZE || fp->file_len >= BUFSIZE) {
	    if ((fp->file_flags & (FILE_WRITE | FILE_DIRTY)) ==
	        (FILE_WRITE | FILE_DIRTY) && fp->file_len > 0) {
	        file_seek(fp->file_id, fp->file_pos);
	        file_write(fp->file_id, fp->file_buffer, fp->file_len);
	        fp->file_flags &= ~FILE_DIRTY;
	    }
	    fp->file_pos = pos;
	    offset = 0;
            if (fp->file_flags & FILE_READ) {
	        file_seek(fp->file_id, fp->file_pos);
	        fp->file_len = file_read(fp->file_id, fp->file_buffer, BUFSIZE);
	        if (fp->file_len < 0) {
    		    Set_integer(op, FILEPOS, pos);
	            return FALSE;
	        }
	    } else {
	        fp->file_len = 0;
	    }
        }
        fp->file_buffer[offset++] = *str++;
        if (fp->file_len < offset)
	    fp->file_len = offset;
        pos++;
        fp->file_flags |= FILE_DIRTY;
    }
    Set_integer(op, FILEPOS, pos);
    return TRUE;
}


/*
 * Initialize the console input buffer.
 */
void
init_console(Objptr op)
{
    console.file_oop = op;
    console.file_buffer = (char *) malloc(BUFSIZE);
    console.file_len = 0;
    console.file_pos = 0;
    console.file_id = 0;
    console.file_flags = FILE_READ;
}

/*
 * Read whatever is waiting in stdin queue, put process to sleep if
 * there is nothing to read.
 */
Objptr
read_console(int stream, int mode)
{
    Objptr              res;

   /* Can only read stream 0 */
    if (stream != 0)
	return NilPtr;

    if (console.file_len == 0) {
	/* Put process to sleeep */
	wait_console(console.file_oop);
	return NilPtr;
    }

   /* Update mode for console */
    if (mode) 
	console.file_flags |= FILE_CHAR;
    else
	console.file_flags &= ~FILE_CHAR;

    console.file_buffer[console.file_len] = '\0';
    res = MakeString(console.file_buffer);
    console.file_len = 0;

    return res;
}


