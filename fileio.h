/*
 * Smalltalk interpreter: File IO routines.
 *
 * $Id: $
 *
 * $Log: $
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

/* OS Wrapper functions */
long                file_open(char *, char *, int *);
long                file_seek(long, long);
int                 file_write(long, char *, long);
int                 file_read(long, char *, long);
int                 file_close(long);
long                file_size(long);

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
    char               *file_end;	/* End of data */
    struct file_buffer *file_next;	/* Next in chain of open files */
};

#define BUFSIZE		8192
#define FILE_READ	1
#define FILE_WRITE	2
#define FILE_DIRTY	4
#define FILE_APPEND	8
