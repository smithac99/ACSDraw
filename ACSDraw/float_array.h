/*
 *  float_array.h
 *  ACSDraw
 *
 *  Created by Alan Smith on Sat Feb 16 2002.
 *  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>

struct float_array
   { 
	int width,height;
	float *array;
    float_array(int w,int h);
    virtual ~float_array();
	float valueAt(int i,int j);
	void setValueAt(int i,int j,float value){array[width * j + i] = value;};
	void multiplyValueAt(int i,int j,float value);
   };
