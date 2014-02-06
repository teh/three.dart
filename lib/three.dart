library three;

import 'dart:async';
import 'dart:html' hide Path;
import 'dart:typed_data';
import 'dart:web_gl' as gl;
import 'dart:math' as Math;
import 'dart:convert' show JSON;
import 'dart:mirrors';

import 'extras/utils/math_utils.dart' as MathUtils;

import 'extras/utils/image_utils.dart' as ImageUtils;
import 'extras/utils/font_utils.dart' as FontUtils;
import 'extras/utils/curve_utils.dart' as CurveUtils;
import 'extras/utils/shape_utils.dart' as ShapeUtils;
import 'extras/animation/animation_handler.dart' as AnimationHandler;
import 'extras/utils/uniforms_utils.dart' as UniformsUtils;

part 'src/cameras/camera.dart';
part 'src/cameras/orthographic_camera.dart';
part 'src/cameras/perspective_camera.dart';

part 'src/core/buffer_geometry.dart';
part 'src/core/geometry_attribute.dart';
part 'src/core/event_emitter.dart';
part 'src/core/face3.dart';
part 'src/core/geometry.dart';
part 'src/core/igeometry.dart';
part 'src/core/morph_color.dart';
part 'src/core/morph_normal.dart';
part 'src/core/morph_target.dart';
part 'src/core/object3d.dart';
part 'src/core/projector.dart';
part 'src/core/raycaster.dart';
part 'src/core/clock.dart';

part 'src/lights/ambient_light.dart';
part 'src/lights/area_light.dart';
part 'src/lights/directional_light.dart';
part 'src/lights/hemisphere_light.dart';
part 'src/lights/light.dart';
part 'src/lights/point_light.dart';
part 'src/lights/shadow_caster.dart';
part 'src/lights/spot_light.dart';

part 'src/math/box2.dart';
part 'src/math/box3.dart';
part 'src/math/color.dart';
part 'src/math/euler.dart';
part 'src/math/frustum.dart';
part 'src/math/line3.dart';
part 'src/math/matrix2.dart';
part 'src/math/matrix3.dart';
part 'src/math/matrix4.dart';
part 'src/math/plane.dart';
part 'src/math/polygon.dart';
part 'src/math/quaternion.dart';
part 'src/math/ray.dart';
part 'src/math/sphere.dart';
part 'src/math/spline.dart';
part 'src/math/triangle.dart';
part 'src/math/vector2.dart';
part 'src/math/vector3.dart';
part 'src/math/vector4.dart';

// TODO part 'src/loaders/buffer_geometry_loader.dart';
part 'src/loaders/geometry_loader.dart';
part 'src/loaders/loading_manager.dart';
part 'src/loaders/material_loader.dart';
part 'src/loaders/object_loader.dart';
part 'src/loaders/scene_loader.dart';
part 'src/loaders/texture_loader.dart';
part 'src/loaders/xhr_loader.dart';
part 'src/loaders/loader.dart';
part 'src/loaders/json_loader.dart';
part 'src/loaders/image_loader.dart';
part 'src/loaders/stl_loader.dart';

part 'extras/animation/animation.dart';
part 'extras/animation/animation_morph_target.dart';
part 'extras/animation/ianimation.dart';
part 'extras/animation/key_frame_animation.dart';

part 'extras/cameras/combined_camera.dart';
part 'extras/cameras/cube_camera.dart';

part 'extras/core/curve.dart';
part 'extras/core/curve_path.dart';
part 'extras/core/path.dart';
part 'extras/core/shape.dart';

part 'extras/curves/arc_curve.dart';
part 'extras/curves/closed_spline_curve3.dart';
part 'extras/curves/cubic_bezier_curve.dart';
part 'extras/curves/cubic_bezier_curve3.dart';
part 'extras/curves/ellipse_curve.dart';
part 'extras/curves/line_curve.dart';
part 'extras/curves/line_curve3.dart';
part 'extras/curves/quadratic_bezier_curve.dart';
part 'extras/curves/quadratic_bezier_curve3.dart';
part 'extras/curves/spline_curve.dart';
part 'extras/curves/spline_curve3.dart';

part 'extras/core/gyroscope.dart';

part 'extras/objects/immediate_render_object.dart';
part 'extras/objects/lens_flare.dart';
part 'extras/objects/morph_blend_mesh.dart';

