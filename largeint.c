/*
 * Smalltalk largeint: Routines for handling large integers.
 *
 * $Log: largeint.c,v $
 * Revision 1.1  2001/08/18 16:18:12  rich
 * Initial revision
 *
 *
 *
 */

#ifndef lint
static char        *rcsid = "$Id: largeint.c,v 1.1 2001/08/18 16:18:12 rich Exp $";

#endif

#include "smalltalk.h"
#include "object.h"
#include "smallobjs.h"
#include "largeint.h"

#define upper_half(x)		(((x) >> 16) & 0xffff)
#define lower_half(x)		((x) & 0xffff)
#define lower_tohigh(x)		(lower_half((x)) << 16)

/* Macro to return the result */
#define return_result(rval, rlen, sign) \
	/* Trim result first */ \
	while((rlen) > 1 && (rval)[(rlen)-1] == 0) \
		rlen--; \
	/* Check if it could be a small integer */ \
	if ((rlen) == 1 && ((long)(*(rval))) >= 0 && \
				 canbe_integer(sign * (*(rval)))) \
	        return(as_integer_object(sign * (*(rval)))); \
	else { \
		Objptr		res; \
		unsigned long	*rptr; \
		int		i; \
		/* Nope... allocate and copy result */ \
		res = create_new_object(((sign) > 0)?LargePosIntegerClass: \
					   	LargeNegIntegerClass, \
				 	(rlen) * sizeof(unsigned long)); \
		rptr = (unsigned long *)get_object_base(res); \
		for(i = 0; i < (rlen); i++)  \
	    		*rptr++ = *(rval)++; \
		return res; \
	}

/* Return object as a large integer. */
Objptr large_int(Objptr a)
{
    long int            x;
    Objptr              res;
    unsigned long      *rval;

    /* Check class of a */
    switch (class_of(a)) {
    case LargePosIntegerClass:
    case LargeNegIntegerClass:
	return a;
    case FloatClass:
	/* Handle better later */
	x = (long) (*(double *) get_object_base(a));
	break;
    case SmallIntegerClass:
	x = as_integer(a);
	break;
    default:
	return NilPtr;
    }
    res = create_new_object((x >= 0) ? LargePosIntegerClass :
			    LargeNegIntegerClass, sizeof(unsigned long));

    rval = (unsigned long *) get_object_base(res);
    *rval = (x >= 0) ? x : -x;
    return res;
}

/* Negate a large integer */
Objptr negate(Objptr a)
{
    int                 c;
    double              x;
    Objptr              res;
    int                 rlen;
    int                 i;
    unsigned long      *aval;
    unsigned long      *rval;

    /* Check sign of a */
    c = class_of(a);
    switch (c) {
    case LargePosIntegerClass:
	c = LargeNegIntegerClass;
	break;
    case LargeNegIntegerClass:
	c = LargePosIntegerClass;
	break;
    case SmallIntegerClass:
	return as_integer_object(-as_integer(a));
    case FloatClass:
	x = *((double *) get_object_base(a));
	res = create_new_object(FloatClass, sizeof(double));

	*((double *) get_object_base(res)) = -x;
	return res;
    }
    /* Check if it could be a small integer */
    rlen = length_of(a) / sizeof(unsigned long);

    aval = (unsigned long *) get_object_base(a);
    res = create_new_object(c, rlen * sizeof(unsigned long));

    rval = (unsigned long *) get_object_base(res);
    for (i = 0; i < rlen; i++)
	*rval++ = *aval++;
    return res;
}

/* And two LargeNumbers together */
Objptr large_and(Objptr a, Objptr b)
{
    unsigned long      *aval, *bval;
    unsigned long      *rval, *rptr;
    int                 asign, bsign;
    int                 alen, blen, rlen;
    int                 cya, cyb;
    int                 i;
    unsigned long       av, bv;

    /* Grab sizes and pointer to actual data. */
    aval = (unsigned long *) get_object_base(a);
    bval = (unsigned long *) get_object_base(b);
    alen = length_of(a) / sizeof(unsigned long);
    blen = length_of(b) / sizeof(unsigned long);

    asign = 0;
    if (class_of(a) == LargeNegIntegerClass)
	asign = 1;
    bsign = 0;
    if (class_of(b) == LargeNegIntegerClass)
	bsign = 1;

    /* Make sure A is longer */
    if (alen < blen) {
	/* If not swap them */
	unsigned long      *x;

	x = aval;
	aval = bval;
	bval = x;
	i = alen;
	alen = blen;
	blen = i;
	i = asign;
	asign = bsign;
	bsign = i;
    }

    /* Place to put result. */
    rptr = rval = (unsigned long *) alloca(alen * sizeof(unsigned long));

    cya = 1;
    cyb = 1;
    /* And B in */
    for (i = 0; i < blen; i++) {
	av = *aval++;
	if (asign) {
	    av = ~av;
	    av += cya;
	    cya = (av < cya);
	}
	bv = *bval++;
	if (bsign) {
	    bv = ~bv;
	    bv += cyb;
	    cyb = (bv < cyb);
	}
	*rptr++ = av & bv;
    }
    /* Propegate carry through rest of A */
    for (; i < alen; i++) {
	av = *aval++;
	if (asign) {
	    av = ~av;
	    av += cya;
	    cya = (av < cya);
	}
	if (bsign) {
	    bv = cyb;
	    cyb = 0;
	} else {
	    bv = 0;
	}
	*rptr++ = av & bv;
    }

    /* Check if it could be a small integer */
    rlen = (rptr - rval) + 1;
    return_result(rval, rlen, 1);
}

