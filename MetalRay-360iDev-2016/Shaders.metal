#include <metal_stdlib>
using namespace metal;

//_____________________________________________________________________________/ objects

struct ViewInfo {
	int objectCount;
	float3 location, halfXYZ, upVector, vTM;
	float pixelPerUnitDistance, halfHeight, theta, phi;
};

enum HitResponseType {
	bounce, color, none
};

enum MaterialType {
	lambertian, metalic, dialectric
};

struct Ray {
	float3 origin = float3(), direction = float3();
};

struct HitResponse {
	HitResponseType type = none;
	float distance = 0;
	Ray ray = Ray();
	float3 color = float3();
};

struct Background {
	float3 gradientDirection = float3(0, -1, 0);
	float3 startColor = float3(0.5, 0.7, 1);
	float3 endColor = float3(0, 0, 0);
	
	HitResponse hitTest(Ray passingRay) {
		float t = (passingRay.direction.y + 1) / 2;
		HitResponse response;
		response.type = color;
		response.distance = 1000000;
		response.color = (t * startColor) + ((1-t) * endColor);
		return response;
	}
};

struct Sphere {
	MaterialType materialType = lambertian;
	float3 color = float3(1);
	float3 center = float3(0);
	float radius = 0;
	float fuzz = 0;
	float indexOfRefraction = 1;
};

//_____________________________________________________________________________/ functions

static float schlick(float cosine, float indexOfRefraction) { // ~ 7% of total compute time here
	float r0 = (1 - indexOfRefraction) / (1 + indexOfRefraction);
	r0 *= r0;
	return r0 + ((1 - r0) * pow(1 - cosine, 5));
}

static HitResponse lightResponse(Sphere sphere, Ray passingRay, float3 normal, float3 surfaceIntersection,
								 float3 color, float3 randomInteriorPoint, float reflectionThreshold) {
	
	float3 reflected = reflect(passingRay.direction, normal);
	
	HitResponse response = HitResponse();
	response.type = bounce;
	response.distance = distance(passingRay.origin, surfaceIntersection);
	response.color = color;
	
	Ray ray;
	ray.origin = surfaceIntersection;
	
	switch (sphere.materialType) {
			
		case lambertian:
			//		case metalic:
			//		case dialectric:
			ray.direction = normal + randomInteriorPoint;
			response.ray = ray;
			
			return response;
			
		case metalic:
			ray.direction = reflected + min(sphere.fuzz, 1.0) * randomInteriorPoint;
			response.ray = ray;
			
			if (dot(ray.direction, normal) < 0) {
				return HitResponse();
			}
			
			return response;
			
		case dialectric: // 20% of total computer time for this case
			
			ray.direction = reflected; // unless it gets refracted, which is the rest of this case
			response.color = float3(1);
			
			float3 outwardNormal = normal;
			float nRatio = sphere.indexOfRefraction;
			float cosine;
			
			
			if (0 < dot(passingRay.direction, normal)) {
				cosine = sphere.indexOfRefraction * dot(passingRay.direction, normal) / length(passingRay.direction);
			}
			else {
				outwardNormal = -1 * normal;
				nRatio = 1 / sphere.indexOfRefraction;
				float len = length(passingRay.direction);
				cosine = -1 * dot(passingRay.direction, normal) / len;
			}
			
			float3 uv = normalize(passingRay.direction);
			float dt = dot(uv, outwardNormal);
			float discriminant = 1 - (nRatio * nRatio * (1 - dt * dt));
			
			if (0 < discriminant) {
				float reflectionProbability = schlick(cosine, sphere.indexOfRefraction);
				
				if (reflectionProbability < reflectionThreshold) {
					ray.direction = (nRatio * (passingRay.direction - normal * dt)) - (normal * sqrt(discriminant));
				}
			}
			
			response.ray = ray;
			
			return response;
	}
	
	// really this should never happen.
	
	response.ray = ray;
	return response;
}

static HitResponse hitTest(Sphere sphere, Ray passingRay, float2 limits, float3 randomInteriorPoint, float rando) {
	
	float3 centerToRayOrigin = passingRay.origin - sphere.center;
	float c = length_squared(centerToRayOrigin) - sphere.radius * sphere.radius;
	
	bool rayOriginWithinSphere = (0 < c);
	bool rayDirectionTowardSphere = (0 < dot(passingRay.direction, centerToRayOrigin));
	
	if (!rayOriginWithinSphere && !rayDirectionTowardSphere) {
		return HitResponse();
	}
	
	float a = length_squared(passingRay.direction);
	float b = dot(centerToRayOrigin, passingRay.direction);
	
	float discriminant = b * b - a * c;
	
	if (discriminant < 0) {
		return HitResponse();
	}
	
	float partA = -1 * b / a;
	float partB = sqrt(discriminant) / a;
	float solution = partA - partB;
	
	if ((solution < limits.x) || (limits.y < solution)) {
		solution = partA + partB;
	}
	
	if ((solution < limits.x) || (limits.y < solution)) {
		return HitResponse();
	}
	
	float3 surfaceIntersection = passingRay.origin + passingRay.direction * solution;
	float3 normal = normalize(surfaceIntersection - sphere.center);
	
	return lightResponse(sphere, passingRay, normal, surfaceIntersection, sphere.color, randomInteriorPoint, rando);
}

