/*
 * Smalltalk interpreter: File IO routines.
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