/* Or two LargeNumbers together */
Objptr large_or(Objptr a, Objptr b)
{
    unsigned long      *aval, *bval;
    unsigned long      *rval, *rptr;
    int                 asign, bsign;
    int                 alen, blen, rlen;
    int                 cya, cyb;
    int                 i;
    unsigned long       av, bv;

    /* Grab sizes and pointer to actual data. */
    aval = (unsigned long *) get_object_base(a);
    bval = (unsigned long *) get_object_base(b);
    alen = length_of(a) / sizeof(unsigned long);
    blen = length_of(b) / sizeof(unsigned long);

    asign = 0;
    if (class_of(a) == LargeNegIntegerClass)
	asign = 1;
    bsign = 0;
    if (class_of(b) == LargeNegIntegerClass)
	bsign = 1;

    /* Make sure A is longer */
    if (alen < blen) {
	/* If not swap them */
	unsigned long      *x;

	x = aval;
	aval = bval;
	bval = x;
	i = alen;
	alen = blen;
	blen = i;
	i = asign;
	asign = bsign;
	bsign = i;
    }

    /* Place to put result. */
    rptr = rval = (unsigned long *) alloca(alen * sizeof(unsigned long));

    cya = 1;
    cyb = 1;
    /* And B in */
    for (i = 0; i < blen; i++) {
	av = *aval++;
	if (asign) {
	    av = ~av;
	    av += cya;
	    cya = (av < cya);
	}
	bv = *bval++;
	if (bsign) {
	    bv = ~bv;
	    bv += cyb;
	    cyb = (bv < cyb);
	}
	*rptr++ = av | bv;
    }
    /* Propegate carry through rest of A */
    for (; i < alen; i++) {
	av = *aval++;
	if (asign) {
	    av = ~av;
	    av += cya;
	    cya = (av < cya);
	}
	if (bsign) {
	    bv = cyb;
	    cyb = 0;
	} else {
	    bv = 0;
	}
	*rptr++ = av | bv;
    }

    /* Check if it could be a small integer */
    rlen = (rptr - rval) + 1;
    return_result(rval, rlen, 1);
}

/* Xor two LargeNumbers together */
Objptr large_xor(Objptr a, Objptr b)
{
    unsigned long      *aval, *bval;
    unsigned long      *rval, *rptr;
    int                 asign, bsign;
    int                 alen, blen, rlen;
    int                 cya, cyb;
    int                 i;
    unsigned long       av, bv;

    /* Grab sizes and pointer to actual data. */
    aval = (unsigned long *) get_object_base(a);
    bval = (unsigned long *) get_object_base(b);
    alen = length_of(a) / sizeof(unsigned long);
    blen = length_of(b) / sizeof(unsigned long);

    asign = 0;
    if (class_of(a) == LargeNegIntegerClass)
	asign = 1;
    bsign = 0;
    if (class_of(b) == LargeNegIntegerClass)
	bsign = 1;

    /* Make sure A is longer */
    if (alen < blen) {
	/* If not swap them */
	unsigned long      *x;

	x = aval;
	aval = bval;
	bval = x;
	i = alen;
	alen = blen;
	blen = i;
	i = asign;
	asign = bsign;
	bsign = i;
    }

    /* Place to put result. */
    rptr = rval = (unsigned long *) alloca(alen * sizeof(unsigned long));

    cya = 1;
    cyb = 1;
    /* And B in */
    for (i = 0; i < blen; i++) {
	av = *aval++;
	if (asign) {
	    av = ~av;
	    av += cya;
	    cya = (av < cya);
	}
	bv = *bval++;
	if (bsign) {
	    bv = ~bv;
	    bv += cyb;
	    cyb = (bv < cyb);
	}
	*rptr++ = av ^ bv;
    }
    /* Propegate carry through rest of A */
    for (; i < alen; i++) {
	av = *aval++;
	if (asign) {
	    av = ~av;
	    av += cya;
	    cya = (av < cya);
	}
	if (bsign) {
	    bv = cyb;
	    cyb = 0;
	} else {
	    bv = 0;
	}
	*rptr++ = av ^ bv;
    }

    /* Check if it could be a small integer */
    rlen = (rptr - rval) + 1;
    return_result(rval, rlen, 1);
}