part 'extras/geometries/circle_geometry.dart';
part 'extras/geometries/convex_geometry.dart';
part 'extras/geometries/cube_geometry.dart';
part 'extras/geometries/ring_geometry.dart';
part 'extras/geometries/cylinder_geometry.dart';
part 'extras/geometries/extrude_geometry.dart';
part 'extras/geometries/icosahedron_geometry.dart';
part 'extras/geometries/lathe_geometry.dart';
part 'extras/geometries/octahedron_geometry.dart';
part 'extras/geometries/parametric_geometry.dart';
part 'extras/geometries/plane_geometry.dart';
part 'extras/geometries/polyhedron_geometry.dart';
part 'extras/geometries/shape_geometry.dart';
part 'extras/geometries/sphere_geometry.dart';
part 'extras/geometries/tetrahedron_geometry.dart';
part 'extras/geometries/text_geometry.dart';
part 'extras/geometries/torus_geometry.dart';
part 'extras/geometries/torus_knot_geometry.dart';
part 'extras/geometries/tube_geometry.dart';

part 'extras/helpers/arrow_helper.dart';
part 'extras/helpers/axis_helper.dart';
part 'extras/helpers/bounding_box_helper.dart';
part 'extras/helpers/box_helper.dart';
part 'extras/helpers/camera_helper.dart';
part 'extras/helpers/directional_light_helper.dart';
part 'extras/helpers/edges_helper.dart';
part 'extras/helpers/face_normals_helper.dart';
part 'extras/helpers/grid_helper.dart';
part 'extras/helpers/hemisphere_light_helper.dart';
part 'extras/helpers/point_light_helper.dart';
part 'extras/helpers/spot_light_helper.dart';
part 'extras/helpers/vertex_normals_helper.dart';
part 'extras/helpers/vertex_tangents_helper.dart';
part 'extras/helpers/wireframe_helper.dart';

part 'extras/renderers/plugins/shadow_map_plugin.dart';

part 'src/materials/material.dart';
part 'src/materials/mesh_basic_material.dart';
part 'src/materials/mesh_face_material.dart';
part 'src/materials/particle_system_material.dart';
part 'src/materials/line_basic_material.dart';
part 'src/materials/line_dashed_material.dart';
part 'src/materials/mesh_lambert_material.dart';
part 'src/materials/mesh_depth_material.dart';
part 'src/materials/mesh_normal_material.dart';
part 'src/materials/itexture_material.dart';
part 'src/materials/mesh_phong_material.dart';
part 'src/materials/shader_material.dart';
part 'src/materials/sprite_material.dart';
part 'src/materials/sprite_canvas_material.dart';

part 'src/objects/bone.dart';
part 'src/objects/mesh.dart';
part 'src/objects/line.dart';
part 'src/objects/particle_system.dart';
part 'src/objects/sprite.dart';
part 'src/objects/skinned_mesh.dart';
part 'src/objects/lod.dart';
part 'src/objects/morph_anim_mesh.dart';

part 'src/renderers/renderables/irenderable.dart';
part 'src/renderers/renderables/renderable_object.dart';
part 'src/renderers/renderables/renderable_vertex.dart';
part 'src/renderers/renderables/renderable_face3.dart';
part 'src/renderers/renderables/renderable_line.dart';
part 'src/renderers/renderables/renderable_sprite.dart';

part 'src/renderers/shaders/attribute.dart';
part 'src/renderers/shaders/uniform.dart';
part 'src/renderers/shaders/shader_lib.dart';
part 'src/renderers/shaders/shader_chunk.dart';
part 'src/renderers/shaders/uniforms_lib.dart';

part 'src/renderers/renderer.dart';
part 'src/renderers/webgl/webgl_renderer.dart';
part 'src/renderers/webgl/webgl_render_target.dart';
part 'src/renderers/webgl/webgl_render_target_cube.dart';

part 'src/renderers/webgl/webgl_camera.dart';
part 'src/renderers/webgl/webgl_geometry.dart';
part 'src/renderers/webgl/webgl_image_list.dart';
part 'src/renderers/webgl/webgl_material.dart';
part 'src/renderers/webgl/webgl_object.dart';

part 'src/scenes/scene.dart';
part 'src/scenes/fog.dart';
part 'src/scenes/fog_linear.dart';
part 'src/scenes/fog_exp2.dart';

part 'src/textures/compressed_texture.dart';
part 'src/textures/data_texture.dart';
part 'src/textures/texture.dart';

part 'uv_mapping.dart';
part 'src/materials/mappings.dart';

// from Geometry
int GeometryIdCount = 0;

// from Object3D
int Object3DIdCount = 0;

// from Material
int MaterialIdCount = 0;

// from Texture
int TextureIdCount = 0;

// GL STATE CONSTANTS
const int CULL_FACE_NONE = 0;
const int CULL_FACE_BACK = 1;
const int CULL_FACE_FRONT = 2;
const int CULL_FACE_FRONTBACK = 3;

const int FRONT_FACE_DIRECTION_CW = 0;
const int FRONT_FACE_DIRECTION_CCW = 1;

