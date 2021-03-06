/*
  JCM2606.
  HALCYON 2.
  PLEASE READ "LICENSE.MD" BEFORE EDITING THIS FILE.
*/

#ifndef INTERNAL_INCLUDED_SETTING_CLOUDS
  #define INTERNAL_INCLUDED_SETTING_CLOUDS

  #define CLOUDS

  // MAIN
  #define CLOUDS_STEPS 3 // [2 3 4 5 6 7 8 9 10 11 12 13 14 15 16]
  #define CLOUDS_OCTAVES 4 // [3 4 5 6]

  cv(int) cloudSteps = CLOUDS_STEPS;
  cRCP(float, cloudSteps);
  cv(int) cloudOctaves = CLOUDS_OCTAVES;
  cRCP(float, cloudOctaves);

  cv(float) cloudHorizonFade = 0.1;

  #define CLOUD_ALTITUDE 512.0 // [128.0 256.0 512.0 1024.0 2048.0]
  #define CLOUD_SCALE 0.000005

  cv(float) cloudScaleMultiplier = CLOUD_ALTITUDE * CLOUD_SCALE;

  // PROPERTIES
  #define CLOUDS_COVERAGE_CLEAR 1.0
  #define CLOUDS_COVERAGE_RAIN 2.0 // [1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5]

  cv(float) cloudCoverageClear = 1.0 / CLOUDS_COVERAGE_CLEAR;
  cv(float) cloudCoverageRain = 1.0 / CLOUDS_COVERAGE_RAIN;

  #define CLOUDS_DENSITY_CLEAR 1600.0
  #define CLOUDS_DENSITY_RAIN 2400.0

  // LIGHTING
  #define CLOUDS_LIGHTING_DIRECT_INTENSITY 1.0
  #define CLOUDS_LIGHTING_SKY_INTENSITY 0.5
  #define CLOUDS_LIGHTING_BOUNCED_INTENSITY 0.125

  #define CLOUDS_LIGHTING_DIRECT_STEPS 3 // [0 1 2 3 4 5 6 7 8]
  #define CLOUDS_LIGHTING_SKY_STEPS 1 // [0 1 2 3 4 5 6 7 8]
  #define CLOUDS_LIGHTING_BOUNCED_STEPS 0 // [0 1 2 3 4 5 6 7 8]

  #define CLOUDS_LIGHTING_DIRECT_WEIGHT 2.0
  #define CLOUDS_LIGHTING_SKY_WEIGHT 1.25
  #define CLOUDS_LIGHTING_BOUNCED_WEIGHT 1.25

  cv(float) cloudLightDirectIntensity = CLOUDS_LIGHTING_DIRECT_INTENSITY * cloudOctavesRCP;
  cv(float) cloudLightSkyIntensity = CLOUDS_LIGHTING_SKY_INTENSITY * cloudOctavesRCP;
  cv(float) cloudLightBouncedIntensity = CLOUDS_LIGHTING_BOUNCED_INTENSITY * cloudOctavesRCP;

  // CLOUD SHADOWING
  #define CLOUD_SHADOW

  //#define CLOUD_SHADOW_SKY // When enabled, sky light is shadowed by cloud directly overhead.
  #define CLOUD_SHADOW_SKY_INTENSITY 0.75
 
  cv(float) cloudShadowSkyIntensityInverse = 1.0 - CLOUD_SHADOW_SKY_INTENSITY;

#endif /* INTERNAL_INCLUDED_SETTING_CLOUDS */
