/*
 * Smalltalk interpreter: Interface for large integer routines.
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
 * $Id: largeint.h,v 1.1 2001/08/18 16:18:12 rich Exp $
 *
 * $Log: largeint.h,v $
 * Revision 1.1  2001/08/18 16:18:12  rich
 * Initial revision
 *
 *
 */

/* Add to small integers together */
Objptr              small_add(Objptr, Objptr);

/* Subtract to small integers  */
Objptr              small_sub(Objptr, Objptr);

/* Multiply to small integers together */
Objptr              small_mult(Objptr, Objptr);

/* Return object as a large integer. */
Objptr              large_int(Objptr);

/* Negate a large integer */
Objptr              negate(Objptr);

/* And two LargeNumbers together */
Objptr              large_and(Objptr, Objptr);

/* Or two LargeNumbers together */
Objptr              large_or(Objptr, Objptr);

/* Xor two LargeNumbers together */
Objptr              large_xor(Objptr, Objptr);

/* Xor two LargeNumbers together */
Objptr              large_shift(Objptr, Objptr);

/* Add to LargeInteger objects */
Objptr              large_add(Objptr, Objptr);

/* Subtract to LargeInteger objects */
Objptr              large_sub(Objptr, Objptr);

int                 large_cmp(Objptr, Objptr, int *);

/* Multiply two large integer object together */
Objptr              large_mult(Objptr, Objptr);

/* Divide two large integer objects */
/* Type = 0 return a / b */
/* Type = 1 return a % b */
/* Type = 2 return a / b but fail if remainder is not 0 */
Objptr              large_divide(Objptr, Objptr, int);
