/// vbuffer_create_icosphere(radius, tex1, tex2, detail, smooth, invert, morph)
/// @arg radius
/// @arg tex1
/// @arg tex2
/// @arg detail
/// @arg smooth
/// @arg invert
/// @arg morph

function vbuffer_create_icosphere(rad, tex1, tex2, detail, smooth, invert, morph)
{
	vbuffer_start();
	
	var n = negate(invert);
	var t = (1 + sqrt(5)) / (2 + (morph * ((morph > 0) ? morph : 1)));
	
	// Avoid calculating by infinity or 0
	t = clamp(t, 0.001, 10000)
	
	// Base icosahedron vertices
	var base = [
		[-1,  t,  0], [ 1,  t,  0], [-1, -t,  0], [ 1, -t,  0],
		[ 0, -1,  t], [ 0,  1,  t], [ 0, -1, -t], [ 0,  1, -t],
		[ t,  0, -1], [ t,  0,  1], [-t,  0, -1], [-t,  0,  1]
	];
	
	var faces = [
		[0,11,5],[0,5,1],[0,1,7],[0,7,10],[0,10,11],
		[1,5,9],[5,11,4],[11,10,2],[10,7,6],[7,1,8],
		[3,9,4],[3,4,2],[3,2,6],[3,6,8],[3,8,9],
		[4,9,5],[2,4,11],[6,2,10],[8,6,7],[9,8,1]
	];
	
	// Normalize base vertices (unit sphere)
	for (var i = 0; i < array_length(base); i++)
	{
		var v = base[i];
		var len = sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2]);
		base[i] = [v[0]/len, v[1]/len, v[2]/len];
	}
	
	// Subdivide faces (inline midpoint)
	for (var d = 0; d < detail; d++)
	{
		var midpoint_cache = ds_map_create();
		var new_faces = [];
		var new_faces_len = 0;
		
		for (var f = 0; f < array_length(faces); f++)
		{
			var tri = faces[f];
			var v0 = tri[0];
			var v1 = tri[1];
			var v2 = tri[2];
			
			var key, va, vb, mx, my, mz, len, idx;
			
			// midpoint a-b
			key = string(min(v0,v1)) + "_" + string(max(v0,v1));
			var ab;
			if (ds_map_exists(midpoint_cache, key)) {
				ab = midpoint_cache[? key];
			} else {
				va = base[v0]; vb = base[v1];
				mx = (va[0]+vb[0])*0.5; my = (va[1]+vb[1])*0.5; mz = (va[2]+vb[2])*0.5;
				len = sqrt(mx*mx + my*my + mz*mz);
				idx = array_length(base);
				base[idx] = [mx/len, my/len, mz/len];
				ds_map_add(midpoint_cache, key, idx);
				ab = idx;
			}
			
			// midpoint b-c
			key = string(min(v1,v2)) + "_" + string(max(v1,v2));
			var bc;
			if (ds_map_exists(midpoint_cache, key)) {
				bc = midpoint_cache[? key];
			} else {
				va = base[v1]; vb = base[v2];
				mx = (va[0]+vb[0])*0.5; my = (va[1]+vb[1])*0.5; mz = (va[2]+vb[2])*0.5;
				len = sqrt(mx*mx + my*my + mz*mz);
				idx = array_length(base);
				base[idx] = [mx/len, my/len, mz/len];
				ds_map_add(midpoint_cache, key, idx);
				bc = idx;
			}
			
			// midpoint c-a
			key = string(min(v2,v0)) + "_" + string(max(v2,v0));
			var ca;
			if (ds_map_exists(midpoint_cache, key)) {
				ca = midpoint_cache[? key];
			} else {
				va = base[v2]; vb = base[v0];
				mx = (va[0]+vb[0])*0.5; my = (va[1]+vb[1])*0.5; mz = (va[2]+vb[2])*0.5;
				len = sqrt(mx*mx + my*my + mz*mz);
				idx = array_length(base);
				base[idx] = [mx/len, my/len, mz/len];
				ds_map_add(midpoint_cache, key, idx);
				ca = idx;
			}
			
			// manual push (replaces array_push)
			new_faces[new_faces_len++] = [v0, ab, ca];
			new_faces[new_faces_len++] = [v1, bc, ab];
			new_faces[new_faces_len++] = [v2, ca, bc];
			new_faces[new_faces_len++] = [ab, bc, ca];
		}
		
		faces = new_faces;
		ds_map_destroy(midpoint_cache);
	}
	
	// Texture info
	var texsize = point2D_sub(tex2, tex1);
	// var texmid = point2D_add(tex1, vec2_mul(texsize, 0.5));
	
	// Generate triangles
	for (var f = 0; f < array_length(faces); f++)
	{
		var tri = faces[f];
		var verts = [];
		var verts_len = 0;
		
		// compute per-face normal for flat shading
		var fnx = 0, fny = 0, fnz = 0;
		if (!smooth)
		{
			var p1 = base[tri[0]];
			var p2 = base[tri[1]];
			var p3 = base[tri[2]];
			var ux = p2[0] - p1[0], uy = p2[1] - p1[1], uz = p2[2] - p1[2];
			var vx = p3[0] - p1[0], vy = p3[1] - p1[1], vz = p3[2] - p1[2];
			fnx = uy*vz - uz*vy;
			fny = uz*vx - ux*vz;
			fnz = ux*vy - uy*vx;
			var flen = sqrt(fnx*fnx + fny*fny + fnz*fnz);
			if (flen != 0) { fnx /= flen; fny /= flen; fnz /= flen; } else { fnx=0; fny=1; fnz=0; }
		}
		
		for (var k = 0; k < 3; k++)
		{
			var v = base[tri[k]];
			
			var px = v[0] * rad;
			var py = v[1] * rad;
			var pz = v[2] * rad;
			
			var nx = smooth ? v[0] : fnx;
			var ny = smooth ? v[1] : fny;
			var nz = smooth ? v[2] : fnz;
			
			var u = 0.5 + arctan2(v[0], v[2]) / (2 * pi);
			var vtex = 0.5 - arcsin(v[1]) / pi;
			var texu = tex1[X] + u * texsize[X];
			var texv = tex1[Y] + vtex * texsize[Y];
			
			verts[verts_len++] = [px, py, pz, nx * n, ny * n, nz * n, texu, texv];
		}
		
		if (invert)
		{
			vertex_add(verts[2][0], verts[2][1], verts[2][2], verts[2][3], verts[2][4], verts[2][5], verts[2][6], verts[2][7]);
			vertex_add(verts[1][0], verts[1][1], verts[1][2], verts[1][3], verts[1][4], verts[1][5], verts[1][6], verts[1][7]);
			vertex_add(verts[0][0], verts[0][1], verts[0][2], verts[0][3], verts[0][4], verts[0][5], verts[0][6], verts[0][7]);
		}
		else
		{
			for (var v = 0; v < verts_len; v++)
			{
				var vv = verts[v];
				vertex_add(vv[0], vv[1], vv[2], vv[3], vv[4], vv[5], vv[6], vv[7]);
			}
		}
	}
	
	return vbuffer_done();
}