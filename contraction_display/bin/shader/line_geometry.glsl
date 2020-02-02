#version 460
layout(lines_adjacency) in;
layout(triangle_strip, max_vertices=4) out;

in VS_OUT{
	vec3 tangent;	//direction 3d, normalized
	vec4 color;		//line color
	vec3 normal;	//at the edge of line, normal, normalized
	vec3 c_normal;	//at the center of line, normal, normalized
	vec3 real_pos;	//real position in 3D Dimen
	vec4 scr_pos;
	flat uint pointID;
} gs_in[4];

out GS_OUT{
	vec3 tangent;
	vec4 color;
	vec3 normal;
	vec3 c_normal;
	vec3 real_pos;
	flat uint pointID;
	float sign;		//used for calulating normals. 
					//0~0.5~1 pi: normal -> c_normal -> -normal
} gs_out;
uniform float line_width;
void emit(const int index,const float mult,const vec2 dir_2d)
{
	gs_out.tangent=gs_in[index].tangent;
	gs_out.color=gs_in[index].color;
	gs_out.normal=gs_in[index].normal;
	gs_out.pointID = gs_in[index].pointID;
	gs_out.c_normal=gs_in[index].c_normal;
	gs_out.real_pos = gs_in[index].real_pos;
	gs_out.sign=mult*0.5f*3.1415926535f;
	vec4 poss = gs_in[index].scr_pos / gs_in[index].scr_pos.w;
	gl_Position = poss + vec4(mult*dir_2d, 0.0f, 0.0f);//*(-poss.z+2.0f);
	EmitVertex();
}
void main()
{
	if (gs_in[1].scr_pos.w < 1 || gs_in[2].scr_pos.w < 1)return;
	vec2 tdir_2d = line_width * normalize((gs_in[0].scr_pos / gs_in[0].scr_pos.w - gs_in[2].scr_pos / gs_in[2].scr_pos.w).xy);
	vec2 dir_2d1=vec2(-tdir_2d.y,tdir_2d.x);
	tdir_2d = line_width * normalize((gs_in[1].scr_pos / gs_in[1].scr_pos.w - gs_in[3].scr_pos / gs_in[3].scr_pos.w).xy);
	vec2 dir_2d2 = vec2(-tdir_2d.y, tdir_2d.x);
	emit(1, 1, dir_2d1);
	emit(1, -1, dir_2d1);
	emit(2, 1, dir_2d2);
	emit(2, -1, dir_2d2);
}