/*
 * Smalltalk interpreter: Image reader/writer.
 *
 * $Log: image.c,v $
 * Revision 1.6  2002/02/07 04:21:04  rich
 * Extract path on image load and change to it's directory before starting it.
 *
 * Revision 1.5  2001/08/29 20:16:35  rich
 * Added support for graphics system.
 *
 * Revision 1.4  2001/08/18 16:17:01  rich
 * Added support for display
 *
 * Revision 1.3  2001/07/31 14:09:48  rich
 * Make to work under new cygwin.
 *
 * Revision 1.2  2000/02/01 18:09:51  rich
 * Support for files in image file.
 * Fix bug in image loading.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#ifndef lint
static char        *rcsid =
	"$Id: image.c,v 1.6 2002/02/07 04:21:04 rich Exp $";

#endif

#include "smalltalk.h"
#include "object.h"
#include "smallobjs.h"
#include "image.h"
#include "interp.h"
#include "fileio.h"
#include "graphic.h"
#include "system.h"

/* Image consist of a header:
 *    #! interp_path\n        <*Optional*>
 *      char        magic[4]    'RCST'
 *      int         version     1
 *      int         otsize/1024
 *      int         growsize
 *      Objptr      activeprocess
 *      Objptr      current_context
 *      int         number_objects
 *      int         number_files
 * And Objects:
 *      Objptr      op
 *      int         flags
 *      Objptr      class
 *      int         size            
 *      int         objdata
 * For each file:
 *      Objptr      fileOop     <*Optional, number_files*>
 * Special objects:
 * 	Objptr	    display
 *	Objptr	    cursor
 *	Objptr	    inputsensor
 *	Objptr	    ticksemaphore
 * 	Objptr	    consolelist
 */

char                image_buf[8192];
static int          file_id;
static char        *file_ptr;
static int          buf_len;

/*
 * Read the next character from the buffer.
 */
static char
next_char()
{
    if (buf_len == 0) {
	buf_len = file_read(file_id, image_buf, sizeof(image_buf));
	file_ptr = image_buf;
    }
    if (buf_len <= 0)
	return -1;
    buf_len--;
    return *file_ptr++;
}

/*
 * Write the character into the buffer, flushing buffer if full.
 */
static void
flush_buf()
{
    file_write(file_id, image_buf, buf_len);
}

/*
 * Write the character into the buffer, flushing buffer if full.
 */
static void
put_char(char c)
{
    if (buf_len == sizeof(image_buf)) {
	file_write(file_id, image_buf, buf_len);
	file_ptr = image_buf;
	buf_len = 0;
    }
    buf_len++;
    *file_ptr++ = c;
}

/*
 * Read the next integer off the file.
 */
static int
next_int()
{
    int                 value;

    value = 0xff & next_char();
    value |= (0xff & next_char()) << 8;
    value |= (0xff & next_char()) << 16;
    value |= (0xff & next_char()) << 24;
    return value;
}

/*
 * Write value as integer onto file.
 */

static void
put_int(int value)
{
    put_char(value & 0xff);
    put_char((value >> 8) & 0xff);
    put_char((value >> 16) & 0xff);
    put_char((value >> 24) & 0xff);
}

/*
 * Load an image file into memory.
 */
