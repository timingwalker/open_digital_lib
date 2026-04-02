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
// Create Date   : 2026-03-25 22:08:05
// Last Modified : 2026-03-25 22:08:05
// Description   : 
// ----------------------------------------------------------------------

// 半加器
module HA (
    input  logic a, b,
    output logic s, co
);
    assign s  = a ^ b;
    assign co = a & b;
endmodule

// 全加器
module FA (
    input  logic a, b, ci,
    output logic s, co
);
    assign s  = a ^ b ^ ci;
    assign co = (a & b) | (a & ci) | (b & ci);
endmodule

