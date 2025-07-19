/// blend_color(color1, color2, amount)
/// @arg color1
/// @arg color2
/// @arg amount
// Idk why is this function broken with others util (color_multiply)
// just don't rename it to color_blend

function blend_color(color1, color2, amount)
{
    var r1 = color_get_red(color1);
    var g1 = color_get_green(color1);
    var b1 = color_get_blue(color1);

    var r2 = color_get_red(color2);
    var g2 = color_get_green(color2);
    var b2 = color_get_blue(color2);

    var r = r1 * (1 - amount) + r2 * amount;
    var g = g1 * (1 - amount) + g2 * amount;
    var b = b1 * (1 - amount) + b2 * amount;

    return make_color_rgb(r, g, b);
}
