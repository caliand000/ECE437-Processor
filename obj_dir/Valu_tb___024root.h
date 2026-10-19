// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Valu_tb.h for the primary calling header

#ifndef VERILATED_VALU_TB___024ROOT_H_
#define VERILATED_VALU_TB___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Valu_tb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Valu_tb___024root final {
  public:

    // DESIGN-SPECIFIC STATE
    CData/*0:0*/ alu_tb__DOT__CLK;
    CData/*0:0*/ alu_tb__DOT__nRST;
    CData/*4:0*/ alu_tb__DOT__opcode;
    CData/*0:0*/ alu_tb__DOT__zero;
    CData/*0:0*/ alu_tb__DOT__negative;
    CData/*0:0*/ alu_tb__DOT__overflow;
    IData/*31:0*/ alu_tb__DOT__A;
    IData/*31:0*/ alu_tb__DOT__B;
    IData/*31:0*/ alu_tb__DOT__DUT__DOT__intermediate_result;
    IData/*31:0*/ __Vi;
    VlUnpacked<QData/*63:0*/, 1> __VstlTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VicoTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggeredAcc;
    VlUnpacked<QData/*63:0*/, 1> __VnbaTriggered;
    VlDelayScheduler __VdlySched;

    // INTERNAL VARIABLES
    Valu_tb__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Valu_tb___024root(Valu_tb__Syms* symsp, const char* namep);
    ~Valu_tb___024root();
    VL_UNCOPYABLE(Valu_tb___024root);

    // INTERNAL METHODS
};


#endif  // guard
