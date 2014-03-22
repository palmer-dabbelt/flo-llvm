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

#ifndef OPERATION_HXX
#define OPERATION_HXX

#include "node.h++"
#include <libflo/operation.h++>
#include <libcodegen/fix.h++>

class operation: public libflo::operation<node> {
    friend class libflo::operation<node>;

private:
    operation(std::shared_ptr<node>& dest,
              const libflo::unknown<size_t>& width,
              const libflo::opcode& op,
              const std::vector<std::shared_ptr<node>>& s);

public:
    /* A bunch of different mechanisms for refering to the codegen
     * names of this operation. */
    const libcodegen::fix_t dv(void) const { return d()->cg_name(); }
    const libcodegen::fix_t sv(size_t i) const { return s(i)->cg_name(); }
    const libcodegen::fix_t ov(size_t i) const { return o(i)->cg_name(); }
    const libcodegen::fix_t sv(void) const { return sv(0); }
    const libcodegen::fix_t tv(void) const { return sv(1); }
    const libcodegen::fix_t uv(void) const { return sv(2); }
    const libcodegen::fix_t vv(void) const { return sv(3); }

    /* Returns TRUE if this node should be written back to persistant
     * state. */
    bool writeback(void) const { return d()->exported(); }
};

#endif
