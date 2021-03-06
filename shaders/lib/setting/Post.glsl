/*
  JCM2606.
  HALCYON 2.
  PLEASE READ "LICENSE.MD" BEFORE EDITING THIS FILE.
*/

#ifndef INTERNAL_INCLUDED_SETTING_POST
  #define INTERNAL_INCLUDED_SETTING_POST

  #define EXPOSURE 0.9

  #define GAMMA 2.2

  #define SATURATION 1.0
  cv(float) actualSaturation = 1.0 - SATURATION;

  #define _tonemap tonemapUC2

#endif /* INTERNAL_INCLUDED_SETTING_POST */
