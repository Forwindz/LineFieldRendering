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
    const int beginOffset1=beginOffset+1;
    const int endOffset     = imageLoad(uSegOffsetList,localX+1).x;
    const int endOffset1=endOffset-1;
    //transform data to float
    for(int i=beginOffset;i<endOffset;i++)
    {
        const float v = uintBitsToFloat(imageLoad(uAlphaList,i).x);
        imageStore(uTempAlphaList,i,vec4(v));
		imageStore(uAlphaList, i, uvec4(floatBitsToUint(1.0f)));
    }
	
    for(int tt=0;tt<fp.times;tt++)
    {
        //smooth
        for(int i=beginOffset1;i<endOffset1;i++)
        {
            float vc=imageLoad(uTempAlphaList,i).x;
            const float vl1=imageLoad(uTempAlphaList,i-1).x;
            const float vr1=imageLoad(uTempAlphaList,i+1).x;
            vc=(vc+vl1+vr1)/3.0f;
            imageStore(uTempAlphaList,i,vec4(vc));
        }
        //smooth head and tail
        float vc=imageLoad(uTempAlphaList,beginOffset).x;
        float v0=imageLoad(uTempAlphaList,beginOffset1).x;
        vc=(vc+v0)*0.5f;
        imageStore(uTempAlphaList,beginOffset,vec4(vc));

        vc=imageLoad(uTempAlphaList,endOffset1).x;
        v0=imageLoad(uTempAlphaList,endOffset).x;
        vc=(vc+v0)*0.5f;
        imageStore(uTempAlphaList,endOffset,vec4(vc));
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