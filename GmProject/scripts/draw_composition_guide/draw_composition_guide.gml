/// draw_composition_guide(x, y, width, height, alpha)
/// @arg x
/// @arg y
/// @arg width
/// @arg height
/// @arg alpha

function draw_composition_guide(xx, yy, wid, hei, alpha = 0.8)
{
    var col = c_white;
    var a   = alpha;

    var cx = xx + wid * 0.5;
    var cy = yy + hei * 0.5;
	
    switch (project_composition_guide)
    {
        
        case e_composition_guide.RULE_OF_THIRDS:
	        var cw = wid / project_grid_columns;
	        var ch = hei / project_grid_rows;

	        for (var i = 1; i < project_grid_columns; i++)
	            draw_line_ext(xx + cw * i, yy, xx + cw * i, yy + hei, col, a);

	        for (var j = 1; j < project_grid_rows; j++)
	            draw_line_ext(xx, yy + ch * j, xx + wid, yy + ch * j, col, a);
			break;
		
        /*
        case e_composition_guide.GOLDEN_SECTION:
            var phi = 1.61803398875;
            var gx1 = xx + wid / phi;
            var gy1 = yy + hei / phi;

            draw_line_ext(gx1, yy, gx1, yy + hei, col, a);
            draw_line_ext(xx, gy1, xx + wid, gy1, col, a);
			break;

        
        case e_composition_guide.GOLDEN_TRIANGLES:
            // Main diagonal
            draw_line_ext(xx, yy, xx + wid, yy + hei, col, a);

            // Opposite diagonal
            draw_line_ext(xx + wid, yy, xx, yy + hei, col, a);
			break;

        
        case e_composition_guide.GOLDEN_SpiRAL:

		    var phi = 1.618033988749895;

		    // Draw golden ratio grid (optional but matches Blender)
		    var golden_x = xx + wid / phi;
		    var golden_y = yy + hei / phi;

		    draw_line_ext(golden_x, yy, golden_x, yy + hei, col, a);
		    draw_line_ext(xx, golden_y, xx + wid, golden_y, col, a);

		    // Determine orientation (landscape or portrait)
		    var landscape = (wid >= hei);

		    // Set initial rectangle
		    var rx = xx;
		    var ry = yy;
		    var rw = wid;
		    var rh = hei;

		    // Fibonacci spiral iterations
		    var steps = 8;
		    var dir = 0; // 0=right, 1=down, 2=left, 3=up

		    repeat (steps)
		    {
		        // Choose square size
		        var s = min(rw, rh);

		        // Arc center
		        var cx, cy;

		        switch (dir)
		        {
		            case 0: // right → downward arc
		                cx = rx + s;
		                cy = ry;
		                break;

		            case 1: // down → left arc
		                cx = rx + rw;
		                cy = ry + s;
		                break;

		            case 2: // left → up arc
		                cx = rx + s;
		                cy = ry + rh;
		                break;

		            case 3: // up → right arc
		                cx = rx;
		                cy = ry + s;
		                break;
		        }

		        // Draw arc using line segments
		        var arc_steps = 22;
		        var a1 = dir * 90;
		        var a2 = a1 + 90;

		        for (var i = 0; i < arc_steps; i++)
		        {
		            var ang1 = degtorad(a1 + (i     / arc_steps) * 90);
		            var ang2 = degtorad(a1 + ((i+1) / arc_steps) * 90);

		            draw_line_ext(
		                cx + cos(ang1) * s,
		                cy + sin(ang1) * s,
		                cx + cos(ang2) * s,
		                cy + sin(ang2) * s,
		                col, a
		            );
		        }

		        // Shrink bounding box for next iteration
		        switch (dir)
		        {
		            case 0: rx += s; rw -= s; break;
		            case 1: rh -= s; ry += s; break;
		            case 2: rw -= s; break;
		            case 3: rh -= s; break;
		        }

		        // Rotate direction
		        dir = (dir + 1) mod 4;
		    }

		break;
		
		case e_composition_guide.GOLDEN_RATIO:
		{
		    var phi = 1.618033988749895;
		    var b   = 2 * ln(phi) / pi; // growth exponent for a golden spiral

		    // --- configuration (change these to taste) ---
		    // start_corner: 0=top-right, 1=bottom-right, 2=bottom-left, 3=top-left
		    // clockwise: true -> spiral winds clockwise (increase theta draws clockwise), false -> counterclockwise
		    var start_corner = (wid >= hei) ? 0 : 2; // sensible default: landscape -> top-right, portrait -> bottom-left
		    var clockwise = true;
		    var inner_scale = 0.02; // initial radius as fraction of smaller dimension (0.02 = 2%)
		    var theta_step = 0.07;  // radians per segment (smaller = smoother, more segments)
		    // ---------------------------------------------

		    // choose center depending on corner
		    var cx, cy;
		    switch (start_corner)
		    {
		        case 0: cx = xx + wid; cy = yy;            break; // top-right
		        case 1: cx = xx + wid; cy = yy + hei;     break; // bottom-right
		        case 2: cx = xx;        cy = yy + hei;     break; // bottom-left
		        case 3: cx = xx;        cy = yy;            break; // top-left
		    }

		    // initial scale 'a' (small starting radius)
		    var a = min(wid, hei) * inner_scale;

		    // maximum radius required to cover the rectangle (distance from center to farthest corner)
		    var max_rx = max(abs(cx - xx), abs(cx - (xx + wid)));
		    var max_ry = max(abs(cy - yy), abs(cy - (yy + hei)));
		    var max_r  = sqrt(max_rx*max_rx + max_ry*max_ry);

		    // compute theta range so r(theta_end) >= max_r
		    // r(theta) = a * exp(b * theta) --> theta_end = ln(max_r / a) / b
		    var theta_end = 0;
		    if (max_r > a) theta_end = ln(max_r / a) / b;
		    else theta_end = 2 * pi; // fallback

		    // choose an angular offset so the spiral "faces" the rectangle from that corner:
		    // these offsets make the spiral enter the rectangle in a pleasing way
		    var ang_offset;
		    switch (start_corner)
		    {
		        case 0: ang_offset = -pi/2; break; // top-right -> start pointing left/down
		        case 1: ang_offset = pi;    break; // bottom-right -> start pointing left/up
		        case 2: ang_offset = pi/2;  break; // bottom-left -> start pointing right/up
		        case 3: ang_offset = 0;     break; // top-left -> start pointing right/down
		    }

		    // direction multiplier for winding direction
		    var dir_mul = (clockwise) ? 1 : -1;

		    // Draw spiral by sampling theta from 0..theta_end
		    var theta = 0;
		    var prev_x = cx + a * exp(b * theta) * cos(ang_offset + dir_mul * theta);
		    var prev_y = cy + a * exp(b * theta) * sin(ang_offset + dir_mul * theta);

		    while (theta < theta_end)
		    {
		        theta += theta_step;
		        var r = a * exp(b * theta);
		        var x1 = cx + r * cos(ang_offset + dir_mul * theta);
		        var y1 = cy + r * sin(ang_offset + dir_mul * theta);

		        draw_line_ext(prev_x, prev_y, x1, y1, col, a);

		        prev_x = x1;
		        prev_y = y1;
		    }
		}
		break;
		
		
        case e_composition_guide.HARMONIOUS_TRIANGLES:
            draw_line_ext(xx, yy, xx + wid, yy + hei, col, a);
            draw_line_ext(xx + wid, yy, xx, yy + hei, col, a);
			break;

        
			case e_composition_guide.CROSS:
            draw_line_ext(cx, yy, cx, yy + hei, col, a);
            draw_line_ext(xx, cy, xx + wid, cy, col, a);
			break;

        
        case e_composition_guide.DIAGONAL:
            draw_line_ext(xx, yy, xx + wid, yy + hei, col, a);
            draw_line_ext(xx + wid, yy, xx, yy + hei, col, a);
			break;
		*/
        
        case e_composition_guide.RADIAL:
            draw_line_ext(cx, cy, xx, yy, col, a);
            draw_line_ext(cx, cy, xx + wid, yy, col, a);
            draw_line_ext(cx, cy, xx, yy + hei, col, a);
            draw_line_ext(cx, cy, xx + wid, yy + hei, col, a);

            draw_line_ext(cx, cy, xx, cy, col, a);
            draw_line_ext(cx, cy, xx + wid, cy, col, a);
            draw_line_ext(cx, cy, cx, yy, col, a);
            draw_line_ext(cx, cy, cx, yy + hei, col, a);
			break;

        /*
		
        case e_composition_guide.PYRAMID:
            draw_line_ext(cx, yy, xx, yy + hei, col, a);
            draw_line_ext(cx, yy, xx + wid, yy + hei, col, a);
            draw_line_ext(xx, yy + hei, xx + wid, yy + hei, col, a);
			break;
		*/
		
		case e_composition_guide.TRIANGLE:
			// Golden triangle
			// Main diagonal
			draw_line_ext(xx, yy, xx + wid, yy + hei, col, a);
			
			// Perpendicular to (wid, 0)
			var px = (wid * wid * wid) / (wid * wid + hei * hei);
			var py = (hei * wid * wid) / (wid * wid + hei * hei);
			draw_line_ext(xx + wid, yy, xx + px, yy + py, col, a);
			
			// Perpendicular to (0, hei)
			var px2 = (wid * hei * hei) / (wid * wid + hei * hei);
			var py2 = (hei * hei * hei) / (wid * wid + hei * hei);
			draw_line_ext(xx, yy + hei, xx + px2, yy + py2, col, a);
			break;

        case e_composition_guide.CIRCULAR:
			// Concentric circles/ovals
			var cnt = project_grid_rows;
			for (var i = 1; i <= cnt; i++)
			{
				var rx = (wid / 2) * (i / cnt);
				var ry = (hei / 2) * (i / cnt);
				// We don't have draw_ellipse_ext, but we can use draw_circle_ext if it supports non-uniform scaling or just draw it as a circles.
				// Actually, draw_circle_ext might not support ellipses easily.
				// Let's check draw_circle_ext implementation if it exists.
				// If not, I'll just use 32 segments or so.
				var detail = 64;
				var px, py, ox, oy;
				for (var j = 0; j <= detail; j++)
				{
					var angle = (j / detail) * 360;
					px = cx + lengthdir_x(rx, angle);
					py = cy + lengthdir_y(ry, angle);
					if (j > 0)
						draw_line_ext(ox, oy, px, py, col, a);
					ox = px;
					oy = py;
				}
			}
			break;
    }
}