// SHADOWING TYPES
const int BASIC_SHADOW_MAP = 0;
const int PCF_SHADOW_MAP = 1;
const int PCF_SOFT_SHADOW_MAP = 2;


// MATERIAL CONSTANTS

// side
const int FRONT_SIDE = 0;
const int BACK_SIDE = 1;
const int DOUBLE_SIDE = 2;

const int NO_SHADING = 0;
const int FLAT_SHADING = 1;
const int SMOOTH_SHADING = 2;

const int NO_COLORS = 0;
const int FACE_COLORS = 1;
const int VERTEX_COLORS = 2;

// blending modes
const int NO_BLENDING = 0;
const int NORMAL_BLENDING = 1;
const int ADDITIVE_BLENDING = 2;
const int SUBTRACTIVE_BLENDING = 3;
const int MULTIPLY_BLENDING = 4;
const int CUSTOM_BLENDING = 5;

// custom blending equations
// (numbers start from 100 not to clash with other mappings to OpenGL constants defined in texture.dart)
const int ADD_EQUATION = 100;
const int SUBTRACT_EQUATION = 101;
const int REVERSE_SUBTRACT_EQUATION = 102;

// custom blending destination factors
const int ZERO_FACTOR = 200;
const int ONE_FACTOR = 201;
const int SRC_COLOR_FACTOR = 202;
const int ONE_MINUS_SRC_COLOR_FACTOR = 203;
const int SRC_ALPHA_FACTOR = 204;
const int ONE_MINUS_SRC_ALPHA_FACTOR = 205;
const int DST_ALPHA_FACTOR = 206;
const int ONE_MINUS_DST_ALPHA_FACTOR = 207;

// custom blending source factors
const int DST_COLOR_FACTOR = 208;
const int ONE_MINUS_DST_COLOR_FACTOR = 209;
const int SRC_ALPHA_SATURATE_FACTOR = 210;


//TEXTURE CONSTANS

const int MULTIPLY_OPERATION = 0;
const int MIX_OPERATION = 1;
const int ADD_OPERATION = 2;

// Wrapping modes
const int REPEAT_WRAPPING = 1000;
const int CLAMP_TO_EDGE_WRAPPING = 1001;
const int MIRRORED_REPEAT_WRAPPING = 1002;

// Filters
const int NEAREST_FILTER = 1003;
const int NEAREST_MIPMAP_NEAREST_FILTER = 1004;
const int NEAREST_MIPMAP_LINEAR_FILTER = 1005;
const int LINEAR_FILTER = 1006;
const int LINEAR_MIPMAP_NEAREST_FILTER = 1007;
const int LINEAR_MIPMAP_LINEAR_FILTER = 1008;

// Data Types
const int UNSIGNED_BYTE_TYPE = 1009;
const int BYTE_TYPE = 1010;
const int SHORT_TYPE = 1011;
const int UNSIGNED_SHORT_TYPE = 1012;
const int INT_TYPE = 1013;
const int UNSIGNED_INT_TYPE = 1014;
const int FLOAT_TYPE = 1015;

// Pixel types
const int UNSIGNED_SHORT_4444_TYPE = 1016;
const int UNSIGNED_SHORT_5551_TYPE = 1017;
const int UNSIGNED_SHORT_565_TYPE = 1018;

// Pixel Formats
const int ALPHA_FORMAT = 1019;
const int RGB_FORMAT = 1020;
const int RGBA_FORMAT = 1021;
const int LUMINANCE_FORMAT = 1022;
const int LUMINANCE_ALPHA_FORMAT = 1023;

// Compressed texture formats
const int RGB_S3TC_DXT1_FORMAT = 2001;
const int RGBA_S3TC_DXT1_FORMAT = 2002;
const int RGBA_S3TC_DXT3_FORMAT = 2003;
const int RGBA_S3TC_DXT5_FORMAT = 2004;