static unsigned long highmask[] = {
    0x80000000, 0xc0000000, 0xe0000000, 0xf0000000,
    0xf8000000, 0xfc000000, 0xfe000000, 0xff000000,
    0xff800000, 0xffc00000, 0xffe00000, 0xfff00000,
    0xfff80000, 0xfffc0000, 0xfffe0000, 0xffff0000,
    0xffff8000, 0xffffc000, 0xffffe000, 0xfffff000,
    0xfffff800, 0xfffffc00, 0xfffffe00, 0xffffff00,
    0xffffff80, 0xffffffc0, 0xffffffe0, 0xfffffff0,
    0xfffffff8, 0xfffffffc, 0xfffffffe, 0xffffffff
};

static unsigned long lowmask[] = {
    0x00000001, 0x00000003, 0x00000007, 0x0000000f,
    0x0000001f, 0x0000003f, 0x0000007f, 0x000000ff,
    0x000001ff, 0x000003ff, 0x000007ff, 0x00000fff,
    0x00001fff, 0x00003fff, 0x00007fff, 0x0000ffff,
    0x0001ffff, 0x0003ffff, 0x0007ffff, 0x000fffff,
    0x001fffff, 0x003fffff, 0x007fffff, 0x00ffffff,
    0x01ffffff, 0x03ffffff, 0x07ffffff, 0x0fffffff,
    0x1fffffff, 0x3fffffff, 0x7fffffff, 0xffffffff,
};

/* Xor two LargeNumbers together */
Objptr large_shift(Objptr a, Objptr b)
{
    unsigned long      *aval;
    unsigned long      *rval;
    int                 bval, words;
    int                 alen, rlen;
    Objptr              res;
    int                 i, j;
    int                 bits, nbits;
    unsigned long       mask, nmask;
    unsigned long       av;

    /* Grab sizes and pointer to actual data. */
    aval = (unsigned long *) get_object_base(a);
    alen = length_of(a) / sizeof(unsigned long);

    /* B must be of type small integer */
    if (class_of(b) != SmallIntegerClass)
	return NilPtr;
    bval = as_integer(b);

    if (bval == 0)
	return a;

    /* Compute shift */
    words = 1 + bval / 32;
    bits = ((bval > 0) ? bval : -bval) & 0x1f;

    /* Place to put result. */
    rlen = alen + words;
    rval = (unsigned long *) alloca(rlen * sizeof(unsigned long));

    if (bval > 0) {		/* Shift upwards */
	/* backwords copy a to result. */
	mask = highmask[bits - 1];
	nmask = ~mask;
	nbits = 32 - bits;
	av = 0;
	for (j = alen - 1, i = alen + words; j >= words; j--, i--) {
	    av |= (aval[i] & mask) >> nbits;
	    rval[i] = av;
	    av = (aval[i] & nmask) << bits;
	}
	rval[i--] = av;
	/* Last bits of result are 0 */
	while (i >= 0)
	    rval[i--] = 0;
    } else {			/* Shift downwards */
	/* Forwards copy a to result. */
	mask = lowmask[bits - 1];
	nmask = ~mask;
	nbits = 32 - bits;
	words = -words;
	av = (aval[words] & nmask) >> bits;
	for (i = 0, j = words + 1; j < alen; i++, j++) {
	    av |= (aval[j] & mask) << nbits;
	    rval[i] = av;
	    av = (aval[j] & nmask) >> bits;
	}
	rval[i] = av;
    }

    /* Trim off leading zero words */
    while (rlen > 0 && rval[rlen - 1] == 0)
	rlen--;

    /* Check if it could be a small integer */
    if (rlen == 1 && canbe_integer(*rval))
	return (as_integer_object(*rval));

    /* Nope... allocate and copy result */
    res = create_new_object(class_of(a), rlen * sizeof(unsigned long));

    aval = (unsigned long *) get_object_base(res);
    for (i = 0; i < rlen; i++)
	aval[i] = rval[i];
    return res;
}

/* Add two unsigned LargeNumbers together */
static              Objptr
large_add_u(Objptr a, Objptr b, int sign)
{
    unsigned long      *aval, *bval;
    unsigned long      *rval, *rptr;
    int                 alen, blen, rlen;
    int                 cy;
    int                 i;
    unsigned long       av, bv;

    /* Grab sizes and pointer to actual data. */
    aval = (unsigned long *) get_object_base(a);
    bval = (unsigned long *) get_object_base(b);
    alen = length_of(a) / sizeof(unsigned long);
    blen = length_of(b) / sizeof(unsigned long);

    /* Make sure A is longer */
    if (alen < blen) {
	/* If not swap them */
	unsigned long      *x;

	x = aval;
	aval = bval;
	bval = x;
	i = alen;
	alen = blen;
	blen = i;
    }

    /* Place to put result. */
    rptr = rval =

	(unsigned long *) alloca((alen + 1) * sizeof(unsigned long));
    cy = 0;
    /* Add B in */
    for (i = 0; i < blen; i++) {
	av = *aval++;
	bv = *bval++;
	bv += cy;
	cy = (bv < cy);
	bv = av + bv;
	cy += (bv < av);
	*rptr++ = bv;
    }
    /* Propegate carry through rest of A */
    for (; i < alen; i++) {
	av = *aval++;
	bv = cy;
	bv = av + bv;
	cy = (bv < av);
	*rptr++ = bv;
    }
    /* Top carry to last word */
    *rptr++ = cy;

    /* Check if it could be a small integer */
    rlen = rptr - rval;
    return_result(rval, rlen, sign);
}

