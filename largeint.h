/*
 * Smalltalk interpreter: Interface for large integer routines.
 *
 * $Id: $
 *
 * $Log: $
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
