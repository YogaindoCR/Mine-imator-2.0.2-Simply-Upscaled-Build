/// string_hash_to_int(string)
/// @arg string

function string_hash_to_int(str) {
    var h = 0;
    for (var i = 1; i <= string_length(str); i++) {
        h = h * 31 + ord(string_char_at(str, i));
    }
    return h;
}