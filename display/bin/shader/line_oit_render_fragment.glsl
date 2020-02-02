#version 430 core

struct ImportanceParams
{
	float q, r, l;
};

uniform ImportanceParams params;

//buffers
layout(binding = 0, r32ui)		uniform					uimage2DMS		uHeadPointer;
layout(binding = 1, rgba32ui)	uniform		readonly	uimageBuffer	uListContent;

layout(binding = 3, r32f)		uniform		readonly	imageBuffer		ug;
layout(binding = 4, r32ui)		uniform					uimageBuffer	uAlphaList;

//output
layout(location = 0)out vec4 outputColor;
layout(location = 1)out vec4 outputID;
//layout(location = 1)out float outputDepth;

//local variables
const int MAX_FRAG = 128;
uvec4 frags[MAX_FRAG];
float fg[MAX_FRAG];//tempory store g value

void main()
{
	//load fragments
	/*
	vec4
	depth,color,segID,next
	*/
	
	uint curInd;
	uint fragCount = 0;
	curInd = imageLoad(uHeadPointer, ivec2(gl_FragCoord).xy,gl_SampleID).x;
	imageStore(uHeadPointer, ivec2(gl_FragCoord).xy, gl_SampleID,uvec4(0));
	while (curInd != 0 && fragCount < MAX_FRAG)
	{
		uvec4 data = imageLoad(uListContent, int(curInd));
		//swap curInd & nextInd,
		//therefore, in frags, we store current Index in w.
		curInd = data.w;
		frags[fragCount++] = data;
	}
	
	//sort fragments by depth
	//selection sort
	if (fragCount > 1)
	{
		const uint fragCountm1 = fragCount - 1;
		
		for (uint i = 0; i < fragCountm1; i++)
		{
			uint minInd = i;
			float minDepth = uintBitsToFloat(frags[i].x);
			for (uint j = i + 1; j < fragCount; j++)
			{
				const float depth2 = uintBitsToFloat(frags[j].x);
				if (minDepth > depth2)
				{
					minDepth = depth2;
					minInd = j;
				}
			}
			//swap
			if (minInd != i)
			{
				const uvec4 temp = frags[i];
				frags[i] = frags[minInd];
				frags[minInd] = temp;
			}
		}
		
	}
	/*
	for (uint i = 0; i < fragCountm1; i++)
	{
		const uint maxInd = fragCountm1 - i;
		for (uint j = 0; j < maxInd; j++)
		{
			const float depth1 = uintBitsToFloat(frags[j].x);
			const float depth2 = uintBitsToFloat(frags[j+1].x);
			if (depth1 > depth2)
			{
				const uvec4 temp = frags[j];
				frags[j] = frags[j+1];
				frags[j+1] = temp;
			}
		}
	}
	*/
	
	//blend color
	vec4 resultColor = vec4(0);
	float leftEnergy = 1.0f;
	float gsum = 0.0f;
	float alpha = 0.0f;
	//float as = 0;
	//float depth = 1.0f;
	for (uint i = 0; i < fragCount; i++)
	{
		const uvec4 data = frags[i];

		//fetch g and store in local
		fg[i] = imageLoad(ug, int(data.z)).x;
		gsum += fg[i] * fg[i];
		//color
		const vec4 color = unpackUnorm4x8(data.y);
		alpha = color.w;
		resultColor += color * leftEnergy * alpha;
		leftEnergy *= (1 - alpha);
		//if (leftEnergy < 0.1f && depth>0.99f)depth = uintBitsToFloat(frags[i].x);
	}
	//outputDepth = depth;
	resultColor += leftEnergy * vec4(1);//add background color
	

	//compute alpha for next frame
	float gfront_sum = 0;
	float gbehind_sum = 0;
	
	for (uint i = 0; i < fragCount; i++)
	{
		gbehind_sum = gsum - fg[i] * fg[i] - gfront_sum;
		float alphaData = 1.0f / (1.0f + pow((1 - fg[i]), 2 * params.l)*
			(gbehind_sum*params.q + params.r*gfront_sum));
		imageAtomicMin(uAlphaList, int(frags[i].z), floatBitsToUint(alphaData+0.001f));
		gfront_sum += fg[i] * fg[i];
	}
	
	
	outputColor = resultColor.xyzw;
	
	if (fragCount == 0)
	{ 
		outputID = vec4(0, 0, 0, 0);
	}
	else
	{
		int segid = int(frags[0].z);
		int innerid = int(frags[0].z & 0xFFF00000)>>20;
		outputID = vec4(
			(10 % 100) / 100.0f,
			(segid / 10000 % 100) / 100.0f,
			(segid / 100 % 100) / 100.0f,
			(segid % 100) / 100.0f
		);
	}
}