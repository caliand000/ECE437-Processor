// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Valu_tb.h for the primary calling header

#ifndef VERILATED_VALU_TB___024UNIT_H_
#define VERILATED_VALU_TB___024UNIT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Valu_tb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Valu_tb___024unit final : public VerilatedModule {
  public:

    // INTERNAL VARIABLES
    Valu_tb__Syms* const vlSymsp;

    // CONSTRUCTORS
    Valu_tb___024unit(Valu_tb__Syms* symsp, const char* v__name);
    ~Valu_tb___024unit();
    VL_UNCOPYABLE(Valu_tb___024unit);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
