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

#include "node_list.h++"

/* This is a helper function for the constructor that just creates a
 * new node that cooresponds to every libflo node. */
static std::vector<node_ptr> map_nodes(const libflo::node_list &flo);

node_list::node_list(void)
    : _nodes()
{
}

node_list::node_list(const libflo::node_list &flo)
    : _nodes(map_nodes(flo))
{
}

std::vector<node_ptr> map_nodes(const libflo::node_list &flo)
{
    std::vector<node_ptr> out;

    for (auto it = flo.nodes(); !it.done(); ++it)
        out.push_back(node_ptr(new node(*it)));

    return out;
}

node_ptr node_list::add(node_ptr a)
{
    _nodes.push_back(a);
    return a;
}

node_list::iter node_list::nodes(void) const
{
    return node_list::iter(_nodes);
}