final Map Colors = {"aliceblue": 0xF0F8FF, "antiquewhite": 0xFAEBD7, "aqua": 0x00FFFF, "aquamarine": 0x7FFFD4, "azure": 0xF0FFFF,
"beige": 0xF5F5DC, "bisque": 0xFFE4C4, "black": 0x000000, "blanchedalmond": 0xFFEBCD, "blue": 0x0000FF, "blueviolet": 0x8A2BE2,
"brown": 0xA52A2A, "burlywood": 0xDEB887, "cadetblue": 0x5F9EA0, "chartreuse": 0x7FFF00, "chocolate": 0xD2691E, "coral": 0xFF7F50,
"cornflowerblue": 0x6495ED, "cornsilk": 0xFFF8DC, "crimson": 0xDC143C, "cyan": 0x00FFFF, "darkblue": 0x00008B, "darkcyan": 0x008B8B,
"darkgoldenrod": 0xB8860B, "darkgray": 0xA9A9A9, "darkgreen": 0x006400, "darkgrey": 0xA9A9A9, "darkkhaki": 0xBDB76B, "darkmagenta": 0x8B008B,
"darkolivegreen": 0x556B2F, "darkorange": 0xFF8C00, "darkorchid": 0x9932CC, "darkred": 0x8B0000, "darksalmon": 0xE9967A, "darkseagreen": 0x8FBC8F,
"darkslateblue": 0x483D8B, "darkslategray": 0x2F4F4F, "darkslategrey": 0x2F4F4F, "darkturquoise": 0x00CED1, "darkviolet": 0x9400D3,
"deeppink": 0xFF1493, "deepskyblue": 0x00BFFF, "dimgray": 0x696969, "dimgrey": 0x696969, "dodgerblue": 0x1E90FF, "firebrick": 0xB22222,
"floralwhite": 0xFFFAF0, "forestgreen": 0x228B22, "fuchsia": 0xFF00FF, "gainsboro": 0xDCDCDC, "ghostwhite": 0xF8F8FF, "gold": 0xFFD700,
"goldenrod": 0xDAA520, "gray": 0x808080, "green": 0x008000, "greenyellow": 0xADFF2F, "grey": 0x808080, "honeydew": 0xF0FFF0, "hotpink": 0xFF69B4,
"indianred": 0xCD5C5C, "indigo": 0x4B0082, "ivory": 0xFFFFF0, "khaki": 0xF0E68C, "lavender": 0xE6E6FA, "lavenderblush": 0xFFF0F5, "lawngreen": 0x7CFC00,
"lemonchiffon": 0xFFFACD, "lightblue": 0xADD8E6, "lightcoral": 0xF08080, "lightcyan": 0xE0FFFF, "lightgoldenrodyellow": 0xFAFAD2, "lightgray": 0xD3D3D3,
"lightgreen": 0x90EE90, "lightgrey": 0xD3D3D3, "lightpink": 0xFFB6C1, "lightsalmon": 0xFFA07A, "lightseagreen": 0x20B2AA, "lightskyblue": 0x87CEFA,
"lightslategray": 0x778899, "lightslategrey": 0x778899, "lightsteelblue": 0xB0C4DE, "lightyellow": 0xFFFFE0, "lime": 0x00FF00, "limegreen": 0x32CD32,
"linen": 0xFAF0E6, "magenta": 0xFF00FF, "maroon": 0x800000, "mediumaquamarine": 0x66CDAA, "mediumblue": 0x0000CD, "mediumorchid": 0xBA55D3,
"mediumpurple": 0x9370DB, "mediumseagreen": 0x3CB371, "mediumslateblue": 0x7B68EE, "mediumspringgreen": 0x00FA9A, "mediumturquoise": 0x48D1CC,
"mediumvioletred": 0xC71585, "midnightblue": 0x191970, "mintcream": 0xF5FFFA, "mistyrose": 0xFFE4E1, "moccasin": 0xFFE4B5, "navajowhite": 0xFFDEAD,
"navy": 0x000080, "oldlace": 0xFDF5E6, "olive": 0x808000, "olivedrab": 0x6B8E23, "orange": 0xFFA500, "orangered": 0xFF4500, "orchid": 0xDA70D6,
"palegoldenrod": 0xEEE8AA, "palegreen": 0x98FB98, "paleturquoise": 0xAFEEEE, "palevioletred": 0xDB7093, "papayawhip": 0xFFEFD5, "peachpuff": 0xFFDAB9,
"peru": 0xCD853F, "pink": 0xFFC0CB, "plum": 0xDDA0DD, "powderblue": 0xB0E0E6, "purple": 0x800080, "red": 0xFF0000, "rosybrown": 0xBC8F8F,
"royalblue": 0x4169E1, "saddlebrown": 0x8B4513, "salmon": 0xFA8072, "sandybrown": 0xF4A460, "seagreen": 0x2E8B57, "seashell": 0xFFF5EE,
"sienna": 0xA0522D, "silver": 0xC0C0C0, "skyblue": 0x87CEEB, "slateblue": 0x6A5ACD, "slategray": 0x708090, "slategrey": 0x708090, "snow": 0xFFFAFA,
"springgreen": 0x00FF7F, "steelblue": 0x4682B4, "tan": 0xD2B48C, "teal": 0x008080, "thistle": 0xD8BFD8, "tomato": 0xFF6347, "turquoise": 0x40E0D0,
"violet": 0xEE82EE, "wheat": 0xF5DEB3, "white": 0xFFFFFF, "whitesmoke": 0xF5F5F5, "yellow": 0xFFFF00, "yellowgreen": 0x9ACD32};

