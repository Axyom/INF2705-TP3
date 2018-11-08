#version 410

// ==> Les variables en commentaires ci-dessous sont déclarées implicitement:
// in vec3 gl_TessCoord;
// in int gl_PatchVerticesIn;
// in int gl_PrimitiveID;
// patch in float gl_TessLevelOuter[4];
// patch in float gl_TessLevelInner[2];
// in gl_PerVertex
// {
//   vec4 gl_Position;
//   float gl_PointSize;
//   float gl_ClipDistance[];
// } gl_in[gl_MaxPatchVertices];

// out gl_PerVertex
// {
//   vec4 gl_Position;
//   float gl_PointSize;
//   float gl_ClipDistance[];
// };

// Définition des paramètres des sources de lumière
layout (std140) uniform LightSourceParameters
{
   vec4 ambient;
   vec4 diffuse;
   vec4 specular;
   vec4 position[2];      // dans le repère du monde
   vec3 spotDirection[2]; // dans le repère du monde
   float spotExponent;
   float spotAngleOuverture; // ([0.0,90.0] ou 180.0)
   float constantAttenuation;
   float linearAttenuation;
   float quadraticAttenuation;
} LightSource;

// Définition des paramètres des matériaux
layout (std140) uniform MaterialParameters
{
   vec4 emission;
   vec4 ambient;
   vec4 diffuse;
   vec4 specular;
   float shininess;
} FrontMaterial;

// Définition des paramètres globaux du modèle de lumière
layout (std140) uniform LightModelParameters
{
   vec4 ambient;       // couleur ambiante
   bool localViewer;   // observateur local ou à l'infini?
   bool twoSide;       // éclairage sur les deux côtés ou un seul?
} LightModel;

layout (std140) uniform varsUnif
{
   // partie 1: illumination
   int typeIllumination;     // 0:Gouraud, 1:Phong
   bool utiliseBlinn;        // indique si on veut utiliser modèle spéculaire de Blinn ou Phong
   bool utiliseDirect;       // indique si on utilise un spot style Direct3D ou OpenGL
   bool afficheNormales;     // indique si on utilise les normales comme couleurs (utile pour le débogage)
   // partie 3: texture
   int texnumero;            // numéro de la texture appliquée
   bool utiliseCouleur;      // doit-on utiliser la couleur de base de l'objet en plus de celle de la texture?
   int afficheTexelFonce;    // un texel noir doit-il être affiché 0:noir, 1:mi-coloré, 2:transparent?
};

uniform mat4 matrModel;
uniform mat4 matrVisu;
uniform mat4 matrProj;
uniform mat3 matrNormale;

layout(quads) in;

in Attribs {
   vec4 couleur;
   vec3 normal;
   vec4 pos;
   vec4 texCoords;
} AttribsIn[];

out Attribs {
    vec4 couleur;
    vec3 normal;
    vec3 pos;
    vec2 texCoords;
} AttribsOut;

float interpole( float v0, float v1, float v2, float v3 )
{
   // mix( x, y, f ) = x * (1-f) + y * f.
   float v01 = mix( v0, v1, gl_TessCoord.x );
   float v32 = mix( v3, v2, gl_TessCoord.x );
   return mix( v01, v32, gl_TessCoord.y );
}
vec2 interpole( vec2 v0, vec2 v1, vec2 v2, vec2 v3 )
{
   // mix( x, y, f ) = x * (1-f) + y * f.
   vec2 v01 = mix( v0, v1, gl_TessCoord.x );
   vec2 v32 = mix( v3, v2, gl_TessCoord.x );
   return mix( v01, v32, gl_TessCoord.y );
}
vec3 interpole( vec3 v0, vec3 v1, vec3 v2, vec3 v3 )
{
   // mix( x, y, f ) = x * (1-f) + y * f.
   vec3 v01 = mix( v0, v1, gl_TessCoord.x );
   vec3 v32 = mix( v3, v2, gl_TessCoord.x );
   return mix( v01, v32, gl_TessCoord.y );
}
vec4 interpole( vec4 v0, vec4 v1, vec4 v2, vec4 v3 )
{
   // mix( x, y, f ) = x * (1-f) + y * f.
   vec4 v01 = mix( v0, v1, gl_TessCoord.x );
   vec4 v32 = mix( v3, v2, gl_TessCoord.x );
   return mix( v01, v32, gl_TessCoord.y );
}

float calculerSpot( in vec3 D, in vec3 L )
{
   float spotFacteur = 1.0;
   return( spotFacteur );
}

vec4 calculerReflexion( in vec3 L, in vec3 N, in vec3 O )
{
    vec4 color = vec4(0.0, 0.0, 0.0, 1.0);

    // composante diffuse
    //color.rgb = FrontMaterial.diffuse.rgb * LightSource.diffuse.rgb * max(dot(N,L), 0.);
    color += FrontMaterial.diffuse * LightSource.diffuse * max(dot(N,L), 0.);
    // composante spéculaire
    if (utiliseBlinn)
    {
        color += FrontMaterial.specular * LightSource.specular * pow(max(dot(normalize(L+O),N),0.), FrontMaterial.shininess);
    }
    else
    {
        color += FrontMaterial.specular * LightSource.specular * pow(max(dot(reflect(-L,N),O),0.), FrontMaterial.shininess);
    }
    // composante ambiante
    color += FrontMaterial.ambient * LightSource.ambient;

    return color;
}

void main()
{
    // on substitue les donnees precedemment utilisees dans le vertex shader par celles fournies par la generation de tesselation
   vec4 Color = interpole( AttribsIn[0].couleur, AttribsIn[1].couleur, AttribsIn[3].couleur, AttribsIn[2].couleur );
   vec3 Normal = interpole( AttribsIn[0].normal, AttribsIn[1].normal, AttribsIn[3].normal, AttribsIn[2].normal );
   vec4 Vertex = interpole( AttribsIn[0].pos, AttribsIn[1].pos, AttribsIn[3].pos, AttribsIn[2].pos );
   vec4 TexCoord = interpole( AttribsIn[0].texCoords, AttribsIn[1].texCoords, AttribsIn[3].texCoords, AttribsIn[2].texCoords );

   // transformation standard du sommet
   gl_Position = matrProj * matrVisu * matrModel * Vertex;
   AttribsOut.texCoords = TexCoord.st;

   mat4 MV = matrVisu * matrModel;
   vec3 pos = vec3(MV * Vertex); // position du vertex courant dans la base view
   vec3 O = normalize(-pos); // dans la base view, la camera est a la position (0,0,0)
   vec3 N = normalize( matrNormale * Normal ); // calcul de la normale normalisée


   if (typeIllumination == 0)
   {
       AttribsOut.couleur = vec4(0., 0., 0., 1.);
       for(int i=0; i<2; i++)
       {
           vec3 L = normalize(vec3(matrVisu*LightSource.position[i]) - pos); // car la position des lumieres est deja dans le repere du monde
           // couleur du sommet
           vec3 D = normalize(transpose(inverse(mat3(matrVisu)))*(-LightSource.spotDirection[i]));
           AttribsOut.couleur += calculerReflexion( L, N, O ) * calculerSpot(D, L);
       }

       //emission
       AttribsOut.couleur += FrontMaterial.emission + LightModel.ambient*FrontMaterial.ambient;
       AttribsOut.couleur = clamp(AttribsOut.couleur, 0., 1.);
   }
   else
   {
       // on passe la normale au fragment shader avec phong pour effectuer une interpolation des normales
       AttribsOut.normal = N;
       AttribsOut.pos = pos;
   }
}