/* Subtract two unsigned LargeNumbers */
static              Objptr
large_sub_u(Objptr a, Objptr b, int sign)
{
    unsigned long      *aval, *bval;
    unsigned long      *rval, *rptr;
    int                 alen, blen, rlen;
    int                 cy;
    int                 i;
    unsigned long       av, bv;

    /* Grab sizes and pointer to actual data. */
    aval = (unsigned long *) get_object_base(a);
    bval = (unsigned long *) get_object_base(b);
    alen = length_of(a) / sizeof(unsigned long);
    blen = length_of(b) / sizeof(unsigned long);

    /* Make sure A is longer */
    if (alen < blen) {
	/* If not swap them */
	unsigned long      *x;

	x = aval;
	aval = bval;
	bval = x;
	i = alen;
	alen = blen;
	blen = i;
	sign = -sign;
    }

    /* Place to put result. */
    rptr = rval =

	(unsigned long *) alloca((alen + 1) * sizeof(unsigned long));
    cy = 0;
    /* Subtract B in */
    for (i = 0; i < blen; i++) {
	av = *aval++;
	bv = *bval++;
	bv -= cy;
	cy = (cy > bv);
	bv = av - bv;
	cy += (bv > av);
	*rptr++ = bv;
    }

    /* Propegate borrow through rest of A */
    for (; i < alen; i++) {
	av = *aval++;
	bv = cy;
	bv = av - bv;
	cy = (bv > av);
	*rptr++ = bv;
    }

    /* Borrow out mean we need to negate result */
    if (cy) {
	unsigned long      *rneg = rval;

	cy = 1;
	while (rneg < rptr) {
	    unsigned long       x;

	    x = cy + ~*rneg;
	    cy = (x < cy);
	    *rneg++ = x;
	}
	*rptr++ = cy;
	sign = -sign;
    }

    /* Check if it could be a small integer */
    rlen = rptr - rval;
    return_result(rval, rlen, sign);
}

/* Compare two unsigned LargeNumbers */
static int
large_cmp_u(Objptr a, Objptr b, int sign)
{
    unsigned long      *aval, *bval;
    unsigned long      *rval, *rptr;
    int                 alen, blen, rlen;
    int                 cy;
    int                 i;
    unsigned long       av, bv;

    /* Grab sizes and pointer to actual data. */
    aval = (unsigned long *) get_object_base(a);
    bval = (unsigned long *) get_object_base(b);
    alen = length_of(a) / sizeof(unsigned long);
    blen = length_of(b) / sizeof(unsigned long);

    /* Make sure A is longer */
    if (alen < blen) {
	/* If not swap them */
	unsigned long      *x;

	x = aval;
	aval = bval;
	bval = x;
	i = alen;
	alen = blen;
	blen = i;
	sign = -1;
    }

    /* Place to put result. */
    rptr = rval =

	(unsigned long *) alloca((alen + 1) * sizeof(unsigned long));
    cy = 0;
    /* Subtract B in */
    for (i = 0; i < blen; i++) {
	av = *aval++;
	bv = *bval++;
	bv -= cy;
	cy = (cy > bv);
	bv = av - bv;
	cy += (bv > av);
	*rptr++ = bv;
    }

    /* Propegate borrow through rest of A */
    for (; i < alen; i++) {
	av = *aval++;
	bv = cy;
	bv = av - bv;
	cy = (bv > av);
	*rptr++ = bv;
    }

    /* Borrow out mean we need to negate result */
    if (cy) {
	unsigned long      *rneg = rval;

	cy = 1;
	while (rneg <= rptr) {
	    unsigned long       x;

	    x = cy + ~*rneg;
	    cy = (x < cy);
	    *rneg++ = x;
	}
	*rneg = cy;
	rptr++;
	sign = -sign;
    }

    /* Trim off leading zero words */
    while (--rptr != rval)
	if (*rptr != 0)
	    break;

    /* Check if results are zero. */
    rlen = (rptr - rval) + 1;
    if (rlen == 1 && *rval == 0)
	return 0;
    return sign;
}

