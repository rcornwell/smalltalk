
/*
 * Smalltalk interpreter: Image saveing/loading routines.
 *
 * $Id: image.h,v 1.1 1999/09/02 15:57:59 rich Exp $
 *
 * $Log: image.h,v $
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

int                 load_image(char *name);
int                 save_image(char *name, char *process);
