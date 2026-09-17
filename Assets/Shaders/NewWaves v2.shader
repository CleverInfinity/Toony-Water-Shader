Shader "Custom/NewWavesv2"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (1,1,1,1)
		_DeepColor("Deep Color", Color) = (1,1,1,1)

		_MainNormal("Main Normal", 2D) = "white" {}
		_SecondaryNormal("Secondary Normal", 2D) = "white" {}
		_Shininess("Shininess", Range(1.0, 50.0)) = 6.85

		_WaveHeight("Wave Height", Range(0.0, 1.1)) = 0.5
        _WaveSpeed("Wave Speed", Range(0.0, 10.0)) = 1.8
		_WaveSteepness("Wave Steepness", Range(0.0, 0.5)) = 0.5
		_WaveLength("Wave Length", Range(1.0, 10.0)) = 10
		_WaveDirection("Wave Direction", Vector) = (1, 1, 0, 0)

		_WaveNumber("Number of Waves", Range(4, 6)) = 4

		_TessellationAmount("Tessellation Amount", Range(1.0, 128.0)) = 32
		_TessellationFadeStartDistance("Tessellation Fade Start Distance", float) = 10
		_TessellationFadeEndDistance("Tessellation Fade End Distance", float) = 100

		_DepthMaxDistance("Depth Max Distance", Float) = 5

		_CellSize("Cell Size", Range(0,4)) = 3
		_FoamWidth("Foam Width", Range(0.001, 1.0)) = 0.15
		_ShoreNoiseStrength("Shore Noise Strength", Range(0, 1)) = 0.15
		_ShoreWaveDepth("Shore Wave Depth", Range(0.01, 1.0)) = 0.64

		
	}
	SubShader
	{
		Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

		ZWrite on
		ZTest LEqual

		Pass{
			HLSLPROGRAM
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

			#pragma vertex vertex
            #pragma fragment fragment
			#pragma hull hull
			#pragma domain domain

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseColor;
				float4 _DeepColor;

				float4 _MainNormal_ST;
				float4 _SecondaryNormal_ST;

				float _Shininess;

				float _WaveHeight;
				float _WaveSpeed;
				float _WaveSteepness;
				float _WaveLength;
				float4 _WaveDirection;
				float _WaveNumber;

				float _TessellationAmount;
				float _TessellationFadeStartDistance;
				float _TessellationFadeEndDistance;

				float _DepthMaxDistance;

				float _CellSize;
				float _FoamWidth;
				float _ShoreNoiseStrength;
				float _ShoreWaveDepth;

			CBUFFER_END

			TEXTURE2D(_MainNormal);
			TEXTURE2D(_SecondaryNormal);
			SAMPLER(sampler_MainNormal);
			SAMPLER(sampler_SecondaryNormal);



			struct appdata
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;

				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
			};

			struct tessControlPoint{
				float3 positionWS : INTERNALTESSPOS;

				float2 uv : TEXCOORD0;
				half3 tspace0 : TEXCOORD2;
				half3 tspace1 : TEXCOORD3;
				half3 tspace2 : TEXCOORD4;
			};

			struct tessFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			struct t2f
			{
				float2 uv : TEXCOORD0;
				float2 noiseUV : TEXCOORD6;
				float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD1;
				float4 positionSS : TEXCOORD2;

				//for the TBN matrix wathever that means
				half3 tspace0 : TEXCOORD3;
				half3 tspace1 : TEXCOORD4;
				half3 tspace2 : TEXCOORD5;
				float waveHeight : TEXCOORD7;
			};




			tessControlPoint vertex(appdata input)
			{
				tessControlPoint output = (tessControlPoint)0;
				output.uv = input.uv;
				output.positionWS = TransformObjectToWorld(input.positionOS.xyz);

				float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
				float3 tangentWS = TransformObjectToWorldDir(input.tangentOS.xyz);
				//calculate a vector perpendicular to normal and tangent and then corrects its direction
				float3 bitangentWS = cross(normalWS, tangentWS) * input.tangentOS.w;


				output.tspace0 = half3(tangentWS.x, bitangentWS.x, normalWS.x);
				output.tspace1 = half3(tangentWS.y, bitangentWS.y, normalWS.y);
				output.tspace2 = half3(tangentWS.z, bitangentWS.z, normalWS.z);

				
				return output;
			}






			[domain("tri")]
            [outputcontrolpoints(3)]
            [outputtopology("triangle_cw")]
            [partitioning("integer")]
            [patchconstantfunc("patchConstantFunc")]
            tessControlPoint hull(InputPatch<tessControlPoint,3> patch,uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }

			tessFactors patchConstantFunc(InputPatch<tessControlPoint, 3> patch)
			{
				tessFactors output = (tessFactors)0;

				//get position of all verticies
				float3 triPos0 = patch[0].positionWS;
				float3 triPos1 = patch[1].positionWS;
				float3 triPos2 = patch[2].positionWS;

				//get position of all edge mid point
				float3 edgePos0 = 0.5f * (triPos1 + triPos2);
				float3 edgePos1 = 0.5f * (triPos0 + triPos2);
				float3 edgePos2 = 0.5f * (triPos1 + triPos0);

				//get camera position
				float3 camPos = _WorldSpaceCameraPos;

				float dist0 = distance(edgePos0, camPos);
				float dist1 = distance(edgePos1, camPos);
				float dist2 = distance(edgePos2, camPos);

				float fadeDist = _TessellationFadeEndDistance - _TessellationFadeStartDistance;


                float edgeFactor0 = saturate(1.0f - (dist0 - _TessellationFadeStartDistance) / fadeDist);
                float edgeFactor1 = saturate(1.0f - (dist1 - _TessellationFadeStartDistance) / fadeDist);
                float edgeFactor2 = saturate(1.0f - (dist2 - _TessellationFadeStartDistance) / fadeDist);

				output.edge[0] = max(edgeFactor0 * _TessellationAmount, 1);
                output.edge[1] = max(edgeFactor1 * _TessellationAmount, 1);
                output.edge[2] = max(edgeFactor2 * _TessellationAmount, 1);
                output.inside = (output.edge[0] + output.edge[1] + output.edge[2]) / 3.0f;

				return output;
			}





			
			///Hash function to get random variable for each waves based on their index as a seed
			static const float HASH_K = 43758.5453123;
			float hash1(float n)
			{
				return frac(sin(n) * HASH_K);
			}
			//1D -> 2D
			float hash1(float2 p)
			{
				return hash1(dot(p, float2(12.9898, 78.233)));
			}
			// 3D -> 1D
			float hash1(float3 p)
			{
				return hash1(dot(p, float3(12.9898, 78.233, 37.719)));
			}
			// 2D -> 2D  (replaces old "randomfloat2")
			float2 hash2(float2 p)
			{
				return frac(sin(float2(dot(p, float2(127.1, 311.7)),dot(p, float2(269.5, 183.3)))) * HASH_K);
			}
			// 3D -> 3D  (replaces old "randomfloat3")
			float3 hash3(float3 p)
			{
				return frac(sin(float3(dot(p, float3(12.989, 78.233, 37.719)),dot(p, float3(39.346, 11.135, 83.155)),dot(p, float3(73.156, 52.235, 9.151)))) * HASH_K);
			}



			//Calculate GerstnerWaves from Nvidia Equation 9
			float3 GerstnerWaves(float3 positionWS,float2 direction, float waveSpeed, float waveHeight, float waveSteepness, float waveLength){
				waveLength = 2.0 * PI /waveLength;
				float x =  2 * waveSteepness * waveHeight * direction.x * cos(waveLength * dot(direction,positionWS.xz) + (_Time.y * waveSpeed));
				float z = 2* waveSteepness * waveHeight * direction.y * cos(waveLength * dot(direction,positionWS.xz) + (_Time.y * waveSpeed));
				float y = waveHeight * sin(waveLength * dot(direction,positionWS.xz) + (_Time.y * waveSpeed));
				return float3(x,y,z);
			}

			float3 SumGerstnerWaves(float3 positionWS)
			{
				//simple sin wave with NVIDIA 8a equation
				//float waveDispalcement = 2 * _WaveHeight * pow((sin(positionWS.x + positionWS.z + _Time.y * _WaveSpeed)+1)/2,2.5);
				
				//create _WaveNumber number of waves and add variation to them
				float3 waveDispalcement = float3(0,0,0);
				for (int i = 0; i < (int)_WaveNumber; i++)
				{
					float fi = (float)i;
    
					float angle = hash1(fi) * 6.28318; // direction
					float2 dir = normalize(float2(cos(angle), sin(angle)));
					float lenVar = lerp(0.8, 1.2, hash1(fi * 2.0 + 7.0));  
					float speedVar = lerp(0.8, 1.2, hash1(fi * 3.0 + 13.0));
    
					waveDispalcement += GerstnerWaves(positionWS, dir, _WaveSpeed * speedVar, _WaveHeight / _WaveNumber, _WaveSteepness, _WaveLength * lenVar);
				}

				return waveDispalcement;
			}






			[domain("tri")]
			t2f domain(tessFactors factors, OutputPatch<tessControlPoint, 3> patch, float3 barycentricCoordinates : SV_domainLocation)
			{
				t2f output = (t2f)0;

				float3 positionWS = patch[0].positionWS * barycentricCoordinates.x + patch[1].positionWS * barycentricCoordinates.y + patch[2].positionWS * barycentricCoordinates.z;
				float2 uv = patch[0].uv * barycentricCoordinates.x + patch[1].uv * barycentricCoordinates.y + patch[2].uv * barycentricCoordinates.z;
				
				half3 tspace0 = patch[0].tspace0 * barycentricCoordinates.x + patch[1].tspace0 * barycentricCoordinates.y + patch[2].tspace0 * barycentricCoordinates.z;
                half3 tspace1 = patch[0].tspace1 * barycentricCoordinates.x + patch[1].tspace1 * barycentricCoordinates.y + patch[2].tspace1 * barycentricCoordinates.z;
                half3 tspace2 = patch[0].tspace2 * barycentricCoordinates.x + patch[1].tspace2 * barycentricCoordinates.y + patch[2].tspace2 * barycentricCoordinates.z;
				
				float3 waveDisplacement = SumGerstnerWaves(positionWS);
                float3 newPositionWS = positionWS + waveDisplacement;


				output.uv = uv;
                output.positionWS = newPositionWS;
                output.positionCS = TransformWorldToHClip(newPositionWS);
				output.positionSS = ComputeScreenPos(output.positionCS);

                output.tspace0 = tspace0;
                output.tspace1 = tspace1;
                output.tspace2 = tspace2;


				return output;
			}



			float3 voronoiNoise(float3 value){
				float3 baseCell = floor(value);

				float minDistToCell = 10.0;
				float minEdgeDistance = 10.0;

				float3 toClosestCell;
				float3 closestCell;

				for(int x = -1; x<=1; x++)
				{
					for(int y = -1 ; y <= 1 ; y++ )
					{
						for(int z = -1; z<= 1; z++){
							float3 cell = baseCell + float3(x,y,z);
							float3 cellPosition = cell + float3(hash3(cell));
							float3 toCell = cellPosition - value;
							float distToClosestCell = length(toCell);

							if(distToClosestCell<minDistToCell){
								minDistToCell = distToClosestCell;
								closestCell = cell;
								toClosestCell = toCell;
							}
						}
					}
				}
				for(int x1 = -1; x1<=1; x1++)
				{
					for(int y1 = -1 ; y1 <= 1 ; y1++ )
					{
						for(int z1 = -1; z1<= 1; z1++){
							float3 cell = baseCell + float3(x1, y1 ,z1);
							float3 cellPosition = cell + hash3(cell);
							float3 toCell = cellPosition - value;

							float3 diffToClosestCell = abs(closestCell - cell);
							bool isClosestCell = diffToClosestCell.x + diffToClosestCell.y + diffToClosestCell.z < 0.1;
							if(!isClosestCell){
								float3 toCenter = (toClosestCell + toCell) * 0.5;
								float3 cellDifference = normalize(toCell - toClosestCell);
								float edgeDistance = dot(toCenter, cellDifference);
								minEdgeDistance = min(minEdgeDistance, edgeDistance);
							}
						}
					}
				}
				float3 cellRandom = hash3(closestCell);
				return float3(minDistToCell, cellRandom.x, minEdgeDistance);
			}






			float4 fragment(t2f input) : SV_TARGET
			{
				//-- Normal Maps --
				//uv displaced in time	 to scorll 2 normals maps differently
				float2 uv1 =  input.uv + _Time.y * float2(0.025, 0.0); 
				float2 uv2 = input.uv + _Time.y * float2(-0.0123, 0.05); 
				half3 normalTS1 = UnpackNormal(SAMPLE_TEXTURE2D(_MainNormal, sampler_MainNormal, uv1)); //SAMPLE_TEXTURE2D get the texture color
				half3 normalTS2 = UnpackNormal(SAMPLE_TEXTURE2D(_SecondaryNormal, sampler_SecondaryNormal, uv2)); //UnpackNormal interprets that texture as a normal map
				//combine both normal maps
				half3 blendedNormalTS = normalize(half3(normalTS1.xy + normalTS2.xy, normalTS1.z * normalTS2.z));
					
				//from tangent space to world space
				half3 normalWS;	
				normalWS.x = dot(input.tspace0, blendedNormalTS);
				normalWS.y = dot(input.tspace1, blendedNormalTS);
				normalWS.z = dot(input.tspace2, blendedNormalTS);
					
				//-- calculate the specular	--
				Light light = GetMainLight();
			
				float3 viewDirWS = GetWorldSpaceViewDir(input.positionWS);
				float3 H = normalize(light.direction + viewDirWS);
				float3 specular = pow(saturate(dot(normalWS, H)), _Shininess) * light.color;
					
				//calculate the lightAmount
					
				half3 lightAmount = LightingLambert(light.color, light.direction, normalWS.xyz);


				//-- calculate Depth Based coloring --
				// the more 2 is big the smaller screenUV to find where on screen it should appear
				float2 screenUV = input.positionSS.xy / input.positionSS.w;
				//get depth based on the camera to get how far into the screen
				float rawDepth = SampleSceneDepth(screenUV);
				//reconstruct world pos
				float3 sceneWorldPos = ComputeWorldSpacePosition(screenUV, rawDepth, UNITY_MATRIX_I_VP); 

				//find the difference between the water and whats underneath
				float depthDifference = input.positionWS.y - sceneWorldPos.y;
				float depthFade = saturate(depthDifference  / _DepthMaxDistance);
				float shoreMask = 1.0 - depthFade;
		
				half3 finalColor = lerp(_DeepColor.rgb, _BaseColor.rgb , shoreMask);


				//-- voronoi noise --
				float3 value = input.positionWS.xyz / _CellSize;
				value.y = _Time.y * 0.05;
				//make voronoi less straight
				value.xz += float2(sin(value.x * 3.7 + value.y * 2.1), sin(value.z * 4.3 + value.x * 1.7)) * 0.15;
				float3 noise = voronoiNoise(value);
				float border = 1 - smoothstep(0.005 - length(fwidth(value)),  0.005 + length(fwidth(value)), noise.z);

				//-- shoreline foam --
				float shoreFoam = 1.0 - smoothstep(0.0,_FoamWidth,depthFade);

				//-- shoreline waves --
				float distortedDepth = saturate(depthFade + (noise.x - 0.5) * _ShoreNoiseStrength);
				float wavePosition = distortedDepth * 5; //for 5 waves
				wavePosition -= _Time.y * 0.25; //move at speed of 0.25
				float wave = frac(wavePosition);
				wave = 1.0 - smoothstep(0.0, 0.08, wave);
				float waveDepthMask = 1.0 - smoothstep(0.0,_ShoreWaveDepth,depthFade);
				wave *= waveDepthMask;  //prevents waves from continuing into the ocean 
				wave *= smoothstep(0.15, 0.8, noise.y); // make the foam less perfectly uniform using Voronoi noise

				float totalFoam = max(shoreFoam, wave);
				
				finalColor = lerp(finalColor, float3(1,1,1), totalFoam +  border * 0.15);
				

				return (float4(finalColor,0) * float4(lightAmount, 1) + float4(specular, 0));
			}

			ENDHLSL
		}
	}
}