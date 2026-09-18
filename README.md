# Toony Water Shader

A Toony, Wind Waker inspired Water Shader in HLSL for Unity (URP). You can find the assets in “Assets/Shaders/New Waves v2.shader”. 

A development journal tracking my progress on this project is also included on WaterShaderJournal.pdf.
<img width="1452" height="639" alt="image" src="https://github.com/user-attachments/assets/3c7c2419-f930-4566-bee8-3a3aed050362" />

## Requirements

  - Unity (tested with 6000.3.5f2)
  - URP


## Features
- Two moving normal maps,
- 4 summed Gerstner Waves,
- Tessellation
- Specular and depth-based shading,
- Voronoi noise for surface foam,
- Shoreline foam and waves, also using Voronoi Noise

## How to Use
  1. Import the shader into your Unity project (or clone this repo).
  2. Create a new Material and set its shader to `Custom/NewWavesv2`.
  3. Assign the material to a plane in your scene.
  4. Adjust the exposed properties (mainly normal maps and colors — the others are the values used for the screenshots).


## Documentation Used
- [Normals Maps](https://drive.google.com/drive/folders/1-U8iJARDsrhftYncn-6b6gko8zJ_j0VZ)
- [Voronoi Noise](https://www.ronja-tutorials.com/post/028-voronoi-noise/)
- [Tessellation ](https://www.youtube.com/watch?v=SurwAUTGp18) 
- [Depth Based Shading](https://www.youtube.com/watch?v=2wa6UbtKvMs)
- [Gerstner Waves](https://developer.nvidia.com/gpugems/gpugems/part-i-natural-effects/chapter-1-effective-water-simulation-physical-models) Specifically Equation 9

## Other Useful Documentation Used

- https://roystan.net/articles/toon-water/
- https://www.cyanilux.com/tutorials/shoreline-shader-breakdown/
- https://www.youtube.com/watch?v=gRq-IdShxpU&t=6s
- https://docs.unity3d.com/Manual/urp/use-built-in-shader-methods-lighting.html
- https://catlikecoding.com/unity/tutorials/advanced-rendering/tessellation/



## Plans for the Future

- Better shoreline waves using a different type of noise (current one looks weird)
- Better specular (current one is too intense)
- Better shoreline foam (current one is dependent on camera)
- Work on underwater lighting effect
- Add physics and work on the transition between the physical part and the shader part



