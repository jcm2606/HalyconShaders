/*
  JCM2606.
  HALCYON 2.
  PLEASE READ "LICENSE.MD" BEFORE EDITING THIS FILE.
*/

#ifndef INTERNAL_INCLUDED_COMMON_NORMALS
  #define INTERNAL_INCLUDED_COMMON_NORMALS

  #if PROGRAM == GBUFFERS_WATER || PROGRAM == SHADOW
    vec3 getNormal(in vec3 world, in float objectID) {
      return vec3(0.0, 0.0, 1.0);
    }
  #endif

#endif /* INTERNAL_INCLUDED_COMMON_NORMALS */