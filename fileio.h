/*
 * Smalltalk interpreter: File IO routines.
 *
 * $Id: fileio.h,v 1.2 2000/02/01 18:09:51 rich Exp rich $
 *
 * $Log: fileio.h,v $
 * Revision 1.2  2000/02/01 18:09:51  rich
 * Added fill_buffer and flush_buffer for stdin and stdout support.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

/* Smalltalk level functions */
Objptr              new_file(char *, char *);
char               *get_chunk(Objptr);
int                 peek_for(Objptr, char);
int                 open_buffer(Objptr op);
void                close_buffer(Objptr op);
int                 read_buffer(Objptr op, int *c);
int                 size_buffer(Objptr op);
int                 write_buffer(Objptr op, int c);
void		    close_files();
void		    check_files();

/* OS Wrapper functions */
long                file_open(char *, char *, int *);
long                file_seek(long, long);
int                 file_write(long, char *, long);
int                 file_read(long, char *, long);
int                 file_close(long);
long                file_size(long);
char	           *fill_buffer(int, int);
int		    flush_buffer(int, char *);

/* Misc functions. */
void                error(char *);
void                errorStr(char *, char *);
void		    dump_string(char *);

struct file_buffer {
    Objptr              file_oop;	/* File identifier */
    long                file_id;	/* Os interal identifier */
    long                file_pos;	/* Buffer position */
    int                 file_flags;	/* Flags on file */
    char               *file_buffer;	/* Internal Buffer */
    char               *file_offset;	/* Pointer into buffer */
    int                 file_len;	/* Amount of data in buffer */
    struct file_buffer *file_next;	/* Next in chain of open files */
};

extern struct file_buffer *files;

#define BUFSIZE		8192
#define FILE_READ	1
#define FILE_WRITE	2
#define FILE_DIRTY	4
#define FILE_APPEND	8