static float3 rotateVector(float3 vector, float3 r, float theta) {
	float3 uParallel = dot(r, vector) * r;
	float3 uPerpendicular = vector - uParallel;
	return uParallel + cos(theta) * uPerpendicular + sin(theta) * cross(r, vector);
}

static Ray rayForPixel(float2 z, float2 randomXYNudge, ViewInfo viewInfo) {
	
	float2 zScaled = float2((z.x + randomXYNudge.x) / viewInfo.pixelPerUnitDistance,
							viewInfo.halfHeight - (z.y + randomXYNudge.y) / viewInfo.pixelPerUnitDistance);
	
	float3 directionForPixelSimple = float3(zScaled.x, zScaled.y, 0) - viewInfo.halfXYZ;
	
	float3 vector = rotateVector(directionForPixelSimple, viewInfo.upVector, viewInfo.theta);
	
	if (0.0000001 < abs(viewInfo.phi)) {
		vector = rotateVector(vector, viewInfo.vTM, viewInfo.phi);
	}
	
	Ray returnRay;
	returnRay.origin = viewInfo.location;
	returnRay.direction = vector;
	
	return returnRay;
}

//_____________________________________________________________________________/ main shader

kernel void rayShader(const device Sphere* objectsIn    [[ buffer(0) ]],
					  const device ViewInfo* viewInfoIn [[ buffer(1) ]],
					  
					  const device float* randoms       [[ buffer(2) ]],
					  const device int* randomOffset    [[ buffer(3) ]],
					  
					  texture2d<float, access::write> output [[texture(0)]],
					  
					  uint2 upos [[thread_position_in_grid]]) {
	
	// internal info tracking
	int width = output.get_width();
	int height = output.get_height();
	ViewInfo viewInfo = viewInfoIn[0];
	float2 z = float2(upos.x, upos.y);
	
	// drawing setup
	Background background;
	float2 limits = float2(0.001, 1000);
	int blendingIterations = 20; // 75
	int bounceLimit = 10; // 50
	
	// stuff for randoms
	int randomSize = width * height * 3;
	int rindex = (upos.y * width + upos.x) * 3 + randomOffset[0];
	float reflectionThreshold = 1;
	float2 randomXYNudge = float2(0);
	float3 randomInteriorPoint = float3(0);
	int pIndex = rindex;
	
	float3 totalColor = float3(0);
	for (int iteration = 0; iteration < blendingIterations; iteration++) {
		
		bool rayIntercepted = false;
		bool bouncing = false;
		float3 colorFactor = float3(1);
		float3 colorContribution = float3(0);
		
		rindex += 3711;
		randomXYNudge = float2(randoms[rindex % randomSize], randoms[(rindex+1) % randomSize]);
		
		Ray emittedRay = rayForPixel(z, randomXYNudge, viewInfo);
		
		int bounceDownCount = 0;
		do {
			bouncing = false;
			
			int lockCounter = 0;
			do {
				lockCounter += 1;
				pIndex += 767;
				float r1 = randoms[pIndex     % randomSize];
				float r2 = randoms[(pIndex+1) % randomSize];
				float r3 = randoms[(pIndex+2) % randomSize];
				randomInteriorPoint = 2 * float3(r1, r2, r3) - float3(1);
			} while ((length_squared(randomInteriorPoint) >= 1) && (lockCounter < 100));
			
			reflectionThreshold = randoms[pIndex % randomSize];
			
			float closestDistance = 10000000;
			HitResponse closestResponse = HitResponse();
			
			for (int objectIndex = 0; objectIndex < viewInfo.objectCount; objectIndex++) {
				HitResponse hit = hitTest(objectsIn[objectIndex], emittedRay, limits, randomInteriorPoint, reflectionThreshold);
				if (hit.type != none) {
					float thisDistance = hit.distance;
					if (thisDistance < closestDistance) {
						closestDistance = thisDistance;
						closestResponse = hit;
					}
				}
			}
			
			if (closestResponse.type != none) {
				if (!bouncing) {
					switch (closestResponse.type) {
						case color:
							colorContribution = closestResponse.color;
							rayIntercepted = true;
							bouncing = false;
							break;
							
						case bounce:
							emittedRay = closestResponse.ray;
							colorFactor *= closestResponse.color;
							bounceDownCount += 1;
							bouncing = true;
							break;
							
						case none:
							break;
					}
				}
			}
		} while (bouncing && bounceDownCount < bounceLimit);
		
		if (!rayIntercepted && bounceDownCount < bounceLimit) {
			HitResponse backgroundHit = background.hitTest(emittedRay);
			colorContribution = backgroundHit.color;
		}
		
		totalColor += colorFactor * colorContribution;
	}
	
	totalColor /= (float)blendingIterations;
	
	output.write(float4(totalColor.x, totalColor.y, totalColor.z, 1), upos);
}
