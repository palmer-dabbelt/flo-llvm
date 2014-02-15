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

#include "llvm.h++"
using namespace libcodegen;

llvm::llvm(FILE *f)
    : _f(f)
{
}

llvm::llvm(const std::string filename)
    : _f(fopen(filename.c_str(), "w"))
{
}

void llvm::declare(const function_t &f)
{
    fprintf(_f, "declare %s @%s(", f.ret_llvm().c_str(), f.name().c_str());

    auto args = f.args_llvm();
    if (args.size() > 0) {
        size_t i = 0;
        for (auto it = args.begin(); it != args.end(); ++it) {
            if (i != 0)
                fprintf(_f, ", ");
            i++;

            fprintf(_f, "%s", (*it).c_str());
        }
    }

    fprintf(_f, ")\n");
}
