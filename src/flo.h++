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

#ifndef FLO_HXX
#define FLO_HXX

#include "node.h++"
#include "operation.h++"
#include <libflo/flo.h++>

class flo;
typedef std::shared_ptr<flo> flo_ptr;

class flo: public libflo::flo<node, operation> {
public:
    /* Returns the class name that's associated with this Flo file. */
    const std::string class_name(void) const;

    /* Produces a list that contains an element that cooresponds to
     * each width that has a node in this program.  Each width will
     * only be produced once. */
    const std::vector<size_t> used_widths(void) const;

    /* Lists every node sorted alphabetically by the node's name. */
    std::vector<std::shared_ptr<node>> nodes_alpha(void) const;

    /* Lists every node sorted by their cycle. */
    std::vector<std::shared_ptr<node>> nodes_cycle(void) const;

public:
    flo(std::map<std::string, std::shared_ptr<node>>& nodes,
        std::vector<std::shared_ptr<operation>>& ops);

public:    
    /* Parses a Flo file. */
    static const std::shared_ptr<flo> parse(const std::string filename);

};

#endif
