#version 430 core  

struct FadeParam{
	float speed;
    int times;
    int maxSZ;
};

uniform FadeParam fp;

layout(binding = 4, r32ui)		uniform					uimageBuffer	uAlphaList;     //alpha from fragment shader
layout(binding = 5, r32f)		uniform					imageBuffer	    uTempAlphaList; //alpha tempory storage
layout(binding = 6, r32f)		uniform					imageBuffer	    uRealAlphaList; //alpha current the shader use while rendering
layout(binding = 7, r32i)		uniform		readonly	iimageBuffer	uSegOffsetList; //offsets

layout(local_size_x = 32) in;

void main()
{
	int localX = int(gl_GlobalInvocationID);
    if(fp.maxSZ<localX)return;
    const int beginOffset   = imageLoad(uSegOffsetList,localX).x;
    const int endOffset     = imageLoad(uSegOffsetList,localX+1).x;
    //transform data to float
    float minv=10.0f;
    for(int i=beginOffset;i<endOffset;i++)
    {
        const float v = uintBitsToFloat(imageLoad(uAlphaList,i).x);
		imageStore(uAlphaList, i, uvec4(floatBitsToUint(1.0f)));
        if(v<minv)minv=v;
    }
    const vec4 minv4=vec4(minv);
    for(int i=beginOffset;i<endOffset;i++)
    {
        imageStore(uTempAlphaList, i, minv4);
    }
	
    //fade to current alpha
    for(int i=beginOffset;i<endOffset;i++)
    {
        const float v_real = imageLoad(uRealAlphaList,i).x;
        const float v_goal = imageLoad(uTempAlphaList,i).x;
		const float v_cur = v_real + (v_goal - v_real)*fp.speed*1.0f;
        imageStore(uRealAlphaList,i,vec4(v_cur));
    }
}