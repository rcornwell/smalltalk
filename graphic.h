
/*
 * Smalltalk interpreter: Interface to graphics system
 *
 * $Id: $
 *
 * $Log: $
 *
 */

/* Structure used to hold cursor value */
typedef struct _cursor_obj
{
    int                 xpos, ypos;	/* Position */
    int                 width, height;	/* Size */
    int                 offx, offy;	/* Offset to image */
    int                 linked;	/* Is image linked */
    unsigned long       bits[32];	/* copy of image */
}
cursor_obj         , *Cursor_object;

/* Structure used to hold contents of BitBlit object */
typedef struct _copy_bits
{
    int                 sx, sy, sw, sh;	/* Source */
    unsigned long      *source_bits;
    int                 dx, dy, dw, dh;	/* Dest */
    unsigned long      *dest_bits;
    int                 hx, hy, hw, hh;	/* Half tone */
    unsigned long      *half_bits;
    int                 cx, cy, cw, ch;	/* Clip region */
    int                 w, h;
    int                 comb_rule;
    int                 display;
}
copy_bits          , *Copy_bits;

extern Objptr       display_object;
extern unsigned long *display_bits;
extern Objptr       cursor_object;
extern cursor_obj   current_cursor;
extern Objptr       tick_semaphore;
extern Objptr       input_semaphore;
extern event_queue  input_queue;

/* Wrapper function for doing bit blit operation.  */
int                 copybits(Objptr);

/* Primitive to scan a character array and display it.  */
Objptr              character_scanword(Objptr, Objptr);

/* Line drawing primitive.  */
int                 drawLoop(Objptr, int, int);

/*
 * Update the display, realy in system, but here so we don't need to include
 * graphic.h when we include system.h.
 */
void		    UpdateDisplay(Copy_bits);

/* modify a form object */
Objptr              BitAt(Objptr, Objptr);

Objptr              BitAtPut(Objptr, Objptr, Objptr);

/* Post an event to the smalltalk system */
void                PostEvent(int, unsigned long);
