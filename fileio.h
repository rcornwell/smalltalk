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
 * $Id: fileio.h,v 1.5 2001/08/18 16:17:01 rich Exp rich $
 *
 * $Log: fileio.h,v $
 * Revision 1.5  2001/08/18 16:17:01  rich
 * Moved os specific definitions to system.h
 *
 * Revision 1.4  2001/07/31 14:09:48  rich
 * Removed unused element of file_buffer.
 *
 * Revision 1.3  2001/01/13 15:50:19  rich
 * Added check_files routine
 *
 * Revision 1.2  2000/02/01 18:09:51  rich
 * Added fill_buffer and flush_buffer for stdin and stdout support.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

/* Smalltalk level functions */
void		    parsefile(Objptr);
void 	            load_source(char *);
char               *get_chunk(Objptr);
int                 peek_for(Objptr, char);
int                 open_buffer(Objptr op);
void                close_buffer(Objptr op);
int                 read_buffer(Objptr op, int *c);
int                 read_str_buffer(Objptr op, int len, Objptr *res);
int                 size_buffer(Objptr op);
int                 write_buffer(Objptr op, int c);
int                 write_str_buffer(Objptr op, char *str, int len);
void		    close_files();
void		    check_files();
int		    file_isdirect(Objptr);
void		    init_console(Objptr);
Objptr		    read_console(int, int);

struct file_buffer {
    Objptr              file_oop;	/* File identifier */
    long                file_id;	/* Os interal identifier */
    long                file_pos;	/* Buffer position */
    int                 file_flags;	/* Flags on file */
    int                 file_len;	/* Amount of data in buffer */
    char               *file_buffer;	/* Internal Buffer */
    struct file_buffer *file_next;	/* Next in chain of open files */
};

extern struct file_buffer *files;
extern struct file_buffer console;

#define BUFSIZE		8192
#define FILE_READ	1
#define FILE_WRITE	2
#define FILE_DIRTY	4
#define FILE_APPEND	8
#define FILE_CHAR	16
