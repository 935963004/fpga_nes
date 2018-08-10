module ppu_bg
(
    input wire clk_in,
    input wire rst_in,
    input wire [9:0] nes_x_in,
    input wire [9:0] nes_y_in,
    input wire [9:0] nes_y_next_in,
    input wire pix_pulse_in,
    input wire [7:0] vram_d_in,
    input wire ri_upd_cntrs_in,//update counters from scroll regs(after 0x2006 write)
    input wire ri_inc_addr_in,
    input wire ri_inc_addr_amt_in,
    input wire en_in,//enable background
    input wire ls_clip_in,//clip background in left 8 pixels
    input wire [2:0] fv_in,
    input wire [4:0] vt_in,
    input wire v_in,
    input wire [2:0] fh_in,
    input wire [4:0] ht_in,
    input wire h_in,
    input wire s_in,//playfied pattern table selection reg value
    output reg [13:0] vram_a_out,
    output wire [3:0] palette_idx_out
);

reg upd_v;
reg upd_h;
reg inc_v;
reg inc_h;
reg [8:0] q_bg_shift3, d_bg_shift3;
reg [8:0] q_bg_shift2, d_bg_shift2;
reg [16:0] q_bg_shift1, d_bg_shift1;
reg [16:0] q_bg_shift0, d_bg_shift0;
reg [2:0] q_fv, d_fv;
reg [4:0] q_vt, d_vt;
reg q_v, d_v;
reg [4:0] q_ht, d_ht;
reg q_h, d_h;
reg [7:0] q_ni, d_ni;//nametable tile index
reg [1:0] q_a, d_a;//tile attribute value latch(bits 3 and 2)
reg [7:0] q_p0, d_p0;//palette data 0(bit 0 for tile)
reg [7:0] q_p1, d_p1;

always @(posedge clk_in)
  begin
    if(rst_in)
      begin
        q_fv <= 2'h0;
        q_vt <= 5'h00;
        q_v <= 1'h0;
        q_ht <= 5'h00;
        q_h <= 1'h0;
        q_bg_shift3 <= 9'h000;
        q_bg_shift2 <= 9'h000;
        q_bg_shift1 <= 16'h0000;
        q_bg_shift0 <= 16'h0000;
        q_ni <= 8'h00;
        q_a <= 2'h0;
        q_p0 <= 8'h00;
        q_p1 <= 8'h00;
      end
    else
      begin
        q_fv <= d_fv;
        q_vt <= d_vt;
        q_v <= d_v;
        q_ht <= d_ht;
        q_h <= d_h;
        q_bg_shift3 <= d_bg_shift3;
        q_bg_shift2 <= d_bg_shift2;
        q_bg_shift1 <= d_bg_shift1;
        q_bg_shift0 <= d_bg_shift0;
        q_ni <= d_ni;
        q_a <= d_a;
        q_p0 <= d_p0;
        q_p1 <= d_p1;
      end
  end