int
load_image(char *name)
{
    int                 temp;
    int                 otsize;
    int                 numobjs;
    int                 numfiles;
    int                 op, flags, class, size;
    int                *ip;
    char                c;
    char		*path;
    char		*ptr;

    if ((file_id = file_open(name, "r", &temp)) == -1)
	return FALSE;
    
    file_ptr = image_buf;
    buf_len = 0;
   /* Find start of header */
   /* Skip if unix style header. */
    if ((c = next_char()) == '#') {
	while ((c = next_char()) != '\n' && c != -1) ;
	c = next_char();
    }
   /* Make sure magic number matches */
    if (c != 'R') {
	file_close(file_id);
	return FALSE;
    }
    c = next_char();
    if (c != 'C') {
	file_close(file_id);
	return FALSE;
    }
    c = next_char();
    if (c != 'S') {
	file_close(file_id);
	return FALSE;
    }
    c = next_char();
    if (c != 'T') {
	file_close(file_id);
	return FALSE;
    }
    switch ((temp = next_int())) {
    case 1:
	break;
    default:
	file_close(file_id);
	return FALSE;
    }

   /* Load header in */
    otsize = next_int();
    growsize = next_int();
    newProcess = next_int();
    current_context = next_int();
    numobjs = next_int();
    numfiles = next_int();

   /* Create the object table */
    new_objectable(otsize/1024);

   /* Load in object data */
    for (; numobjs > 0; numobjs--) {
	op = next_int();
	flags = next_int();
	class = next_int();
	size = next_int();
	if ((ip = create_object((Objptr) op, flags, (Objptr) class,
				size)) == NULL) {
	    file_close(file_id);
	    error("Unable to load image");
	    /* Not reached */
	}
	size = (size + (sizeof(int) - 1)) / sizeof(int);

	for (; size > 0; size--)
	    *ip++ = next_int();
    }

   /* Load in the open files */
    for (; numfiles > 0; numfiles--) 
	open_buffer(next_int());

   /* Load in the known system objects */
    display_object = next_int();
    cursor_object = next_int();
    input_semaphore = next_int();
    tick_semaphore = next_int();
    console.file_oop = next_int();

  /* All dones close input */
    file_close(file_id);

  /* Put us in same directory as image was loaded from */
    if ((path = alloca(strlen(name) + 1)) != NULL) {
	strcpy(path, name);
	for(ptr = &path[strlen(path)]; ptr != path; ptr--) {
	   if (*ptr == '\\' || *ptr == '/') {
		*ptr = '\0';
		break;
	   }
	}
	if (ptr != path) 
	   file_cwd(path);
    }
    return TRUE;
}

/*
 * Save memory to file so it can be restarted at later time.
 */
int
save_image(char *name, char *process)
{
    int                 temp;
    int                 numobjs;
    int			numfiles;
    Objptr              op, class;
    int                 size, flags;
    int                *ip;
    struct file_buffer *fp;
    Objptr		save_input = input_semaphore;
    Objptr		save_tick = tick_semaphore;

    /* Stop any thing touching the image while we dump */
    input_semaphore = NilPtr;
    tick_semaphore = NilPtr;

    if ((file_id = file_open(name, "w", &temp)) == -1)
	return FALSE;
    file_ptr = image_buf;
    buf_len = 0;
   /* Put unix header on front of image. */
    if (process != NULL) {
	put_char('#');
	put_char('!');
	put_char(' ');
	while (*process != '\0')
	    put_char(*process++);
	put_char('\n');
    }
   /* Make sure magic number matches */
    put_char('R');
    put_char('C');
    put_char('S');
    put_char('T');
    put_int(1);			/* Version */

   /* Clean off any outstanding signals */
    checkProcessSwitch();

   /* Dump header in */
    put_int(otsize);
    put_int(growsize);
    put_int(newProcess);
    put_int(current_context);
    put_int(numobjs = as_integer(usedOops()) - 1);
    for(fp = files, numfiles = 0; fp != NULL; fp = fp->file_next) 
	numfiles++;
    put_int(numfiles);

   /* Load in object data */
    for (op = NilPtr; numobjs > 0; numobjs--) {
	if ((ip = next_object(&op, &flags, &class, &size)) == NULL) 
	    break;
	put_int(op);
	put_int(flags);
	put_int(class);
	put_int(size);
	size = (size + (sizeof(int) - 1)) / sizeof(int);

	for (; size > 0; size--)
	    put_int(*ip++);
    }

   /* Save out the open files */
    for(fp = files; fp != NULL; fp = fp->file_next) 
	put_int(fp->file_oop);

   /* Save out the known objects */
    put_int(display_object);
    put_int(cursor_object);
    put_int(save_input);
    put_int(save_tick);
    put_int(console.file_oop);

   /* Restore input system */
    input_semaphore = save_input;
    tick_semaphore = save_tick;

   /* Flush output and close file */
    flush_buf();
    file_close(file_id);
    return TRUE;
}