/* Add to LargeInteger objects */
Objptr large_add(Objptr a, Objptr b)
{
    int                 type = 0;
    Objptr              c;
    Objptr              res;

    /* Check sign of a */
    c = class_of(a);
    if (c == LargePosIntegerClass)
	type += 1;
    else if (c != LargeNegIntegerClass)
	return NilPtr;

    /* Check sign of b */
    c = class_of(b);
    if (c == LargePosIntegerClass)
	type += 2;
    else if (c != LargeNegIntegerClass)
	return NilPtr;

    switch (type) {
    default:
    case 0:			/* a neg, b neg */
	res = large_add_u(a, b, -1);

    case 1:			/* a pos, b neg */
	res = large_sub_u(a, b, 1);

    case 2:			/* a neg, b pos */
	res = large_sub_u(a, b, -1);

    case 3:			/* a pos, b pos */
	res = large_add_u(a, b, 1);
    }
    return res;
}

/* Subtract to LargeInteger objects */
Objptr large_sub(Objptr a, Objptr b)
{
    int                 type = 0;
    Objptr              c;
    Objptr              res;

    /* Check sign of a */
    c = class_of(a);
    if (c == LargePosIntegerClass)
	type += 1;
    else if (c != LargeNegIntegerClass)
	return NilPtr;

    /* Check sign of b */
    c = class_of(b);
    if (c == LargePosIntegerClass)
	type += 2;
    else if (c != LargeNegIntegerClass)
	return NilPtr;

    switch (type) {
    default:
    case 0:			/* a neg, b neg */
	res = large_sub_u(a, b, -1);

    case 1:			/* a pos, b neg */
	res = large_add_u(a, b, 1);

    case 2:			/* a neg, b pos */
	res = large_add_u(a, b, -1);

    case 3:			/* a pos, b pos */
	res = large_sub_u(a, b, 1);
    }
    return res;
}

int
large_cmp(Objptr a, Objptr b, int *success)
{
    int                 type = 0;
    Objptr              c;
    Objptr              res;

    /* Check sign of a */
    c = class_of(a);
    if (c == LargePosIntegerClass)
	type += 1;
    else if (c != LargeNegIntegerClass) {
	*success = FALSE;
	return 0;
    }

    /* Check sign of b */
    c = class_of(b);
    if (c == LargePosIntegerClass)
	type += 2;
    else if (c != LargeNegIntegerClass) {
	*success = FALSE;
	return 0;
    }

    switch (type) {
    default:
    case 0:			/* a neg, b neg */
	res = large_cmp_u(a, b, -1);

    case 1:			/* a pos, b neg */
	res = 1;

    case 2:			/* a neg, b pos */
	res = -1;

    case 3:			/* a pos, b pos */
	res = large_cmp_u(a, b, 1);
    }
    *success = TRUE;
    return res;
}

struct dbllong
{
    unsigned long       low;
    unsigned long       high;
};

#define dbladd(s, l, h) \
	(s)->low += l; \
	subcy = (s)->low < l; \
	(s)->high += subcy; \
	*carry += (s)->high < subcy; \
	(s)->high += h; \
	*carry += (s)->high < h;

/*
 * Multiply step.
 *
 * Take two unsigned long numbers x and y, multiply them together
 * storing result into sum after adding in carry.
 * Update carry out.
 */
static INLINE void
mult_step(unsigned long x, unsigned long y, int *carry,
	  struct dbllong *sum)
{
    unsigned long       s;
    int                 subcy;
    unsigned long       lpart, hpart;

    sum->low += *carry;
    subcy = sum->low < *carry;
    /* Mult low parts */
    s = lower_half(x) * lower_half(y);
    sum->low += s;
    subcy += sum->low < s;
    sum->high += subcy;
    *carry = sum->high < subcy;
    /* Now high/low part */
    s = upper_half(x) * lower_half(y);
    lpart = lower_tohigh(s);	/* Split result in half */
    hpart = upper_half(s);
    dbladd(sum, lpart, hpart)
	s = lower_half(x) * upper_half(y);
    lpart = lower_tohigh(s);	/* Split result in half */
    hpart = upper_half(s);
    dbladd(sum, lpart, hpart)
	s = upper_half(x) * upper_half(y);
    sum->high += s;
    *carry += sum->high < subcy;
}

/* Multiply two small integer object together */
Objptr small_mult(Objptr a, Objptr b)
{
    int                 sign = 1;
    struct dbllong      sum;
    long                aval, bval;
    unsigned long       uaval, ubval;
    unsigned long       rval[3];
    unsigned long      *xptr = rval;
    int                 rlen;
    int                 cy;

    /* Check sign of a */
    if (!is_integer(a))
	return NilPtr;

    aval = as_integer(a);
    if (aval >= 0) {
	uaval = aval;
    } else {
	sign = -sign;
	uaval = -aval;
    }

    /* Check sign of b */
    if (!is_integer(b))
	return NilPtr;

    bval = as_integer(b);
    if (bval >= 0) {
	ubval = bval;
    } else {
	sign = -sign;
	ubval = -bval;
    }

    sum.low = 0;
    sum.high = 0;
    cy = 0;
    mult_step(uaval, ubval, &cy, &sum);
    /* Compute length of result */
    rval[2] = cy;
    rval[1] = sum.high;
    rval[0] = sum.low;
    rlen = 3;
    return_result(xptr, rlen, sign);
}

