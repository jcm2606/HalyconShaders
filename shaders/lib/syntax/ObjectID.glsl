/*
  JCM2606.
  HALCYON 2.
  PLEASE READ "LICENSE.MD" BEFORE EDITING THIS FILE.
*/

#ifndef INTERNAL_INCLUDED_SYNTAX_OBJECTID
  #define INTERNAL_INCLUDED_SYNTAX_OBJECTID

  cv(int) objectIDMax = 256;
  cRCP(float, objectIDMax);

  #define OBJECT_FALLBACK 255
  #define OBJECT_UNLIT 254
  
  #define OBJECT_HAND 253
  #define OBJECT_ENTITY 252
  #define OBJECT_PARTICLE 251
  #define OBJECT_WEATHER 250

  #define OBJECT_STAINED_GLASS 249
  #define OBJECT_TRANSPARENT 248
  #define OBJECT_WATER 247
  #define OBJECT_ICE 246
  
  #define OBJECT_EMISSIVE 245
  #define OBJECT_SUBSURFACE 244
  #define OBJECT_TERRAIN 243
  #define OBJECT_METAL 242

#endif /* INTERNAL_INCLUDED_SYNTAX_OBJECTID */
