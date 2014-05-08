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

#include "flo.h++"
#include <algorithm>
#include <map>
#include <vector>

#ifndef LINE_MAX
#define LINE_MAX 1024
#endif

static bool node_alpha_cmp(std::shared_ptr<node> a, std::shared_ptr<node> b);
static bool node_cycle_cmp(std::shared_ptr<node> a, std::shared_ptr<node> b);

flo::flo(std::map<std::string, std::shared_ptr<node>>& nodes,
         std::vector<std::shared_ptr<operation>>& ops)
    : libflo::flo<node, operation>(nodes, ops)
{
}

const std::string flo::class_name(void) const
{
    for (const auto& node: nodes()) {
        if (strstr(node->name().c_str(), ":") == NULL)
            continue;

        char buffer[LINE_MAX];
        strncpy(buffer, node->name().c_str(), LINE_MAX);
        strstr(buffer, ":")[0] = '\0';
        return buffer;
    }

    fprintf(stderr, "Unable to obtain class name\n");
    abort();
    return "";
}

const std::vector<size_t> flo::used_widths(void) const
{
    std::map<size_t, bool> used;
    std::vector<size_t> out;

    for (const auto& node: nodes()) {
        if (used.find(node->width()) == used.end()) {
            used[node->width()] = true;
            out.push_back(node->width());
        }
    }

    return out;
}

std::vector<std::shared_ptr<node>> flo::nodes_alpha(void) const
{
    std::vector<std::shared_ptr<node>> copy;
    for (const auto& node: nodes())
        copy.push_back(node);

    std::sort(copy.begin(), copy.end(), &node_alpha_cmp);

    return copy;
}

std::vector<std::shared_ptr<node>> flo::nodes_cycle(void) const
{
    std::vector<std::shared_ptr<node>> copy;
    for (const auto& node: nodes())
        copy.push_back(node);

    std::sort(copy.begin(), copy.end(), &node_cycle_cmp);

    return copy;
}

bool node_alpha_cmp(std::shared_ptr<node> a, std::shared_ptr<node> b)
{
    return a->name() < b->name();
}

bool node_cycle_cmp(std::shared_ptr<node> a, std::shared_ptr<node> b)
{
    return a->dfdepth() < b->dfdepth();
}

const std::shared_ptr<flo> flo::parse(const std::string filename)
{
    auto func = libflo::flo<node, operation>::create_node;

    auto f = libflo::flo<node, operation>::parse_help<flo>(filename,
                                                           func);

    return f;
}
