/*
 * Smalltalk largeint: Routines for handling large integers.
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
 * $Log: largeint.c,v $
 * Revision 1.2  2020/07/12 16:00:00  rich
 * Coverity cleanup.
 *
 * Revision 1.1  2001/08/18 16:18:12  rich
 * Initial revision
 *
 *
 *
 */


#include <stdint.h>
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
	if ((rlen) == 1 && ((int32_t)(*(rval))) >= 0 && \
				 canbe_integer(sign * (*(rval)))) \
	        return(as_integer_object(sign * (*(rval)))); \
	else { \
		Objptr		res; \
		uint32_t       *rptr; \
		int		i; \
		/* Nope... allocate and copy result */ \
		res = create_new_object(((sign) > 0)?LargePosIntegerClass: \
					   	LargeNegIntegerClass, \
				 	(rlen) * sizeof(uint32_t)); \
		rptr = (uint32_t *)get_object_base(res); \
		for(i = 0; i < (rlen); i++)  \
	    		*rptr++ = *(rval)++; \
		return res; \
	}

/* Return object as a large integer. */
Objptr large_int(Objptr a)
{
    int32_t             x;
    Objptr              res;
    uint32_t           *rval;

    /* Check class of a */
    switch (class_of(a)) {
    case LargePosIntegerClass:
    case LargeNegIntegerClass:
	return a;
    case FloatClass:
	/* Handle better later */
	x = (uint32_t) (*(double *) get_object_base(a));
	break;
    case SmallIntegerClass:
	x = as_integer(a);
	break;
    default:
	return NilPtr;
    }
    res = create_new_object((x >= 0) ? LargePosIntegerClass :
			    LargeNegIntegerClass, sizeof(uint32_t));

    rval = (uint32_t *) get_object_base(res);
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
    uint32_t           *aval;
    uint32_t           *rval;

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
    rlen = length_of(a) / sizeof(uint32_t);

    aval = (uint32_t *) get_object_base(a);
    res = create_new_object(c, rlen * sizeof(uint32_t));

    rval = (uint32_t *) get_object_base(res);
    for (i = 0; i < rlen; i++)
	*rval++ = *aval++;
    return res;
}