/* Multiply two large integer object together */
Objptr large_mult(Objptr a, Objptr b)
{
    int                 sign = 1;
    Objptr              c;
    struct dbllong      sum;
    unsigned long      *aval, *bval;
    unsigned long      *rval, *rptr;
    int                 alen, blen, rlen;
    int                 cy;
    int                 i, j;

    /* Check sign of a */
    c = class_of(a);
    if (c == LargeNegIntegerClass)
	sign = -sign;
    else if (c != LargePosIntegerClass)
	return NilPtr;

    /* Check sign of b */
    c = class_of(b);
    if (c == LargeNegIntegerClass)
	sign = -sign;
    else if (c != LargePosIntegerClass)
	return NilPtr;

    /* Grab sizes and pointer to actual data. */
    aval = (unsigned long *) get_object_base(a);
    bval = (unsigned long *) get_object_base(b);
    alen = length_of(a) / sizeof(unsigned long);
    blen = length_of(b) / sizeof(unsigned long);

    /* Make sure A is longer */
    if (alen < blen) {
	/* If not swap them */
	unsigned long      *x;

	x = aval;
	aval = bval;
	bval = x;
	i = alen;
	alen = blen;
	blen = i;
    }

    /* Place to put result */
    rptr = rval =

	(unsigned long *) alloca((blen + alen) * sizeof(unsigned long));
    sum.low = 0;
    sum.high = 0;

    /* Do partial products */
    for (rlen = 0; rlen < blen; rlen++) {
	cy = 0;
	for (j = 0; j < rlen + 1; j++)
	    mult_step(aval[j], bval[rlen - j], &cy, &sum);
	rval[rlen] = sum.low;
	sum.low = sum.high;
	sum.high = cy;
    }
    for (; rlen < alen; rlen++) {
	cy = 0;
	for (j = rlen - blen + 1; j < rlen + 1; j++)
	    mult_step(aval[j], bval[rlen - j], &cy, &sum);
	rval[rlen] = sum.low;
	sum.low = sum.high;
	sum.high = cy;
    }
    for (; rlen < alen + blen; rlen++) {
	cy = 0;
	for (j = rlen - blen + 1; j < alen; j++)
	    mult_step(aval[j], bval[rlen - j], &cy, &sum);
	rval[rlen] = sum.low;
	sum.low = sum.high;
	sum.high = cy;
    }

    /* Check if it could be a small integer */
    return_result(rval, rlen, sign);
}

/*
 * Short divide
 * Divide aval / n result to qval, rem
 */
static INLINE void
short_divide(unsigned long *aval, int alen, unsigned long n,
	     unsigned long *qval, unsigned long *rem)
{
    int                 i;
    int                 r;
    double              base = 4.0 * (double) (0x40000000);
    double              dem = (double) n;

    r = 0;
    for (i = alen - 1; i >= 0; i--) {
	int                 carry;
	struct dbllong      temp;
	double              d;
	unsigned long       qq;

	/* Convert remainder and digit to double */
	/* Cheap Portable 64 bit divide */
	/* DO NOT remove parens here, order is important */
	d = ((((double) r) * base) + ((double) (aval[i]))) / dem;

	/* Extract quotient estimate */
	qq = (unsigned long) d;

	/* The divide above could have lost bits, recover them */
	temp.low = 0;
	temp.high = 0;
	carry = 0;
	mult_step(qq, n, &carry, &temp);

	/* Now subtract the original numerator as an integer */
	temp.low = aval[i] - temp.low;
	carry = temp.low > aval[i];
	temp.high -= carry;
	temp.high = r - temp.high;

	/* If result is larger then denomiator we lost bits */
	while (temp.high != 0 && temp.low > n) {
	    /* add 1 to quotent and subtract denomitor from temp */
	    qq++;
	    temp.low = temp.low - n;
	    temp.high -= (n > temp.low);
	}

	/* Now qq is true quotient and temp.low is remainder. */
	qval[i] = qq;
	r = temp.low;
    }
    *rem = r;
}

/*
 * Divide step:
 *	rval = rval - d * bval * (base^j):
 *	if (bval < 0) {
 *		qq--;
 *		rval = rval + bval * (base^j);
 *	}
 *	return qq;
 */
