/*
 * Smalltalk interpreter: Interface to system
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
 * $Id: system.h,v 1.3 2002/02/07 04:21:05 rich Exp $
 *
 * $Log: system.h,v $
 * Revision 1.3  2002/02/07 04:21:05  rich
 * Added function to change directory.
 *
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

