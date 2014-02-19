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

#include "node.h++"
#include <string.h>

#ifndef BUFFER_SIZE
#define BUFFER_SIZE 1024
#endif


/* Performs name mangling on a Chisel name. */
static const std::string mangle_name(const std::string flo_name);

static const std::vector<std::string>
mangle_s(const std::vector<std::string> &s);

node::node(const libflo::node_ptr n)
    : libflo::node(n->d(), n->op(), n->s()),
      _mangled_d(mangle_name(n->d())),
      _mangled_s(mangle_s(n->s())),
      _exported(strcmp(n->d().c_str(), _mangled_d.c_str()) != 0)
      
{
}

const std::string mangle_name(const std::string flo_name)
{
    char buffer[BUFFER_SIZE];
    strncpy(buffer, flo_name.c_str(), BUFFER_SIZE);

    for (size_t i = 0; i < strlen(buffer); ++i)
        if (buffer[i] == ':')
            buffer[i] = '_';

    return buffer;
}

const std::vector<std::string> mangle_s(const std::vector<std::string> &s)
{
    std::vector<std::string> out;

    for (auto it = s.begin(); it != s.end(); ++it)
        out.push_back(mangle_name(*it));

    return out;
}
