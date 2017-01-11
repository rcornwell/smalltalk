/*
 * Smalltalk interpreter: Interface to graphics system
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
 * $Id: graphic.h,v 1.2 2002/01/16 19:11:51 rich Exp $
 *
 * $Log: graphic.h,v $
 * Revision 1.2  2002/01/16 19:11:51  rich
 * Return exception code in place holder of scanword.
 *
 * Revision 1.1  2001/08/18 16:20:57  rich
 * Initial revision
 *
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
int                 character_scanword(Objptr, Objptr, Objptr *);

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
