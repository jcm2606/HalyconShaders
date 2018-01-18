/*
  JCM2606.
  HALCYON 2.
  PLEASE READ "LICENSE.MD" BEFORE EDITING THIS FILE.
*/

/* CONST */
/* VARYING */
varying vec2 uvCoord;

varying vec4 colour;

varying vec3 view;
varying vec3 world;
varying vec3 shadow;

flat(vec2) entity;
flat(float) objectID;

/* UNIFORM */
uniform sampler2D texture;

/* GLOBAL */
/* STRUCT */
/* INCLUDE */
/* FUNCTION */
/* MAIN */
void main() {
  vec4 albedo = texture2D(texture, uvCoord) * colour;

  if(compare(objectID, OBJECT_WATER)) albedo = vec4(1.0);

  gl_FragData[0] = toLDR(albedo, dynamicRangeShadow);
  gl_FragData[1] = vec4(vec3(0.0), objectID * objectIDMaxRCP);
}