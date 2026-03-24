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
// Create Date   : 2026-03-23 21:18:19
// Last Modified : 2026-03-23 21:26:52
// Description   : onehot to binary
// ----------------------------------------------------------------------

module ODL_onehot_to_bin #(
     parameter int ONEHOT_WIDTH = 8
    ,parameter int BIN_WIDTH = $clog2(ONEHOT_WIDTH)
)(
    input  logic [ONEHOT_WIDTH-1:0]     onehot_i
   ,output logic [BIN_WIDTH-1:0]        bin_o
);

    for (genvar j=0; j<BIN_WIDTH; j++) begin: for_each_binary_bit
        logic [ONEHOT_WIDTH-1:0] tmp_mask;
            for (genvar i=0; i<ONEHOT_WIDTH; i++) begin : select_onehot_bits_to_gen_this_binary_bit
                logic [BIN_WIDTH-1:0] tmp_i;
                assign tmp_i = i;
                assign tmp_mask[i] = tmp_i[j];
            end
        assign bin_o[j] = |(tmp_mask & onehot_i);
    end


endmodule

