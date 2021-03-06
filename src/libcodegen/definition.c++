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

#include "definition.h++"
using namespace libcodegen;

definition::definition(llvm *parent)
    : _parent(parent)
{
}

definition::~definition(void)
{
    _parent->define_finish(this);
}

void definition::comment(const std::string format, ...)
{
    va_list args;
    va_start(args, format);
    comment(format, args);
    va_end(args);
}

void definition::comment(const std::string format, va_list args)
{
    _parent->comment(format, args);
}

void definition::operate(const operation &op)
{
    _parent->operate(op);
}
