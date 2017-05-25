/*
 *  float_array.cpp
 *  ACSDraw
 *
 *  Created by Alan Smith on Sat Feb 16 2002.
 *  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
 *
 */

#include "float_array.h"

float_array::float_array(int w,int h)
   {
    array = new float[w * h];
	width = w;
	height = h;
   };

float_array::~float_array()
   {
    delete[]array;
   };

float float_array::valueAt(int i,int j)
   {
	float result;
	if ((i<0) || (j<0) || (i>=width) ||(j>=height))
		result = 0.0;
	else 
		result=(array[width * j + i]);
	return(result);
   };

void float_array::multiplyValueAt(int i,int j,float multiplier)
   {
	if ((i<0) || (j<0) || (i>=width) ||(j>=height))
		return;
	else 
		array[width * j + i] *= multiplier;
   };
