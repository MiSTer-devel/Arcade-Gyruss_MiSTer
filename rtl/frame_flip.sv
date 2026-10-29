//============================================================================
//
//  Frame buffer flip screen.
//
//  Gyruss' has no flipscreen
//  so buffer the pixel stream in BRAM and read it back in reverse
//
//============================================================================

module frame_flip #(
	parameter WIDTH  = 256,
	parameter HEIGHT = 224
)
(
	input               clk,
	input               ce_pix,
	input      [7:0]    rgb_in,
	input               hblank,     // active high
	input               vblank,     // active high
	input               vsync,      // active high
	input               flip,
	output     [7:0]    rgb_out
);

localparam PIXELS = WIDTH * HEIGHT;
localparam AW     = $clog2(2 * PIXELS);

reg  [7:0] x = 0;
reg  [7:0] y = 0;
reg        old_hblank = 0;
reg        old_vsync  = 0;

always @(posedge clk) begin
	if (ce_pix) begin
		old_hblank <= hblank;
		old_vsync  <= vsync;

		if (hblank)
			x <= 0;
		else
			x <= x + 8'd1;

		if (vblank)
			y <= 0;
		else if (hblank && !old_hblank)
			y <= (y == HEIGHT - 1) ? 8'd0 : y + 8'd1;
	end
end

wire [8:0] xa = {1'b0, x} + 9'd1;
wire [7:0] rx = xa[7:0];
wire [8:0] ya = {1'b0, y} + xa[8];
wire [7:0] ry = (ya >= HEIGHT) ? (ya - HEIGHT) : ya[7:0];

// Two buffers: the frame being written and the previous one being read back.
// A single buffer would tear at the halfway point
reg  [7:0] mem [0:2*PIXELS-1];
reg  [7:0] q = 0;
reg  [7:0] last_pixel = 0;
reg        wr_buf = 0;
reg        rd_buf = 1;

// Blank the first two frames after flip is enabled
reg  [1:0] prime = 0;

wire [AW-2:0] wr_off = y * WIDTH + x;
wire [AW-2:0] rd_off = (HEIGHT - 1 - ry) * WIDTH + (WIDTH - 1 - rx);
wire [AW-1:0] wr_addr = wr_buf ? (PIXELS + wr_off) : wr_off;
wire [AW-1:0] rd_addr = rd_buf ? (PIXELS + rd_off) : rd_off;

always @(posedge clk) begin
	if (!flip) begin
		prime  <= 0;
		wr_buf <= 0;
		rd_buf <= 1;
	end
	else begin
		if (ce_pix && vsync && !old_vsync) begin
			rd_buf <= wr_buf;
			wr_buf <= ~wr_buf;
			if (prime != 2'd2)
				prime <= prime + 2'd1;
		end
	end

	if (flip && ce_pix && !hblank && !vblank) begin
		mem[wr_addr] <= rgb_in;

		if (x == WIDTH - 1 && y == HEIGHT - 1)
			last_pixel <= rgb_in;
		q <= mem[rd_addr];
	end
end

wire [7:0] buf_pixel = ((x == 0) && (y == 0)) ? last_pixel : q;

assign rgb_out = flip ? ((prime == 2'd2) ? buf_pixel : 8'd0) : rgb_in;

endmodule
