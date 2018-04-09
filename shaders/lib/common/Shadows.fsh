/*
    Jcm2606.
    Halcyon.
    Please read "LICENSE.md" before editing this file.
*/

#if !defined INCLUDED_COMMON_SHADOWS
    #define INCLUDED_COMMON_SHADOWS

    #include "/lib/util/SpaceTransform.glsl"
    #include "/lib/util/ShadowTransform.glsl"

    float CompareShadowDepth(float depth, float comparison) { return saturate(1.0 - abs(comparison - depth) * float(shadowMapResolution)); }

    vec2 FindBlockers(const vec3 shadowPosition, const vec2 dither) {
        const int   samples    = 9;
        const float samplesRCP = rcp(samples);

        const float radius = 1.0e-3;

        vec2 blockers = vec2(0.0);

        for(int i = 0; i < samples; ++i) {
            vec2 coord = DistortShadowPositionProj(MapSpiral(i * dither.y + dither.x, samples * dither.y) * radius + shadowPosition.xy);

            blockers += vec2(
                texture2D(shadowtex1, coord.xy).x,
                texture2D(shadowtex0, coord.xy).x
            );
        }

        return blockers * samplesRCP;
    }

    vec3 CalculateShadowColour(const vec3 shadowPosition, const vec3 worldPosition, const vec2 spread, const vec2 dither) {
        const int   samples    = SHADOW_QUALITY;
        const float samplesRCP = rcp(samples);

        vec3 shadowWorldPosition = transMAD(shadowModelView, worldPosition);

        vec3 shadowColour = vec3(0.0);

        for(int i = 0; i < samples; ++i) {
            vec2 offset = MapSpiral(i * dither.y + dither.x, samples * dither.y);

            #if   PROGRAM == DEFERRED1
                vec3 coordBack  = vec3(DistortShadowPositionProj(offset * spread.x + shadowPosition.xy), shadowPosition.z);
                vec3 coordFront = vec3(DistortShadowPositionProj(offset * spread.y + shadowPosition.xy), shadowPosition.z);

                float depthFront = texture2D(shadowtex0, coordFront.xy).x;

                float shadowBack  = float(texture2D(shadowtex1, coordBack.xy).x > coordBack.z);//cutShadow(CompareShadowDepth(coordBack.z, texture2D(shadowtex1, coordBack.xy).x));
                float shadowFront = float(depthFront > coordFront.z);//cutShadow(CompareShadowDepth(coordFront.z, depthFront));

                vec4 colourSample     = texture2D(shadowcolor0, coordFront.xy);
                     colourSample.rgb = ToLinear(colourSample.rgb);

                vec3 shadowColourSample = (colourSample.rgb - 1.0) * (shadowBack * colourSample.a * abs(shadowFront - shadowBack)) + shadowBack;

                bool isWaterShadow = bool(texture2D(shadowcolor1, coordFront.xy).a);

                float waterDepth = depthFront * 8.0 - 4.0;
                      waterDepth = waterDepth * shadowProjectionInverse[2].z + shadowProjectionInverse[3].z;
                      waterDepth = shadowWorldPosition.z - waterDepth;

                if(isWaterShadow && waterDepth < 0.0)
                    shadowColourSample *= exp2(waterTransmittanceCoeff * ATMOSPHERICS_WATER_DENSITY * waterDepth);

                shadowColour += shadowColourSample;
            #elif PROGRAM == COMPOSITE0
                vec3 coordFront = vec3(DistortShadowPositionProj(offset * spread.y + shadowPosition.xy), shadowPosition.z);

                float shadowFront = cutShadow(CompareShadowDepth(coordFront.z, texture2D(shadowtex0, coordFront.xy).x));

                shadowColour += shadowFront;
            #endif
        }

        return shadowColour * samplesRCP;
    }

    vec3 CalculateShadows(const vec3 viewPosition, const vec2 dither) {
        const float spread = 200.0 * shadowDepthMult;

        const float minWidth = 0.0;
        const float maxWidth = 4.0;

        vec3 worldPosition  = ViewToWorldPosition(viewPosition);
        vec3 shadowPosition = WorldToShadowPosition(worldPosition);

        const float shadowBias = 2.5e-1 * shadowMapResolutionRCP;
        shadowPosition.z -= shadowBias;

        vec2 blockers  = FindBlockers(shadowPosition, dither);
             blockers  = abs(vec2(shadowPosition.z) - blockers);
             blockers *= spread;
             blockers  = clamp(blockers, vec2(minWidth), vec2(maxWidth));
             blockers *= 0.001;

        return CalculateShadowColour(shadowPosition, worldPosition, blockers, dither);
    }

#endif