/* And two LargeNumbers together */
Objptr large_and(Objptr a, Objptr b)
{
    uint32_t           *aval, *bval;
    uint32_t           *rval, *rptr;
    int                 asign, bsign;
    int                 alen, blen, rlen;
    unsigned int        cya, cyb;
    int                 i;
    uint32_t            av, bv;

    /* Grab sizes and pointer to actual data. */
    aval = (uint32_t *) get_object_base(a);
    bval = (uint32_t *) get_object_base(b);
    alen = length_of(a) / sizeof(uint32_t);
    blen = length_of(b) / sizeof(uint32_t);

    asign = 0;
    if (class_of(a) == LargeNegIntegerClass)
	asign = 1;
    bsign = 0;
    if (class_of(b) == LargeNegIntegerClass)
	bsign = 1;

    /* Make sure A is longer */
    if (alen < blen) {
	/* If not swap them */
	uint32_t       *x;

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
    rptr = rval = (uint32_t *) alloca(alen * sizeof(uint32_t));

    /* Initialize result to zero */
    memset(rval, 0, alen * sizeof(uint32_t));

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
    uint32_t           *aval, *bval;
    uint32_t           *rval, *rptr;
    int                 asign, bsign;
    int                 alen, blen, rlen;
    unsigned int        cya, cyb;
    int                 i;
    uint32_t            av, bv;

    /* Grab sizes and pointer to actual data. */
    aval = (uint32_t *) get_object_base(a);
    bval = (uint32_t *) get_object_base(b);
    alen = length_of(a) / sizeof(uint32_t);
    blen = length_of(b) / sizeof(uint32_t);

    asign = 0;
    if (class_of(a) == LargeNegIntegerClass)
	asign = 1;
    bsign = 0;
    if (class_of(b) == LargeNegIntegerClass)
	bsign = 1;

    /* Make sure A is longer */
    if (alen < blen) {
	/* If not swap them */
	uint32_t      *x;

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
    rptr = rval = (uint32_t *) alloca(alen * sizeof(uint32_t));

    /* Initialize result to zero */
    memset(rval, 0, alen * sizeof(uint32_t));

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
    uint32_t           *aval, *bval;
    uint32_t           *rval, *rptr;
    int                 asign, bsign;
    int                 alen, blen, rlen;
    int                 cya, cyb;
    int                 i;
    uint32_t            av, bv;

    /* Grab sizes and pointer to actual data. */
    aval = (uint32_t *) get_object_base(a);
    bval = (uint32_t *) get_object_base(b);
    alen = length_of(a) / sizeof(uint32_t);
    blen = length_of(b) / sizeof(uint32_t);

    asign = 0;
    if (class_of(a) == LargeNegIntegerClass)
	asign = 1;
    bsign = 0;
    if (class_of(b) == LargeNegIntegerClass)
	bsign = 1;

    /* Make sure A is longer */
    if (alen < blen) {
	/* If not swap them */
	uint32_t       *x;

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
    rptr = rval = (uint32_t *) alloca(alen * sizeof(uint32_t));

    /* Initialize result to zero */
    memset(rval, 0, alen * sizeof(uint32_t));

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

static uint32_t highmask[] = {
    0x80000000, 0xc0000000, 0xe0000000, 0xf0000000,
    0xf8000000, 0xfc000000, 0xfe000000, 0xff000000,
    0xff800000, 0xffc00000, 0xffe00000, 0xfff00000,
    0xfff80000, 0xfffc0000, 0xfffe0000, 0xffff0000,
    0xffff8000, 0xffffc000, 0xffffe000, 0xfffff000,
    0xfffff800, 0xfffffc00, 0xfffffe00, 0xffffff00,
    0xffffff80, 0xffffffc0, 0xffffffe0, 0xfffffff0,
    0xfffffff8, 0xfffffffc, 0xfffffffe, 0xffffffff
};

static uint32_t lowmask[] = {
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
    uint32_t           *aval;
    uint32_t           *rval;
    int                 bval, words;
    int                 alen, rlen;
    Objptr              res;
    int                 i, j;
    int                 bits, nbits;
    uint32_t            mask, nmask;
    uint32_t            av;

    /* Grab sizes and pointer to actual data. */
    aval = (uint32_t *) get_object_base(a);
    alen = length_of(a) / sizeof(uint32_t);

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
    rval = (uint32_t *) alloca(rlen * sizeof(uint32_t));

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
    res = create_new_object(class_of(a), rlen * sizeof(uint32_t));

    aval = (uint32_t *) get_object_base(res);
    for (i = 0; i < rlen; i++)
	aval[i] = rval[i];
    return res;
}

/* Add two unsigned LargeNumbers together */
static              Objptr
large_add_u(Objptr a, Objptr b, int sign)
{
    uint32_t           *aval, *bval;
    uint32_t           *rval, *rptr;
    int                 alen, blen, rlen;
    int                 cy;
    int                 i;
    uint32_t            av, bv;

    /* Grab sizes and pointer to actual data. */
    aval = (uint32_t *) get_object_base(a);
    bval = (uint32_t *) get_object_base(b);
    alen = length_of(a) / sizeof(uint32_t);
    blen = length_of(b) / sizeof(uint32_t);

    /* Make sure A is longer */
    if (alen < blen) {
	/* If not swap them */
	uint32_t      *x;

	x = aval;
	aval = bval;
	bval = x;
	i = alen;
	alen = blen;
	blen = i;
    }

    /* Place to put result. */
    rptr = rval = (uint32_t *) alloca((alen + 1) * sizeof(uint32_t));

    /* Initialize result to zero */
    memset(rval, 0, alen * sizeof(uint32_t));

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
    uint32_t           *aval, *bval;
    uint32_t           *rval, *rptr;
    int                 alen, blen, rlen;
    int                 cy;
    int                 i;
    uint32_t            av, bv;

    /* Grab sizes and pointer to actual data. */
    aval = (uint32_t *) get_object_base(a);
    bval = (uint32_t *) get_object_base(b);
    alen = length_of(a) / sizeof(uint32_t);
    blen = length_of(b) / sizeof(uint32_t);

    /* Make sure A is longer */
    if (alen < blen) {
	/* If not swap them */
	uint32_t      *x;

	x = aval;
	aval = bval;
	bval = x;
	i = alen;
	alen = blen;
	blen = i;
	sign = -sign;
    }

    /* Place to put result. */
    rptr = rval = (uint32_t *) alloca((alen + 1) * sizeof(uint32_t));

    /* Initialize result to zero */
    memset(rval, 0, alen * sizeof(uint32_t));

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
	uint32_t      *rneg = rval;

	cy = 1;
	while (rneg < rptr) {
	    uint32_t       x;

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
    uint32_t           *aval, *bval;
    uint32_t           *rval, *rptr;
    int                 alen, blen, rlen;
    int                 cy;
    int                 i;
    uint32_t            av, bv;

    /* Grab sizes and pointer to actual data. */
    aval = (uint32_t *) get_object_base(a);
    bval = (uint32_t *) get_object_base(b);
    alen = length_of(a) / sizeof(uint32_t);
    blen = length_of(b) / sizeof(uint32_t);

    /* Make sure A is longer */
    if (alen < blen) {
	/* If not swap them */
	uint32_t      *x;

	x = aval;
	aval = bval;
	bval = x;
	i = alen;
	alen = blen;
	blen = i;
	sign = -1;
    }

    /* Place to put result. */
    rptr = rval = (uint32_t *) alloca((alen + 1) * sizeof(uint32_t));

    /* Initialize result to zero */
    memset(rval, 0, alen * sizeof(uint32_t));

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
	uint32_t      *rneg = rval;

	cy = 1;
	while (rneg <= rptr) {
	    uint32_t       x;

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
        break;

    case 1:			/* a pos, b neg */
	res = large_sub_u(a, b, 1);
        break;

    case 2:			/* a neg, b pos */
	res = large_sub_u(a, b, -1);
        break;

    case 3:			/* a pos, b pos */
	res = large_add_u(a, b, 1);
        break;
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
        break;

    case 1:			/* a pos, b neg */
	res = large_add_u(a, b, 1);
        break;

    case 2:			/* a neg, b pos */
	res = large_add_u(a, b, -1);
        break;

    case 3:			/* a pos, b pos */
	res = large_sub_u(a, b, 1);
        break;
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
        break;

    case 1:			/* a pos, b neg */
	res = 1;
        break;

    case 2:			/* a neg, b pos */
	res = -1;
        break;

    case 3:			/* a pos, b pos */
	res = large_cmp_u(a, b, 1);
        break;
    }
    *success = TRUE;
    return res;
}

struct dbllong
{
    uint32_t       low;
    uint32_t       high;
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
 * Take two uint32_t numbers x and y, multiply them together
 * storing result into sum after adding in carry.
 * Update carry out.
 */
static INLINE void
mult_step(uint32_t x, uint32_t y, int *carry,
	  struct dbllong *sum)
{
    uint32_t            s;
    int                 subcy;
    uint32_t            lpart, hpart;

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
    int32_t             aval, bval;
    uint32_t            uaval, ubval;
    uint32_t            rval[3];
    uint32_t           *xptr = rval;
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
    uint32_t           *aval, *bval;
    uint32_t           *rval;
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
    aval = (uint32_t *) get_object_base(a);
    bval = (uint32_t *) get_object_base(b);
    alen = length_of(a) / sizeof(uint32_t);
    blen = length_of(b) / sizeof(uint32_t);

    /* Make sure A is longer */
    if (alen < blen) {
	/* If not swap them */
	uint32_t      *x;

	x = aval;
	aval = bval;
	bval = x;
	i = alen;
	alen = blen;
	blen = i;
    }

    /* Place to put result */
    rval = (uint32_t *) alloca((blen + alen) * sizeof(uint32_t));
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
short_divide(uint32_t *aval, int alen, uint32_t n,
	     uint32_t *qval, uint32_t *rem)
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
	uint32_t            qq;

	/* Convert remainder and digit to double */
	/* Cheap Portable 64 bit divide */
	/* DO NOT remove parens here, order is important */
	d = ((((double) r) * base) + ((double) (aval[i]))) / dem;

	/* Extract quotient estimate */
	qq = (uint32_t) d;

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
static INLINE uint32_t
divide_step(uint32_t qq, int blen, int j,
	    uint32_t *bval, uint32_t *rval)
{
    uint32_t            borrow;
    int                 i;
    uint32_t            u;
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
static INLINE uint32_t
trial_quotent(uint32_t v1, uint32_t v2, uint32_t *u)
{
    uint32_t       d;

    /* Compute a seed quotent */
    if (u[2] == v1) {
	/* Equal start at base - 1 */
	d = 0xffffffff;
    } else {
	/* No equal start at [u1,u2] / v1 */
	uint32_t       x;
	uint32_t       temp[3];
	uint32_t       r[2];

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
	uint32_t            x1, x2, x3;
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
	    uint32_t       z;

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
    uint32_t           *aval, *bval;
    uint32_t           *qval, *rval;
    uint32_t            v1, v2, qq;
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
    aval = (uint32_t *) get_object_base(a);
    bval = (uint32_t *) get_object_base(b);
    alen = length_of(a) / sizeof(uint32_t);
    blen = length_of(b) / sizeof(uint32_t);

    /* Check for zero divide */
    if (blen == 1) {
	/* Check for divide by zero */
	if (*bval == 0)
	    return NilPtr;
	/* Handle large by single value differently. */
	qlen = alen;
	qval = (uint32_t *) alloca(qlen * (sizeof(uint32_t)));

	rlen = 1;
	rval = (uint32_t *) alloca(rlen * (sizeof(uint32_t)));

	short_divide(aval, alen, *bval, qval, rval);
    } else if (alen < blen) {
	/* If a smaller then b, then result is 0 with a as remainder */
	qlen = 1;
	qval = (uint32_t *) alloca(qlen * (sizeof(uint32_t)));

	rlen = alen;
	rval = (uint32_t *) alloca(rlen * (sizeof(uint32_t)));

	*qval = 0;
	for (i = 0; i < alen; i++)
	    rval[i] = aval[i];
    } else {
	double              base = 4.0 * (double) (0x40000000);
	uint32_t       d;

	qlen = alen - blen + 1;
	qval = (uint32_t *) alloca(qlen * sizeof(uint32_t));

	/* Create some temporary work registers */
	rlen = alen + 1;
	rval = (uint32_t *) alloca(rlen * sizeof(uint32_t));
//	vval = (uint32_t *) alloca(rlen * sizeof(uint32_t));

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
	d = (uint32_t)
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
	uint32_t       d;
	double              base = 4.0 * (double) (0x40000000);
	int                 ulen;
	uint32_t      *uval;
	int                 cy;
	struct dbllong      sum;

	/* Ok, no short cut have to do long division */
	/* Compute initial reciprical seed */
	d = (uint32_t) (base / ((double) (bval[blen - 1] + 1)));

	/* Multiply a * d result to u */
	ulen = 1 + alen;
	uval = (uint32_t *) alloca(ulen * sizeof(uint32_t));

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

	    (uint32_t *) alloca((1 + blen) * sizeof(uint32_t));
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
	qval = (uint32_t *) alloca(qlen * sizeof(uint32_t));

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
	rval = (uint32_t *) alloca(rlen * (sizeof(uint32_t)));

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
