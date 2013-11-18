signature arm_decompLib =
sig
    val l3_arm_decompile: string -> Term.term quotation -> Thm.thm * Thm.thm
    val l3_arm_decompile_no_status:
       string -> Term.term quotation -> Thm.thm * Thm.thm

    val l3_arm_decompile32: string -> Term.term quotation -> Thm.thm * Thm.thm
    val l3_arm_decompile32_no_status:
       string -> Term.term quotation -> Thm.thm * Thm.thm

    val l3_arm_tools: helperLib.decompiler_tools
    val l3_arm_tools_array: helperLib.decompiler_tools
    val l3_arm_tools_array_no_status: helperLib.decompiler_tools
    val l3_arm_tools_mapped: helperLib.decompiler_tools
    val l3_arm_tools_mapped_no_status: helperLib.decompiler_tools
    val l3_arm_tools_mapped32: helperLib.decompiler_tools
    val l3_arm_tools_mapped32_no_status: helperLib.decompiler_tools
    val l3_arm_triples: string -> Thm.thm list
end