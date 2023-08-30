const limits = @cImport(@cInclude("limits.h"));

// WARNING: this does not work.

// PSF font import
// The variable is defined in the linked object file 'font.o'.
// TODO: How do we use the variable in a zig file?
//       In C it would be done as follows:
//       extern char _binary_font_psf_start;
//       extern char _binary_font_psf_end;
// Pretty simple apparently, just need to remember the const or var keyword.
extern const _binary_font_psf_start: u8;
extern const _binary_font_psf_end: u8;

// PSF1 Header
const PSF1Header = extern struct {
    magic: u16,
    fontMode: u8,
    characterSize: u8,
};

// PSF2 Header
const PSFFont = extern struct {
    magic: u32,
    version: u32,
    headersize: u32,
    flags: u32,
    numglyph: u32,
    bytesperglyph: u32,
    height: u32,
    width: u32,
};

fn psfInit() void {
    var glyph: u16 = 0;

    // cast the address to the PSF header struct
    const font: *PSFFont = @as(*PSFFont, @ptrCast(@alignCast(&_binary_font_psf_start)));
    // if (font.flags == 0) {
    //     return;
    // }

    const s: [*]u32 = @as([*]u32, (@as([*]u32, @ptrCast(@alignCast(&_binary_font_psf_start)))) + font.headersize + font.numglyph * font.bytesperglyph);

    // Allocator setup
    const allocator = std.heap.page_allocator();

    var unicode = try allocator.alloc(2, limits.USHRT_MAX);
    defer allocator.free(unicode);

    while (s > _binary_font_psf_end) {
        var uc: u16 = @as(u16, @intFromPtr(s[0]));
        if (uc == 0xFF) {
            glyph += 1;
            s += 1;
            continue;
        } else if (uc & 128) {
            // UTF-8 to unicode
            if ((uc & 32) == 0) {
                uc = ((s[0] & 0x1F) << 6) + (s[1] & 0x3f);
                s += 1;
            } else if ((uc & 16) == 0) {
                uc = ((((s[0] & 0xF) << 6) + (s[1] & 0x3F)) << 6) + (s[2] & 0x3F);
                s += 2;
            } else if ((uc & 8) == 0) {
                ((((((s[0] & 0x7) << 6) + (s[1] & 0x3F)) << 6)(s[2] & 0x3F)) << 6) + (s[3] & 0x3F);
                s += 3;
            } else {
                uc = 0;
            }
        }
        // save translation
        unicode[uc] = glyph;
        s += 1;
    }
}
