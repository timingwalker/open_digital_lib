// ----------------------------------------------------------------------
// Copyright 2026 TimingWalker
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ----------------------------------------------------------------------
// Create Date   : 2018
// Last Modified : 2026-03-24 21:39:27
// Description   : 
// ----------------------------------------------------------------------

module CTRL(
    input               clk             ,
    input               rst_n           ,
    input               start           ,
    output              start_pos       ,
    output reg          start_pos_1d    ,
    output              key_update      ,
    output              state_update    ,
    output              isLastRound     ,
    output reg [7:0]    rcon
);

reg             start_1d            ;
reg             start_2d            ;
reg             start_3d            ;
reg             state_pos_1d        ;
reg      [3:0]  round_cnt           ;
reg             valid               ;


assign start_pos = start_2d & (~start_3d);
always @ (posedge clk or negedge rst_n) begin
    if ( rst_n == 1'b0 ) begin
        start_1d <= 1'b0;
        start_2d <= 1'b0;
        start_3d <= 1'b0;
    end
    else begin
        start_1d <= start;
        start_2d <= start_1d;
        start_3d <= start_2d;
    end
end

always @ (posedge clk or negedge rst_n) begin
    if ( rst_n == 1'b0 ) begin
        start_pos_1d <= 1'b0;
    end
    else begin
        start_pos_1d <= start_pos;
    end
end

always @ (posedge clk or negedge rst_n) begin
    if ( rst_n == 1'b0 ) begin
        round_cnt <= 4'd0;
    end
    else if (start_pos == 1'b1) begin
        round_cnt <= 4'd1;
    end
    else if (round_cnt == 4'd11) begin
        round_cnt <= 4'd0;
    end
    else if (round_cnt != 4'd0) begin
        round_cnt <= round_cnt + 4'd1;
    end
end

assign state_update = |round_cnt[3:0];
assign key_update = start_pos | state_update;
assign isLastRound = (round_cnt == 4'hb) ? 1'b1 : 1'b0;

always @ (posedge clk or negedge rst_n) begin
    if ( rst_n == 1'b0 ) begin
        valid <= 1'b0;
    end
    else if (start_pos == 1'b1) begin
        valid <= 1'b0;
    end
    else if (round_cnt == 4'd11) begin
        valid <= 1'b1;
    end
    else;
end

always @(*) begin
    case(round_cnt)
        4'h0: rcon = 8'h0;
        4'h1: rcon = 8'h1;
        4'h2: rcon = 8'h2;
        4'h3: rcon = 8'h4;
        4'h4: rcon = 8'h8;
        4'h5: rcon = 8'h10;
        4'h6: rcon = 8'h20;
        4'h7: rcon = 8'h40;
        4'h8: rcon = 8'h80;
        4'h9: rcon = 8'h1b;
        4'ha: rcon = 8'h36;
        4'hb: rcon = 8'h0;
        default: rcon = 8'h0;
    endcase
end

endmodule