static INLINE unsigned long
divide_step(unsigned long qq, int blen, int j,
	    unsigned long *bval, unsigned long *rval)
{
    unsigned long       borrow;
    int                 i;
    unsigned long       u;
    struct dbllong      x;
    int                 carry;

    /* Subtract a * d from b */
    borrow = 0;
    x.high = 0;
    for (i = 0; i < blen; i++) {
	carry = x.high;
	x.low = 0;
	x.high = 0;
	/* x => bval[i] * qq + 0 */
	mult_step(bval[i], qq, &carry, &x);
	/* Now subtract r - x */
	u = x.low - borrow;
	borrow = (borrow > u);
	u = rval[i] - u;
	borrow += (u > rval[i]);
	rval[i] = u;
    }
    /* If we had extra bits, go one higher in rval */
    if (x.high != 0) {
	u = x.high - borrow;
	borrow = (borrow > u);
	u = rval[i] - u;
	borrow += (u > rval[i]);
	rval[i] = u;
	i++;
    }
    if (borrow != 0) {
	/* Negate value and subtract b */
	borrow = 0;
	carry = 1;
	for (i = 0; i < blen; i++) {
	    u = carry + ~rval[i];
	    carry = (u < carry);
	    u -= borrow;
	    borrow = (borrow > u);
	    u = u - bval[i];
	    borrow += (bval[i] > u);
	    rval[i] = u;
	}
	/* If we overflowed, negate top word */
	if (x.high != 0) {
	    rval[i] = (carry + ~rval[i]) - borrow;
	}
	qq--;
    }
    return qq;
}

/* Compute trial quotient. */
static INLINE unsigned long
trial_quotent(unsigned long v1, unsigned long v2, unsigned long *u)
{
    unsigned long       d;

    /* Compute a seed quotent */
    if (u[2] == v1) {
	/* Equal start at base - 1 */
	d = 0xffffffff;
    } else {
	/* No equal start at [u1,u2] / v1 */
	unsigned long       x;
	unsigned long       temp[3];
	unsigned long       r[2];

	x = u[0];
	temp[0] = u[1];
	temp[1] = u[2];
	r[0] = v2;
	r[1] = v1;

	/* Normalize numbers to get maximum value of estimate */
	while ((r[1] & 0xf0000000) == 0 && (temp[1] & 0xf0000000) == 0) {
	    /* Shift up 4 bits */
	    r[1] = (r[1] << 4) | ((r[0] >> 28) & 0xf);
	    r[0] <<= 4;
	    temp[1] = (temp[1] << 4) | ((temp[0] >> 28) & 0xf);
	    temp[0] = (temp[0] << 4) | ((x >> 28) & 0xf);
	    x <<= 4;
	}

	/* Do a divide to get estimate of divisor */
	short_divide(temp, 2, r[1], r, &x);
	/*
	 * Save time here, if d more than one digit,
	 * set d to base - 1.
	 */
	if (r[1] > 0)
	    d = 0xffffffff;
	else
	    d = r[0];
    }

    /* 
     * Compute:
     * While [v1,v2] * d > [u3, u2, u1]
     *      d = d - 1
     * return d as trial quotent.
     */
    while (1) {
	struct dbllong      xtemp;
	unsigned long       x1, x2, x3;
	int                 cy;

	/* Compute v1 * d -> x1, x2 */
	/* Mult low parts */
	xtemp.low = 0;
	xtemp.high = 0;
	cy = 0;
	mult_step(v2, d, &cy, &xtemp);
	x1 = xtemp.low;
	xtemp.low = xtemp.high;
	xtemp.high = cy;
	cy = 0;

	/* Now do v1 * d -> x2, x3 */
	mult_step(v1, d, &cy, &xtemp);
	x2 = xtemp.low;
	x3 = xtemp.high;

	/*
	 * If carry out, don't bother to compare since we know d
	 * is too large.
	 */
	if (cy == 0) {
	    /* Check if x3,x2,x1 > u3,u2,u1 */
	    unsigned long       z;

	    z = x1 - u[0];
	    cy = (z > x1);
	    z = u[1] - cy;
	    cy = (cy > z);
	    z = x2 - z;
	    cy += (z > x2);
	    z = u[2] - cy;
	    cy = (cy > z);
	    z = x3 - z;
	    cy += (z > x3);

	    /* Go until we get a carry, then return last one */
	    if (cy > 0)
		return d + 1;

	}
	/* No to large back off by one and try again */
	d--;
    }
}

