// =============================================================================
// 33-bit Signed Multiplier
// Modified Booth Encoding (Radix-4) + Wallace Tree
//
// Stage 1 is dynamically optimized per column based on input count.
// Stages 2-6 use a fixed structure to guarantee correct carry propagation.
// =============================================================================

module ODL_mult_booth_33 (
    input  logic signed [32:0] X,
    input  logic signed [32:0] Y,
    output logic signed [65:0] P
);

    // =====================================================================
    // 1. Modified Booth Encoding  (17 groups, radix-4)
    // =====================================================================
    wire [34:0] Y_ext = {Y[32], Y, 1'b0};
    genvar i, j;

    generate for (i = 0; i < 17; i++) begin : booth
        wire [2:0] grp    = {Y_ext[2*i+2], Y_ext[2*i+1], Y_ext[2*i]};
        wire       neg    = (grp inside {3'b100, 3'b101, 3'b110});
        wire       zero   = (grp inside {3'b000, 3'b111});
        wire       two    = (grp inside {3'b011, 3'b100});

        wire [34:0] X_se  = {{2{X[32]}}, X};
        wire [34:0] X_2x  = {X[32], X, 1'b0};
        wire [34:0] X_sel = zero ? 35'b0 : (two ? X_2x : X_se);
        wire [34:0] X_pp  = neg  ? (~X_sel + 35'b1) : X_sel;
        wire       pp_sign = X_pp[34];
    end endgenerate

    // =====================================================================
    // 2. Partial-Product Matrix   (17 rows × 67 cols)
    // =====================================================================
    logic [16:0][66:0] pp;

    generate for (i = 0; i < 17; i++) begin : pp_row
        localparam int LO = 2*i, HI = 2*i + 34;
        for (j = 0; j < 67; j++) begin : pp_col
            if      (j < LO)  assign pp[i][j] = 1'b0;
            else if (j <= HI) assign pp[i][j] = booth[i].X_pp[j - LO];
            else              assign pp[i][j] = booth[i].pp_sign;
        end
    end endgenerate

    // =====================================================================
    // 3. Wallace Tree Compression
    //
    // Stage 1: N inputs → ceil(N/3) FA + optional HA.
    //          Row indices: FA sums at [0..NFA-1],
    //                       HA sum / pass-through at [NFA]  (if REM > 0).
    //                       FA carries at [6..5+NFA],
    //                       HA carry  at [6+NFA]           (if REM == 2).
    //          Unused rows are zero-filled.
    //
    // Stages 2-6: Fixed structure.  Unused inputs are guaranteed 0
    //             by upstream zero-fill, so synthesis prunes the resulting
    //             dangling logic automatically.
    // =====================================================================

    logic [11:0][67:0] s1;   // Stage 1
    logic [ 7:0][67:0] s2;   // Stage 2
    logic [ 5:0][67:0] s3;   // Stage 3
    logic [ 3:0][67:0] s4;   // Stage 4
    logic [ 2:0][67:0] s5;   // Stage 5
    logic [ 1:0][67:0] s6;   // Stage 6

    // -----------------------------------------------------------------
    // Stage 1 — Dynamic: allocate FA/HA per column based on input count
    // -----------------------------------------------------------------
    generate for (j = 0; j < 67; j++) begin : stg1
        localparam int N    = (j < 32) ? (j/2 + 1) : 17;
        localparam int NFA  = N / 3;
        localparam int REM  = N % 3;
        localparam int NSUM = NFA + (REM >  0 ? 1 : 0);
        localparam int NCRY = NFA + (REM == 2 ? 1 : 0);

        for (i = 0; i < NFA; i++) begin : fa
            FA u (.a(pp[3*i][j]), .b(pp[3*i+1][j]), .ci(pp[3*i+2][j]),
                  .s(s1[i][j]), .co(s1[i+6][j+1]));
        end

        if (REM == 1) begin : pass1
            assign s1[NFA][j] = pp[3*NFA][j];
        end else if (REM == 2) begin : ha1
            HA u (.a(pp[3*NFA][j]), .b(pp[3*NFA+1][j]),
                  .s(s1[NFA][j]), .co(s1[NFA+6][j+1]));
        end

        for (i = NSUM; i < 6;  i++) begin : zs  assign s1[  i][j] = 1'b0; end
        for (i = NCRY; i < 6;  i++) begin : zc  assign s1[i+6][j] = 1'b0; end
    end endgenerate

    // -----------------------------------------------------------------
    // Stage 2 — Fixed: 4 FAs per column
    // -----------------------------------------------------------------
    generate for (j = 0; j < 67; j++) begin : stg2
        FA u0 (.a(s1[0][j]),  .b(s1[1][j]),  .ci(s1[2][j]),
               .s(s2[0][j]),  .co(s2[4][j+1]));
        FA u1 (.a(s1[3][j]),  .b(s1[4][j]),  .ci(s1[5][j]),
               .s(s2[1][j]),  .co(s2[5][j+1]));
        FA u2 (.a(s1[6][j]),  .b(s1[7][j]),  .ci(s1[8][j]),
               .s(s2[2][j]),  .co(s2[6][j+1]));
        FA u3 (.a(s1[9][j]),  .b(s1[10][j]), .ci(s1[11][j]),
               .s(s2[3][j]),  .co(s2[7][j+1]));
    end
        assign s2[4][0] = 0; assign s2[5][0] = 0;
        assign s2[6][0] = 0; assign s2[7][0] = 0;
    endgenerate

    // -----------------------------------------------------------------
    // Stage 3 — Fixed: 2 FAs + 2 pass-through
    // -----------------------------------------------------------------
    generate for (j = 0; j < 67; j++) begin : stg3
        FA u0 (.a(s2[0][j]), .b(s2[1][j]), .ci(s2[2][j]),
               .s(s3[0][j]), .co(s3[4][j+1]));
        FA u1 (.a(s2[3][j]), .b(s2[4][j]), .ci(s2[5][j]),
               .s(s3[1][j]), .co(s3[5][j+1]));
        assign s3[2][j] = s2[6][j];
        assign s3[3][j] = s2[7][j];
    end
        assign s3[4][0] = 0; assign s3[5][0] = 0;
    endgenerate

    // -----------------------------------------------------------------
    // Stage 4 — Fixed: 2 FAs
    // -----------------------------------------------------------------
    generate for (j = 0; j < 67; j++) begin : stg4
        FA u0 (.a(s3[0][j]), .b(s3[1][j]), .ci(s3[2][j]),
               .s(s4[0][j]), .co(s4[2][j+1]));
        FA u1 (.a(s3[3][j]), .b(s3[4][j]), .ci(s3[5][j]),
               .s(s4[1][j]), .co(s4[3][j+1]));
    end
        assign s4[2][0] = 0; assign s4[3][0] = 0;
    endgenerate

    // -----------------------------------------------------------------
    // Stage 5 — Fixed: 1 FA + 1 pass-through
    // -----------------------------------------------------------------
    generate for (j = 0; j < 67; j++) begin : stg5
        FA u (.a(s4[0][j]), .b(s4[1][j]), .ci(s4[2][j]),
              .s(s5[0][j]), .co(s5[2][j+1]));
        assign s5[1][j] = s4[3][j];
    end
        assign s5[2][0] = 0;
    endgenerate

    // -----------------------------------------------------------------
    // Stage 6 — Final: 1 FA
    // -----------------------------------------------------------------
    generate for (j = 0; j < 67; j++) begin : stg6
        FA u (.a(s5[0][j]), .b(s5[1][j]), .ci(s5[2][j]),
              .s(s6[0][j]), .co(s6[1][j+1]));
    end endgenerate

    // =====================================================================
    // 4. Final Carry-Propagate Addition
    // =====================================================================
    assign P = s6[0][65:0] + s6[1][65:0];

endmodule
