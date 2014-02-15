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

#ifndef LIBCODEGEN__LLVM_HXX
#define LIBCODEGEN__LLVM_HXX

#include <memory>
#include <stdio.h>
#include <string>
#include "builtin.h++"
#include "function.h++"
#include "pointer.h++"

namespace libcodegen {
    /* Generates LLVM IR (the text-based format, not the binary one)
     * from codegen.  Note that this is an SSA format, so there's a
     * number of things you can't do that you could in C. */
    class llvm {
    private:
        FILE *_f;

    public:
        /* These constructors are private because you're only supposed
         * to accuss this trough a shared pointer. */
        llvm(FILE *f);
        llvm(const std::string filename);

        /* Emits a function declaration. */
        void declare(const function_t &f);
    };
}

#endif