always @*
  begin
    d_ni = q_ni;
    d_a = q_a;
    d_p0 = q_p0;
    d_p1 = q_p1;
    d_bg_shift3 = q_bg_shift3;
    d_bg_shift2 = q_bg_shift2;
    d_bg_shift1 = q_bg_shift1;
    d_bg_shift0 = q_bg_shift0;
    upd_v = 1'b0;
    inc_v = 1'b0;
    upd_h = 1'b0;
    inc_h = 1'b0;
    d_fv = q_fv;
    d_v = q_v;
    d_h = q_h;
    d_vt = q_vt;
    d_ht = q_ht;
    vram_a_out = { q_fv[1:0], q_v, q_h, q_vt, q_ht };
    if(ri_inc_addr_in)
      begin
        if(ri_inc_addr_amt_in)
          { d_fv, d_v, d_h, d_vt } = { q_fv, q_v, q_h, q_vt } + 10'h001;
        else
          { d_fv, d_v, d_h, d_vt, d_ht } = { q_fv, q_v, q_h, q_vt, q_ht } + 15'h0001;
      end
    else
      begin
        if(inc_v)
          begin
            if({ q_vt, q_fv } == { 5'b11101, 3'b111 })
              { d_v, d_vt, d_fv } = { ~q_v, 8'h00 };
            else
              { d_v, d_vt, d_fv } = { q_v, d_vt, d_fv } + 9'h001;
          end
        if(inc_h)
          { d_h, d_ht } = { q_h, q_ht } + 6'h01;
        if(ri_upd_cntrs_in)
          begin
            d_v = v_in;
            d_vt = vt_in;
            d_fv = fv_in;
            d_h = h_in;
            d_ht = ht_in;
          end
        else
          begin
            if(upd_v)
              begin
                d_v = v_in;
                d_vt = vt_in;
                d_fv = fv_in;
              end
            if(upd_h)
              begin
                d_h = h_in;
                d_ht = ht_in;
              end
          end
      end

    if((nes_y_in < 239 || nes_y_next_in == 0) && en_in)
      begin
        if(pix_pulse_in && nes_x_in == 319)
          begin
            upd_h = 1'b1;
            if(nes_y_next_in != nes_y_in)
              begin
                if(nes_y_next_in == 0)
                  upd_v = 1'b1;
                else
                  inc_v = 1'b1;
              end
          end
        
        if(nes_x_in < 256 || (nes_x_in >= 320 && nes_x_in < 336))
          begin
            if(pix_pulse_in)
              begin
                d_bg_shift0 = { 1'b0, q_bg_shift0[15:1] };
                d_bg_shift1 = { 1'b0, q_bg_shift1[15:1] };
                d_bg_shift2 = { q_bg_shift2[7], q_bg_shift2[7:1] };
                d_bg_shift3 = { q_bg_shift3[7], q_bg_shift3[7:1] };
                if(nes_x_in[2:0] == 3'h7)
                  begin
                    d_bg_shift0[15:8] = { q_p0[0], q_p0[1], q_p0[1], q_p0[2],
                    q_p0[3], q_p0[4], q_p0[5], q_p0[6], q_p0[7] };
                    d_bg_shift1[15:8] = { q_p1[0], q_p1[1], q_p1[1], q_p1[2],
                    q_p1[3], q_p1[4], q_p1[5], q_p1[6], q_p1[7] };
                    d_bg_shift2[8] = q_a[0];
                    d_bg_shift3[8] = q_a[1];
                    inc_h  = 1'b1;
                  end
              end
            
            case(nes_x_in[2:0])
              3'b000:
                begin
                  vram_a_out = { 2'b10, q_v, q_h, q_vt, q_ht };
                  d_ni = vram_d_in;
                end
              3'b001:
                begin
                  vram_a_out = { 2'b10, q_v, q_h, 4'b1111, q_vt[4:2], q_ht[4:2] };
                  if(q_vt[1] == 1'b0 && q_ht[1] == 1'b0)
                    d_a = vram_d_in[1:0];
                  else if(q_vt[1] == 1'b0 && q_ht[1] == 1'b1)
                    d_a = vram_d_in[3:2];
                  else if(q_vt[1] == 1'b1 && q_ht[1] == 1'b0)
                    d_a = vram_d_in[5:4];
                  else
                    d_a = vram_d_in[7:6];
                end
              3'b010:
                begin
                  vram_a_out = { 1'b0, s_in, q_ni, 1'b0, q_fv };
                  d_p0 = vram_d_in;
                end
              3'b011:
                begin
                  vram_a_out = { 1'b0, s_in, q_ni, 1'b1, q_fv };
                  d_p1 = vram_d_in;
                end
            endcase
          end
      end
  end

assign palette_idx_out = (!ls_clip_in && en_in) ? { q_bg_shift3[fh_in], q_bg_shift2[fh_in],
q_bg_shift1[fh_in], q_bg_shift0[fh_in] } : 4'h0;

endmodule