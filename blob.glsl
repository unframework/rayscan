#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

float distanceToSphere(vec3 pt, vec3 ctr, float radius) {
    return distance(pt, ctr) - radius;
}

float smin(float a, float b, float k) {
    float res = exp(-k * a) + exp(-k * b);
    return -log(res) / k;
}

float rawDistanceToObject(vec3 pt) {
    return smin(
        distanceToSphere(pt, vec3(-0.500 + 0.05 * sin(u_time * 7.0),0.000,-5.000), 1.5),
        distanceToSphere(pt, vec3(1.223,1.123,-4.731), 1.2 + 0.05 * sin(u_time * 2.5) * sin(u_time * 17.0)),
        5.0
    );
}

vec3 displacer(vec3 pt) {
    return 0.0 * vec3(
        sin(pt.x / 0.3) *
        sin(pt.y / 0.2) *
        sin(pt.z / 0.2)
    );
}

float distanceToObject(vec3 pt) {
    return rawDistanceToObject(pt + displacer(pt));
}

vec3 calculateNormal(in vec3 pt) {
    vec2 eps = vec2(1.0, -1.0) * 0.0005;

    return normalize(eps.xyy * distanceToObject(pt + eps.xyy) +
                     eps.yyx * distanceToObject(pt + eps.yyx) +
                     eps.yxy * distanceToObject(pt + eps.yxy) +
                     eps.xxx * distanceToObject(pt + eps.xxx));
}

void main() {
    vec2 st = (gl_FragCoord.xy) / u_resolution.xy - vec2(0.5, 0.5);
    st.x *= u_resolution.x / u_resolution.y;

    vec3 rayOrigin = vec3(0.0, 0.0, 1.0);
    vec3 rayDirection = normalize(vec3(st, 0.0) - rayOrigin);

    float distance;
    float photonPosition = 1.0;

    for (int i = 0; i < 100; i += 1) {
        distance = distanceToObject(rayOrigin + rayDirection * photonPosition);
        photonPosition += distance;

        if (distance < 0.01) {
            break;
        }
    }

    if (distance > 0.01) {
        gl_FragColor = vec4(vec3(0.140,0.120,0.106), 1.000);
    } else {
        vec3 intersectionNormal = calculateNormal(rayOrigin + rayDirection * photonPosition);
        vec3 rayCross = cross(intersectionNormal, rayDirection);

        float mainIntensity = -dot(intersectionNormal, rayDirection);
        float backIntensity = max(0.0, dot(rayCross, rayCross) - 0.4) / 0.6;

        float layer = step(0.08, mod(photonPosition / 0.15, 1.0));

        gl_FragColor = vec4(layer * mainIntensity * mainIntensity * vec3(0.3,0.45,0.6) + (backIntensity * backIntensity) * vec3(0.2,0.3,0.4), 1.000);
    }
}