/* Divide two large integer objects */
/* Type = 0 return a / b */
/* Type = 1 return a % b */
/* Type = 2 return a / b but fail if remainder is not 0 */
Objptr large_divide(Objptr a, Objptr b, int type)
{
    int                 sign = 1;
    Objptr              c;
    unsigned long      *aval, *bval;
    unsigned long      *qval, *rval;
    unsigned long      *vval;
    unsigned long       v1, v2, qq;
    int                 alen, blen, qlen, rlen;
    int                 i;

    /* Check sign of a */
    c = class_of(a);
    if (c == LargeNegIntegerClass)
	sign = -sign;
    else if (c != LargePosIntegerClass)
	return NilPtr;

    /* Check sign of b */
    c = class_of(b);
    if (c == LargeNegIntegerClass)
	sign = -sign;
    else if (c != LargePosIntegerClass)
	return NilPtr;

    /* Grab sizes and pointer to actual data. */
    aval = (unsigned long *) get_object_base(a);
    bval = (unsigned long *) get_object_base(b);
    alen = length_of(a) / sizeof(unsigned long);
    blen = length_of(b) / sizeof(unsigned long);

    /* Check for zero divide */
    if (blen == 1) {
	/* Check for divide by zero */
	if (*bval == 0)
	    return NilPtr;
	/* Handle large by single value differently. */
	qlen = alen;
	qval = (unsigned long *) alloca(qlen * (sizeof(unsigned long)));

	rlen = 1;
	rval = (unsigned long *) alloca(rlen * (sizeof(unsigned long)));

	short_divide(aval, alen, *bval, qval, rval);
    } else if (alen < blen) {
	/* If a smaller then b, then result is 0 with a as remainder */
	qlen = 1;
	qval = (unsigned long *) alloca(qlen * (sizeof(unsigned long)));

	rlen = alen;
	rval = (unsigned long *) alloca(rlen * (sizeof(unsigned long)));

	*qval = 0;
	for (i = 0; i < alen; i++)
	    rval[i] = aval[i];
    } else {
	double              base = 4.0 * (double) (0x40000000);
	unsigned long       d;

	qlen = alen - blen + 1;
	qval = (unsigned long *) alloca(qlen * sizeof(unsigned long));

	/* Create some temporary work registers */
	rlen = alen + 1;
	rval = (unsigned long *) alloca(rlen * sizeof(unsigned long));
	vval = (unsigned long *) alloca(rlen * sizeof(unsigned long));

	/* Copy a to r */
	for (i = 0; i < alen; i++)
	    rval[i] = aval[i];
	rval[i] = 0;

	/* Compute first digit */
	v1 = bval[blen - 1];
	v2 = bval[blen - 2];

	/* Convert remainder and digit to double */
	/* Cheap Portable 64 bit divide */
	/* DO NOT remove parens here, order is important */
	d = (unsigned long)
	    (((base * ((double) rval[rlen - 2])) + ((double) rval[rlen - 3]))
	     / ((base * ((double) v1)) + ((double) v2)));

	/* Run first step of divide */
	qq = divide_step(d, blen, rlen - 1, bval,
			 &(rval[rlen - blen - 1]));
	qval[qlen - 1] = qq;
	/* Do division loop */
	for (i = alen - blen - 1; i >= 0; i--) {
	    qq = trial_quotent(v1, v2, &(rval[i + blen - 2]));
	    qval[i] = divide_step(qq, blen, i, bval, &(rval[i]));
	}
#if 0
	unsigned long       d;
	double              base = 4.0 * (double) (0x40000000);
	int                 ulen;
	unsigned long      *uval;
	int                 cy;
	struct dbllong      sum;

	/* Ok, no short cut have to do long division */
	/* Compute initial reciprical seed */
	d = (unsigned long) (base / ((double) (bval[blen - 1] + 1)));

	/* Multiply a * d result to u */
	ulen = 1 + alen;
	uval = (unsigned long *) alloca(ulen * sizeof(unsigned long));

	sum.low = 0;
	sum.high = 0;
	/* Do partial products */
	cy = 0;
	for (i = 0; i < alen; i++) {
	    cy = 0;
	    mult_step(aval[i], d, &cy, &sum);
	    uval[i] = sum.low;
	    sum.low = sum.high;
	    sum.high = cy;
	}
	uval[i] = sum.low;

	/* Multiply b * d result to v */
	vval =

	    (unsigned long *) alloca((1 + blen) * sizeof(unsigned long));
	sum.low = 0;
	sum.high = 0;
	/* Do partial products */
	cy = 0;
	for (i = 0; i < blen; i++) {
	    cy = 0;
	    mult_step(bval[i], d, &cy, &sum);
	    vval[i] = sum.low;
	    sum.low = sum.high;
	    sum.high = cy;
	}
	vval[i] = sum.low;

	/* Get initial values for loop */
	v1 = vval[blen - 1];
	v2 = vval[blen - 2];
	qlen = alen - blen + 1;
	qval = (unsigned long *) alloca(qlen * sizeof(unsigned long));

	/* Do division loop */
	for (i = alen - blen; i >= 0; i--) {
	    qq = trial_quotent(v1, v2, &(uval[i + blen - 2]));
	    qval[i] = divide_step(qq, blen, i, vval, &(uval[i + 1]));
	}

	/* Shorten uval */
	while (ulen > 0) {
	    if (uval[ulen] != 0)
		break;
	    ulen--;
	}

	/* Compute remainder. */
	rlen = ulen;
	rval = (unsigned long *) alloca(rlen * (sizeof(unsigned long)));

	short_divide(uval, ulen, d, rval, &qq);
#endif

    }

    switch (type) {
    case 0:			/* Type = 0 return a / b */
	break;

    case 1:			/* Type = 1 return a % b */
	qlen = rlen;
	qval = rval;
	break;

    case 2:			/* Type = 2 return a / b but fail if remainder is not 0 */
	/* Shorten remainder */
	while (rlen > 0) {
	    if (rval[rlen - 1] != 0)
		break;
	    rlen--;
	}
	/* If we have a remainder we fail */
	if (rlen != 0)
	    return NilPtr;
    }

    return_result(qval, qlen, sign);
}
