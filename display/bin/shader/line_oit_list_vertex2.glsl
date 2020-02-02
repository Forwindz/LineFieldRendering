#version 460


layout(location = 0) in vec3 position;
layout(location = 1) in vec3 in_tangent;
layout(location = 2) in vec4 in_color;
layout(location = 3) in uint in_segID;

layout(binding = 6, r32f) uniform readonly imageBuffer uRealAlphaList;

out VS_OUT{
	vec3 tangent;	//direction 3d, normalized
	vec4 color;		//line color
	vec3 normal;	//at the edge of line, normal, normalized
	vec3 c_normal;	//at the center of line, normal, normalized
	vec3 real_pos;
	vec4 scr_pos;
	flat int segID;
} vs_out;

uniform mat4 mvp_matrix;
uniform vec3 eye_pos;
uniform uint ubiasID;


void main()
{
	//load alpha
	const float alpha = imageLoad(uRealAlphaList, int(in_segID)).x;
	const vec4 real_color = vec4(in_color.xyz, alpha);
	//set data
	vec4 spos = mvp_matrix * vec4(position, 1.0f);
	vs_out.scr_pos = spos;
	vs_out.real_pos = position;
	vs_out.color = real_color;
	vs_out.tangent = in_tangent;

	//point---->eye
	vec3 ep = normalize(eye_pos - position);
	vec3 dir = cross(ep, in_tangent);
	vs_out.normal = dir;
	vs_out.c_normal = cross(in_tangent, dir);
	vs_out.segID = int(in_segID + ubiasID);
}
