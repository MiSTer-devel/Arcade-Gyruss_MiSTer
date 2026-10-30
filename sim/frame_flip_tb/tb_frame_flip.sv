//============================================================================
//
//  frame_flip testbench.
//
//  Generates a 256x224 raster, one pixel per ce_pix, and checks:
//    - flip off: the output stream is the input stream, unchanged;
//    - flip on:  output frame N is input frame N-1 reversed, which is the
//                same frame rotated 180 degrees.
//
//============================================================================

`timescale 1ns/1ps

module tb_frame_flip;

localparam W = 256;
localparam H = 224;
localparam PIX = W * H;
localparam HBLANK = 128;
localparam VLINES = 24;
localparam VSYNC_LINES = 8;

reg clk = 0;
always #10 clk = ~clk;

reg [2:0] div = 0;
reg       ce_pix = 0;
always @(posedge clk) begin
	div    <= div + 3'd1;
	ce_pix <= (div == 3'd6);
end

reg  [7:0] rgb_in = 0;
reg        hblank = 1;
reg        vblank = 1;
reg        vsync  = 0;
reg        flip   = 0;
wire [7:0] rgb_out;

frame_flip dut
(
	.clk(clk),
	.ce_pix(ce_pix),
	.rgb_in(rgb_in),
	.hblank(hblank),
	.vblank(vblank),
	.vsync(vsync),
	.flip(flip),
	.rgb_out(rgb_out)
);

reg [7:0] in_all [0:PIX*8-1];
reg [7:0] out_all[0:PIX*8-1];
integer in_cnt = 0;
integer out_cnt = 0;

always @(posedge clk) begin
	if (ce_pix && !hblank && !vblank) begin
		out_all[out_cnt] = rgb_out;
		out_cnt = out_cnt + 1;
	end
end

// Wait for the next pixel slot. Returns after the ce_pix edge has consumed the
// values driven before the call, so the caller may drive the next pixel.
task automatic step;
begin
	@(negedge clk);
	while (!ce_pix) @(negedge clk);
	@(posedge clk);
	@(negedge clk);
end
endtask

task automatic gen_frame(input integer f);
	integer lx, ly, i;
begin
	for (ly = 0; ly < H; ly = ly + 1) begin
		for (lx = 0; lx < W; lx = lx + 1) begin
			hblank = 0;
			vblank = 0;
			vsync  = 0;
			rgb_in = (lx + 3*ly + 7*f) & 8'hFF;
			in_all[in_cnt] = rgb_in;
			in_cnt = in_cnt + 1;
			step;
		end
		hblank = 1;
		for (i = 0; i < HBLANK; i = i + 1)
			step;
	end
	vblank = 1;
	for (ly = 0; ly < VLINES; ly = ly + 1) begin
		hblank = 1;
		vsync  = (ly < VSYNC_LINES);
		for (i = 0; i < W + HBLANK; i = i + 1)
			step;
	end
	vsync = 0;
end
endtask

integer f, k, errors;

initial begin
	// ---- bypass: output must match input exactly ----
	flip = 0;
	gen_frame(0);
	gen_frame(1);

	errors = 0;
	if (out_cnt != in_cnt) begin
		$display("FAIL bypass: %0d output pixels, %0d input", out_cnt, in_cnt);
		errors = errors + 1;
	end
	for (k = 0; k < in_cnt; k = k + 1) begin
		if (out_all[k] !== in_all[k]) begin
			if (errors < 8)
				$display("FAIL bypass pixel %0d: out %02h in %02h", k, out_all[k], in_all[k]);
			errors = errors + 1;
		end
	end
	if (errors == 0)
		$display("PASS bypass: %0d pixels unchanged", in_cnt);

	// ---- flip: output frame N is input frame N-1 reversed ----
	in_cnt  = 0;
	out_cnt = 0;
	flip    = 1;
	for (f = 0; f < 6; f = f + 1)
		gen_frame(f);

	errors = 0;
	// frame 2 is the first complete buffered frame; compare 2..5
	for (f = 2; f < 6; f = f + 1) begin
		for (k = 0; k < PIX; k = k + 1) begin
			if (out_all[f*PIX + k] !== in_all[(f-1)*PIX + (PIX-1-k)]) begin
				if (errors < 8)
					$display("FAIL flip frame %0d pixel %0d: out %02h in %02h",
					         f, k, out_all[f*PIX + k], in_all[(f-1)*PIX + (PIX-1-k)]);
				errors = errors + 1;
			end
		end
	end
	if (errors == 0)
		$display("PASS flip: frames 2..5 are the previous frame rotated 180 degrees");
	else
		$display("FAIL flip: %0d mismatches", errors);

	$stop;
end

endmodule
