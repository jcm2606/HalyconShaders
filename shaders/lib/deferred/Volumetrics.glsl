/*
  JCM2606.
  HALCYON.
  PLEASE READ "LICENSE.MD" BEFORE EDITING.
*/

#ifndef INTERNAL_INCLUDED_DEFERRED_VOLUMETRICS
  #define INTERNAL_INCLUDED_DEFERRED_VOLUMETRICS

  #if   PROGRAM == COMPOSITE0
    #include "/lib/common/util/ShadowTransform.glsl"

    #include "/lib/common/Lightmaps.glsl"

    // OPTIONS
    c(int) steps = 8;
    cRCP(float, steps);
 
    c(float) absorptionCoeff = 2.0;

    // OPTICAL DEPTH
    float getHeightFog(in vec3 world) {
      #ifndef FOG_LAYER_HEIGHT
        return 0.0;
      #endif

      return exp2(-max0(world.y - SEA_LEVEL) * FOG_LAYER_HEIGHT_FALLOFF) * FOG_LAYER_HEIGHT_DENSITY;
    }

    float getSheetFog(in vec3 world) {
      #ifndef FOG_LAYER_SHEET
        return 0.0;
      #endif

      #ifdef FOG_LAYER_SHEET_HQ
        c(int) octaves = FOG_LAYER_SHEET_OCTAVES;
        cRCP(float, octaves);

        float opticalDepth = 1.0;

        c(mat2) rot = rot2(-0.7);

        vec3 position = world * 0.3 * vec3(1.0, 1.0, 1.0);

        float weight = 1.0;

        c(vec2) windDir = vec2(0.0, 1.0);
        vec3 wind = vec3(windDir.x, 0.0, windDir.y) * frametime;
        float windSpeed = 0.4;

        for(int i = 0; i < octaves; i++) {
          opticalDepth -= texnoise3D(noisetex, position + wind * windSpeed) * weight;
          
          position *= 2.1;
          position.xz *= rot;
          position.xy *= rot;
          windSpeed *= 1.1;
          weight *= 0.5;
        }

        //opticalDepth -= 0.9;
        opticalDepth  = clamp01(opticalDepth);
        opticalDepth  = sqrt(opticalDepth);
        
        opticalDepth = opticalDepth * 0.7 + 0.3;
      #else
        float opticalDepth = 1.0;
      #endif

      opticalDepth *= FOG_LAYER_SHEET_DENSITY;

      return exp2(-abs(world.y - SEA_LEVEL) * FOG_LAYER_SHEET_FALLOFF) * opticalDepth;
    }

    float getVolumeFog(in vec3 world) {
      #ifndef FOG_LAYER_VOLUME
        return 0.0;
      #endif

      float opticalDepth = 1.0;

      c(mat2) rot = rot2(-0.7);

      vec3 position = world * 0.004;

      float weight = 1.0;

      c(vec2) windDir = vec2(0.0, 1.0);
      vec3 wind = vec3(windDir.x, 0.0, windDir.y) * frametime;
      float windSpeed = 0.07;

      // PRIMARY VOLUME
      c(int) primaryOctaves = 2;
      cRCP(float, primaryOctaves);

      for(int i = 0; i < primaryOctaves; i++) {
        opticalDepth -= texnoise3D(noisetex, position + wind * windSpeed) * weight;

        position *= 2.4;
        position.xz *= rot;
        position.yz *= rot;
        windSpeed *= 1.1;
        weight *= 0.6;
      }

      // ROLLING MIST
      c(int) rollingOctaves = 5;
      cRCP(float, rollingOctaves);

      position *= 4.0;

      for(int i = 0; i < rollingOctaves; i++) {
        opticalDepth += texnoise3D(noisetex, position + wind * windSpeed) * weight;

        position *= 2.4;
        position.xz *= rot;
        position.yz *= rot;
        windSpeed *= 1.1;
        weight *= 0.6;
      }

      opticalDepth -= 0.4;
      opticalDepth = clamp01(opticalDepth);
      //opticalDepth = ceil(opticalDepth);
      //opticalDepth = sqrt(opticalDepth);

      opticalDepth *= 64.0;

      return exp2(-abs(world.y - SEA_LEVEL) * 0.2) * opticalDepth;

      return opticalDepth;
    }

    float getRainFog(in vec3 world) {
      #ifndef FOG_LAYER_RAIN
        return 0.0;
      #endif

      return rainStrength * FOG_LAYER_RAIN_MULTIPLIER;
    }

    float getWaterFog(in float opticalDepth, in vec3 world, in bool differenceMask, in bool isWater) {
      #ifndef FOG_LAYER_WATER
        return 0.0;
      #endif

      return (differenceMask && isWater) ? FOG_LAYER_WATER_DENSITY : opticalDepth;
    }

    float getOpticalDepth(in vec3 world, in float eBS, in float objectID, in bool differenceMask, in bool isWater) {
      float opticalDepth = 0.0;

      opticalDepth += getHeightFog(world);
      opticalDepth += getSheetFog(world);
      opticalDepth += getVolumeFog(world);
      opticalDepth += getRainFog(world);

      opticalDepth  = getWaterFog(opticalDepth, world, differenceMask, isWater);

      return opticalDepth * 0.01;
    }

    // MARCHER
    struct Ray {
      vec3 start;
      vec3 end;
      vec3 pos;
      vec3 incr;
      float dist;
    };

    struct RayVol {
      vec3 origin;
      vec3 target;
      vec3 dir;
      vec3 pos;
      vec3 incr;

      float dist;
    };

    #define getRayDirection(ray) ( normalize(ray.target - ray.origin) )
    #define getRayDistance(ray) ( distance(ray.target, ray.origin) )
    #define getRayIncrement(ray) ( ray.dir * ray.dist * stepsRCP )

    float volVisibilityCheck(in vec3 ray, in vec3 dir, in float odAtStart, in float visDensity, in float dither, in float stepSize, in float eBS, const int samples) {
      const float visStepSizeScale = 1.0 / (float(samples) + 0.5);
      float visStepSize = stepSize * visStepSizeScale;

      dir *= visStepSize;
      ray += dither * dir;

      float opticalDepth = 0.5 * odAtStart;

      for(int i = 0; i < samples; i++, ray += dir) {
        opticalDepth -= getOpticalDepth(ray, eBS, 0.0, false, false);
      }

      return clamp01(exp((absorptionCoeff * visDensity) * visStepSize * (opticalDepth)));
    }

    float volumetrics_miePhase(in float theta, cin(float) G) {
      c(float) gg = G * G;
      c(float) p1 = (0.75 * (1.0 - gg)) / (tau * (2.0 + gg));
      float p2 = (theta * theta + 1.0) * pow(1.0 + gg - 2.0 * G * theta, -1.5);
    
      return p1 * p2;
    }

    vec4 getVolumetrics(io GbufferObject gbuffer, io PositionObject position, io MaskObject mask, out float frontTransmittance, in vec2 screenCoord, in mat2x3 atmosphereLighting) {
      frontTransmittance = 1.0;

      #ifndef VOLUMETRICS
        return vec4(0.0, 0.0, 0.0, 1.0);
      #endif

      vec4 volumetrics = vec4(0.0, 0.0, 0.0, 1.0);

      #define scattering volumetrics.rgb
      #define transmittance volumetrics.a

      // DEFINE SMOOTHED EYE BRIGHTNESS
      float eBS = getRawSkyLightmap(getEBS().y);

      // DEFINE SKY MASK
      bool isSky = !getLandMask(position.depthBack);

      // DEFINE WORLD TO SHADOW MATRIX
      mat4 matrixWorldToShadow = shadowProjection * shadowModelView;

      // DEFINE DITHER
      float dither = bayer128(gl_FragCoord.xy);

      // DEFINE RAY OBJECTS
      RayVol viewRay, worldRay, shadowRay;

      // POPULATE RAY OBJECTS
      // VIEW
      c(float) skyDistance = 64.0;
      viewRay.origin = vec3(0.0);
      viewRay.target = position.viewBack;
      viewRay.dir = getRayDirection(viewRay);
      viewRay.dist = getRayDistance(viewRay);
      viewRay.incr = getRayIncrement(viewRay);
      viewRay.pos = viewRay.incr * dither + viewRay.origin;

      // WORLD
      worldRay.origin = viewToWorld(viewRay.origin);
      worldRay.target = viewToWorld(viewRay.target);
      worldRay.dir = getRayDirection(worldRay);
      worldRay.dist = getRayDistance(worldRay);
      worldRay.incr = getRayIncrement(worldRay);
      worldRay.pos = worldRay.incr * dither + worldRay.origin;

      // SHADOW
      c(vec3) shadowRayScale = vec3(1.0, 1.0, shadowDepthMult);
      shadowRay.origin = transMAD(matrixWorldToShadow, worldRay.origin) * shadowRayScale;
      shadowRay.target = transMAD(matrixWorldToShadow, worldRay.target) * shadowRayScale;
      shadowRay.dir = getRayDirection(shadowRay);
      shadowRay.dist = getRayDistance(shadowRay);
      shadowRay.incr = getRayIncrement(shadowRay);
      shadowRay.pos = shadowRay.incr * dither + shadowRay.origin;

      // DEFINE MIE TAIL
      float miePhase = volumetrics_miePhase((dot(viewRay.dir, lightVector)), 0.2) * 2.0;

      // DEFINE FRONT VIEW DISTANCE
      float distanceToViewFront = distance(viewRay.origin, position.viewFront);

      // DEFINE STEP SIZE
      float stepSize = flength(worldRay.incr);

      // MARCH
      for(int i = 0; i < steps; i++, viewRay.pos += viewRay.incr, worldRay.pos += worldRay.incr, shadowRay.pos += shadowRay.incr) {
        // DEFINE POSITIONS
        vec3 shadow = vec3(distortShadowPosition(shadowRay.pos.xy, 0), shadowRay.pos.z) * 0.5 + 0.5;
        vec3 world = worldRay.pos + cameraPosition;

        // GET RAW FRONT SHADOW DEPTH
        float depthFront = texture2DLod(shadowtex0, shadow.xy, 0).x;

        // GET SHADOW VISIBILITY VALUES
        float visibilityBack = CutShadow(compareShadow(texture2DLod(shadowtex1, shadow.xy, 0).x, shadow.z));
        float visibilityFront = CutShadow(compareShadow(depthFront, shadow.z));

        // SKY VISIBILITY OVERRIDE
        if(isSky && (any(greaterThan(shadow.xy, vec2(1.0))) || any(lessThan(shadow.xy, vec2(0.0))))) {
          visibilityBack = 1.0;
          visibilityFront = 1.0;
        }

        // CLAMP SHADOW VISIBILITY VALUES
        visibilityBack = min1(visibilityBack);
        visibilityFront = min1(visibilityFront);

        // DEFINE DIFFERENCE MASK
        bool differenceMask = visibilityBack - visibilityFront > 0.0;

        // DEFINE DISTANCES
        float distanceToSurface = max0(shadow.z - depthFront) * shadowDepthBlocks;
        float distanceToViewRay = distance(viewRay.origin, viewRay.pos);

        // GET SHADOW OBJECT ID
        float objectID = texture2DLod(shadowcolor1, shadow.xy, 0).a * objectIDRange;

        // DEFINE OBJECT ID MASKS
        bool isWater = comparef(objectID, OBJECT_WATER, ubyteMaxRCP);

        // GET OPTICAL DEPTH
        float opticalDepth = getOpticalDepth(world, eBS, objectID, differenceMask, isWater);

        // GET VOLUME VISIBILITY
        #ifdef FOG_LIGHTING_DIRECT
          float visibilityDirect = volVisibilityCheck(world, wLightVector, opticalDepth, 0.9, dither, stepSize, eBS, FOG_LIGHTING_DIRECT_STEPS);
        #else
          float visibilityDirect = 1.0;
        #endif

        #ifdef FOG_LIGHTING_SKY
          float visibilitySky = volVisibilityCheck(world, vec3(0.0, 1.0, 0.0), opticalDepth, 0.9, dither, stepSize, eBS, FOG_LIGHTING_SKY_STEPS);
        #else
          float visibilitySky = 1.0;
        #endif

        // GET CLOUD SHADOW
        float cloudShadow = getCloudShadow(world);

        // OCCLUDE RAY
        vec2 rayVisibility = vec2(1.0);

        #define directVisibility rayVisibility.x
        #define skyVisibility rayVisibility.y

        directVisibility *= cloudShadow * miePhase * visibilityDirect * visibilityBack;
        skyVisibility *= (cloudShadow * 0.75 + 0.25) * visibilitySky;

        #if   FOG_OCCLUSION_SKY == 1
          skyVisibility *= visibilityBack;
        #elif FOG_OCCLUSION_SKY == 2
          // TODO: Sky light occlusion approximation.
        #endif

        // ILLUMINATE RAY
        vec3 lightColour = atmosphereLighting[0] * directVisibility + atmosphereLighting[1] * skyVisibility;
        vec3 rayColour = lightColour;

        #undef directVisibility
        #undef skyVisibility

        // GET INTERACTION WITH FRONT SHADOWS
        if(differenceMask) rayColour *= toShadowHDR(texture2DLod(shadowcolor0, shadow.xy, 0).rgb);

        // GET INTERACTION WITH WATER VOLUME
        // WATER SURFACE -> RAY
        if(differenceMask && isWater) rayColour = interactWater(rayColour, distanceToSurface);

        // RAY -> EYE
        if((differenceMask && isWater) || (isEyeInWater == 1 && mask.water)) {
          vec3 waterAbsorptionOrigin = (isEyeInWater == 0) ? position.viewFront : viewRay.origin;
          vec3 waterAbsorptionTarget = (!differenceMask && mask.water && isEyeInWater == 1) ? position.viewFront : viewRay.pos;

          rayColour = interactWater(rayColour, distance(waterAbsorptionOrigin, waterAbsorptionTarget));
        }

        // ACCUMULATE RAY
        scattering += rayColour * transmittedScatteringIntegral(opticalDepth * stepSize, absorptionCoeff) * transmittance;
        float absorption = exp(-absorptionCoeff * opticalDepth * stepSize);
        transmittance *= absorption;
        frontTransmittance *= (distanceToViewRay < distanceToViewFront) ? absorption : 1.0;
      }

      #undef scattering
      #undef transmittance

      return volumetrics;
    }
  #elif PROGRAM == COMPOSITE1
    #include "/lib/deferred/Refraction.glsl"

    #define hammersley(i, N) vec2( float(i) / float(N), float( bitfieldReverse(i) ) * 2.3283064365386963e-10 )
    #define circlemap(p) (vec2(cos((p).y*tau), sin((p).y*tau)) * p.x)

    vec3 drawCombinedVolumetrics(io GbufferObject gbuffer, io PositionObject position, in vec3 frame, in vec2 screenCoord) {
      #if !defined VOLUMETRICS && !defined VOLUMETRIC_CLOUDS
        return frame;
      #endif

      // OPTIONS
      c(float) samples = 24;
      cRCP(float, samples);

      c(float) radius = 0.003;

      c(int) fogLOD = 2;
      c(int) cloudLOD = 1;

      // GET REFRACTED SCREEN COORDINATE
      vec2 originalCoord = screenCoord;
      float refractDist = 0.0;
      screenCoord = getRefractPos(refractDist, screenCoord, position.viewBack, position.viewFront, gbuffer.normal).xy;

      if(refractDist == 0.0 || texture2D(depthtex1, screenCoord.xy).x < position.depthFront) screenCoord = originalCoord;

      // GENERATE DITHER PATTERN
      c(float) ditherScale = pow(32, 2.0);
      float dither = bayer32(gl_FragCoord.xy) * ditherScale;

      // DEFINE FOG AND CLOUD VARIABLES
      #ifdef VOLUMETRICS
        vec4 fog = vec4(0.0);

        #define fogScattering fog.rgb
        #define fogTransmittance fog.a
      #endif

      #ifdef VOLUMETRIC_CLOUDS
        vec4 cloud = vec4(0.0);

        #define cloudScattering cloud.rgb
        #define cloudTransmittance cloud.a
      #endif

      // FILTER
      for(int i = 0; i < samples; i++) {
        vec2 offset = circlemap(
          lattice(i * ditherScale + dither, samples * ditherScale)
        ) * radius + screenCoord;

        // ACCUMULATE FOG
        #ifdef VOLUMETRICS
          fog += texture2DLod(colortex4, offset, fogLOD);
        #endif

        // ACCUMULATE CLOUDS
        #ifdef VOLUMETRIC_CLOUDS
          cloud += texture2DLod(colortex5, offset, cloudLOD);
        #endif
      }

      // NORMALIZE DATA
      #ifdef VOLUMETRICS
        fog *= samplesRCP;
      #endif

      #ifdef VOLUMETRIC_CLOUDS
        cloud *= samplesRCP;
      #endif

      // DRAW CLOUDS
      #ifdef VOLUMETRIC_CLOUDS
        frame = frame * cloudTransmittance + cloudScattering;
      #endif

      // DRAW FOG
      #ifdef VOLUMETRICS
        frame = frame * fogTransmittance + fogScattering;
      #endif

      #ifdef VOLUMETRICS
        #undef fogScattering
        #undef fogTransmittance
      #endif

      #ifdef VOLUMETRIC_CLOUDS
        #undef cloudScattering
        #undef cloudTransmittance
      #endif

      return frame;
    }

    #undef hammersley
    #undef circlemap
  #endif

#endif /* INTERNAL_INCLUDED_DEFERRED_VOLUMETRICS */
