const limine = @import("limine");
const std = @import("std");

const PSF1_FONT_MAGIC = 0x0436;
const PSF2_FONT_MAGIC = 0x864ab572;

// The Limine requests can be placed anywhere, but it is important that
// the compiler does not optimise them away, so, usually, they should
// be made volatile or equivalent. In Zig, `export var` is what we use.
pub export var framebuffer_request: limine.FramebufferRequest = .{};

inline fn done() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

// The following will be our kernel's entry point.
export fn _start() callconv(.C) noreturn {
    fillFramebuffer();

    // We're done, just hang...
    done();
}

// fillFramebuffer calls writePixel which is probably inefficient see: https://wiki.osdev.org/Drawing_In_a_Linear_Framebuffer
fn fillFramebuffer() void {
    // Ensure we got a framebuffer.
    if (framebuffer_request.response) |framebuffer_response| {
        if (framebuffer_response.framebuffer_count < 1) {
            done();
        }

        // Get the first framebuffer's information.
        const framebuffer = framebuffer_response.framebuffers()[0];

        for (0..framebuffer.height) |y| {
            for (0..framebuffer.width) |x| {
                writePixel(framebuffer, @as(u64, x), @as(u64, y));
            }
        }
    }
}

fn writePixel(framebuffer: *limine.Framebuffer, x: u64, y: u64) void {
    // Calculate the pixel offset using the framebuffer information we obtained above.
    // We skip `i` scanlines (pitch is provided in bytes) and add `i * 4` to skip `i` pixels forward.
    // const pixel_offset = y * framebuffer.pitch + x * 4;
    const pixel_offset = y * framebuffer.pitch + x * 4;

    const blue = 0x000000FF;
    const green = blue << 8;
    const red = blue << (8 * 2);
    const alpha = blue << (8 * 3);

    switch (x) {
        // Blue
        0...250 => {
            @as(*u32, @ptrCast(@alignCast(framebuffer.address + pixel_offset))).* = blue;
        },
        // Green
        251...500 => {
            @as(*u32, @ptrCast(@alignCast(framebuffer.address + pixel_offset))).* = green;
        },
        // Red
        501...750 => {
            @as(*u32, @ptrCast(@alignCast(framebuffer.address + pixel_offset))).* = red;
        },
        // Alpha
        else => {
            @as(*u32, @ptrCast(@alignCast(framebuffer.address + pixel_offset))).* = alpha;
        },
    }
    // Write 0xFFFFFFFF to the provided pixel offset to fill it white.
    // @as(*u32, @ptrCast(@alignCast(framebuffer.address + pixel_offset))).* = 0x0000FF00;
}

// fn psfInit() void {
//     const glyph: u16 = undefined;
// }
