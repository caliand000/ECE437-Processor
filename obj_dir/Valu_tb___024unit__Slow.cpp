// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Valu_tb.h for the primary calling header

#include "Valu_tb__pch.h"
#include "Valu_tb__Syms.h"
#include "Valu_tb___024unit.h"

void Valu_tb___024unit___ctor_var_reset(Valu_tb___024unit* vlSelf);

Valu_tb___024unit::Valu_tb___024unit(Valu_tb__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Valu_tb___024unit___ctor_var_reset(this);
}

void Valu_tb___024unit::__Vconfigure(bool first) {
    if (false && first) {}  // Prevent unused
}

Valu_tb___024unit::~Valu_tb___024unit() {
}
