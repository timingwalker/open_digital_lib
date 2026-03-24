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
// Create Date   : 2024-03-26 21:27:37
// Last Modified : 2024-03-26 21:41:14
// Description   :
// ----------------------------------------------------------------------

module ODL_rst_sync(
     input  logic                        clk_i
    ,input  logic                        rst_ni
    ,output logic                        rstn_sync_o
);

    logic rstn, rstn_1d, rstn_2d, rstn_3d, rstn_4d;

    always_ff @(posedge clk_i, negedge rst_ni)
    begin
        if (~rst_ni)
        begin
            rstn    <= 1'b0;
            rstn_1d <= 1'b0;
            rstn_2d <= 1'b0;
            rstn_3d <= 1'b0;
            rstn_4d <= 1'b0;
        end
        else
        begin
            rstn    <= 1'b1;
            rstn_1d <= rstn;
            rstn_2d <= rstn_1d;
            rstn_3d <= rstn_2d;
            rstn_4d <= rstn_3d;
        end
    end

    assign rstn_sync_o = rstn_4d;

endmodule
