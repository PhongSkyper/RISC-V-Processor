// ============================================================================
// BRC - Branch Comparison Unit (rule-compliant)
// - Unsigned less: from comparator_32bit_unsigned (ripple compare)
// - Signed less  : sign-bit logic + unsigned-less (two's complement order)
// - Equality     : XOR-reduction (domain independent)
// ============================================================================
module brc (
  input  logic [31:0] i_rs1_data,
  input  logic [31:0] i_rs2_data,
  input  logic        i_br_un,     // 1: unsigned (BLTU/BGEU), 0: signed (BLT/BGE)
  output logic        o_br_less,
  output logic        o_br_equal
);

  // --- Unsigned comparator (ripple) ---
  logic u_less;
  logic u_eq_unused; // equality computed independently below
  comparator_32bit_unsigned ucmp_u (
    .a     (i_rs1_data),
    .b     (i_rs2_data),
    .less  (u_less),
    .equal (u_eq_unused)
  );

  // --- Equality (robust, domain-independent) ---
  // eq = NOT(OR of all bitwise differences)
  assign o_br_equal = ~(|(i_rs1_data ^ i_rs2_data));

  // --- Signed less without '<' ---
  // If signs differ: negative < positive.
  // If signs same  : use unsigned-less (order preserved in 2's complement).
  logic sa, sb, signs_diff, s_less;
  assign sa         = i_rs1_data[31];
  assign sb         = i_rs2_data[31];
  assign signs_diff = sa ^ sb;
  assign s_less     = (signs_diff & sa) | ((~signs_diff) & u_less);

  // --- Select mode (unsigned vs signed) ---
  assign o_br_less  = i_br_un ? u_less : s_less;

endmodule
