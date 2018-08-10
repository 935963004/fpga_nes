module ppu_ri
(
  input wire clk_in,
  input wire rst_in,
  input wire [2:0] sel_in,
  input wire ncs_in,//register interface enable
  input wire r_rw_in,
  input wire [7:0] cpu_d_in,
  input wire [13:0] vram_a_in,
  inout wire [7:0] vram_d_in,
  input wire [7:0] pram_d_in,
  input wire vblank_in,
  output wire [7:0] cpu_d_out,
  output reg [7:0] vram_d_out,
  output reg vram_wr_out,
  output reg pram_wr_out,
  output wire [2:0] fv_out,
  output wire [4:0] vt_out,
  output wire v_out,
  output wire [2:0] fh_out,
  output wire [4:0] ht_out,
  output wire h_out,
  output wire s_out,
  output reg inc_addr_out,
  output wire inc_addr_amt_out,
  output wire nvbl_en_out,//enable nmi on vertical blank
  output wire vblank_out,
  output wire bg_en_out,
  output wire bg_ls_clip_out,
  output wire upd_cntrs_out
);

reg [7:0] q_cpu_d_out, d_cpu_d_out;
reg q_upd_cntrs_out, d_upd_cntrs_out;
reg q_nvbl_en, d_nvbl_en;
reg q_addr_incr, d_addr_incr;
reg q_bg_en, d_bg_en;
reg q_bg_ls_clip, d_bg_ls_clip;
reg q_vblank, d_vblank;
reg q_fs, d_fs;
reg [7:0] q_rd_buf, d_rd_buf;
reg q_rd, d_rd;
reg q_ncs_in;//last ncs signal
reg q_vblank_in;
reg [2:0] q_fv, d_fv;
reg [4:0] q_vt, d_vt;
reg q_v, d_v;
reg [2:0] q_fh, d_fh;
reg [4:0] q_ht, d_ht;
reg q_h, d_h;
reg q_s, d_s;

always @(posedge clk_in)
  begin
    if(rst_in)
      begin
        q_cpu_d_out <= 8'h00;
        q_upd_cntrs_out <= 1'h0;
        q_nvbl_en <= 1'h0;
        q_addr_incr <= 1'h0;
        q_bg_en <= 1'h0;
        q_bg_ls_clip <= 1'h0;
        q_vblank <= 1'h0;
        q_fs <= 1'h0;
        q_rd_buf <= 8'h00;
        q_rd <= 1'h0;
        q_ncs_in <= 1'h1;
        q_vblank_in <= 1'h0;
        q_fv <= 2'h0;
        q_vt <= 5'h00;
        q_v <= 1'h0;
        q_fh <= 3'h0;
        q_h <= 1'h0;
        q_s <= 1'h0;
      end
    else
      begin
        q_cpu_d_out <= d_cpu_d_out;
        q_upd_cntrs_out <= d_upd_cntrs_out;
        q_nvbl_en <= d_nvbl_en;
        q_addr_incr <= d_addr_incr;
        q_bg_en <= d_bg_en;
        q_bg_ls_clip <= d_bg_ls_clip;
        q_vblank <= d_vblank;
        q_fs <= d_fs;
        q_rd_buf <= d_rd_buf;
        q_rd <= d_rd;
        q_ncs_in <= ncs_in;
        q_vblank_in <= vblank_in;
        q_fv <= d_fv;
        q_vt <= d_vt;
        q_v <= d_v;
        q_fh <= d_fh;
        q_h <= d_h;
        q_s <= d_s;
      end
  end

always @*
  begin
    d_cpu_d_out = q_cpu_d_out;
    d_nvbl_en = q_nvbl_en;
    d_addr_incr = q_addr_incr;
    d_bg_en = q_bg_en;
    d_bg_ls_clip = q_bg_ls_clip;
    d_fs = q_fs;
    d_rd_buf = (q_rd) ? vram_d_in : q_rd_buf;
    d_rd = 1'b0;
    d_upd_cntrs_out = 1'b0;
    d_vblank = (q_vblank_in == 1'b0 && vblank_in == 1'b1) ? 1'b1 : (~vblank_in) ? 1'b0 : q_vblank;
    vram_wr_out = 1'b0;
    vram_d_out = 8'h00;
    pram_wr_out = 1'b0;
    inc_addr_out = 1'b0;
    d_fv = q_fv;
    d_vt = q_vt;
    d_v = q_v;
    d_fh = q_fh;
    d_ht = q_ht;
    d_h = q_h;
    d_s = q_s;

    if(q_ncs_in == 1'b1 && ncs_in == 1'b0)
      begin
        case(sel_in)
          3'h0:
            begin
              d_nvbl_en = cpu_d_in[7];
              d_s = cpu_d_in[4];
              d_addr_incr = cpu_d_in[2];
              d_v = cpu_d_in[1];
              d_h = cpu_d_in[0];
            end
          3'h1:
            begin
              d_bg_en = cpu_d_in[3];
              d_bg_ls_clip = cpu_d_in[1];
            end
          3'h2:
            begin
              d_cpu_d_out = { q_vblank, 7'b0000000 };
              d_fs = 1'b0;
              d_vblank = 1'b0;
            end
          3'h5:
            begin
              d_fs = ~q_fs;
              if(~q_fs)
                begin
                  d_fh = cpu_d_in[2:0];
                  d_ht = cpu_d_in[7:3];
                end
              else
                begin
                  d_fv = cpu_d_in[2:0];
                  d_ht = cpu_d_in[7:3];
                end
            end
          3'h6:
            begin
              d_fs = ~q_fs;
              if(~q_fs)
                begin
                  d_fv = { 1'b0, cpu_d_in[5:4] };
                  d_v = cpu_d_in[3];
                  d_h = cpu_d_in[2];
                  d_vt[4:3] = cpu_d_in[1:0];
                end
              else
                begin
                  d_vt[2:0] = cpu_d_in[7:5];
                  d_ht = cpu_d_in[4:0];
                  d_upd_cntrs_out = 1'b1;
                end
            end
          3'h7:
            begin
              if(r_rw_in)
                begin
                  d_cpu_d_out = (vram_a_in[13:8] == 6'h3F) ? pram_d_in : q_rd_buf;
                  d_rd = 1'b1;
                  inc_addr_out = 1'b1;
                end
              else
                begin
                  if(vram_a_in[13:8] == 6'h3F)
                    pram_wr_out = 1'b1;
                  else
                    vram_wr_out = 1'b1;
                  vram_d_out = cpu_d_in;
                  inc_addr_out = 1'b1;
                end
            end
        endcase
      end
  end

assign fv_out = q_fv;
assign vt_out = q_vt;
assign v_out = q_v;
assign fh_out = q_fh;
assign ht_out = q_ht;
assign h_out = q_h;
assign s_out = q_s;
assign inc_addr_amt_out = q_addr_incr;
assign nvbl_en_out = q_nvbl_en;
assign vblank_out = q_vblank;
assign bg_en_out = q_bg_en;
assign bg_ls_clip_out = q_bg_ls_clip;
assign upd_cntrs_out = q_upd_cntrs_out;
assign cpu_d_out = (!ncs_in & r_rw_in) ? q_cpu_d_out : 8'h00;

endmodule