/*
 * Copyright (C) 2014 Palmer Dabbelt
 *   <palmer.dabbelt@eecs.berkeley.edu>
 *
 * This file is part of flo-llvm.
 *
 * flo-llvm is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * flo-llvm is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with flo-llvm.  If not, see
 * <http://www.gnu.org/licenses/>.
 */

#include "operation.h++"


operation::operation(std::shared_ptr<node>& dest,
                     const libflo::unknown<size_t>& width,
                     const libflo::opcode& op,
                     const std::vector<std::shared_ptr<node>>& s)
    : libflo::operation<node>(dest, width, op, s)
{
    if (strstr(d()->name().c_str(), ":") != NULL)
        d()->force_export();

    /* Most operations don't require anything else to be exported, but
     * registers require that their source is in the output file. */
    switch(op) {
    case libflo::opcode::ADD:
    case libflo::opcode::AND:
    case libflo::opcode::ARSH:
    case libflo::opcode::CAT:
    case libflo::opcode::CATD:
    case libflo::opcode::DIV:
    case libflo::opcode::EAT:
    case libflo::opcode::EQ:
    case libflo::opcode::GT:
    case libflo::opcode::GTE:
    case libflo::opcode::INIT:
    case libflo::opcode::LD:
    case libflo::opcode::LIT:
    case libflo::opcode::LOG2:
    case libflo::opcode::LSH:
    case libflo::opcode::LT:
    case libflo::opcode::LTE:
    case libflo::opcode::MEM:
    case libflo::opcode::MOV:
    case libflo::opcode::MSK:
    case libflo::opcode::MUL:
    case libflo::opcode::MUX:
    case libflo::opcode::NEG:
    case libflo::opcode::NEQ:
    case libflo::opcode::NOP:
    case libflo::opcode::NOT:
    case libflo::opcode::OR:
    case libflo::opcode::RD:
    case libflo::opcode::RND:
    case libflo::opcode::RSH:
    case libflo::opcode::RSHD:
    case libflo::opcode::RST:
    case libflo::opcode::ST:
    case libflo::opcode::SUB:
    case libflo::opcode::XOR:
        break;

    case libflo::opcode::WR:
        this->d()->skip_vcd_export();
        break;

    case libflo::opcode::IN:
        this->d()->force_export();
        this->d()->force_vcd_export();
        break;

    case libflo::opcode::OUT:
        this->d()->force_export();
        this->d()->force_vcd_export();
        break;

    case libflo::opcode::REG:
        this->d()->force_export();
#ifndef TORTURE_OUTPUT
        this->d()->force_vcd_export();
#endif
        break;
    }
}
