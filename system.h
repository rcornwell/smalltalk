
/*
 * Smalltalk interpreter: Interface to system
 *
 * $Id: system.h,v 1.2 2001/08/29 20:16:35 rich Exp rich $
 *
 * $Log: system.h,v $
 * Revision 1.2  2001/08/29 20:16:35  rich
 * Added endSystem method to shut graphics system down.
 *
 * Revision 1.1  2001/08/18 16:22:13  rich
 * Initial revision
 *
 *
 */

/* Initialize the system */
int		    initSystem();

/* End graphics system */
void		    endSystem();

/* Wait for a external event. */
int		    WaitEvent(int);

/* Modify object so that it becomes the display object */
Objptr              BeDisplay(Objptr);

/* Point cursor object at cursor object. */
Objptr              BeCursor(Objptr);

/* OS Wrapper functions */
long                file_open(char *, char *, int *);
long                file_seek(long, long);
int                 file_write(long, char *, long);
int                 file_read(long, char *, long);
int                 file_close(long);
long                file_size(long);
int		    file_checkdirect(char *);
Objptr		    file_direct(Objptr);
int		    file_delete(Objptr);
int		    file_rename(Objptr, Objptr);
void		    file_cwd(char *);
int		    write_console(int, char *);
unsigned long	    current_time();
int		    current_mtime();

/* Misc functions. */
void                error(char *);
void                errorStr(char *, char *);
void		    dump_string(char *);

