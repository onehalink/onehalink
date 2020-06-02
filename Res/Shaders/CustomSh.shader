Shader "Unlit/CustomSh"
{
    Properties{
        //[Header("基础贴图")]
        [NoScaleOffcut]_MainTex("Main Tex|基础贴图", 2D) = "white"{}
        //[Header("基础颜色")]
        _MainColor("Main Color|基础颜色", Color) = (1, 1, 1, 1)
        //[Header("高光的颜色")]
        _Specular("Specular|高光的颜色", Color) = (1, 1, 1, 1)
        //[Header("高光区域控制参数")]
        _Gloss("Gloss|高光区域控制参数", Range(0.0, 1000.0)) = 600
        //[Header("阴影（暗面）颜色")]
        _ShadowColor("Shadow Color|阴影（暗面）颜色", Color) = (0.7, 0.7, 0.8, 1)
        //[Header("阴影（暗面）占比区域")]
        _ShadowArea("Shadow Area|阴影（暗面）占比区域", Range(0.0, 1.0)) = 0.5
        
        [Space(20)]
        //[Header("轮廓线颜色")]
        _OutlineColor("Outline Color|轮廓线颜色", Color) = (0, 0, 0, 1)
        //[Header("轮廓线宽度")]
        _OutlineWidth("Outline Width|轮廓线宽度", Range(0.0, 1.0)) = 0.003

        [Space(20)]
        //[Header("Fresnel 系数")]
        _FresnelParameter("Fresnel Parameter|Fresnel 系数", Range(0.0, 1.0)) = 0.5
        //[Header("Fresnel Effect 颜色控制参数")]
        _FrensnelEffectColor("Fresnel Effect Color|Fresnel Effect 颜色控制参数", Color) = (1, 1, 1, 1)
        [Enum(Off,0,On,1)]_FresnelEffectToggle("Fresnel Effect Toggle|打开/关闭Fresnel Effect",Float) = 1
    }

    SubShader{
        Tags{
            "RenderType" = "Opaque"
        }
        LOD 200

        Pass{
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 _OutlineColor;
            fixed _OutlineWidth;

            struct appdata{
                float4 vertex : POSITION;
                float3 normal : NORMAL;

            };
            struct v2f{
                float4 pos : SV_POSITION;
                fixed3 col : COLOR;
            };

            v2f vert(appdata v){
                v2f o;

                float4 pos = v.vertex + float4(v.normal, 0) * _OutlineWidth;
                o.pos = UnityObjectToClipPos(pos);
                o.col = _OutlineColor.rgb;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                return fixed4(i.col, 1);
            }
            ENDCG
        }

        Pass{
            Tags{
                "LightMode" = "ForwardBase"
            }

            Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed4 _MainColor;
            fixed4 _ShadowColor;
            fixed _ShadowArea;

            fixed _FresnelParameter;
            fixed4 _FrensnelEffectColor;
            float _FresnelEffectToggle;

            float _Gloss;
            fixed4 _Specular;

            struct appdata{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(appdata v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                fixed3 halfDir = normalize(worldViewDir + worldLightDir);

                float NDotL = dot(worldNormal, worldLightDir);

                fixed3 col = NDotL > _ShadowArea ? _MainColor.rgb : _ShadowColor.rgb;

                fixed3 texCol = tex2D(_MainTex, i.uv);
                fixed3 fresnelResult = _FresnelParameter +(1-_FresnelParameter) * pow(1- dot(worldNormal, worldViewDir), 5);
                fixed3 spec = pow(saturate(dot(halfDir, worldNormal)), _Gloss);


                col = col * texCol + fresnelResult * _FrensnelEffectColor*_FresnelEffectToggle + spec * _Specular.rgb;
                return fixed4(col, 1);
            }
            ENDCG

            
        }
    }
}
