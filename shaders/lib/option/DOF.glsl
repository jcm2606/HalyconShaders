/*
  JCM2606.
  HALCYON.
  PLEASE READ "LICENSE.MD" BEFORE EDITING.
*/

#ifndef INTERNAL_INCLUDED_OPTION_DOF
  #define INTERNAL_INCLUDED_OPTION_DOF

  #define DOF

  #define DOF_INTENSITY 0.05

  #define DOF_DISPERSION
  #define DOF_DISPERSION_INTENSITY 0.2
  
  cv(float) dofDispersionR = 1.0 - (DOF_DISPERSION_INTENSITY * 2.0);
  cv(float) dofDispersionG = 1.0 - DOF_DISPERSION_INTENSITY;
  cv(float) dofDispersionB = 1.0;

#endif /* INTERNAL_INCLUDED_OPTION_DOF */
