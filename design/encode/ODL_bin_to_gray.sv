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
// Create Date   : 2026-03-23 21:14:30
// Last Modified : 2026-03-23 21:17:27
// Description   : Binary to gray
// ----------------------------------------------------------------------

module ODL_bin_to_gray #(
    parameter int WIDTH = 8
)(
    input  logic [WIDTH-1:0]     bin_i
   ,output logic [WIDTH-1:0]     gray_o
);

    assign gray_o[WIDTH-1] = bin_i[WIDTH-1];
    for (genvar i=0; i<WIDTH-1; i++) begin : gen_bin_to_gray
        assign gray_o[i] = bin_i[i] ^ bin_i[i+1];
    end

endmodule

