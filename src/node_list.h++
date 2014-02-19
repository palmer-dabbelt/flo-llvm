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

#ifndef NODE_LIST_HXX
#define NODE_LIST_HXX

#include <libflo/node_list.h++>
#include "node.h++"

class node_list {
public:
    /* Iterates over the set of nodes in this list. */
    class iter {
    private:
        std::vector<node_ptr> _nodes;
        std::vector<node_ptr>::const_iterator _it;

    public:
        iter(const std::vector<node_ptr> &nodes)
            : _nodes(nodes),
              _it(_nodes.begin())
            {
            }

        node_ptr operator*(void) const { return *_it; }
        void operator++(void) { ++_it; }
        bool done(void) const { return _it == _nodes.end(); }
    };

private:
    std::vector<node_ptr> _nodes;

public:
    /* Creates a new, empty node list. */
    node_list(void);

    /* Creates a new node list by mapping every libflo node to one of
     * our nodes. */
    node_list(const libflo::node_list &flo);

    /* Returns the size of this node list. */
    size_t size(void) const { return _nodes.size(); }

    /* Adds a node to this list, in an unspecified order. */
    node_ptr add(node_ptr a);

    /* Returns an iterator that allows us to walk this list. */
    iter nodes(void) const;
};

#endif
